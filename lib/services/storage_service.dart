import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../models/medication.dart';

/// Service responsible for data persistence and storage operations.
/// 
/// This service handles:
/// - Initializing Hive database
/// - CRUD operations for medications
/// - Image storage management
/// - Data backup and restore capabilities
class StorageService {
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  /// Box name for storing medications
  static const String _medicationsBoxName = 'medications';

  /// Directory name for storing medication images
  static const String _imagesDirectoryName = 'medication_images';

  late Box<Medication> _medicationsBox;
  bool _isInitialized = false;

  /// Initializes the storage service.
  /// 
  /// Registers adapters, opens boxes, and ensures image directory exists.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      await Hive.initFlutter();

      // Register adapters for custom types
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(MedicationAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(ScheduleElementAdapter());
      }

      // Open boxes
      _medicationsBox = await Hive.openBox<Medication>(_medicationsBoxName);

      // Ensure image directory exists
      await _ensureImageDirectoryExists();

      _isInitialized = true;
      print('Storage service initialized successfully');
    } catch (e) {
      print('Error initializing storage service: $e');
      rethrow;
    }
  }

  /// Ensures the image storage directory exists.
  Future<Directory> _getImagesDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${appDir.path}/$_imagesDirectoryName');
    
    if (!await imagesDir.exists()) {
      await imagesDir.create(recursive: true);
    }
    
    return imagesDir;
  }

  Future<void> _ensureImageDirectoryExists() async {
    await _getImagesDirectory();
  }

  // ==================== Medication CRUD Operations ====================

  /// Gets all medications from storage.
  List<Medication> getAllMedications() {
    _checkInitialized();
    return _medicationsBox.values.toList();
  }

  /// Gets all active medications.
  List<Medication> getActiveMedications() {
    _checkInitialized();
    return _medicationsBox.values.where((m) => m.isActive).toList();
  }

  /// Gets a medication by its ID.
  Medication? getMedicationById(String id) {
    _checkInitialized();
    return _medicationsBox.get(id);
  }

  /// Saves a new medication or updates an existing one.
  /// 
  /// If a medication with the same ID exists, it will be updated.
  Future<void> saveMedication(Medication medication) async {
    _checkInitialized();
    try {
      await _medicationsBox.put(medication.id, medication);
      print('Medication saved: ${medication.id}');
    } catch (e) {
      print('Error saving medication: $e');
      rethrow;
    }
  }

  /// Deletes a medication by its ID.
  Future<void> deleteMedication(String id) async {
    _checkInitialized();
    try {
      // Get the medication to delete its image if exists
      final medication = _medicationsBox.get(id);
      if (medication != null && medication.imageUrl != null) {
        await deleteImage(medication.imageUrl!);
      }

      await _medicationsBox.delete(id);
      print('Medication deleted: $id');
    } catch (e) {
      print('Error deleting medication: $e');
      rethrow;
    }
  }

  /// Updates the isActive status of a medication.
  Future<void> toggleMedicationActiveStatus(String id) async {
    _checkInitialized();
    final medication = _medicationsBox.get(id);
    if (medication != null) {
      final updated = medication.copyWith(isActive: !medication.isActive);
      await saveMedication(updated);
    }
  }

  /// Marks a dose as taken for a specific schedule element.
  Future<void> markDoseAsTaken(String medicationId, int scheduleIndex) async {
    _checkInitialized();
    final medication = _medicationsBox.get(medicationId);
    if (medication != null && scheduleIndex < medication.scheduleElements.length) {
      final elements = List<ScheduleElement>.from(medication.scheduleElements);
      elements[scheduleIndex] = elements[scheduleIndex].copyWith(
        isTaken: true,
        lastTakenDate: DateTime.now(),
      );
      
      final updated = medication.copyWith(scheduleElements: elements);
      await saveMedication(updated);
    }
  }

  /// Resets all dose taken statuses for a medication.
  /// 
  /// Typically called at the start of a new day.
  Future<void> resetDailyDoses(String medicationId) async {
    _checkInitialized();
    final medication = _medicationsBox.get(medicationId);
    if (medication != null) {
      final elements = medication.scheduleElements.map((e) => e.copyWith(
        isTaken: false,
      )).toList();
      
      final updated = medication.copyWith(scheduleElements: elements);
      await saveMedication(updated);
    }
  }

  /// Resets daily doses for all active medications.
  Future<void> resetAllDailyDoses() async {
    _checkInitialized();
    final activeMeds = getActiveMedications();
    for (final med in activeMeds) {
      await resetDailyDoses(med.id);
    }
  }

  // ==================== Image Management ====================

  /// Saves a medication image to local storage.
  /// 
  /// Returns the file path of the saved image.
  Future<String> saveImage(File imageFile, String medicationId) async {
    _checkInitialized();
    try {
      final imagesDir = await _getImagesDirectory();
      final extension = imageFile.path.split('.').last;
      final fileName = '${medicationId}_$extension';
      final newPath = '${imagesDir.path}/$fileName';

      // Copy the image to our storage directory
      final newFile = await imageFile.copy(newPath);
      print('Image saved: ${newFile.path}');
      
      return newFile.path;
    } catch (e) {
      print('Error saving image: $e');
      rethrow;
    }
  }

  /// Deletes an image file.
  Future<void> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        print('Image deleted: $imagePath');
      }
    } catch (e) {
      print('Error deleting image: $e');
    }
  }

  /// Checks if an image file exists.
  Future<bool> imageExists(String imagePath) async {
    final file = File(imagePath);
    return await file.exists();
  }

  // ==================== Utility Methods ====================

  /// Generates a unique ID for a new medication.
  String generateMedicationId() {
    return DateTime.now().millisecondsSinceEpoch.toString();
  }

  /// Clears all data from storage.
  /// 
  /// Use with caution - this will delete all medications and images.
  Future<void> clearAllData() async {
    _checkInitialized();
    try {
      // Delete all images first
      final imagesDir = await _getImagesDirectory();
      if (await imagesDir.exists()) {
        await imagesDir.delete(recursive: true);
      }

      // Clear the box
      await _medicationsBox.clear();
      print('All data cleared');
    } catch (e) {
      print('Error clearing data: $e');
      rethrow;
    }
  }

  /// Exports all medications to JSON format.
  Map<String, dynamic> exportData() {
    _checkInitialized();
    final medications = getAllMedications();
    return {
      'exported_at': DateTime.now().toIso8601String(),
      'medications': medications.map((m) => m.toMap()).toList(),
    };
  }

  /// Checks if the service is initialized.
  void _checkInitialized() {
    if (!_isInitialized) {
      throw StateError('StorageService not initialized. Call initialize() first.');
    }
  }

  /// Gets the count of medications.
  int get medicationCount => _medicationsBox.length;

  /// Watches for changes in the medications box.
  Stream<BoxEvent> watchMedications() {
    _checkInitialized();
    return _medicationsBox.watch();
  }
}
