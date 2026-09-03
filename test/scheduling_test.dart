import 'package:flutter_test/flutter_test.dart';
import 'package:med_reminder/models/medication.dart';

void main() {
  group('Scheduling Logic Tests', () {
    test('ScheduleElement creates with correct time', () {
      final element = ScheduleElement(
        id: 'test_1',
        duration: const Duration(hours: 9, minutes: 30),
        label: 'Morning',
      );

      expect(element.hour, 9);
      expect(element.minute, 30);
      expect(element.label, 'Morning');
      expect(element.isTaken, false);
    });

    test('ScheduleElement handles midnight time', () {
      final element = ScheduleElement(
        id: 'test_midnight',
        duration: const Duration(hours: 0, minutes: 0),
      );

      expect(element.hour, 0);
      expect(element.minute, 0);
    });

    test('ScheduleElement handles late night time', () {
      final element = ScheduleElement(
        id: 'test_late',
        duration: const Duration(hours: 23, minutes: 59),
      );

      expect(element.hour, 23);
      expect(element.minute, 59);
    });

    test('Medication creates schedule elements correctly', () {
      final scheduleElements = [
        ScheduleElement(
          id: 'elem_1',
          duration: const Duration(hours: 8, minutes: 0),
          label: 'Morning',
        ),
        ScheduleElement(
          id: 'elem_2',
          duration: const Duration(hours: 14, minutes: 0),
          label: 'Afternoon',
        ),
        ScheduleElement(
          id: 'elem_3',
          duration: const Duration(hours: 20, minutes: 0),
          label: 'Evening',
        ),
      ];

      final medication = Medication(
        id: 'med_123',
        title: 'Test Medication',
        pillCount: 2,
        scheduleElements: scheduleElements,
        frequency: 3,
        startDate: DateTime(2024, 1, 1),
      );

      expect(medication.scheduleElements.length, 3);
      expect(medication.frequency, 3);
      expect(medication.scheduleElements[0].label, 'Morning');
      expect(medication.scheduleElements[1].label, 'Afternoon');
      expect(medication.scheduleElements[2].label, 'Evening');
    });

    test('Medication isActive defaults to true', () {
      final medication = Medication(
        id: 'med_default',
        title: 'Default Active',
        pillCount: 1,
        scheduleElements: [],
        frequency: 1,
        startDate: DateTime.now(),
      );

      expect(medication.isActive, true);
    });

    test('Medication timestamps are set on creation', () {
      final medication = Medication(
        id: 'med_timestamps',
        title: 'Timestamp Test',
        pillCount: 1,
        scheduleElements: [],
        frequency: 1,
        startDate: DateTime.now(),
      );

      // Verify timestamps are set and are recent (within last second)
      expect(medication.createdAt, isNotNull);
      expect(medication.updatedAt, isNotNull);
      expect(medication.updatedAt, medication.createdAt);
      
      // Verify createdAt is very recent (within 1 second of now)
      final timeDiff = DateTime.now().difference(medication.createdAt);
      expect(timeDiff.inSeconds, lessThan(1));
    });

    test('Medication copyWith updates updatedAt timestamp', () async {
      final original = Medication(
        id: 'med_copy',
        title: 'Original',
        pillCount: 1,
        scheduleElements: [],
        frequency: 1,
        startDate: DateTime.now(),
      );

      // Small delay to ensure different timestamps
      await Future.delayed(const Duration(milliseconds: 10));

      final updated = original.copyWith(title: 'Updated');

      expect(updated.title, 'Updated');
      expect(updated.id, original.id);
      expect(updated.updatedAt.isAfter(original.updatedAt), true);
    });

    test('ScheduleElement isTaken tracking works', () {
      final element = ScheduleElement(
        id: 'elem_tracking',
        duration: const Duration(hours: 10, minutes: 0),
      );

      expect(element.isTaken, false);
      expect(element.lastTakenDate, null);

      final takenElement = element.copyWith(
        isTaken: true,
        lastTakenDate: DateTime.now(),
      );

      expect(takenElement.isTaken, true);
      expect(takenElement.lastTakenDate, isNotNull);
    });

    test('Multiple medications can have independent schedules', () {
      final med1 = Medication(
        id: 'med_1',
        title: 'Medication One',
        pillCount: 1,
        scheduleElements: [
          ScheduleElement(
            id: 's1',
            duration: const Duration(hours: 8, minutes: 0),
          ),
        ],
        frequency: 1,
        startDate: DateTime.now(),
      );

      final med2 = Medication(
        id: 'med_2',
        title: 'Medication Two',
        pillCount: 2,
        scheduleElements: [
          ScheduleElement(
            id: 's2',
            duration: const Duration(hours: 9, minutes: 0),
          ),
          ScheduleElement(
            id: 's3',
            duration: const Duration(hours: 21, minutes: 0),
          ),
        ],
        frequency: 2,
        startDate: DateTime.now(),
      );

      expect(med1.scheduleElements.length, 1);
      expect(med2.scheduleElements.length, 2);
      expect(med1.scheduleElements[0].hour, 8);
      expect(med2.scheduleElements[0].hour, 9);
      expect(med2.scheduleElements[1].hour, 21);
    });
  });
}
