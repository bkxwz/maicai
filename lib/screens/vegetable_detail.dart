import 'package:flutter/material.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../utils/lunar_helper.dart';

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
  List<Transaction> _transactions = [];
  double _total = 0;
  bool _isLoading = true;

  String get _vegetableImage {
    switch (widget.vegetable) {
      case '豆角':
        return 'doujiao';
      case '菜心':
        return 'caixin';
      case '白菜':
        return 'baicai';
      case '瓜软':
        return 'guaruan';
      case '白瓜':
        return 'baigua';
      default:
        return 'caixin';
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
    
    final transactions = await StorageService.getTransactionsByVegetableAndRange(
      widget.vegetable,
      _startDate,
      _endDate,
    );
    
    double total = 0;
    for (var t in transactions) {
      total += t.amount;
    }
    
    setState(() {
      _transactions = transactions;
      _total = total;
      _isLoading = false;
    });
  }

  void _switchToThisMonth() {
    setState(() => _isThisMonth = true);
    _initThisMonth();
    _loadData();
  }

  void _selectLastWeek() {
    final now = DateTime.now();
    setState(() {
      _isThisMonth = false;
      _endDate = now;
      _startDate = now.subtract(const Duration(days: 7));
    });
    _loadData();
  }

  void _selectLastMonth() {
    final now = DateTime.now();
    final lastMonth = DateTime(now.year, now.month - 1, 1);
    final lastMonthEnd = DateTime(now.year, now.month, 0);
    setState(() {
      _isThisMonth = false;
      _startDate = lastMonth;
      _endDate = lastMonthEnd;
    });
    _loadData();
  }

  Future<void> _selectCustomRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (context, child) {
        return Localizations.override(
          context: context,
          locale: const Locale('zh', 'CN'),
          child: Theme(
            data: ThemeData.light().copyWith(
              colorScheme: const ColorScheme.light(primary: Colors.green),
            ),
            child: child!,
          ),
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

  Future<void> _deleteTransaction(Transaction transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('确认删除', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          '确定要删除这笔记录吗？\n\n${transaction.vegetable}：${transaction.amount.toStringAsFixed(1)} 元',
          style: const TextStyle(fontSize: 16),
        ),
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
      await StorageService.deleteTransaction(transaction.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('已删除', style: TextStyle(fontSize: 16)),
            backgroundColor: Colors.orange,
          ),
        );
      }
      _loadData();
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.month}月${date.day}日';
  }
  
  String _getLunarDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return LunarHelper.getLunarDate(date);
  }

  String _formatDateRange() {
    final start = '${_startDate.month}月${_startDate.day}日';
    final end = '${_endDate.month}月${_endDate.day}日';
    return '$start - $end';
  }

  /// 按日期分组交易记录
  Map<String, List<Transaction>> _groupByDate() {
    final Map<String, List<Transaction>> grouped = {};
    for (var t in _transactions) {
      if (!grouped.containsKey(t.date)) {
        grouped[t.date] = [];
      }
      grouped[t.date]!.add(t);
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/${_vegetableImage}_80.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.vegetable, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
          ],
        ),
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
                        _isThisMonth ? '本月销售总额' : '期间销售总额',
                        style: const TextStyle(fontSize: 18, color: Colors.white70),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          '${_total.toStringAsFixed(1)} 元',
                          style: const TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '共 ${_transactions.length} 笔记录',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                // 时间范围选择
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.grey.shade100,
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(child: _buildQuickButton('本月', _isThisMonth, _switchToThisMonth)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildQuickButton('近一周', false, _selectLastWeek)),
                          const SizedBox(width: 8),
                          Expanded(child: _buildQuickButton('上月', false, _selectLastMonth)),
                        ],
                      ),
                      const SizedBox(height: 10),
                      GestureDetector(
                        onTap: _selectCustomRange,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              _isThisMonth ? '📅 自定义日期范围' : '📅 ${_formatDateRange()}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 交易记录列表（按日期分组，显示每笔）
                Expanded(
                  child: _transactions.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text('该时段暂无记录', style: TextStyle(fontSize: 18, color: Colors.grey.shade600)),
                            ],
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.all(16),
                          children: _buildTransactionList(),
                        ),
                ),
              ],
            ),
    );
  }

  List<Widget> _buildTransactionList() {
    final grouped = _groupByDate();
    final widgets = <Widget>[];
    
    for (var entry in grouped.entries) {
      final date = entry.key;
      final transactions = entry.value;
      final dayTotal = transactions.fold<double>(0, (sum, t) => sum + t.amount);
      
      // 日期标题
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Row(
            children: [
              Text(
                _formatDate(date),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
              ),
              const SizedBox(width: 8),
              Text(
                _getLunarDate(date),
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              const Spacer(),
              Text(
                '小计 ${dayTotal.toStringAsFixed(1)} 元',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.green),
              ),
            ],
          ),
        ),
      );
      
      // 该天的所有交易
      for (var t in transactions) {
        widgets.add(
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.08),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                // 时间
                Container(
                  width: 50,
                  child: Text(
                    _getTimeFromTimestamp(t.timestamp),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                ),
                // 金额
                Expanded(
                  child: Text(
                    '${t.amount.toStringAsFixed(1)} 元',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ),
                // 删除按钮
                GestureDetector(
                  onTap: () => _deleteTransaction(t),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }
    
    return widgets;
  }

  String _getTimeFromTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildQuickButton(String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? Colors.green : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.green),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isActive ? Colors.white : Colors.green,
            ),
          ),
        ),
      ),
    );
  }
}
