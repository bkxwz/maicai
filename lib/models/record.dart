/// 单笔交易记录
class Transaction {
  final String id;          // 唯一ID
  final String date;        // 日期 2026-03-27
  final String vegetable;   // 菜品：豆角/菜心/白菜
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

  Transaction copyWith({
    String? date,
    String? vegetable,
    double? amount,
  }) {
    return Transaction(
      id: id,
      date: date ?? this.date,
      vegetable: vegetable ?? this.vegetable,
      amount: amount ?? this.amount,
      timestamp: timestamp,
    );
  }
}

/// 每日汇总记录（保持兼容）
class DailyRecord {
  final String date;
  final double doubang;
  final double caixin;
  final double baicai;

  DailyRecord({
    required this.date,
    this.doubang = 0,
    this.caixin = 0,
    this.baicai = 0,
  });

  double get total => doubang + caixin + baicai;

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: json['date'] as String,
      doubang: (json['doubang'] as num?)?.toDouble() ?? 0,
      caixin: (json['caixin'] as num?)?.toDouble() ?? 0,
      baicai: (json['baicai'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'doubang': doubang,
      'caixin': caixin,
      'baicai': baicai,
    };
  }

  DailyRecord copyWith({
    String? date,
    double? doubang,
    double? caixin,
    double? baicai,
  }) {
    return DailyRecord(
      date: date ?? this.date,
      doubang: doubang ?? this.doubang,
      caixin: caixin ?? this.caixin,
      baicai: baicai ?? this.baicai,
    );
  }

  double getVegetableAmount(String vegetable) {
    switch (vegetable) {
      case '豆角':
        return doubang;
      case '菜心':
        return caixin;
      case '白菜':
        return baicai;
      default:
        return 0;
    }
  }
}
