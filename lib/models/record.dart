/// 单笔交易记录
class Transaction {
  final String id;          // 唯一ID
  final String date;        // 日期 2026-03-27
  final String vegetable;   // 菜品名
  final double amount;      // 金额
  final int timestamp;      // 时间戳，用于排序

  Transaction({
    String? id,
    required this.date,
    required this.vegetable,
    required this.amount,
    int? timestamp,
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        timestamp = timestamp ?? DateTime.now().millisecondsSinceEpoch;

  factory Transaction.fromJson(Map<String, dynamic> json) {
    return Transaction(
      id: json['id'] as String? ?? DateTime.now().millisecondsSinceEpoch.toString(),
      date: json['date'] as String,
      vegetable: json['vegetable'] as String,
      amount: (json['amount'] as num).toDouble(),
      timestamp: json['timestamp'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'vegetable': vegetable,
      'amount': amount,
      'timestamp': timestamp,
    };
  }
}

/// 每日汇总（按菜品名动态汇总，不绑定固定菜品）
class DailySummary {
  final String date;
  final Map<String, double> amounts; // 菜品名 -> 当日金额

  DailySummary({required this.date, Map<String, double>? amounts})
      : amounts = amounts ?? {};

  double get total => amounts.values.fold(0, (sum, v) => sum + v);

  double amountOf(String dish) => amounts[dish] ?? 0;
}
