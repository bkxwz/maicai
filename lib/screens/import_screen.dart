import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import '../models/record.dart';
import '../services/storage_service.dart';
import '../services/dish_service.dart';
import '../services/file_reader.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen> {
  final TextEditingController _textController = TextEditingController();
  String _status = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _importFromJson(String jsonStr) async {
    setState(() {
      _isLoading = true;
      _status = '正在导入...';
    });

    try {
      final List<dynamic> jsonList = jsonDecode(jsonStr);
      final count = await StorageService.importFromJson(jsonList);

      // 记录里出现但菜品列表缺失的菜名，自动补建（图标用名称首字）
      final names = <String>{};
      for (var item in jsonList) {
        try {
          names.add(item['vegetable'] as String);
        } catch (_) {}
      }
      final addedDishes = await DishService.addMissingDishes(names);

      setState(() {
        _status = addedDishes > 0
            ? '✓ 成功导入 $count 条记录！\n并自动添加了 $addedDishes 个菜品'
            : '✓ 成功导入 $count 条记录！';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '✗ 导入失败：JSON格式错误\n$e';
        _isLoading = false;
      });
    }
  }

  /// 从 .json / .txt 文件导入
  Future<void> _importFromFile() async {
    setState(() {
      _isLoading = true;
      _status = '正在读取文件...';
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json', 'txt'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) {
        // 用户取消选择
        setState(() {
          _isLoading = false;
          _status = '';
        });
        return;
      }

      final file = result.files.single;
      String content;
      if (file.bytes != null) {
        content = const Utf8Decoder(allowMalformed: true).convert(file.bytes!);
      } else if (file.path != null) {
        content = await readFilePath(file.path!);
      } else {
        throw Exception('无法读取所选文件');
      }

      _importFromJson(content);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = '✗ 读取文件失败：$e';
        _isLoading = false;
      });
    }
  }

  void _showPasteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('粘贴JSON数据', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: TextField(
          controller: _textController,
          maxLines: 10,
          decoration: const InputDecoration(
            hintText: '在此粘贴JSON数据...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('取消', style: TextStyle(fontSize: 16)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (_textController.text.isNotEmpty) {
                _importFromJson(_textController.text);
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.green),
            child: const Text('导入', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  void _showSampleFormat() {
    final sample = jsonEncode([
      {
        'date': '2026-03-27',
        'vegetable': '豆角',
        'amount': 12.5,
        'timestamp': DateTime.now().millisecondsSinceEpoch
      },
      {
        'date': '2026-03-27',
        'vegetable': '菜心',
        'amount': 8.0,
        'timestamp': DateTime.now().millisecondsSinceEpoch + 1
      }
    ]);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('JSON格式示例', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        content: SingleChildScrollView(
          child: Text(
            const JsonEncoder.withIndent('  ').convert(jsonDecode(sample)),
            style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('知道了', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('导入数据', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22)),
        centerTitle: true,
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '从其他设备导入卖菜记录',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '支持粘贴JSON数据，或导入之前分享的 .json 文件',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 30),

            // 粘贴JSON按钮
            ElevatedButton.icon(
              onPressed: _showPasteDialog,
              icon: const Icon(Icons.content_paste, size: 28),
              label: const Text('粘贴JSON数据', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 从文件导入按钮
            ElevatedButton.icon(
              onPressed: _importFromFile,
              icon: const Icon(Icons.folder_open, size: 28),
              label: const Text('从文件导入', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green, width: 2),
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // 查看格式示例
            OutlinedButton.icon(
              onPressed: _showSampleFormat,
              icon: const Icon(Icons.help_outline, size: 24),
              label: const Text('查看JSON格式示例', style: TextStyle(fontSize: 16)),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            
            const SizedBox(height: 30),
            
            // 状态显示
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_status.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _status.startsWith('✓') ? Colors.green.shade50 : Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _status.startsWith('✓') ? Colors.green : Colors.red,
                  ),
                ),
                child: Text(
                  _status,
                  style: TextStyle(
                    fontSize: 16,
                    color: _status.startsWith('✓') ? Colors.green.shade700 : Colors.red.shade700,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            
            const Spacer(),
            
            // 提示
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.info, color: Colors.blue.shade700, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '提示：「分享 → 复制数据」的内容可直接粘贴导入；「分享 → 分享文件」的 .json 文件可用「从文件导入」恢复',
                      style: TextStyle(fontSize: 13, color: Colors.blue.shade700),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
