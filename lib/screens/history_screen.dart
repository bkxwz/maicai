import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../services/dish_service.dart';
import '../services/export_service.dart';
import '../utils/format.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailySummary> _summaries = [];
  Map<String, double> _totalsByDish = {};
  List<Dish> _dishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final summaries = await StorageService.getAllDailySummaries();
    final totals = await StorageService.getTotalsByDish();
    final dishes = await DishService.getAllDishes();

    setState(() {
      _summaries = summaries;
      _totalsByDish = totals;
      _dishes = dishes;
      _isLoading = false;
    });
  }

  double get _grandTotal => _totalsByDish.values.fold(0, (sum, v) => sum + v);

  /// 展示顺序：当前菜品在前，已删除但有记录的菜名在后
  List<String> get _allDishNames {
    final names = _dishes.map((d) => d.name).toList();
    for (var name in _totalsByDish.keys) {
      if (!names.contains(name)) names.add(name);
    }
    return names;
  }

  String _formatDate(String dateStr) {
    final date = DateTime.parse(dateStr);
    return '${date.year}年${date.month}月${date.day}日';
  }

  bool _isToday(String dateStr) {
    final date = DateTime.parse(dateStr);
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  Dish? _findDish(String name) {
    try {
      return _dishes.firstWhere((d) => d.name == name);
    } catch (_) {
      return null;
    }
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
                          '${formatAmount(_grandTotal)} 元',
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '共 ${_summaries.length} 天有记录',
                        style: const TextStyle(fontSize: 14, color: Colors.white70),
                      ),
                      const SizedBox(height: 12),
                      // 各菜品总收入（按实际菜品动态显示）
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Wrap(
                          alignment: WrapAlignment.spaceEvenly,
                          runSpacing: 8,
                          children: _allDishNames
                              .map((name) => _buildTotalItem(name, _totalsByDish[name] ?? 0))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _summaries.isEmpty
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
                          itemCount: _summaries.length,
                          itemBuilder: (context, index) {
                            return _buildDayCard(_summaries[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildDayCard(DailySummary record) {
    final isToday = _isToday(record.date);

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
              color: Colors.green.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            // 头部
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: isToday ? Colors.green : Colors.green.shade50,
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
                            color: isToday ? Colors.white : Colors.green),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _formatDate(record.date),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isToday ? Colors.white : Colors.green.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${formatAmount(record.total)} 元',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isToday ? Colors.white : Colors.green.shade700,
                    ),
                  ),
                ],
              ),
            ),
            // 菜品明细（当天有记录的菜品）
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 12),
              color: Colors.white,
              child: Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _allDishNames
                    .where((name) => record.amountOf(name) > 0)
                    .map((name) => _buildDishItem(name, record.amountOf(name)))
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalItem(String name, double amount) {
    final dish = _findDish(name);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dish != null)
                Text(dish.emoji, style: const TextStyle(fontSize: 13))
              else
                Icon(Icons.help_outline, size: 13, color: Colors.white70),
              const SizedBox(width: 3),
              Text(
                name,
                style: const TextStyle(fontSize: 13, color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formatAmount(amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDishItem(String name, double amount) {
    final dish = _findDish(name);
    return Container(
      width: 76,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dish != null)
                Text(dish.emoji, style: const TextStyle(fontSize: 16))
              else
                Icon(Icons.help_outline, size: 16, color: Colors.grey),
              const SizedBox(width: 3),
              Flexible(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            formatAmount(amount),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
