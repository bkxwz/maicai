import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import '../models/dish.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../services/dish_service.dart';
import '../services/sound_service.dart';
import '../services/export_service.dart';
import '../widgets/numpad.dart';
import '../widgets/dish_icon.dart';
import '../utils/format.dart';
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
  Map<String, double> _todayAmounts = {};
  List<Dish> _dishes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  Future<void> _reload() async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final transactions = await StorageService.getTransactionsByDate(today);
    final dishes = await DishService.getAllDishes();

    final Map<String, double> amounts = {};
    for (var t in transactions) {
      amounts[t.vegetable] = (amounts[t.vegetable] ?? 0) + t.amount;
    }

    setState(() {
      _todayAmounts = amounts;
      _dishes = dishes;
      _isLoading = false;
    });
  }

  String get _formattedDate {
    final now = DateTime.now();
    final weekdays = ['周日', '周一', '周二', '周三', '周四', '周五', '周六'];
    final weekday = weekdays[now.weekday % 7];
    return '${now.month}月${now.day}日 $weekday';
  }

  double get _todayTotal => _todayAmounts.values.fold(0, (sum, v) => sum + v);

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
            children: const [
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
    await _reload();

    SoundService.playSuccess();

    setState(() {
      _inputValue = '0';
      _selectedVegetable = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✓ $vegetable +${formatAmount(amount)} 元', style: const TextStyle(fontSize: 18)),
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
    });
  }

  void _navigateToDetail(Dish dish) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VegetableDetailScreen(dish: dish),
      ),
    );
    _reload();
  }

  // ==================== 分享 ====================

  /// 分享菜单：复制（默认）/ 分享文本 / 分享文件
  void _showShareSheet() {
    SoundService.playKeyClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 16, bottom: 4),
              child: Text(
                '分享数据',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'JSON格式，可在「导入」中恢复全部记录',
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ),
            _buildShareTile(
              icon: Icons.content_copy,
              title: '复制数据',
              subtitle: '复制到剪贴板，去「导入」粘贴即可恢复',
              primary: true,
              onTap: () => _runShare(sheetContext, ExportService.copyJsonData, '✓ 已复制，可在「导入」中粘贴恢复'),
            ),
            _buildShareTile(
              icon: Icons.text_fields,
              title: '分享文本',
              subtitle: '把数据作为文字消息发送',
              primary: false,
              onTap: () => _runShare(sheetContext, ExportService.shareJsonText),
            ),
            _buildShareTile(
              icon: Icons.attach_file,
              title: '分享文件',
              subtitle: '发送 .json 文件，可通过「从文件导入」恢复',
              primary: false,
              onTap: () => _runShare(sheetContext, ExportService.shareJsonFile),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildShareTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool primary,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: primary ? Colors.green : Colors.green.shade50,
        ),
        child: Icon(icon, color: primary ? Colors.white : Colors.green, size: 26),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: primary ? FontWeight.bold : FontWeight.w500,
          color: primary ? Colors.green.shade700 : Colors.black87,
        ),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 13)),
      onTap: onTap,
    );
  }

  Future<void> _runShare(BuildContext sheetContext, Future<void> Function() action, [String? successMessage]) async {
    Navigator.pop(sheetContext);
    try {
      await action();
      if (!mounted) return;
      if (successMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage, style: const TextStyle(fontSize: 16)),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$e'.replaceFirst('Exception: ', ''), style: const TextStyle(fontSize: 16)),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ==================== 菜品管理 ====================

  void _showAddDishDialog() {
    showDialog(
      context: context,
      builder: (context) => _AddDishDialog(
        existingNames: _dishes.map((d) => d.name).toList(),
        onAdded: () {
          _reload();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('菜品已添加', style: TextStyle(fontSize: 16)),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 1),
            ),
          );
        },
      ),
    );
  }

  void _showManageDishSheet(Dish dish) {
    SoundService.playKeyClick();
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  DishIcon(dish: dish, size: 30),
                  const SizedBox(width: 8),
                  Text(
                    dish.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.analytics, color: Colors.green, size: 28),
              title: const Text('查看详情', style: TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _navigateToDetail(dish);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.blue, size: 28),
              title: const Text('改名', style: TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _showRenameDialog(dish);
              },
            ),
            // 自定义菜品可设置/更换图片
            if (dish.image == null)
              ListTile(
                leading: const Icon(Icons.image, color: Colors.orange, size: 28),
                title: Text(
                  dish.photo == null ? '设置图片' : '更换图片',
                  style: const TextStyle(fontSize: 18),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _pickPhotoFor(dish);
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_outline, color: Colors.red, size: 28),
              title: const Text('删除（历史记录保留）', style: TextStyle(fontSize: 18)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDeleteDish(dish);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// 从相册选图并设为自定义菜品的图标
  Future<void> _pickPhotoFor(Dish dish) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      _showPhotoError('无法读取所选图片');
      return;
    }
    final photo = await DishService.processImageBytes(bytes);
    if (photo == null) {
      _showPhotoError('不支持的图片格式');
      return;
    }
    await DishService.setCustomPhoto(dish.name, photo);
    if (!mounted) return;
    _reload();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ 图片已更新', style: TextStyle(fontSize: 16)),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _showPhotoError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showRenameDialog(Dish dish) {
    final controller = TextEditingController(text: dish.name);
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('菜品改名', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 6,
          style: const TextStyle(fontSize: 20),
          decoration: const InputDecoration(hintText: '输入新名称'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () async {
              final newName = controller.text.trim();
              if (newName.isEmpty) return;
              Navigator.pop(dialogContext);
              final ok = await DishService.renameDish(dish.name, newName);
              if (!mounted) return;
              if (ok) {
                if (_selectedVegetable == dish.name) {
                  setState(() => _selectedVegetable = newName);
                }
                _reload();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('已改名，历史记录同步更新', style: TextStyle(fontSize: 16)),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('「$newName」已存在', style: const TextStyle(fontSize: 16)),
                    backgroundColor: Colors.orange,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('确定', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteDish(Dish dish) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('删除菜品', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        content: Text(
          '确定删除「${dish.name}」吗？\n\n历史记录会保留，仍计入收入合计。',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('取消', style: TextStyle(fontSize: 18)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await DishService.removeDish(dish.name);
              if (!mounted) return;
              if (_selectedVegetable == dish.name) {
                setState(() => _selectedVegetable = '');
              }
              _reload();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('已删除「${dish.name}」，历史记录保留', style: const TextStyle(fontSize: 16)),
                  backgroundColor: Colors.orange,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('删除', style: TextStyle(fontSize: 18)),
          ),
        ],
      ),
    );
  }

  // ==================== 界面 ====================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
                  _buildTopBarItem(Icons.share, '分享', _showShareSheet),
                  _buildTopBarItem(Icons.download, '导入', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ImportScreen()),
                    );
                    _reload();
                  }),
                  _buildTopBarItem(Icons.analytics, '总收入', () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const HistoryScreen()),
                    );
                    _reload();
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
                      '今日 ${formatAmount(_todayTotal)} 元',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),

            // 菜品区：可滚动，支持任意数量 + 添加按钮
            Flexible(
              fit: FlexFit.tight,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    ..._dishes.map((d) => _buildDishCard(d)),
                    _buildAddDishCard(),
                  ],
                ),
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

            // 数字键盘 - 固定在底部
            NumPad(
              onKeyTap: _onKeyTap,
              onClear: _onClear,
              onConfirm: _onConfirm,
              currentValue: _inputValue,
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

  Widget _buildDishCard(Dish dish) {
    final name = dish.name;
    final amount = _todayAmounts[name] ?? 0;
    final isSelected = _selectedVegetable == name;

    return GestureDetector(
      onTap: () => _selectVegetable(name),
      onLongPress: () => _showManageDishSheet(dish),
      child: Container(
        width: 68,
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 详情按钮 - 独立一行在最上面
            GestureDetector(
              onTap: () => _navigateToDetail(dish),
              child: Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '详情',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
            DishIcon(
              dish: dish,
              size: 44,
              borderColor: isSelected ? Colors.green : Colors.grey.shade300,
            ),
            const SizedBox(height: 2),
            Text(
              name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
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
                formatAmount(amount),
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
      ),
    );
  }

  /// "添加菜品"卡片
  Widget _buildAddDishCard() {
    return GestureDetector(
      onTap: _showAddDishDialog,
      child: Container(
        width: 68,
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: Colors.green,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // 占位对齐详情按钮行
            const SizedBox(height: 20),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.shade50,
                border: Border.all(color: Colors.green, width: 2),
              ),
              child: const Icon(Icons.add, color: Colors.green, size: 32),
            ),
            const SizedBox(height: 2),
            Text(
              '添加',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade700,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

/// 添加菜品对话框：名称 + 上传图片（可选，不上传用名称首字当图标）
class _AddDishDialog extends StatefulWidget {
  final List<String> existingNames;
  final VoidCallback onAdded;

  const _AddDishDialog({required this.existingNames, required this.onAdded});

  @override
  State<_AddDishDialog> createState() => _AddDishDialogState();
}

class _AddDishDialogState extends State<_AddDishDialog> {
  final TextEditingController _nameController = TextEditingController();
  String? _photo; // base64 图片
  String _error = '';
  bool _picking = false;
  List<Dish> _removedBuiltins = [];

  @override
  void initState() {
    super.initState();
    _loadRemovedBuiltins();
  }

  Future<void> _loadRemovedBuiltins() async {
    final removed = await DishService.getRemovedBuiltins();
    if (mounted) setState(() => _removedBuiltins = removed);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );
      if (result != null && result.files.isNotEmpty) {
        final bytes = result.files.single.bytes;
        final photo = bytes == null ? null : await DishService.processImageBytes(bytes);
        if (!mounted) return;
        if (photo == null) {
          setState(() => _error = '不支持的图片格式，请换一张试试');
        } else {
          setState(() {
            _photo = photo;
            _error = '';
          });
        }
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = '请输入菜品名称');
      return;
    }
    if (widget.existingNames.contains(name) ||
        _removedBuiltins.any((d) => d.name == name)) {
      setState(() => _error = '「$name」已存在');
      return;
    }
    final ok = await DishService.addCustomDish(name, _photo);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
      widget.onAdded();
    } else {
      setState(() => _error = '「$name」已存在');
    }
  }

  Future<void> _restore(Dish dish) async {
    await DishService.restoreBuiltin(dish.name);
    if (!mounted) return;
    Navigator.pop(context);
    widget.onAdded();
  }

  @override
  Widget build(BuildContext context) {
    final previewName = _nameController.text.trim().isEmpty ? '菜' : _nameController.text.trim();

    return AlertDialog(
      title: const Text('添加菜品', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              maxLength: 6,
              style: const TextStyle(fontSize: 20),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(hintText: '输入菜品名称（如：芥蓝）'),
            ),
            const SizedBox(height: 8),
            // 图片上传（可选）
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [
                  DishIcon(dish: Dish(name: previewName, photo: _photo), size: 40),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('菜品图片（可选）', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 2),
                        Text(
                          _photo == null ? '不上传则用名称当图标' : '已选择图片',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      OutlinedButton.icon(
                        onPressed: _picking ? null : _pickPhoto,
                        icon: _picking
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.photo_library, size: 20),
                        label: Text(
                          _photo == null ? '选图片' : '更换',
                          style: const TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.green,
                          side: const BorderSide(color: Colors.green),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        ),
                      ),
                      if (_photo != null)
                        TextButton(
                          onPressed: () => setState(() => _photo = null),
                          child: const Text('移除图片', style: TextStyle(fontSize: 12)),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red.shade400,
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
                            minimumSize: Size(0, 28),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_error, style: TextStyle(fontSize: 14, color: Colors.red.shade700)),
            ],
            if (_removedBuiltins.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('恢复默认菜品：', style: TextStyle(fontSize: 14, color: Colors.grey)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _removedBuiltins.map((dish) {
                  return ActionChip(
                    avatar: DishIcon(dish: dish, size: 16),
                    label: Text(dish.name, style: const TextStyle(fontSize: 16)),
                    backgroundColor: Colors.green.shade50,
                    onPressed: () => _restore(dish),
                  );
                }).toList(),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消', style: TextStyle(fontSize: 18)),
        ),
        TextButton(
          onPressed: _save,
          style: TextButton.styleFrom(foregroundColor: Colors.green),
          child: const Text('添加', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
