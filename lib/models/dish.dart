/// 菜品定义：内置菜品带资源图片，自定义菜品可上传图片（base64），
/// 都没有时用名称首字当图标
class Dish {
  final String name;
  final String? image;   // 内置图片资源名（如 doujiao），仅内置菜品有
  final String? photo;   // 自定义菜品上传的图片（base64 PNG，缩至小图）
  final String emoji;    // 旧版遗留字段，仅兼容已存数据，不再使用

  const Dish({required this.name, this.image, this.photo, this.emoji = ''});

  bool get isBuiltin => image != null;

  Map<String, dynamic> toJson() => {'name': name, 'image': image, 'photo': photo};

  factory Dish.fromJson(Map<String, dynamic> json) => Dish(
        name: json['name'] as String,
        image: json['image'] as String?,
        photo: json['photo'] as String?,
      );
}
