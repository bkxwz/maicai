import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/record.dart';

class StorageService {
  static const String _transactionsKey = 'vegetable_transactions';

  /// 获取所有交易记录（按时间倒序）
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
    final transactions = await getAllTransactions();
    transactions.removeWhere((t) => t.id == id);
    await _saveTransactions(transactions);
  }

  /// 获取某天的所有交易记录
  static Future<List<Transaction>> getTransactionsByDate(String date) async {
    final transactions = await getAllTransactions();
    return transactions.where((t) => t.date == date).toList();
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
        .toList();
  }

  /// 按日期汇总全部交易（日期倒序）
  static Future<List<DailySummary>> getAllDailySummaries() async {
    final transactions = await getAllTransactions();
    final Map<String, Map<String, double>> dailyMap = {};
    for (var t in transactions) {
      final amounts = dailyMap.putIfAbsent(t.date, () => {});
      amounts[t.vegetable] = (amounts[t.vegetable] ?? 0) + t.amount;
    }
    return dailyMap.entries
        .map((e) => DailySummary(date: e.key, amounts: e.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// 每个菜品的累计金额
  static Future<Map<String, double>> getTotalsByDish() async {
    final transactions = await getAllTransactions();
    final Map<String, double> totals = {};
    for (var t in transactions) {
      totals[t.vegetable] = (totals[t.vegetable] ?? 0) + t.amount;
    }
    return totals;
  }

  /// 菜品改名：把全部历史记录中的旧菜名改为新菜名
  static Future<void> renameVegetable(String oldName, String newName) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = prefs.getStringList(_transactionsKey) ?? [];
    final transactions = <Transaction>[];
    for (var json in jsonList) {
      try {
        final t = Transaction.fromJson(jsonDecode(json));
        transactions.add(t.vegetable == oldName
            ? Transaction(
                id: t.id,
                date: t.date,
                vegetable: newName,
                amount: t.amount,
                timestamp: t.timestamp,
              )
            : t);
      } catch (_) {
        continue;
      }
    }
    await _saveTransactions(transactions);
  }

  /// 从JSON导入交易记录，返回导入条数
  static Future<int> importFromJson(List<dynamic> jsonList) async {
    final transactions = await getAllTransactions();
    int count = 0;
    final baseTimestamp = DateTime.now().millisecondsSinceEpoch;

    for (var item in jsonList) {
      try {
        final ts = item['timestamp'] as int? ?? baseTimestamp + count;
        transactions.add(Transaction(
          id: '${ts}_$count',
          date: item['date'] as String,
          vegetable: item['vegetable'] as String,
          amount: (item['amount'] as num).toDouble(),
          timestamp: ts,
        ));
        count++;
      } catch (e) {
        // 跳过格式错误的记录
        continue;
      }
    }

    await _saveTransactions(transactions);
    return count;
  }

  static Future<void> _saveTransactions(List<Transaction> transactions) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = transactions.map((t) => jsonEncode(t.toJson())).toList();
    await prefs.setStringList(_transactionsKey, jsonList);
  }

  static String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}
