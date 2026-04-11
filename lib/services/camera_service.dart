import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

/// Camera/media service built on image_picker.
/// No camera package dependency â€” works on Android, iOS, and Web.
class CameraService {
  static final CameraService _instance = CameraService._internal();

  factory CameraService() => _instance;
  CameraService._internal();

  final _imagePicker = ImagePicker();

  bool get isRecording => false;

  // Stub controller â€” kept for API compatibility with camera_screen.dart
  dynamic get controller => null;

  /// Initialize "camera" â€” no-op since we use image_picker instead
  Future<dynamic> initializeCamera() async => null;

  /// Capture photo from camera using image_picker
  Future<File?> capturePhoto() async {
    try {
      final picked = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked == null) return null;
      if (kIsWeb) return null; // Web doesn't have dart:io File
      return File(picked.path);
    } catch (e) {
      debugPrint('CameraService capturePhoto error: $e');
      return null;
    }
  }

  /// Record video using image_picker
  Future<File?> recordVideo() async {
    try {
      final picked = await _imagePicker.pickVideo(source: ImageSource.camera);
      if (picked == null) return null;
      if (kIsWeb) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('CameraService recordVideo error: $e');
      return null;
    }
  }

  /// Pick photo from gallery
  Future<File?> pickFromGallery() async {
    try {
      final picked = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (picked == null) return null;
      if (kIsWeb) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('CameraService pickFromGallery error: $e');
      return null;
    }
  }

  /// Pick video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final picked = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (picked == null) return null;
      if (kIsWeb) return null;
      return File(picked.path);
    } catch (e) {
      debugPrint('CameraService pickVideoFromGallery error: $e');
      return null;
    }
  }

  Future<void> dispose() async {
    // No resources to release with image_picker approach
  }
}

