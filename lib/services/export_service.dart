import 'dart:convert';
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
    buffer.writeln('日期,豆角(元),菜心(元),白菜(元),瓜软(元),白瓜(元),合计(元)');
    
    for (var record in records) {
      buffer.writeln(
        '${record.date},${record.doubang.toStringAsFixed(1)},${record.caixin.toStringAsFixed(1)},${record.baicai.toStringAsFixed(1)},${record.guaruan.toStringAsFixed(1)},${record.baigua.toStringAsFixed(1)},${record.total.toStringAsFixed(1)}'
      );
    }

    // 创建CSV文件
    final directory = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final csvFile = File('${directory.path}/卖菜记账_$timestamp.csv');
    await csvFile.writeAsString(buffer.toString(), encoding: utf8);
    
    // 同时导出JSON（可导入）
    final transactions = await StorageService.getAllTransactions();
    final jsonStr = jsonEncode(transactions.map((t) => t.toJson()).toList());
    final jsonFile = File('${directory.path}/卖菜记账_$timestamp.json');
    await jsonFile.writeAsString(jsonStr, encoding: utf8);

    // 分享文件
    await Share.shareXFiles(
      [XFile(csvFile.path, mimeType: 'text/csv'), XFile(jsonFile.path, mimeType: 'application/json')],
      text: '卖菜记账数据导出（CSV+JSON）',
    );
  }

  /// 导出JSON（可导入格式）
  static Future<void> exportJson() async {
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
      text: '卖菜记账数据（可导入）',
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
    double totalGuaruan = 0;
    double totalBaigua = 0;
    
    for (var record in records) {
      totalDoubang += record.doubang;
      totalCaixin += record.caixin;
      totalBaicai += record.baicai;
      totalGuaruan += record.guaruan;
      totalBaigua += record.baigua;
    }
    
    final grandTotal = totalDoubang + totalCaixin + totalBaicai + totalGuaruan + totalBaigua;
    
    buffer.writeln('📅 共记录 ${records.length} 天');
    buffer.writeln('💰 累计收入：${grandTotal.toStringAsFixed(1)} 元');
    buffer.writeln('');
    buffer.writeln('🫘 豆角：${totalDoubang.toStringAsFixed(1)} 元');
    buffer.writeln('🥬 菜心：${totalCaixin.toStringAsFixed(1)} 元');
    buffer.writeln('🥦 白菜：${totalBaicai.toStringAsFixed(1)} 元');
    buffer.writeln('🥒 瓜软：${totalGuaruan.toStringAsFixed(1)} 元');
    buffer.writeln('🍈 白瓜：${totalBaigua.toStringAsFixed(1)} 元');
    buffer.writeln('');
    buffer.writeln('━━━━━━━━━━━━━━━━━━');
    
    // 最近7天
    buffer.writeln('📈 最近记录：');
    final recentRecords = records.take(7).toList();
    for (var record in recentRecords) {
      final date = DateTime.parse(record.date);
      buffer.writeln('${date.month}/${date.day}：${record.total.toStringAsFixed(1)}元');
    }
    
    return buffer.toString();
  }

  /// 分享文字摘要
  static Future<void> shareSummary() async {
    final summary = await generateSummary();
    await Share.share(summary, subject: '卖菜记账统计');
  }

  /// 分享数据 - 纯JSON格式（可导入）
  static Future<void> shareJson() async {
    final transactions = await StorageService.getAllTransactions();
    
    if (transactions.isEmpty) {
      throw Exception('暂无记录可导出');
    }

    // 生成纯JSON数组，无额外文字
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
}
