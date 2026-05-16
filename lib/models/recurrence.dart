/// Types of recurrence for a repeating task.
enum RecurrenceType { daily, weekly, monthly }

/// Describes how a [Todo] repeats after completion.
///
/// [interval] controls the spacing (e.g., every 2 weeks).
/// [endDate] is optional and stops recurrence after that date.
class RecurrenceRule {
  final RecurrenceType type;
  final int interval;
  final DateTime? endDate;

  const RecurrenceRule({
    required this.type,
    this.interval = 1,
    this.endDate,
  });

  RecurrenceRule copyWith({
    RecurrenceType? type,
    int? interval,
    Object? endDate = _unset,
  }) {
    return RecurrenceRule(
      type: type ?? this.type,
      interval: interval ?? this.interval,
      endDate: endDate == _unset ? this.endDate : endDate as DateTime?,
    );
  }

  static const _unset = Object();

  Map<String, dynamic> toJson() => {
        'type': type.name,
        'interval': interval,
        'endDate': endDate?.toIso8601String(),
      };

  factory RecurrenceRule.fromJson(Map<String, dynamic> json) => RecurrenceRule(
        type: RecurrenceType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => RecurrenceType.daily,
        ),
        interval: json['interval'] as int? ?? 1,
        endDate: json['endDate'] != null
            ? DateTime.parse(json['endDate'] as String)
            : null,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RecurrenceRule &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          interval == other.interval &&
          endDate == other.endDate;

  @override
  int get hashCode => Object.hash(type, interval, endDate);
}
