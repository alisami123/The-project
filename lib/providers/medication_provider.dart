import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../services/image_service.dart';
import 'dart:io';

/// Provider class that manages medication state and business logic.
/// 
/// This provider follows the CareKit-inspired architecture:
/// - Manages medications (similar to CarePlan tasks)
/// - Handles scheduling elements (similar to OCKScheduleElement)
/// - Coordinates between storage, notifications, and image services
/// - Provides reactive state updates for UI
class MedicationProvider with ChangeNotifier {
  final StorageService _storageService;
  final NotificationService _notificationService;
  final ImageService _imageService;

  List<Medication> _medications = [];
  bool _isLoading = false;
  String? _error;

  MedicationProvider({
    StorageService? storageService,
    NotificationService? notificationService,
    ImageService? imageService,
  })  : _storageService = storageService ?? StorageService(),
        _notificationService = notificationService ?? NotificationService(),
        _imageService = imageService ?? ImageService();

  /// Gets all medications
  List<Medication> get medications => _medications;

  /// Gets only active medications
  List<Medication> get activeMedications =>
      _medications.where((m) => m.isActive).toList();

  /// Gets only inactive medications
  List<Medication> get inactiveMedications =>
      _medications.where((m) => !m.isActive).toList();

  /// Gets a medication by ID
  Medication? getMedicationById(String id) {
    try {
      return _storageService.getMedicationById(id);
    } catch (e) {
      _error = 'Error fetching medication: $e';
      notifyListeners();
      return null;
    }
  }

  /// Checks if currently loading
  bool get isLoading => _isLoading;

  /// Gets the current error message
  String? get error => _error;

  /// Gets the count of medications
  int get medicationCount => _medications.length;

  /// Initializes the provider by loading all medications from storage.
  /// 
  /// Must be called before using the provider.
  Future<void> initialize() async {
    await _loadMedications();
    
    // Initialize notification service
    try {
      await _notificationService.initialize();
      
      // Reschedule all active medication notifications
      for (final med in activeMedications) {
        await _notificationService.scheduleAllMedicationReminders(med);
      }
    } catch (e) {
      _error = 'Failed to initialize notifications: $e';
      notifyListeners();
    }
  }

  /// Loads all medications from storage.
  Future<void> _loadMedications() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medications = _storageService.getAllMedications();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load medications: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Creates schedule elements based on frequency and selected times.
  /// 
  /// [frequency] Number of times per day (1, 2, or 3)
  /// [times] List of time durations for each dose
  List<ScheduleElement> createScheduleElements(
    int frequency,
    List<Duration> times,
  ) {
    final labels = ['Morning', 'Afternoon', 'Evening'];
    final elements = <ScheduleElement>[];

    for (int i = 0; i < frequency && i < times.length; i++) {
      elements.add(ScheduleElement(
        id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
        duration: times[i],
        label: frequency > 1 ? labels[i] : null,
      ));
    }

    return elements;
  }

