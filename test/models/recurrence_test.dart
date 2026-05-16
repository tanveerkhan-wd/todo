import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/recurrence.dart';

void main() {
  group('RecurrenceRule model', () {
    test('create with defaults', () {
      final rule = const RecurrenceRule(type: RecurrenceType.daily);
      expect(rule.type, RecurrenceType.daily);
      expect(rule.interval, 1);
      expect(rule.endDate, isNull);
    });

    test('custom interval and endDate', () {
      final end = DateTime(2025, 12, 31);
      final rule = RecurrenceRule(
        type: RecurrenceType.weekly,
        interval: 2,
        endDate: end,
      );
      expect(rule.interval, 2);
      expect(rule.endDate, end);
    });

    test('toJson and fromJson round-trips', () {
      final original = RecurrenceRule(
        type: RecurrenceType.monthly,
        interval: 3,
        endDate: DateTime(2026, 1, 1),
      );

      final json = original.toJson();
      final restored = RecurrenceRule.fromJson(json);

      expect(restored.type, original.type);
      expect(restored.interval, original.interval);
      expect(restored.endDate, original.endDate);
    });

    test('fromJson handles null endDate', () {
      final json = {
        'type': 'daily',
        'interval': 1,
        'endDate': null,
      };

      final rule = RecurrenceRule.fromJson(json);
      expect(rule.type, RecurrenceType.daily);
      expect(rule.interval, 1);
      expect(rule.endDate, isNull);
    });

    test('copyWith updates fields', () {
      final rule = const RecurrenceRule(type: RecurrenceType.daily);
      final updated = rule.copyWith(type: RecurrenceType.weekly, interval: 2);
      expect(updated.type, RecurrenceType.weekly);
      expect(updated.interval, 2);
    });

    test('copyWith clears endDate', () {
      final rule = RecurrenceRule(
        type: RecurrenceType.daily,
        endDate: DateTime(2025, 12, 31),
      );
      final cleared = rule.copyWith(endDate: null);
      expect(cleared.endDate, isNull);
    });

    test('equality', () {
      final a = const RecurrenceRule(type: RecurrenceType.daily, interval: 1);
      final b = const RecurrenceRule(type: RecurrenceType.daily, interval: 1);
      expect(a == b, true);
      expect(a.hashCode, b.hashCode);
    });

    test('inequality', () {
      final a = const RecurrenceRule(type: RecurrenceType.daily);
      final b = const RecurrenceRule(type: RecurrenceType.weekly);
      expect(a == b, false);
    });
  });
}
