import 'package:flutter/material.dart';
import 'dart:convert';
import '../models/record.dart';
import '../services/storage_service.dart';

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
      
      setState(() {
        _status = '✓ 成功导入 $count 条记录！';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _status = '✗ 导入失败：JSON格式错误\n$e';
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
              '支持导入之前导出的JSON格式数据',
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
                      '提示：从"分享"功能导出的数据可以直接粘贴导入',
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