  /// Creates a new medication with the given details.
  /// 
  /// [title] Name of the medication
  /// [pillCount] Number of pills per dose
  /// [frequency] Times per day (1, 2, or 3)
  /// [scheduleTimes] List of times for each dose
  /// [description] Optional description
  /// [imageFile] Optional photo of the medication
  /// [startDate] When to start the medication (defaults to now)
  /// [endDate] Optional end date
  Future<bool> createMedication({
    required String title,
    required int pillCount,
    required int frequency,
    required List<Duration> scheduleTimes,
    String? description,
    File? imageFile,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Validate inputs
      if (title.trim().isEmpty) {
        throw ArgumentError('Medication title cannot be empty');
      }

      if (pillCount <= 0) {
        throw ArgumentError('Pill count must be greater than 0');
      }

      if (![1, 2, 3].contains(frequency)) {
        throw ArgumentError('Frequency must be 1, 2, or 3');
      }

      if (scheduleTimes.length != frequency) {
        throw ArgumentError(
            'Number of schedule times must match frequency');
      }

      // Generate unique ID
      final id = _storageService.generateMedicationId();

      // Save image if provided
      String? imageUrl;
      if (imageFile != null) {
        imageUrl = await _storageService.saveImage(imageFile, id);
      }

      // Create schedule elements
      final scheduleElements = createScheduleElements(frequency, scheduleTimes);

      // Create medication
      final medication = Medication(
        id: id,
        title: title.trim(),
        description: description?.trim(),
        pillCount: pillCount,
        imageUrl: imageUrl,
        scheduleElements: scheduleElements,
        frequency: frequency,
        startDate: startDate ?? DateTime.now(),
        endDate: endDate,
        isActive: true,
      );

      // Save to storage
      await _storageService.saveMedication(medication);

      // Schedule notifications
      await _notificationService.scheduleAllMedicationReminders(medication);

      // Reload medications
      await _loadMedications();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to create medication: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Updates an existing medication.
  /// 
  /// If a new image is provided, the old one is deleted.
  Future<bool> updateMedication({
    required String id,
    String? title,
    int? pillCount,
    int? frequency,
    List<Duration>? scheduleTimes,
    String? description,
    File? newImageFile,
    bool? removeImage,
    DateTime? startDate,
    DateTime? endDate,
    bool? isActive,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final existing = _storageService.getMedicationById(id);
      if (existing == null) {
        throw Exception('Medication not found');
      }

      // Handle image update
      String? imageUrl = existing.imageUrl;
      if (removeImage == true && imageUrl != null) {
        await _storageService.deleteImage(imageUrl);
        imageUrl = null;
      } else if (newImageFile != null) {
        if (imageUrl != null) {
          await _storageService.deleteImage(imageUrl);
        }
        imageUrl = await _storageService.saveImage(newImageFile, id);
      }

      // Handle schedule update
      List<ScheduleElement> scheduleElements = existing.scheduleElements;
      if (frequency != null && scheduleTimes != null) {
        scheduleElements = createScheduleElements(frequency, scheduleTimes);
      }

      // Update medication
      final updated = existing.copyWith(
        title: title ?? existing.title,
        pillCount: pillCount ?? existing.pillCount,
        frequency: frequency ?? existing.frequency,
        description: description ?? existing.description,
        imageUrl: imageUrl,
        scheduleElements: scheduleElements,
        startDate: startDate ?? existing.startDate,
        endDate: endDate ?? existing.endDate,
        isActive: isActive ?? existing.isActive,
      );

      // Cancel old notifications
      await _notificationService.cancelMedicationNotifications(id);

      // Save updated medication
      await _storageService.saveMedication(updated);

      // Schedule new notifications if active
      if (updated.isActive) {
        await _notificationService.scheduleAllMedicationReminders(updated);
      }

      // Reload medications
      await _loadMedications();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to update medication: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Deletes a medication.
  Future<bool> deleteMedication(String id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Cancel notifications first
      await _notificationService.cancelMedicationNotifications(id);

      // Delete from storage (also deletes associated image)
      await _storageService.deleteMedication(id);

      // Reload medications
      await _loadMedications();

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = 'Failed to delete medication: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Toggles the active status of a medication.
  Future<bool> toggleMedicationStatus(String id) async {
    try {
      final medication = _storageService.getMedicationById(id);
      if (medication == null) {
        throw Exception('Medication not found');
      }

      // Cancel existing notifications
      await _notificationService.cancelMedicationNotifications(id);

      // Toggle status
      await _storageService.toggleMedicationActiveStatus(id);

      // If now active, schedule new notifications
      final updated = _storageService.getMedicationById(id);
      if (updated != null && updated.isActive) {
        await _notificationService.scheduleAllMedicationReminders(updated);
      }

      // Reload medications
      await _loadMedications();

      return true;
    } catch (e) {
      _error = 'Failed to toggle medication status: $e';
      notifyListeners();
      return false;
    }
  }

  /// Marks a dose as taken for a specific medication.
  Future<bool> markDoseAsTaken(String medicationId, int scheduleIndex) async {
    try {
      await _storageService.markDoseAsTaken(medicationId, scheduleIndex);
      await _loadMedications();
      return true;
    } catch (e) {
      _error = 'Failed to mark dose as taken: $e';
      notifyListeners();
      return false;
    }
  }

  /// Resets daily doses for all medications.
  /// 
  /// Should be called at midnight or when a new day starts.
  Future<void> resetDailyDoses() async {
    try {
      await _storageService.resetAllDailyDoses();
      await _loadMedications();
    } catch (e) {
      _error = 'Failed to reset daily doses: $e';
      notifyListeners();
    }
  }

  /// Gets upcoming reminders for today.
  List<Map<String, dynamic>> getUpcomingReminders() {
    final now = DateTime.now();
    final currentMinutes = now.hour * 60 + now.minute;
    final reminders = <Map<String, dynamic>>[];

    for (final med in activeMedications) {
      for (int i = 0; i < med.scheduleElements.length; i++) {
        final element = med.scheduleElements[i];
        final elementMinutes = element.hour * 60 + element.minute;

        // Only include future reminders today that haven't been taken
        if (elementMinutes >= currentMinutes && !element.isTaken) {
          reminders.add({
            'medication': med,
            'scheduleElement': element,
            'scheduleIndex': i,
            'time': Duration(minutes: elementMinutes),
          });
        }
      }
    }

    // Sort by time
    reminders.sort((a, b) =>
        (a['time'] as Duration).inMinutes - (b['time'] as Duration).inMinutes);

    return reminders;
  }

  /// Clears any error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
