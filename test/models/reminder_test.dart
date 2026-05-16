import 'package:flutter_test/flutter_test.dart';
import 'package:todo_offline/models/reminder.dart';

void main() {
  group('TodoReminder', () {
    test('create generates valid reminder', () {
      final reminder = TodoReminder.create(minutesBefore: 30);

      expect(reminder.id, isNotEmpty);
      expect(reminder.minutesBefore, 30);
      expect(reminder.isNotified, false);
    });

    test('create defaults to 15 minutes', () {
      final reminder = TodoReminder.create();
      expect(reminder.minutesBefore, 15);
    });

    test('toJson and fromJson round-trips', () {
      final original = TodoReminder.create(minutesBefore: 60);
      final json = original.toJson();
      final restored = TodoReminder.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.minutesBefore, 60);
      expect(restored.isNotified, false);
    });

    test('fromJson handles missing fields with defaults', () {
      final json = <String, dynamic>{'id': 'r1'};
      final reminder = TodoReminder.fromJson(json);

      expect(reminder.id, 'r1');
      expect(reminder.minutesBefore, 15);
      expect(reminder.isNotified, false);
    });

    test('copyWith updates specified fields', () {
      final reminder = TodoReminder.create(minutesBefore: 15);
      final updated = reminder.copyWith(minutesBefore: 30, isNotified: true);

      expect(updated.minutesBefore, 30);
      expect(updated.isNotified, true);
      expect(updated.id, reminder.id);
    });

    test('label returns correct string for various offsets', () {
      expect(TodoReminder.create(minutesBefore: 0).label, 'At due time');
      expect(TodoReminder.create(minutesBefore: 15).label, '15 min');
      expect(TodoReminder.create(minutesBefore: 60).label, '1 hour');
      expect(TodoReminder.create(minutesBefore: 120).label, '2 hours');
      expect(TodoReminder.create(minutesBefore: 1440).label, '1 day');
      expect(TodoReminder.create(minutesBefore: 2880).label, '2 days');
    });

    test('equality is based on id', () {
      final r1 = TodoReminder.create(minutesBefore: 15);
      final r2 = r1.copyWith(minutesBefore: 30);

      expect(r1 == r2, true);
      expect(r1.hashCode, r2.hashCode);
    });
  });
}
