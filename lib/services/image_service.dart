import 'package:image_picker/image_picker.dart';
import 'dart:io';

/// Service responsible for image capture and selection.
/// 
/// This service handles:
/// - Capturing photos from the camera
/// - Selecting images from the gallery
/// - Requesting necessary permissions
class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Captures a photo from the device camera.
  /// 
  /// Returns null if the user cancels or if an error occurs.
  Future<File?> takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 80, // Balance between quality and file size
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo: $e');
      return null;
    }
  }

  /// Selects a photo from the device gallery.
  /// 
  /// Returns null if the user cancels or if an error occurs.
  Future<File?> pickFromGallery() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error picking image from gallery: $e');
      return null;
    }
  }

  /// Takes a photo with custom options.
  /// 
  /// [maxWidth] Maximum width for the captured image
  /// [maxHeight] Maximum height for the captured image
  /// [imageQuality] Quality of the image (1-100)
  Future<File?> takePhotoWithOptions({
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error taking photo with options: $e');
      return null;
    }
  }

  /// Picks an image from gallery with custom options.
  /// 
  /// [maxWidth] Maximum width for the selected image
  /// [maxHeight] Maximum height for the selected image
  /// [imageQuality] Quality of the image (1-100)
  Future<File?> pickFromGalleryWithOptions({
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 80,
  }) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      if (photo != null) {
        return File(photo.path);
      }
      return null;
    } catch (e) {
      print('Error picking image with options: $e');
      return null;
    }
  }

  /// Gets multiple images from the gallery.
  /// 
  /// Returns a list of files, which may be empty if cancelled.
  Future<List<File>> pickMultipleImages({
    int? maxWidth,
    int? maxHeight,
    int imageQuality = 80,
  }) async {
    try {
      final List<XFile> photos = await _picker.pickMultiImage(
        maxWidth: maxWidth?.toDouble(),
        maxHeight: maxHeight?.toDouble(),
        imageQuality: imageQuality,
      );

      return photos.map((photo) => File(photo.path)).toList();
    } catch (e) {
      print('Error picking multiple images: $e');
      return [];
    }
  }
}
