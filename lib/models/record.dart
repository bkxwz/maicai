class DailyRecord {
  final String date; // 格式: 2026-03-27
  final double doubang; // 豆角
  final double caixin;  // 菜心
  final double baicai;  // 白菜

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
