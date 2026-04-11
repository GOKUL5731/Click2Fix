import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../services/camera_service.dart';

class CameraScreen extends StatefulWidget {
  final bool isVideo;
  const CameraScreen({super.key, this.isVideo = false});

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final _cameraService = CameraService();
  bool _isCapturing = false;

  Future<void> _capture() async {
    if (_isCapturing) return;
    setState(() => _isCapturing = true);

    try {
      final File? file = widget.isVideo
          ? await _cameraService.recordVideo()
          : await _cameraService.capturePhoto();

      if (file != null && mounted) {
        Navigator.of(context).pop(file);
      } else if (mounted) {
        setState(() => _isCapturing = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isCapturing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    final File? file = widget.isVideo
        ? await _cameraService.pickVideoFromGallery()
        : await _cameraService.pickFromGallery();
    if (file != null && mounted) {
      Navigator.of(context).pop(file);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(widget.isVideo ? 'Record Video' : 'Take Photo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white30),
              ),
              child: Icon(
                widget.isVideo ? Icons.videocam : Icons.camera_alt,
                size: 60,
                color: Colors.white54,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              widget.isVideo ? 'Record a Video' : 'Take a Photo',
              style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your device camera will open instantly',
              style: TextStyle(color: Colors.white54, fontSize: 14),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library, color: Colors.white70),
                  label: const Text('Gallery', style: TextStyle(color: Colors.white70)),
                  style: OutlinedButton.styleFrom(side: const BorderSide(color: Colors.white24)),
                ),
                const SizedBox(width: 16),
                FilledButton.icon(
                  onPressed: _isCapturing ? null : _capture,
                  icon: _isCapturing
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Icon(widget.isVideo ? Icons.videocam : Icons.camera_alt),
                  label: Text(widget.isVideo ? 'Record' : 'Camera'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
