/// 菜品定义：内置菜品带图片，自定义菜品用 emoji 显示
class Dish {
  final String name;
  final String? image;   // 内置图片资源名（如 doujiao），自定义菜品为 null
  final String emoji;    // 显示用表情

  const Dish({required this.name, this.image, this.emoji = '🥬'});

  bool get isBuiltin => image != null;

  Map<String, dynamic> toJson() => {'name': name, 'emoji': emoji, 'image': image};

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '🥬',
        image: json['image'] as String?,
      );
}
