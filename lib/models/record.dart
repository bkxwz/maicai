/// 单笔交易记录
class Transaction {
  final String id;          // 唯一ID
  final String date;        // 日期 2026-03-27
  final String vegetable;   // 菜品：豆角/菜心/白菜/瓜软/白瓜
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

/// 每日汇总记录
class DailyRecord {
  final String date;
  final double doubang;   // 豆角
  final double caixin;    // 菜心
  final double baicai;    // 白菜
  final double guaruan;   // 瓜软
  final double baigua;    // 白瓜

  DailyRecord({
    required this.date,
    this.doubang = 0,
    this.caixin = 0,
    this.baicai = 0,
    this.guaruan = 0,
    this.baigua = 0,
  });

  double get total => doubang + caixin + baicai + guaruan + baigua;

  factory DailyRecord.fromJson(Map<String, dynamic> json) {
    return DailyRecord(
      date: json['date'] as String,
      doubang: (json['doubang'] as num?)?.toDouble() ?? 0,
      caixin: (json['caixin'] as num?)?.toDouble() ?? 0,
      baicai: (json['baicai'] as num?)?.toDouble() ?? 0,
      guaruan: (json['guaruan'] as num?)?.toDouble() ?? 0,
      baigua: (json['baigua'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'doubang': doubang,
      'caixin': caixin,
      'baicai': baicai,
      'guaruan': guaruan,
      'baigua': baigua,
    };
  }

  double getVegetableAmount(String vegetable) {
    switch (vegetable) {
      case '豆角': return doubang;
      case '菜心': return caixin;
      case '白菜': return baicai;
      case '瓜软': return guaruan;
      case '白瓜': return baigua;
      default: return 0;
    }
  }
}
