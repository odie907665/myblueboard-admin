class TicketTag {
  final int id;
  final String name;
  final String color;

  TicketTag({required this.id, required this.name, required this.color});

  factory TicketTag.fromJson(Map<String, dynamic> json) {
    return TicketTag(id: json['id'], name: json['name'], color: json['color']);
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color};
  }
}
