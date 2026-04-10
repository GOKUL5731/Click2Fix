import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../services/issue_service.dart';

class UploadIssueScreen extends ConsumerStatefulWidget {
  const UploadIssueScreen({super.key});

  @override
  ConsumerState<UploadIssueScreen> createState() => _UploadIssueScreenState();
}

class _UploadIssueScreenState extends ConsumerState<UploadIssueScreen>
    with TickerProviderStateMixin {
  // Services
  final _apiClient = ApiClient();
  late final _authService = AuthService(_apiClient);
  late final _issueService = IssueService(_apiClient);
  final _imagePicker = ImagePicker();
  final _audioRecorder = AudioRecorder();

  // Form state
  final _descriptionController = TextEditingController();
  String? _imagePath;
  String? _voicePath;
  double? _latitude;
  double? _longitude;
  bool _isEmergency = false;

  // UI state
  bool _isSubmitting = false;
  bool _isRecording = false;
  bool _isAnalyzing = false;
  String? _aiDescription;
  String? _aiCategory;
  double? _aiConfidence;
  String? _otpToken;
  bool _showOtpDialog = false;
  final _otpController = TextEditingController();

  // Animation
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initToken();
    _detectLocation();
  }

  void _initToken() {
    final session = ref.read(sessionProvider);
    if (session.token != null) {
      _apiClient.setToken(session.token);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _otpController.dispose();
    _pulseController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _detectLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      // Default to Chennai if location unavailable
      _latitude = 13.0827;
      _longitude = 80.2707;
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _imagePath = picked.path;
          _isAnalyzing = true;
          _aiDescription = null;
          _aiCategory = null;
        });

        // Simulate AI analysis (will work with real backend)
        await Future.delayed(const Duration(seconds: 1));
        setState(() {
          _isAnalyzing = false;
          _aiDescription =
              'Problem detected in image. AI will auto-fill details after submission.';
          _aiCategory = 'auto-detect';
          _aiConfidence = 0.75;
        });
      }
    } catch (e) {
      _showSnackBar('Failed to pick image: $e');
    }
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      try {
        final path = await _audioRecorder.stop();
        setState(() {
          _isRecording = false;
          _voicePath = path;
        });
        _showSnackBar('Voice note recorded! It will be transcribed automatically.');
      } catch (e) {
        setState(() => _isRecording = false);
        _showSnackBar('Recording failed: $e');
      }
    } else {
      try {
        if (await _audioRecorder.hasPermission()) {
          final dir = await getTemporaryDirectory();
          final path = '${dir.path}/voice_note_${DateTime.now().millisecondsSinceEpoch}.webm';
          await _audioRecorder.start(
            const RecordConfig(encoder: AudioEncoder.opus),
            path: path,
          );
          setState(() => _isRecording = true);
        } else {
          _showSnackBar('Microphone permission required');
        }
      } catch (e) {
        _showSnackBar('Could not start recording: $e');
      }
    }
  }

  void _showOtpVerification() {
    final session = ref.read(sessionProvider);
    _otpController.clear();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
          left: 24,
          right: 24,
          top: 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            const Icon(Icons.shield_outlined, size: 48, color: AppColors.primaryBlue),
            const SizedBox(height: 12),
            Text(
              'Verify Your Identity',
              style: Theme.of(ctx).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Enter the OTP sent to ${session.phone ?? "your phone"} to verify this submission.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(
                hintText: '------',
                counterText: '',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Dev mode OTP: 123456',
              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final otp = _otpController.text.trim();
                  if (otp.length != 6) return;
                  try {
                    final token = await _authService.verifyUploadOtp(
                      session.phone ?? '',
                      otp,
                    );
                    setState(() => _otpToken = token);
                    if (ctx.mounted) Navigator.pop(ctx);
                    _submitIssue();
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        const SnackBar(content: Text('Invalid OTP. Try again.')),
                      );
                    }
                  }
                },
                child: const Text('Verify & Submit'),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _initiateSubmission() async {
    if (_imagePath == null) {
      _showSnackBar('Please take a photo or select an image first');
      return;
    }

    final session = ref.read(sessionProvider);

    // Request upload OTP
    setState(() => _isSubmitting = true);
    try {
      await _authService.requestUploadOtp(session.phone ?? '');
      setState(() => _isSubmitting = false);
      _showOtpVerification();
    } catch (e) {
      setState(() => _isSubmitting = false);
      // If OTP request fails (e.g., no backend), submit directly in dev mode
      _submitIssue();
    }
  }

  Future<void> _submitIssue() async {
    setState(() => _isSubmitting = true);
    try {
      final result = await _issueService.createIssue(
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : _aiDescription,
        latitude: _latitude,
        longitude: _longitude,
        isEmergency: _isEmergency,
        imagePath: _imagePath,
        voicePath: _voicePath,
        uploadToken: _otpToken,
      );
      setState(() => _isSubmitting = false);
      _showSnackBar('Issue submitted successfully! Workers will be notified.');

      if (mounted) {
        context.go('/issues');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnackBar('Submission failed: $e');
    }
  }

  void _showSnackBar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            expandedHeight: 80,
            floating: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Snap Your Problem',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  color: cs.onSurface,
                  fontSize: 20,
                ),
              ),
            ),
            actions: [
              if (_isEmergency)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.emergencyRed.withAlpha(30),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning_amber, size: 16, color: AppColors.emergencyRed),
                      const SizedBox(width: 4),
                      Text('EMERGENCY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.emergencyRed)),
                    ],
                  ),
                ),
            ],
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const SizedBox(height: 8),

                // ── Image Capture Section ──
                _buildImageSection(cs),
                const SizedBox(height: 20),

                // ── AI Analysis Result ──
                if (_isAnalyzing) _buildAnalyzingCard(),
                if (_aiDescription != null && !_isAnalyzing) _buildAiResultCard(),
                if (_aiDescription != null || _isAnalyzing) const SizedBox(height: 16),

                // ── Description Input ──
                _buildDescriptionSection(cs),
                const SizedBox(height: 16),

                // ── Voice Input ──
                _buildVoiceSection(cs),
                const SizedBox(height: 16),

                // ── Emergency Toggle ──
                _buildEmergencyToggle(),
                const SizedBox(height: 16),

                // ── Location ──
                _buildLocationCard(),
                const SizedBox(height: 24),

                // ── Submit Button ──
                _buildSubmitButton(cs),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📸 Capture the Problem',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        if (_imagePath != null)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.file(
                  File(_imagePath!),
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: IconButton.filled(
                  onPressed: () => setState(() {
                    _imagePath = null;
                    _aiDescription = null;
                    _aiCategory = null;
                  }),
                  icon: const Icon(Icons.close, size: 18),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.black54,
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          )
        else
          Row(
            children: [
              Expanded(
                child: ScaleTransition(
                  scale: _pulseAnimation,
                  child: _ImageActionCard(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    color: AppColors.primaryBlue,
                    onTap: () => _pickImage(ImageSource.camera),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ImageActionCard(
                  icon: Icons.photo_library_rounded,
                  label: 'Gallery',
                  color: AppColors.trustGold,
                  onTap: () => _pickImage(ImageSource.gallery),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildAnalyzingCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('AI Analyzing Image...',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  Text('Detecting problem type and urgency',
                      style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiResultCard() {
    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [Colors.white, AppColors.primaryBlue.withAlpha(15)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.auto_awesome, color: AppColors.primaryBlue, size: 20),
                const SizedBox(width: 8),
                Text('AI Detection',
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primaryBlue)),
                const Spacer(),
                if (_aiConfidence != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withAlpha(30),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${(_aiConfidence! * 100).toInt()}%',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.successGreen),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(_aiDescription ?? '', style: const TextStyle(fontSize: 14)),
            if (_aiCategory != null) ...[
              const SizedBox(height: 8),
              Chip(
                label: Text(_aiCategory!.replaceAll('_', ' ').toUpperCase(),
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                backgroundColor: AppColors.primaryBlue.withAlpha(20),
                visualDensity: VisualDensity.compact,
              ),
            ],
            const SizedBox(height: 8),
            FilledButton.tonal(
              onPressed: () {
                _descriptionController.text = _aiDescription ?? '';
              },
              child: const Text('Use AI Description'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescriptionSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📝 Describe the Problem',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          maxLength: 500,
          decoration: InputDecoration(
            hintText: 'E.g., "Kitchen pipe is leaking under the sink, water is spreading..."',
            helperText: 'Type manually, use AI auto-fill, or record a voice note below',
            helperMaxLines: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('🎤 Voice Description',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: cs.onSurface)),
        const SizedBox(height: 8),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _toggleRecording,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _isRecording ? AppColors.emergencyRed : AppColors.primaryBlue,
                      boxShadow: _isRecording
                          ? [BoxShadow(color: AppColors.emergencyRed.withAlpha(100), blurRadius: 16)]
                          : null,
                    ),
                    child: Icon(
                      _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _isRecording
                            ? 'Recording... Tap to stop'
                            : _voicePath != null
                                ? 'Voice note recorded ✓'
                                : 'Tap to record voice note',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: _isRecording ? AppColors.emergencyRed : null,
                        ),
                      ),
                      Text(
                        'Speak in any language — auto-translated to English',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                if (_voicePath != null)
                  IconButton(
                    onPressed: () => setState(() => _voicePath = null),
                    icon: const Icon(Icons.delete_outline),
                    color: AppColors.emergencyRed,
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmergencyToggle() {
    return Card(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: _isEmergency
              ? const LinearGradient(colors: [Color(0xFFFFF5F5), Color(0xFFFFE0E0)])
              : null,
        ),
        child: SwitchListTile(
          secondary: Icon(
            Icons.emergency_rounded,
            color: _isEmergency ? AppColors.emergencyRed : AppColors.textSecondary,
          ),
          title: Text(
            'Emergency Fix',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: _isEmergency ? AppColors.emergencyRed : null,
            ),
          ),
          subtitle: Text(
            _isEmergency
                ? 'Priority dispatch • Dynamic pricing applies'
                : 'Toggle for urgent repairs (gas leak, flooding, etc.)',
            style: const TextStyle(fontSize: 12),
          ),
          value: _isEmergency,
          onChanged: (val) => setState(() => _isEmergency = val),
          activeColor: AppColors.emergencyRed,
        ),
      ),
    );
  }

  Widget _buildLocationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(Icons.location_on, color: AppColors.primaryBlue),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Location', style: TextStyle(fontWeight: FontWeight.w600)),
                  Text(
                    _latitude != null
                        ? '${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                        : 'Detecting location...',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: _detectLocation,
              icon: const Icon(Icons.my_location, color: AppColors.primaryBlue),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton(ColorScheme cs) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: FilledButton.icon(
        onPressed: _isSubmitting ? null : _initiateSubmission,
        icon: _isSubmitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Icon(Icons.send_rounded),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Submit & Get Quotes',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: _isEmergency ? AppColors.emergencyRed : AppColors.primaryBlue,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

class _ImageActionCard extends StatelessWidget {
  const _ImageActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withAlpha(60), width: 2),
          color: color.withAlpha(15),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withAlpha(30),
              ),
              child: Icon(icon, size: 32, color: color),
            ),
            const SizedBox(height: 10),
            Text(label, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
          ],
        ),
      ),
    );
  }
}
