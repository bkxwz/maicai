/// Web 端不支持路径读文件（应使用 bytes 或粘贴导入）
Future<String> readFilePath(String path) async {
  throw Exception('Web端无法按路径读取文件，请使用粘贴导入');
}
