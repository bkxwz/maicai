import 'package:flutter/material.dart';
import '../models/dish.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../services/dish_service.dart';
import '../services/export_service.dart';
import '../utils/format.dart';
import '../widgets/dish_icon.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<DailySummary> _allSummaries = [];
  List<Dish> _dishes = [];
  bool _isLoading = true;
  String _range = '全部'; // 全部 / 本周 / 本月 / 本年

  static const List<String> _rangeOptions = ['全部', '本周', '本月', '本年'];

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  Future<void> _loadRecords() async {
    final summaries = await StorageService.getAllDailySummaries();
    final dishes = await DishService.getAllDishes();

    setState(() {
      _allSummaries = summaries;
      _dishes = dishes;
      _isLoading = false;
    });
  }

  /// 当前筛选的起始日期（null = 全部）
  DateTime? _rangeStart() {
    final now = DateTime.now();
    switch (_range) {
      case '本周':
        return DateTime(now.year, now.month, now.day - (now.weekday - 1));
      case '本月':
        return DateTime(now.year, now.month, 1);
      case '本年':
        return DateTime(now.year, 1, 1);
      default:
        return null;
    }
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// 当前筛选范围内的每日汇总
  List<DailySummary> get _summaries {
    final start = _rangeStart();
    if (start == null) return _allSummaries;
    final startStr = _fmt(start);
    return _allSummaries.where((s) => s.date.compareTo(startStr) >= 0).toList();
  }

  /// 当前筛选范围内各菜品累计金额
  Map<String, double> get _totalsByDish {
    final totals = <String, double>{};
    for (var s in _summaries) {
      s.amounts.forEach((dish, amount) {
        totals[dish] = (totals[dish] ?? 0) + amount;
      });
    }
    return totals;
  }

  double get _grandTotal => _totalsByDish.values.fold(0, (sum, v) => sum + v);

  /// 展示顺序：当前菜品在前，已删除但有记录的菜名在后
  List<String> _allDishNames(Map<String, double> totals) {
    final names = _dishes.map((d) => d.name).toList();
    for (var name in totals.keys) {
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
    final summaries = _summaries;
    final totals = _totalsByDish;

    return Scaffold(
      appBar: AppBar(
        title: const Text('总收入', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
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
                      const SizedBox(height: 12),
                      // 时间范围快捷按钮（金额正下方）
                      Row(
                        children: _rangeOptions
                            .map((option) => _buildRangeButton(option))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _range == '全部'
                            ? '共 ${summaries.length} 天有记录'
                            : '$_range共 ${summaries.length} 天有记录',
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
                          children: _allDishNames(totals)
                              .map((name) => _buildTotalItem(name, totals[name] ?? 0))
                              .toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: summaries.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox, size: 64, color: Colors.grey.shade400),
                              const SizedBox(height: 16),
                              Text(
                                _range == '全部' ? '暂无历史记录' : '$_range暂无记录',
                                style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: summaries.length,
                          itemBuilder: (context, index) {
                            return _buildDayCard(summaries[index]);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRangeButton(String option) {
    final isActive = _range == option;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _range = option),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white),
          ),
          child: Center(
            child: Text(
              option,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                color: isActive ? Colors.green : Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDayCard(DailySummary record) {
    final isToday = _isToday(record.date);

    // 外层负责 margin/边框/阴影，内层 ClipRRect 负责把内容裁进圆角，
    // 两者尺寸一致，白色内容才不会刺穿圆角
    return Container(
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
      child: ClipRRect(
        borderRadius: BorderRadius.circular(isToday ? 13 : 16),
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
                children: _allDishNames(record.amounts)
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
                DishIcon(dish: dish, size: 14)
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
                DishIcon(dish: dish, size: 18)
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
