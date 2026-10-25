/// 跨平台文件读取：Web 用空实现，其他平台用 dart:io
export 'file_reader_io.dart' if (dart.library.html) 'file_reader_web.dart';
