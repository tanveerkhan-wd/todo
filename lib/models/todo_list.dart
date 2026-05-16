import 'package:uuid/uuid.dart';

/// A named project / list that groups [Todo]s together.
class TodoList {
  final String id;
  final String name;
  final int color;
  final DateTime createdAt;

  const TodoList({
    required this.id,
    required this.name,
    this.color = 0xFF0D47A1,
    required this.createdAt,
  });

  factory TodoList.create({
    required String name,
    int color = 0xFF0D47A1,
  }) {
    return TodoList(
      id: const Uuid().v4(),
      name: name,
      color: color,
      createdAt: DateTime.now(),
    );
  }

  TodoList copyWith({
    String? id,
    String? name,
    int? color,
    DateTime? createdAt,
  }) {
    return TodoList(
      id: id ?? this.id,
      name: name ?? this.name,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TodoList.fromJson(Map<String, dynamic> json) => TodoList(
        id: json['id'] as String,
        name: json['name'] as String,
        color: json['color'] as int? ?? 0xFF0D47A1,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<Map<String, dynamic>> listToJson(List<TodoList> lists) =>
      lists.map((l) => l.toJson()).toList();

  static List<TodoList> listFromJson(List<dynamic> jsonList) => jsonList
      .map((e) => TodoList.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoList && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TodoList(id: $id, name: $name)';
}
