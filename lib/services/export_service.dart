import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/storage_service.dart';
import '../services/dish_service.dart';
import '../utils/format.dart';

class ExportService {
  /// 分享全部数据（纯JSON数组，可在"导入"中粘贴恢复）
  static Future<void> shareJson() async {
    final transactions = await StorageService.getAllTransactions();

    if (transactions.isEmpty) {
      throw Exception('暂无记录可导出');
    }

    final jsonStr = jsonEncode(transactions.map((t) => t.toJson()).toList());
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/卖菜记账_$timestamp.json');
    await file.writeAsString(jsonStr, encoding: utf8);

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/json')],
      text: '卖菜记账数据',
    );
  }

  /// 生成文字摘要（用于直接分享到聊天）
  static Future<String> generateSummary() async {
    final summaries = await StorageService.getAllDailySummaries();

    if (summaries.isEmpty) {
      return '暂无卖菜记录';
    }

    final totals = await StorageService.getTotalsByDish();
    final dishes = await DishService.getAllDishes();

    // 展示顺序：当前菜品在前，已删除但有记录的菜名在后
    final names = dishes.map((d) => d.name).toList();
    for (var name in totals.keys) {
      if (!names.contains(name)) names.add(name);
    }

    final grandTotal = totals.values.fold(0.0, (sum, v) => sum + v);

    final buffer = StringBuffer();
    buffer.writeln('📊 卖菜记账统计');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    buffer.writeln('📅 共记录 ${summaries.length} 天');
    buffer.writeln('💰 累计收入：${formatAmount(grandTotal)} 元');
    buffer.writeln('');

    for (var name in names) {
      final dish = dishes.where((d) => d.name == name).firstOrNull;
      buffer.writeln('${dish?.emoji ?? '🥬'} $name：${formatAmount(totals[name] ?? 0)} 元');
    }

    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');

    // 最近7天
    buffer.writeln('📈 最近记录：');
    final recent = summaries.take(7);
    for (var record in recent) {
      final date = DateTime.parse(record.date);
      buffer.writeln('${date.month}/${date.day}：${formatAmount(record.total)}元');
    }

    return buffer.toString();
  }

  /// 分享文字摘要
  static Future<void> shareSummary() async {
    final summary = await generateSummary();
    await Share.share(summary, subject: '卖菜记账统计');
  }
}
