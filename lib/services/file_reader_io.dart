/// 按路径读取文本文件（Android/iOS/桌面）
import 'dart:io';

Future<String> readFilePath(String path) => File(path).readAsString();
