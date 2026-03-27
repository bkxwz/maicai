import 'package:flutter/services.dart';

class SoundService {
  /// 按键音 - 系统点击音效 + 轻触反馈
  static Future<void> playKeyClick() async {
    try {
      await SystemSound.play(SystemSoundType.click);
      HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// 确认音 - 双击音效 + 中等触反馈
  static Future<void> playConfirm() async {
    try {
      HapticFeedback.mediumImpact();
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 完成提示音 - 连续点击 + 重触反馈
  static Future<void> playSuccess() async {
    try {
      HapticFeedback.heavyImpact();
      await SystemSound.play(SystemSoundType.click);
      await Future.delayed(const Duration(milliseconds: 80));
      await SystemSound.play(SystemSoundType.click);
    } catch (_) {}
  }

  /// 错误提示音
  static Future<void> playError() async {
    try {
      HapticFeedback.heavyImpact();
    } catch (_) {}
  }
}
