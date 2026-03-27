import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/record.dart';

class StorageService {
  static const String _recordsKey = 'vegetable_records';

  static Future<List<DailyRecord>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final recordsJson = prefs.getStringList(_recordsKey) ?? [];
    return recordsJson
        .map((json) => DailyRecord.fromJson(jsonDecode(json)))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static Future<DailyRecord?> getRecordByDate(String date) async {
    final records = await getAllRecords();
    try {
      return records.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveRecord(DailyRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    final index = records.indexWhere((r) => r.date == record.date);
    
    if (index >= 0) {
      records[index] = record;
    } else {
      records.add(record);
    }
    
    final recordsJson = records.map((r) => jsonEncode(r.toJson())).toList();
    await prefs.setStringList(_recordsKey, recordsJson);
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
