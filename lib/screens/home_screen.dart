import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../services/sound_service.dart';
import '../services/export_service.dart';
import '../widgets/numpad.dart';
import '../utils/lunar_helper.dart';
import 'vegetable_detail.dart';
import 'history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedVegetable = '';
  String _inputValue = '0';
  DailyRecord? _todayRecord;
  bool _isLoading = true;

  final List<Map<String, String>> _vegetables = [
    {'name': '豆角', 'emoji': '🫘'},
    {'name': '菜心', 'emoji': '🥬'},
    {'name': '白菜', 'emoji': '🥦'},
  ];

  @override
  void initState() {
    super.initState();
    _loadTodayRecord();
  }

  Future<void> _loadTodayRecord() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final record = await StorageService.getRecordByDate(today);
    setState(() {
      _todayRecord = record ?? DailyRecord(date: today);
      _isLoading = false;
    });
  }

  String get _formattedDate {
    final now = DateTime.now();
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[now.weekday % 7];
    return '${now.month}月${now.day}日 $weekday';
  }

  double _getVegetableAmount(String name) {
    if (_todayRecord == null) return 0;
    return _todayRecord!.getVegetableAmount(name);
  }

  void _onKeyTap(String key) {
    SoundService.playKeyClick();
    setState(() {
      // 处理小数点
      if (key == '.') {
        if (_inputValue.contains('.')) return;
        if (_inputValue == '0') {
          _inputValue = '0.';
        } else {
          _inputValue += '.';
        }
        return;
      }
      
      // 处理数字
      if (_inputValue == '0') {
        _inputValue = key;
      } else if (_inputValue.contains('.')) {
        final parts = _inputValue.split('.');
        if (parts[1].length < 2 && _inputValue.length < 8) {
          _inputValue += key;
        }
      } else if (_inputValue.length < 6) {
        _inputValue += key;
      }
    });
  }

  void _onClear() {
    SoundService.playKeyClick();
    setState(() {
      _inputValue = '0';
    });
  }

  void _onConfirm() {
    if (_selectedVegetable.isEmpty) {
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请先选择菜品', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    final amount = double.tryParse(_inputValue) ?? 0;
    if (amount <= 0) {
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入金额', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    SoundService.playConfirm();
    _saveAmount(_selectedVegetable, amount);
  }

  Future<void> _saveAmount(String vegetable, double amount) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // 创建新的交易记录
    final transaction = Transaction(
      date: today,
      vegetable: vegetable,
      amount: amount,
    );
    
    await StorageService.addTransaction(transaction);
    
    // 重新加载今日记录
    final record = await StorageService.getRecordByDate(today);
    
    SoundService.playSuccess();
    
    setState(() {
      _todayRecord = record ?? DailyRecord(date: today);
      _inputValue = '0';
      _selectedVegetable = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ $vegetable +${amount.toStringAsFixed(1)} 元', style: const TextStyle(fontSize: 20)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _selectVegetable(String name) {
    SoundService.playKeyClick();
    setState(() {
      _selectedVegetable = name;
      _inputValue = '0';
    });
  }

  void _navigateToDetail(String vegetable) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VegetableDetailScreen(vegetable: vegetable),
      ),
    );
  }

  Future<void> _exportData() async {
    try {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('导出数据', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          content: const Text('请选择导出方式', style: TextStyle(fontSize: 18)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, 'csv'),
              child: const Text('导出Excel', style: TextStyle(fontSize: 18)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, 'summary'),
              child: const Text('分享统计', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      );

      if (choice == 'csv') {
        await ExportService.exportAndShare();
      } else if (choice == 'summary') {
        await ExportService.shareSummary();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('导出失败：$e', style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final total = _todayRecord?.total ?? 0;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: _exportData,
          icon: const Icon(Icons.share, size: 28),
          tooltip: '导出数据',
        ),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const HistoryScreen()),
              );
            },
            icon: const Icon(Icons.history, size: 28),
            tooltip: '历史记录',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 日期和合计 - 压缩高度
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.green,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formattedDate,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '合计 ${total.toStringAsFixed(1)} 元',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      LunarHelper.getLunarDate(DateTime.now()),
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.green.shade100,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 三个菜品并排显示
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: _vegetables.asMap().entries.map((entry) {
                  final v = entry.value;
                  final name = v['name']!;
                  final emoji = v['emoji']!;
                  final amount = _getVegetableAmount(name);
                  final isSelected = _selectedVegetable == name;
                  
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: GestureDetector(
                        onTap: () => _selectVegetable(name),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.green.shade50 : Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Colors.green : Colors.grey.shade300,
                              width: isSelected ? 3 : 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: isSelected 
                                    ? Colors.green.withOpacity(0.3) 
                                    : Colors.black.withOpacity(0.08),
                                blurRadius: isSelected ? 8 : 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(emoji, style: const TextStyle(fontSize: 32)),
                                  const SizedBox(height: 2),
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isSelected ? Colors.green.shade700 : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.green : Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      '${amount.toStringAsFixed(1)}元',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: isSelected ? Colors.white : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              // 详情按钮
                              Positioned(
                                top: -6,
                                right: -6,
                                child: GestureDetector(
                                  onTap: () => _navigateToDetail(name),
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: Colors.blue,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.bar_chart, size: 12, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            
            // 输入金额显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedVegetable.isEmpty ? '请选择菜品' : '输入 $_selectedVegetable：',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _selectedVegetable.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Text(
                      '$_inputValue 元',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w900,
                        color: Colors.green,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // 数字键盘 - 使用Flexible确保不会溢出
            Flexible(
              child: NumPad(
                onKeyTap: _onKeyTap,
                onClear: _onClear,
                onConfirm: _onConfirm,
                currentValue: _inputValue,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
