import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/dish.dart';

/// 菜品圆形图标，统一三种来源：
/// 内置图片 > 用户上传图片 > 名称首字
class DishIcon extends StatelessWidget {
  final Dish dish;
  final double size;          // 内容尺寸，外圈再包 2px 边框
  final Color? borderColor;   // 传 null 用默认灰色

  const DishIcon({super.key, required this.dish, this.size = 44, this.borderColor});

  @override
  Widget build(BuildContext context) {
    final hasPhoto = dish.image != null || dish.photo != null;
    final border = borderColor ?? (size >= 24 ? Colors.grey.shade300 : Colors.transparent);
    final isNameChar = !hasPhoto;
    final inner = isNameChar ? size : size + 4;

    Widget content;
    if (dish.image != null) {
      content = Image.asset(
        'assets/images/${dish.image}_80.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      );
    } else if (dish.photo != null) {
      content = Image.memory(
        base64Decode(dish.photo!),
        width: size,
        height: size,
        fit: BoxFit.cover,
        gaplessPlayback: true,
      );
    } else {
      final char = dish.name.isEmpty ? '菜' : dish.name.substring(0, 1);
      content = Text(
        char,
        style: TextStyle(
          fontSize: size * 0.55,
          fontWeight: FontWeight.bold,
          color: Colors.green.shade700,
        ),
      );
    }

    return Container(
      width: inner + 4,
      height: inner + 4,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isNameChar ? Colors.green.shade50 : Colors.white,
        border: border == Colors.transparent ? null : Border.all(color: border, width: 2),
      ),
      child: ClipOval(
        child: Container(alignment: Alignment.center, child: content),
      ),
    );
  }
}
