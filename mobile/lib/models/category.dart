class Category {
  final int id;
  final String name;
  final String type; // income | expense
  final String? icon;
  final String color;

  Category({required this.id, required this.name, required this.type, this.icon, required this.color});

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        type: json['type'],
        icon: json['icon'],
        color: json['color'] ?? '#6C5CE7',
      );
}
