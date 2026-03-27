import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../utils/lunar_helper.dart';
import 'vegetable_detail.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailyRecord> _records = [];
  double _grandTotal = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final records = await StorageService.getAllRecords();
    double total = 0;
    for (var record in records) {
      total += record.total;
    }
    
    setState(() {
      _records = records;
      _grandTotal = total;
      _isLoading = false;
    });
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.year}年${date.month}月${date.day}日';
  }
  
  String _getLunarDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return LunarHelper.getLunarDate(date);
  }
  
  bool _isToday(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Future<void> _exportSummary() async {
    try {
      await ExportService.shareSummary();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('分享失败：$e')),
        );
      }
    }
  }

  Future<void> _deleteDayRecords(String date) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text('确定要删除 $_formatDate(date) 的所有记录吗？', style: const TextStyle(fontSize: 16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('取消', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final transactions = await StorageService.getTransactionsByDate(date);
      for (var t in transactions) {
        await StorageService.deleteTransaction(t.id);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('已删除'), backgroundColor: Colors.orange),
        );
      }
      _loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: _exportSummary,
            icon: const Icon(Icons.share, size: 26),
            tooltip: '分享统计',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  color: Colors.green,
                  child: Column(
                    children: [
                      const Text(
                        '累计总收入',
                        style: TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${_grandTotal.toStringAsFixed(1)} 元',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共 ${_records.length} 天有记录',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _records.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('暂无历史记录', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _records.length,
                          itemBuilder: (context, index) {
                            final record = _records[index];
                            return _buildDayCard(record);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(DailyRecord record) {
    final isToday = _isToday(record.date);
    final hasRecord = record.total > 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: isToday ? Border.all(color: Colors.green, width: 3) : null,
          boxShadow: [
            BoxShadow(
              color: hasRecord ? Colors.green.withOpacity(0.15) : Colors.black.withOpacity(0.08),
              blurRadius: hasRecord ? 10 : 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 头部 - 完整填充
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: hasRecord 
                    ? (isToday ? Colors.green : Colors.green.shade50) 
                    : Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        if (isToday) 
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              '今天',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        const SizedBox(width: 6),
                        Icon(Icons.calendar_today, 
                          size: 20, 
                          color: hasRecord ? (isToday ? Colors.white : Colors.green) : Colors.grey
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatDate(record.date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: hasRecord 
                                  ? (isToday ? Colors.white : Colors.green.shade700) 
                                  : Colors.grey,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // 金额和删除按钮
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: hasRecord 
                              ? (isToday ? Colors.white : Colors.green) 
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${record.total.toStringAsFixed(1)} 元',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: hasRecord 
                                ? (isToday ? Colors.green : Colors.white) 
                                : Colors.grey,
                          ),
                        ),
                      ),
                      if (hasRecord) ...[
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _deleteDayRecords(record.date),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: Colors.red.shade400,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            // 农历和菜品明细
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
              color: Colors.white,
              child: Column(
                children: [
                  Text(
                    _getLunarDate(record.date),
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildVegetableItem('🫘 豆角', record.doubang),
                      const SizedBox(width: 8),
                      _buildVegetableItem('🥬 菜心', record.caixin),
                      const SizedBox(width: 8),
                      _buildVegetableItem('🥦 白菜', record.baicai),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVegetableItem(String label, double amount) {
    final hasAmount = amount > 0;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: hasAmount ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(10),
          border: hasAmount ? Border.all(color: Colors.green.shade200) : null,
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: hasAmount ? FontWeight.bold : FontWeight.normal,
                color: hasAmount ? Colors.green.shade700 : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(1)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: hasAmount ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
