import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/storage_service.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('历史记录', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
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
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_grandTotal.toStringAsFixed(0)} 元',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共 ${_records.length} 天有记录',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
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
                              Text(
                                '暂无历史记录',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 18, color: Colors.green),
                    const SizedBox(width: 8),
                    Text(
                      _formatDate(record.date),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Text(
                  '小计：${record.total.toStringAsFixed(0)} 元',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _buildVegetableItem('🫘 豆角', record.doubang),
                const SizedBox(width: 8),
                _buildVegetableItem('🥬 菜心', record.caixin),
                const SizedBox(width: 8),
                _buildVegetableItem('🥦 白菜', record.baicai),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVegetableItem(String label, double amount) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: amount > 0 ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: amount > 0 ? Colors.black87 : Colors.grey,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${amount.toStringAsFixed(0)}',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: amount > 0 ? Colors.green : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
