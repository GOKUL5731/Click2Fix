import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
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
  late CameraController? _controller;
  bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _controller = await _cameraService.initializeCamera();
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _capturePhoto() async {
    try {
      final file = await _cameraService.capturePhoto();
      if (file != null && mounted) {
        // Return the file path back to previous screen
        Navigator.of(context).pop(file);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error capturing photo: $e')),
        );
      }
    }
  }

  Future<void> _toggleVideoRecording() async {
    try {
      if (_isRecording) {
        final file = await _cameraService.recordVideo();
        if (file != null && mounted) {
          Navigator.of(context).pop(file);
        }
      } else {
        await _cameraService.recordVideo();
        setState(() => _isRecording = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _cameraService.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null || !_controller!.value.isInitialized) {
      return Scaffold(
        appBar: AppBar(title: const Text('Camera')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.isVideo ? 'Record Video' : 'Take Photo'),
      ),
      body: Stack(
        children: [
          CameraPreview(_controller!),
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                children: [
                  if (_isRecording)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withAlpha(200),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Recording...',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FloatingActionButton(
                        onPressed: () => Navigator.pop(context),
                        backgroundColor: Colors.grey[800],
                        child: const Icon(Icons.close),
                      ),
                      const SizedBox(width: 20),
                      FloatingActionButton(
                        onPressed: widget.isVideo ? _toggleVideoRecording : _capturePhoto,
                        backgroundColor: widget.isVideo && _isRecording
                            ? Colors.red
                            : AppColors.primaryBlue,
                        child: Icon(
                          widget.isVideo
                              ? (_isRecording ? Icons.stop : Icons.videocam)
                              : Icons.camera_alt,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
