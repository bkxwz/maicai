import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/dish.dart';
import 'storage_service.dart';

/// 菜品管理：内置菜品 + 自定义菜品，增删改名均持久化
class DishService {
  static const String _customKey = 'custom_dishes';
  static const String _removedBuiltinKey = 'removed_builtin_dishes';

  /// 内置菜品（可被删除，删除后记录保留，可随时恢复）
  static const List<Dish> builtins = [
    Dish(name: '豆角', image: 'doujiao'),
    Dish(name: '菜心', image: 'caixin'),
    Dish(name: '白菜', image: 'baicai'),
    Dish(name: '瓜软', image: 'guaruan'),
    Dish(name: '白瓜', image: 'baigua'),
  ];

  /// 当前显示的全部菜品：内置（未删除）+ 自定义
  static Future<List<Dish>> getAllDishes() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = prefs.getStringList(_removedBuiltinKey) ?? [];
    final customJson = prefs.getStringList(_customKey) ?? [];
    final customs = customJson.map((s) => Dish.fromJson(jsonDecode(s))).toList();
    return [...builtins.where((d) => !removed.contains(d.name)), ...customs];
  }

  /// 已被删除的内置菜品（用于"恢复默认"）
  static Future<List<Dish>> getRemovedBuiltins() async {
    final prefs = await SharedPreferences.getInstance();
    final removed = prefs.getStringList(_removedBuiltinKey) ?? [];
    return builtins.where((d) => removed.contains(d.name)).toList();
  }

  static Future<bool> exists(String name) async {
    final dishes = await getAllDishes();
    return dishes.any((d) => d.name == name);
  }

  /// 添加自定义菜品（photo 为 base64 图片，可空），同名返回 false
  static Future<bool> addCustomDish(String name, String? photo) async {
    if (await exists(name)) return false;
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getStringList(_customKey) ?? [];
    customJson.add(jsonEncode(Dish(name: name, photo: photo).toJson()));
    await prefs.setStringList(_customKey, customJson);
    return true;
  }

  /// 恢复某个内置菜品
  static Future<void> restoreBuiltin(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final removed = prefs.getStringList(_removedBuiltinKey) ?? [];
    removed.remove(name);
    await prefs.setStringList(_removedBuiltinKey, removed);
  }

  /// 删除菜品：历史记录保留，只是主界面不再显示
  static Future<void> removeDish(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final isBuiltinName = builtins.any((d) => d.name == name);
    if (isBuiltinName) {
      final removed = prefs.getStringList(_removedBuiltinKey) ?? [];
      if (!removed.contains(name)) removed.add(name);
      await prefs.setStringList(_removedBuiltinKey, removed);
    } else {
      final customJson = prefs.getStringList(_customKey) ?? [];
      final kept = customJson.where((s) {
        try {
          return Dish.fromJson(jsonDecode(s)).name != name;
        } catch (_) {
          return false;
        }
      }).toList();
      await prefs.setStringList(_customKey, kept);
    }
  }

  /// 给自定义菜品设置/更新图片（base64）
  static Future<void> setCustomPhoto(String name, String photo) async {
    final prefs = await SharedPreferences.getInstance();
    final customJson = prefs.getStringList(_customKey) ?? [];
    final updated = customJson.map((s) {
      try {
        final dish = Dish.fromJson(jsonDecode(s));
        if (dish.name == name) {
          return jsonEncode(Dish(name: dish.name, image: dish.image, photo: photo).toJson());
        }
        return s;
      } catch (_) {
        return s;
      }
    }).toList();
    await prefs.setStringList(_customKey, updated);
  }

  /// 把选中的图片缩小并转为 base64 PNG（存 SharedPreferences 足够小）
  /// 失败（格式不支持等）返回 null
  static Future<String?> processImageBytes(Uint8List bytes) async {
    try {
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 160);
      final frame = await codec.getNextFrame();
      final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
      if (data == null) return null;
      return base64Encode(data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes));
    } catch (_) {
      return null;
    }
  }

  /// 改名：更新菜品表，并把全部历史记录中的旧菜名一并改为新菜名
  static Future<bool> renameDish(String oldName, String newName) async {
    if (oldName == newName) return true;
    if (await exists(newName)) return false;

    final prefs = await SharedPreferences.getInstance();
    final isBuiltinName = builtins.any((d) => d.name == oldName);

    if (isBuiltinName) {
      // 内置菜品改名 → 移入自定义菜品，保留原图片
      final removed = prefs.getStringList(_removedBuiltinKey) ?? [];
      if (!removed.contains(oldName)) removed.add(oldName);
      await prefs.setStringList(_removedBuiltinKey, removed);

      final builtin = builtins.firstWhere((d) => d.name == oldName);
      final customJson = prefs.getStringList(_customKey) ?? [];
      customJson.add(jsonEncode(Dish(name: newName, image: builtin.image).toJson()));
      await prefs.setStringList(_customKey, customJson);
    } else {
      final customJson = prefs.getStringList(_customKey) ?? [];
      final updated = customJson.map((s) {
        try {
          final dish = Dish.fromJson(jsonDecode(s));
          if (dish.name == oldName) {
            return jsonEncode(Dish(name: newName, photo: dish.photo).toJson());
          }
          return s;
        } catch (_) {
          return s;
        }
      }).toList();
      await prefs.setStringList(_customKey, updated);
    }

    await StorageService.renameVegetable(oldName, newName);
    return true;
  }
}
