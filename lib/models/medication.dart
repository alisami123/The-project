import 'package:hive/hive.dart';

part 'medication.g.dart';

/// Represents a medication with its schedule and details.
/// 
/// This model follows CareKit-inspired patterns:
/// - [id]: Unique identifier (similar to CareKit's UUID for tasks)
/// - [title]: Medication name
/// - [description]: Additional notes about the medication
/// - [pillCount]: Number of pills per dose
/// - [imageUrl]: Local path to the medication photo
/// - [scheduleElements]: List of scheduled times (similar to OCKScheduleElement)
/// - [frequency]: How many times per day (1, 2, or 3)
/// - [startDate]: When the medication schedule begins
/// - [endDate]: Optional end date for the medication
/// - [isActive]: Whether the medication is currently active
/// - [createdAt]: Timestamp of creation
/// - [updatedAt]: Timestamp of last update
@HiveType(typeId: 0)
class Medication extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String? description;

  @HiveField(3)
  int pillCount;

  @HiveField(4)
  String? imageUrl;

  @HiveField(5)
  List<ScheduleElement> scheduleElements;

  @HiveField(6)
  int frequency; // 1, 2, or 3 times per day

  @HiveField(7)
  DateTime startDate;

  @HiveField(8)
  DateTime? endDate;

  @HiveField(9)
  bool isActive;

  @HiveField(10)
  DateTime createdAt;

  @HiveField(11)
  DateTime updatedAt;

  Medication({
    required this.id,
    required this.title,
    this.description,
    required this.pillCount,
    this.imageUrl,
    required this.scheduleElements,
    required this.frequency,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Creates a copy of this medication with updated fields.
  Medication copyWith({
    String? id,
    String? title,
    String? description,
    int? pillCount,
    String? imageUrl,
    List<ScheduleElement>? scheduleElements,
    int? frequency,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Medication(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pillCount: pillCount ?? this.pillCount,
      imageUrl: imageUrl ?? this.imageUrl,
      scheduleElements: scheduleElements ?? this.scheduleElements,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Converts to a Map for JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'pillCount': pillCount,
      'imageUrl': imageUrl,
      'scheduleElements': scheduleElements.map((e) => e.toMap()).toList(),
      'frequency': frequency,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Creates a Medication from a Map.
  factory Medication.fromMap(Map<String, dynamic> map) {
    return Medication(
      id: map['id'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      pillCount: map['pillCount'] as int,
      imageUrl: map['imageUrl'] as String?,
      scheduleElements: (map['scheduleElements'] as List)
          .map((e) => ScheduleElement.fromMap(e as Map<String, dynamic>))
          .toList(),
      frequency: map['frequency'] as int,
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: map['endDate'] != null
          ? DateTime.parse(map['endDate'] as String)
          : null,
      isActive: map['isActive'] as bool,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }

  @override
  String toString() {
    return 'Medication(id: $id, title: $title, frequency: $frequency, isActive: $isActive)';
  }
}

/// Represents a single scheduled time element for a medication.
/// 
/// Similar to CareKit's OCKScheduleElement, this defines when
/// a medication should be taken.
@HiveType(typeId: 1)
class ScheduleElement extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  Duration duration; // Time of day (hours and minutes)

  @HiveField(2)
  String? label; // Optional label like "Morning", "Afternoon", "Evening"

  @HiveField(3)
  bool isTaken; // Track if this dose has been taken

  @HiveField(4)
  DateTime? lastTakenDate;

  ScheduleElement({
    required this.id,
    required this.duration,
    this.label,
    this.isTaken = false,
    this.lastTakenDate,
  });

  /// Gets the hour component of the duration.
  int get hour => duration.inHours;

  /// Gets the minute component of the duration.
  int get minute => duration.inMinutes.remainder(60);

  /// Creates a copy of this schedule element with updated fields.
  ScheduleElement copyWith({
    String? id,
    Duration? duration,
    String? label,
    bool? isTaken,
    DateTime? lastTakenDate,
  }) {
    return ScheduleElement(
      id: id ?? this.id,
      duration: duration ?? this.duration,
      label: label ?? this.label,
      isTaken: isTaken ?? this.isTaken,
      lastTakenDate: lastTakenDate ?? this.lastTakenDate,
    );
  }

  /// Converts to a Map for JSON serialization.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'duration': duration.inMinutes,
      'label': label,
      'isTaken': isTaken,
      'lastTakenDate': lastTakenDate?.toIso8601String(),
    };
  }

  /// Creates a ScheduleElement from a Map.
  factory ScheduleElement.fromMap(Map<String, dynamic> map) {
    return ScheduleElement(
      id: map['id'] as String,
      duration: Duration(minutes: map['duration'] as int),
      label: map['label'] as String?,
      isTaken: map['isTaken'] as bool,
      lastTakenDate: map['lastTakenDate'] != null
          ? DateTime.parse(map['lastTakenDate'] as String)
          : null,
    );
  }

  @override
  String toString() {
    return 'ScheduleElement(id: $id, time: ${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}, label: $label)';
  }
}
