import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/record.dart';
import 'storage_service.dart';

class ExportService {
  /// 导出所有记录为CSV格式并分享
  static Future<void> exportAndShare() async {
    final records = await StorageService.getAllRecords();
    
    if (records.isEmpty) {
      throw Exception('暂无记录可导出');
    }

    // 生成CSV内容
    final StringBuffer buffer = StringBuffer();
    buffer.writeln('日期,豆角(元),菜心(元),白菜(元),合计(元)');
    
    for (var record in records) {
      buffer.writeln(
        '${record.date},${record.doubang.toStringAsFixed(0)},${record.caixin.toStringAsFixed(0)},${record.baicai.toStringAsFixed(0)},${record.total.toStringAsFixed(0)}'
      );
    }

    // 创建临时文件
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${directory.path}/卖菜记账_$timestamp.csv');
    await file.writeAsString(buffer.toString(), encoding: utf8);

    // 分享文件
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'text/csv')],
      text: '卖菜记账数据导出',
    );
  }

  /// 生成文字摘要（用于直接分享到聊天）
  static Future<String> generateSummary() async {
    final records = await StorageService.getAllRecords();
    
    if (records.isEmpty) {
      return '暂无卖菜记录';
    }

    final buffer = StringBuffer();
    buffer.writeln('📊 卖菜记账统计');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    
    // 计算总计
    double totalDoubang = 0;
    double totalCaixin = 0;
    double totalBaicai = 0;
    
    for (var record in records) {
      totalDoubang += record.doubang;
      totalCaixin += record.caixin;
      totalBaicai += record.baicai;
    }
    
    final grandTotal = totalDoubang + totalCaixin + totalBaicai;
    
    buffer.writeln('📅 共记录 ${records.length} 天');
    buffer.writeln('💰 累计收入：${grandTotal.toStringAsFixed(0)} 元');
    buffer.writeln('');
    buffer.writeln('🫘 豆角：${totalDoubang.toStringAsFixed(0)} 元');
    buffer.writeln('🥬 菜心：${totalCaixin.toStringAsFixed(0)} 元');
    buffer.writeln('🥦 白菜：${totalBaicai.toStringAsFixed(0)} 元');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    
    // 最近7天
    buffer.writeln('📈 最近记录：');
    final recentRecords = records.take(7).toList();
    for (var record in recentRecords) {
      final date = DateTime.parse(record.date);
      buffer.writeln('${date.month}/${date.day}：${record.total.toStringAsFixed(0)}元');
    }
    
    return buffer.toString();
  }

  /// 分享文字摘要
  static Future<void> shareSummary() async {
    final summary = await generateSummary();
    await Share.share(summary, subject: '卖菜记账统计');
  }
}

// 需要的import
import 'dart:convert';
