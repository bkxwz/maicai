import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../services/storage_service.dart';

class VegetableDetailScreen extends StatefulWidget {
  final String vegetable;

  const VegetableDetailScreen({super.key, required this.vegetable});

  @override
  State<VegetableDetailScreen> createState() => _VegetableDetailScreenState();
}

class _VegetableDetailScreenState extends State<VegetableDetailScreen> {
  bool _isThisMonth = true;
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  List<DailyRecord> _records = [];
  double _total = 0;
  bool _isLoading = true;

  String get _emoji {
    switch (widget.vegetable) {
      case '豆角':
        return '🫘';
      case '菜心':
        return '🥬';
      case '白菜':
        return '🥦';
      default:
        return '🥬';
    }
  }

  @override
  void initState() {
    super.initState();
    _initThisMonth();
    _loadData();
  }

  void _initThisMonth() {
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = now;
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    final records = await StorageService.getRecordsByDateRange(_startDate, _endDate);
    double total = 0;
    for (var record in records) {
      total += record.getVegetableAmount(widget.vegetable);
    }
    
    setState(() {
      _records = records.where((r) => r.getVegetableAmount(widget.vegetable) > 0).toList()
        ..sort((a, b) => b.date.compareTo(a.date));
      _total = total;
      _isLoading = false;
    });
  }

  void _switchToThisMonth() {
    setState(() => _isThisMonth = true);
    _initThisMonth();
    _loadData();
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Colors.green),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _isThisMonth = false;
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadData();
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  String _formatDateRange() {
    final start = DateFormat('MM-dd').format(_startDate);
    final end = DateFormat('MM-dd').format(_endDate);
    return '$start 至 $end';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$_emoji ${widget.vegetable}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                      Text(
                        _isThisMonth ? '本月销售总额' : '销售总额',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${_total.toStringAsFixed(0)} 元',
                          style: const TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
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
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: _switchToThisMonth,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _isThisMonth ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Center(
                              child: Text(
                                '本月',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _isThisMonth ? Colors.white : Colors.green,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: _selectDateRange,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: !_isThisMonth ? Colors.green : Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.green),
                            ),
                            child: Center(
                              child: Text(
                                !_isThisMonth ? _formatDateRange() : '自定义',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: !_isThisMonth ? Colors.white : Colors.green,
                                ),
                              ),
                            ),
                          ),
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
                                '暂无记录',
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
                            final amount = record.getVegetableAmount(widget.vegetable);
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    _formatDate(record.date),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  Text(
                                    '${amount.toStringAsFixed(0)} 元',
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.green,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
