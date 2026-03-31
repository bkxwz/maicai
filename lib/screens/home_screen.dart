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
import 'import_screen.dart';

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

  // 5个菜品
  final List<Map<String, String>> _vegetables = [
    {'name': '豆角', 'image': 'doujiao'},
    {'name': '菜心', 'image': 'caixin'},
    {'name': '白菜', 'image': 'baicai'},
    {'name': '瓜软', 'image': 'guaruan'},
    {'name': '白瓜', 'image': 'baigua'},
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
      if (key == '.') {
        if (_inputValue.contains('.')) return;
        if (_inputValue == '0') {
          _inputValue = '0.';
        } else {
          _inputValue += '.';
        }
        return;
      }
      
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
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text('请先选择菜品再输入金额！', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      // 不清零，保持原数字
      return;
    }

    final amount = double.tryParse(_inputValue) ?? 0;
    if (amount <= 0) {
      SoundService.playError();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('请输入金额', style: TextStyle(fontSize: 16)),
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
    
    final transaction = Transaction(
      date: today,
      vegetable: vegetable,
      amount: amount,
    );
    
    await StorageService.addTransaction(transaction);
    await _loadTodayRecord();
    
    SoundService.playSuccess();
    
    setState(() {
      _inputValue = '0';
      _selectedVegetable = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ $vegetable +${amount.toStringAsFixed(1)} 元', style: const TextStyle(fontSize: 18)),
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
      // 不清零数字，保持原值
    });
  }

  void _navigateToDetail(String vegetable) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VegetableDetailScreen(vegetable: vegetable),
      ),
    );
    _loadTodayRecord();
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
      body: SafeArea(
        child: Column(
          children: [
            // 顶部栏 - 图标+文字横向排列
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.green,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildTopBarItem(Icons.share, '分享', () async {
                    try {
                      await ExportService.shareJson();
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('分享失败：$e')),
                        );
                      }
                    }
                  }),
                  _buildTopBarItem(Icons.download, '导入', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ImportScreen()),
                    );
                  }),
                  _buildTopBarItem(Icons.history, '历史', () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    );
                  }),
                ],
              ),
            ),
            
            // 日期和今日合计
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: Colors.green,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formattedDate,
                    style: const TextStyle(fontSize: 15, color: Colors.white, fontWeight: FontWeight.w500),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '今日合计 ${total.toStringAsFixed(1)} 元',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            
            // 农历
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(left: 12, bottom: 6),
              color: Colors.green,
              child: Text(
                LunarHelper.getLunarDate(DateTime.now()),
                style: TextStyle(fontSize: 12, color: Colors.green.shade100),
              ),
            ),
            
            // 5个菜品 - 一行紧凑显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              color: Colors.grey.shade100,
              child: Row(
                children: _vegetables.map((v) => _buildCompactVegetableCard(v)).toList(),
              ),
            ),
            
            // 输入金额显示
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              color: Colors.white,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _selectedVegetable.isEmpty ? '请选择菜品' : '$_selectedVegetable：',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: _selectedVegetable.isEmpty ? Colors.grey : Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: Text(
                      '$_inputValue 元',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            
            // 数字键盘 - 完整显示
            Flexible(
              fit: FlexFit.tight,
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

  Widget _buildTopBarItem(IconData icon, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactVegetableCard(Map<String, String> v) {
    final name = v['name']!;
    final imageName = v['image']!;
    final amount = _getVegetableAmount(name);
    final isSelected = _selectedVegetable == name;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => _selectVegetable(name),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.green.shade50 : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? Colors.green : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 圆形图片
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected ? Colors.green : Colors.grey.shade300,
                        width: 2,
                      ),
                    ),
                    child: ClipOval(
                      child: Container(
                        color: Colors.white,
                        alignment: Alignment.center,
                        child: Image.asset(
                          'assets/images/${imageName}_80.png',
                          width: 44,
                          height: 44,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? Colors.green.shade700 : Colors.black87,
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.green : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${amount.toStringAsFixed(1)}',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        color: isSelected ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                ],
              ),
              // 详情按钮 - 悬浮在图片上方
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => _navigateToDetail(name),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.bar_chart, size: 16, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
