class TicketCategory {
  final int id;
  final String name;
  final String description;
  final String color;

  TicketCategory({
    required this.id,
    required this.name,
    required this.description,
    required this.color,
  });

  factory TicketCategory.fromJson(Map<String, dynamic> json) {
    return TicketCategory(
      id: json['id'],
      name: json['name'],
      description: json['description'] ?? '',
      color: json['color'],
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'description': description, 'color': color};
  }
}
