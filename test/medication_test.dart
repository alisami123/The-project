import 'package:flutter_test/flutter_test.dart';
import 'package:med_reminder/models/medication.dart';

void main() {
  group('Medication Model Tests', () {
    test('Medication creates with correct values', () {
      final scheduleElement = ScheduleElement(
        id: 'test_id',
        duration: const Duration(hours: 8, minutes: 0),
        label: 'Morning',
      );

      final medication = Medication(
        id: '123',
        title: 'Test Med',
        pillCount: 2,
        scheduleElements: [scheduleElement],
        frequency: 1,
        startDate: DateTime(2024, 1, 1),
      );

      expect(medication.id, '123');
      expect(medication.title, 'Test Med');
      expect(medication.pillCount, 2);
      expect(medication.frequency, 1);
      expect(medication.isActive, true);
      expect(medication.scheduleElements.length, 1);
    });

    test('Medication copyWith creates updated copy', () {
      final original = Medication(
        id: '123',
        title: 'Original',
        pillCount: 1,
        scheduleElements: [],
        frequency: 1,
        startDate: DateTime(2024, 1, 1),
      );

      final updated = original.copyWith(
        title: 'Updated',
        pillCount: 2,
      );

      expect(updated.id, original.id); // ID stays same
      expect(updated.title, 'Updated');
      expect(updated.pillCount, 2);
      expect(updated.createdAt, original.createdAt); // Should be same
      // updatedAt is set to DateTime.now() which may be same as createdAt in fast tests
    });

    test('ScheduleElement calculates hour and minute correctly', () {
      final element = ScheduleElement(
        id: 'test',
        duration: const Duration(hours: 14, minutes: 30),
      );

      expect(element.hour, 14);
      expect(element.minute, 30);
    });

    test('Medication toMap and fromMap roundtrip', () {
      final scheduleElement = ScheduleElement(
        id: 'elem1',
        duration: const Duration(hours: 9, minutes: 0),
        label: 'Morning',
      );

      final original = Medication(
        id: 'test123',
        title: 'RoundTrip Med',
        description: 'Test description',
        pillCount: 3,
        imageUrl: '/path/to/image.png',
        scheduleElements: [scheduleElement],
        frequency: 1,
        startDate: DateTime(2024, 1, 1),
        endDate: DateTime(2024, 12, 31),
        isActive: true,
      );

      final map = original.toMap();
      final restored = Medication.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.description, original.description);
      expect(restored.pillCount, original.pillCount);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.frequency, original.frequency);
      expect(restored.isActive, original.isActive);
    });
  });

  group('ScheduleElement Tests', () {
    test('ScheduleElement copyWith works correctly', () {
      final original = ScheduleElement(
        id: 'test',
        duration: const Duration(hours: 8, minutes: 0),
        label: 'Morning',
        isTaken: false,
      );

      final updated = original.copyWith(
        isTaken: true,
        lastTakenDate: DateTime.now(),
      );

      expect(updated.id, original.id);
      expect(updated.duration, original.duration);
      expect(updated.label, original.label);
      expect(updated.isTaken, true);
      expect(updated.lastTakenDate, isNotNull);
    });

    test('ScheduleElement toMap and fromMap roundtrip', () {
      final now = DateTime.now();
      final original = ScheduleElement(
        id: 'elem123',
        duration: const Duration(hours: 20, minutes: 45),
        label: 'Evening',
        isTaken: true,
        lastTakenDate: now,
      );

      final map = original.toMap();
      final restored = ScheduleElement.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.duration.inMinutes, original.duration.inMinutes);
      expect(restored.label, original.label);
      expect(restored.isTaken, original.isTaken);
    });
  });
}
