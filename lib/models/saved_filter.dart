import 'package:uuid/uuid.dart';

import 'todo_group.dart';

/// A named preset of filter criteria that can be saved and restored.
class SavedFilter {
  final String id;
  final String name;
  final List<String> tagFilters;
  final TodoFilter? dateFilter;
  final String? listId;
  final DateTime createdAt;

  const SavedFilter({
    required this.id,
    required this.name,
    this.tagFilters = const [],
    this.dateFilter,
    this.listId,
    required this.createdAt,
  });

  factory SavedFilter.create({
    required String name,
    List<String> tagFilters = const [],
    TodoFilter? dateFilter,
    String? listId,
  }) {
    return SavedFilter(
      id: const Uuid().v4(),
      name: name,
      tagFilters: tagFilters,
      dateFilter: dateFilter,
      listId: listId,
      createdAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'tagFilters': tagFilters,
        'dateFilter': dateFilter?.name,
        'listId': listId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory SavedFilter.fromJson(Map<String, dynamic> json) => SavedFilter(
        id: json['id'] as String,
        name: json['name'] as String,
        tagFilters: (json['tagFilters'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [],
        dateFilter: json['dateFilter'] != null
            ? TodoFilter.values.firstWhere(
                (f) => f.name == json['dateFilter'],
                orElse: () => TodoFilter.today,
              )
            : null,
        listId: json['listId'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );

  static List<Map<String, dynamic>> listToJson(List<SavedFilter> filters) =>
      filters.map((f) => f.toJson()).toList();

  static List<SavedFilter> listFromJson(List<dynamic> jsonList) => jsonList
      .map((e) => SavedFilter.fromJson(e as Map<String, dynamic>))
      .toList();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SavedFilter &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
