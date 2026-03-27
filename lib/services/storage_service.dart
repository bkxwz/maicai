import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/record.dart';

class StorageService {
  static const String _recordsKey = 'vegetable_records';
  static const String _transactionsKey = 'vegetable_transactions';

  // ==================== 交易记录（新） ====================
  
  /// 获取所有交易记录
  static Future<List<Transaction>> getAllTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_transactionsKey) ?? [];
    return jsonList
        .map((json) => Transaction.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 添加交易记录
  static Future<void> addTransaction(Transaction transaction) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getAllTransactions();
    transactions.add(transaction);
    await _saveTransactions(transactions);
  }

  /// 删除交易记录
  static Future<void> deleteTransaction(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getAllTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  /// 获取某天某菜品的交易记录
  static Future<List<Transaction>> getTransactionsByDateAndVegetable(
    String date,
    String vegetable,
  ) async {
    final transactions = await getAllTransactions();
    return transactions
        .where((t) => t.date == date && t.vegetable == vegetable)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 获取某天的所有交易记录
  static Future<List<Transaction>> getTransactionsByDate(String date) async {
    final transactions = await getAllTransactions();
    return transactions
        .where((t) => t.date == date)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  /// 获取某菜品在时间范围内的交易记录
  static Future<List<Transaction>> getTransactionsByVegetableAndRange(
    String vegetable,
    DateTime start,
    DateTime end,
  ) async {
    final transactions = await getAllTransactions();
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    return transactions
        .where((t) => 
            t.vegetable == vegetable &&
            t.date.compareTo(startStr) >= 0 && 
            t.date.compareTo(endStr) <= 0)
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  static Future<void> _saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, jsonList);
  }

  /// 从JSON导入交易记录
  static Future<int> importFromJson(List<dynamic> jsonList) async {
    final prefs = await SharedPreferences.getInstance();
    final transactions = await getAllTransactions();
    int count = 0;
    
    for (var item in jsonList) {
      try {
        final transaction = Transaction(
          date: item['date'] as String,
          vegetable: item['vegetable'] as String,
          amount: (item['amount'] as num).toDouble(),
          timestamp: item['timestamp'] as int? ?? DateTime.now().millisecondsSinceEpoch + count,
        );
        transactions.add(transaction);
        count++;
      } catch (e) {
        // 跳过格式错误的记录
        continue;
      }
    }
    
    final jsonListStr = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, jsonListStr);
    return count;
  }

  // ==================== 日汇总记录（兼容旧版） ====================

  static Future<List<DailyRecord>> getAllRecords() async {
    // 从交易记录生成日汇总
    final transactions = await getAllTransactions();
    final Map<String, DailyRecord> dailyMap = {};
    
    for (var t in transactions) {
      final existing = dailyMap[t.date];
      double doubang = existing?.doubang ?? 0;
      double caixin = existing?.caixin ?? 0;
      double baicai = existing?.baicai ?? 0;
      double guaruan = existing?.guaruan ?? 0;
      double baigua = existing?.baigua ?? 0;
      
      switch (t.vegetable) {
        case '豆角': doubang += t.amount; break;
        case '菜心': caixin += t.amount; break;
        case '白菜': baicai += t.amount; break;
        case '瓜软': guaruan += t.amount; break;
        case '白瓜': baigua += t.amount; break;
      }
      
      dailyMap[t.date] = DailyRecord(
        date: t.date,
        doubang: doubang,
        caixin: caixin,
        baicai: baicai,
        guaruan: guaruan,
        baigua: baigua,
      );
    }
    
    return dailyMap.values.toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<DailyRecord?> getRecordByDate(String date) async {
    final transactions = await getTransactionsByDate(date);
    if (transactions.isEmpty) return null;
    
    double doubang = 0, caixin = 0, baicai = 0, guaruan = 0, baigua = 0;
    for (var t in transactions) {
      switch (t.vegetable) {
        case '豆角': doubang += t.amount; break;
        case '菜心': caixin += t.amount; break;
        case '白菜': baicai += t.amount; break;
        case '瓜软': guaruan += t.amount; break;
        case '白瓜': baigua += t.amount; break;
      }
    }
    
    return DailyRecord(
      date: date, 
      doubang: doubang, 
      caixin: caixin, 
      baicai: baicai,
      guaruan: guaruan,
      baigua: baigua,
    );
  }

  static Future<void> saveRecord(DailyRecord record) {
    // 保留兼容，但实际使用addTransaction
    return Future.value();
  }

  static Future<List<DailyRecord>> getRecordsByDateRange(
    DateTime start,
    DateTime end,
  ) async {
    final records = await getAllRecords();
    final startStr = _formatDate(start);
    final endStr = _formatDate(end);
    
    return records.where((r) {
      return r.date.compareTo(startStr) >= 0 && r.date.compareTo(endStr) <= 0;
    }).toList()
      ..sort((a, b) => a.date.compareTo(b.date));
  }

  static Future<double> getVegetableTotal(
    String vegetable,
    DateTime start,
    DateTime end,
  ) async {
    final records = await getRecordsByDateRange(start, end);
    double total = 0;
    for (var record in records) {
      total += record.getVegetableAmount(vegetable);
    }
    return total;
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
