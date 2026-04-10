import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class CameraService {
  static final CameraService _instance = CameraService._internal();
  
  factory CameraService() {
    return _instance;
  }
  
  CameraService._internal();

  CameraController? _controller;
  final _imagePicker = ImagePicker();

  /// Initialize camera for live preview
  Future<CameraController?> initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return null;
      
      final frontCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        frontCamera,
        ResolutionPreset.high,
      );

      await _controller!.initialize();
      return _controller;
    } catch (e) {
      print('Error initializing camera: $e');
      return null;
    }
  }

  CameraController? get controller => _controller;

  /// Capture photo from camera
  Future<File?> capturePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      final image = await _controller!.takePicture();
      return File(image.path);
    } catch (e) {
      print('Error capturing photo: $e');
      return null;
    }
  }

  /// Record video
  Future<File?> recordVideo() async {
    if (_controller == null || !_controller!.value.isInitialized) {
      return null;
    }

    try {
      if (_controller!.value.isRecordingVideo) {
        final file = await _controller!.stopVideoRecording();
        return File(file.path);
      } else {
        await _controller!.startVideoRecording();
        return null; // Return null while recording
      }
    } catch (e) {
      print('Error recording video: $e');
      return null;
    }
  }

  /// Get photo from gallery
  Future<File?> pickFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        return File(image.path);
      }
      return null;
    } catch (e) {
      print('Error picking from gallery: $e');
      return null;
    }
  }

  /// Get video from gallery
  Future<File?> pickVideoFromGallery() async {
    try {
      final XFile? video = await _imagePicker.pickVideo(source: ImageSource.gallery);
      if (video != null) {
        return File(video.path);
      }
      return null;
    } catch (e) {
      print('Error picking video: $e');
      return null;
    }
  }

  /// Dispose camera
  Future<void> dispose() async {
    if (_controller != null) {
      await _controller!.dispose();
      _controller = null;
    }
  }

  bool get isRecording => _controller?.value.isRecordingVideo ?? false;
}
