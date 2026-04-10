import 'dart:convert';
import 'dart:async';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
// ignore: avoid_web_libraries_in_flutter
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/primary_action_button.dart';

class UploadIssueScreen extends StatefulWidget {
  const UploadIssueScreen({super.key});
  @override
  State<UploadIssueScreen> createState() => _UploadIssueScreenState();
}

class _UploadIssueScreenState extends State<UploadIssueScreen> {
  final _descController = TextEditingController();
  String? _imageDataUrl;
  String? _imageName;
  bool _isAnalyzing = false;
  bool _showCamera = false;

  // dart:html elements for webcam
  html.VideoElement? _videoElement;
  html.MediaStream? _mediaStream;
  String _viewId = 'webcam-view';

  @override
  void initState() {
    super.initState();
    _viewId = 'webcam-${DateTime.now().millisecondsSinceEpoch}';
  }

  // ── Open live camera ─────────────────────────────────────────
  Future<void> _openCamera() async {
    if (!kIsWeb) return;
    try {
      final stream = await html.window.navigator.mediaDevices!.getUserMedia({
        'video': {'facingMode': 'environment'}, // back camera preferred
        'audio': false,
      });
      _mediaStream = stream;
      _videoElement = html.VideoElement()
        ..srcObject = stream
        ..autoplay = true
        ..muted = true
        ..style.width = '100%'
        ..style.height = '100%'
        ..style.objectFit = 'cover';

      // Register Flutter platform view
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        _viewId,
        (int id) => _videoElement!,
      );

      setState(() => _showCamera = true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppColors.emergencyRed,
          ),
        );
      }
    }
  }

  // ── Capture photo from live stream ───────────────────────────
  void _capturePhoto() {
    if (_videoElement == null) return;
    final canvas = html.CanvasElement(
      width: _videoElement!.videoWidth,
      height: _videoElement!.videoHeight,
    );
    canvas.context2D.drawImage(_videoElement!, 0, 0);
    final dataUrl = canvas.toDataUrl('image/jpeg', 0.92);
    _stopCamera();
    setState(() {
      _imageDataUrl = dataUrl;
      _imageName = 'camera_${DateTime.now().millisecondsSinceEpoch}.jpg';
      _showCamera = false;
    });
  }

  // ── Stop camera stream ───────────────────────────────────────
  void _stopCamera() {
    _mediaStream?.getTracks().forEach((t) => t.stop());
    _mediaStream = null;
    _videoElement = null;
  }

  // ── Gallery / file picker ────────────────────────────────────
  void _pickFromGallery() {
    if (!kIsWeb) return;
    final input = html.FileUploadInputElement()..accept = 'image/*';
    input.onChange.listen((_) {
      final file = input.files?.first;
      if (file == null) return;
      final reader = html.FileReader();
      reader.readAsDataUrl(file);
      reader.onLoad.listen((_) {
        if (mounted) {
          setState(() {
            _imageDataUrl = reader.result as String;
            _imageName = file.name;
          });
        }
      });
    });
    input.click();
  }

  void _analyze() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(milliseconds: 1800), () {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        context.go('/ai-result');
      }
    });
  }

  @override
  void dispose() {
    _stopCamera();
    _descController.dispose();
    super.dispose();
  }

  // ── Camera overlay ───────────────────────────────────────────
  Widget _buildCameraOverlay() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(children: [
        // Live video stream
        Positioned.fill(
          child: HtmlElementView(viewType: _viewId),
        ),

        // Top bar
        Positioned(
          top: 0, left: 0, right: 0,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.black.withAlpha(180), Colors.transparent],
              ),
            ),
            child: Row(children: [
              IconButton(
                onPressed: () {
                  _stopCamera();
                  setState(() => _showCamera = false);
                },
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
              const Expanded(
                child: Text('Take Photo',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(width: 48),
            ]),
          ),
        ),

        // Capture button at bottom
        Positioned(
          bottom: 40, left: 0, right: 0,
          child: Column(children: [
            Text('Aim at the problem area',
                style: TextStyle(color: Colors.white.withAlpha(180), fontSize: 14)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _capturePhoto,
              child: Container(
                width: 80, height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                  color: Colors.white.withAlpha(30),
                ),
                child: Center(
                  child: Container(
                    width: 60, height: 60,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                    ),
                    child: const Icon(Icons.camera_alt, color: AppColors.primaryBlue, size: 28),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _pickFromGallery,
              icon: const Icon(Icons.photo_library, color: Colors.white70, size: 18),
              label: const Text('Choose from Gallery',
                  style: TextStyle(color: Colors.white70)),
            ),
          ]),
        ),
      ]),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Show camera fullscreen overlay
    if (_showCamera) return _buildCameraOverlay();

    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => context.go('/home')),
        title: const Text('Report Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

          // ── Image preview / tap to open camera ───────────────
          GestureDetector(
            onTap: _openCamera,
            child: Container(
              width: double.infinity, height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _imageDataUrl != null
                      ? AppColors.successGreen
                      : AppColors.primaryBlue.withAlpha(60),
                  width: 2,
                ),
              ),
              child: _imageDataUrl != null
                  ? Stack(children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(18),
                        child: Image.memory(
                          base64Decode(_imageDataUrl!.split(',').last),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black.withAlpha(140)],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        bottom: 12, left: 14,
                        child: Row(children: [
                          const Icon(Icons.check_circle, color: AppColors.successGreen, size: 18),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(_imageName ?? 'Photo captured',
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                        ]),
                      ),
                      Positioned(
                        top: 10, right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() { _imageDataUrl = null; _imageName = null; }),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.close, color: Colors.white, size: 18),
                          ),
                        ),
                      ),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withAlpha(15),
                            borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.camera_alt_rounded, size: 36, color: AppColors.primaryBlue),
                      ),
                      const SizedBox(height: 14),
                      Text('Tap to Open Camera',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('AI will auto-detect the issue from photo',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ]),
            ),
          ),

          const SizedBox(height: 14),

          // ── Action buttons ────────────────────────────────────
          Row(children: [
            Expanded(child: _Opt(icon: Icons.camera_alt, label: 'Camera', onTap: _openCamera)),
            const SizedBox(width: 10),
            Expanded(child: _Opt(icon: Icons.photo_library, label: 'Gallery', onTap: _pickFromGallery)),
            const SizedBox(width: 10),
            Expanded(child: _Opt(icon: Icons.refresh, label: 'Retake', onTap: _imageDataUrl != null ? _openCamera : _openCamera)),
          ]),

          const SizedBox(height: 28),

          Text('Describe the problem', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(
            controller: _descController, maxLines: 4,
            decoration: const InputDecoration(hintText: 'e.g., Kitchen pipe leaking, water on the floor'),
          ),

          const SizedBox(height: 24),

          Text('Location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.my_location, color: AppColors.successGreen, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 6),
                  Text('GPS Location Detected',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.successGreen)),
                ]),
                const SizedBox(height: 4),
                Text('Lat: 13.0827, Lng: 80.2707',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                Text('Chennai, Tamil Nadu',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ])),
            ]),
          ),

          const SizedBox(height: 32),

          PrimaryActionButton(
            label: 'Detect Problem with AI',
            icon: Icons.auto_awesome,
            isLoading: _isAnalyzing,
            onPressed: _analyze,
          ),

          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Opt extends StatelessWidget {
  const _Opt({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        ),
        child: Column(children: [
          Icon(icon, size: 20, color: AppColors.primaryBlue),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.labelSmall),
        ]),
      ),
    );
  }
}
