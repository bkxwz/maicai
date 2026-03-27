import 'package:flutter/services.dart';

class SoundService {
  static final SoundService _instance = SoundService._internal();
  factory SoundService() => _instance;
  SoundService._internal();

  /// 按键音
  static Future<void> playKeyClick() async {
    try {
      await SystemChannels.platform.invokeMethod<void>('SystemSound.play', 'click');
    } catch (_) {}
  }

  /// 确认音
  static Future<void> playConfirm() async {
    try {
      await SystemChannels.platform.invokeMethod<void>('SystemSound.play', 'click');
    } catch (_) {}
  }

  /// 完成提示音
  static Future<void> playSuccess() async {
    try {
      await SystemChannels.platform.invokeMethod<void>('SystemSound.play', 'click');
    } catch (_) {}
  }
}
