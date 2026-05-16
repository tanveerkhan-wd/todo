import 'package:uuid/uuid.dart';

/// A single reminder associated with a [Todo].
///
/// [minutesBefore] is the offset before the due date at which the
/// notification should fire (e.g. 15 = 15 minutes before due).
/// [isNotified] tracks whether this reminder has already been delivered.
class TodoReminder {
  final String id;
  final int minutesBefore;
  final bool isNotified;

  const TodoReminder({
    required this.id,
    required this.minutesBefore,
    this.isNotified = false,
  });

  factory TodoReminder.create({int minutesBefore = 15}) {
    return TodoReminder(
      id: const Uuid().v4(),
      minutesBefore: minutesBefore,
      isNotified: false,
    );
  }

  TodoReminder copyWith({
    String? id,
    int? minutesBefore,
    bool? isNotified,
  }) {
    return TodoReminder(
      id: id ?? this.id,
      minutesBefore: minutesBefore ?? this.minutesBefore,
      isNotified: isNotified ?? this.isNotified,
    );
  }

  /// Human-readable label for the reminder offset.
  String get label {
    if (minutesBefore == 0) return 'At due time';
    if (minutesBefore < 60) return '$minutesBefore min';
    if (minutesBefore < 1440)
      return '${minutesBefore ~/ 60} hour${minutesBefore >= 120 ? "s" : ""}';
    final days = minutesBefore ~/ 1440;
    return '$days day${days > 1 ? "s" : ""}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'minutesBefore': minutesBefore,
        'isNotified': isNotified,
      };

  factory TodoReminder.fromJson(Map<String, dynamic> json) => TodoReminder(
        id: json['id'] as String,
        minutesBefore: json['minutesBefore'] as int? ?? 15,
        isNotified: json['isNotified'] as bool? ?? false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TodoReminder &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
