import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
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
    return LunarHelper.getFullDateString(DateTime.now());
  }

  double _getVegetableAmount(String name) {
    if (_todayRecord == null) return 0;
    return _todayRecord!.getVegetableAmount(name);
  }

  void _onKeyTap(String key) {
    setState(() {
      if (_inputValue == '0') {
        _inputValue = key;
      } else if (_inputValue.length < 6) {
        _inputValue += key;
      }
    });
  }

  void _onClear() {
    setState(() {
      _inputValue = '0';
    });
  }

  void _onConfirm() {
    if (_selectedVegetable.isEmpty) {
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入金额', style: TextStyle(fontSize: 18)),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 1),
        ),
      );
      return;
    }

    _saveAmount(_selectedVegetable, amount);
  }

  Future<void> _saveAmount(String vegetable, double amount) async {
    if (_todayRecord == null) return;

    DailyRecord newRecord;
    switch (vegetable) {
      case '豆角':
        newRecord = _todayRecord!.copyWith(doubang: _todayRecord!.doubang + amount);
        break;
      case '菜心':
        newRecord = _todayRecord!.copyWith(caixin: _todayRecord!.caixin + amount);
        break;
      case '白菜':
        newRecord = _todayRecord!.copyWith(baicai: _todayRecord!.baicai + amount);
        break;
      default:
        return;
    }

    await StorageService.saveRecord(newRecord);
    
    setState(() {
      _todayRecord = newRecord;
      _inputValue = '0';
      _selectedVegetable = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('已记录 $vegetable +${amount.toStringAsFixed(0)} 元', style: const TextStyle(fontSize: 18)),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  void _selectVegetable(String name) {
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
        title: const Text('卖菜记账', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // 日期和合计
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            color: Colors.green,
            child: Column(
              children: [
                Text(
                  _formattedDate,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Text(
                    '今日合计：${total.toStringAsFixed(0)} 元',
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
          
          const SizedBox(height: 16),
          
          // 三个菜品并排显示
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: _vegetables.asMap().entries.map((entry) {
                final v = entry.value;
                final name = v['name']!;
                final emoji = v['emoji']!;
                final amount = _getVegetableAmount(name);
                final isSelected = _selectedVegetable == name;
                
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: GestureDetector(
                      onTap: () => _selectVegetable(name),
                      onLongPress: () => _navigateToDetail(name),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isSelected ? Colors.green.shade50 : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected ? Colors.green : Colors.grey.shade300,
                            width: isSelected ? 3 : 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSelected 
                                  ? Colors.green.withOpacity(0.3) 
                                  : Colors.black.withOpacity(0.08),
                              blurRadius: isSelected ? 10 : 6,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Text(
                              emoji,
                              style: const TextStyle(fontSize: 40),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: isSelected ? Colors.green.shade700 : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.green : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${amount.toStringAsFixed(0)} 元',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: isSelected ? Colors.white : Colors.black87,
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
          
          const SizedBox(height: 12),
          
          // 输入金额显示
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _selectedVegetable.isEmpty ? '请选择菜品' : '输入 $_selectedVegetable：',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: _selectedVegetable.isEmpty ? Colors.grey : Colors.black87,
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Text(
                    '$_inputValue 元',
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                      color: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // 数字键盘
          Expanded(
            child: NumPad(
              onKeyTap: _onKeyTap,
              onClear: _onClear,
              onConfirm: _onConfirm,
              currentValue: _inputValue,
            ),
          ),
          
          // 历史记录按钮
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HistoryScreen()),
                );
              },
              icon: const Icon(Icons.history, size: 24),
              label: const Text('查看历史记录', style: TextStyle(fontSize: 18)),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
            ),
          ),
        ],
      ),
    );
  }
}
