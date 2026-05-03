// 金额格式化：整数不显示小数，有小数如实显示
String formatAmount(double amount) {
  if (amount % 1 == 0) return amount.toInt().toString();
  var s = amount.toStringAsFixed(2);
  s = s.replaceAll(RegExp(r'0+$'), '');
  if (s.endsWith('.')) s = s.substring(0, s.length - 1);
  return s;
}
