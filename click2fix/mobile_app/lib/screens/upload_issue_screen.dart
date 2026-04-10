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
  bool _hasImage = false;
  String _imageName = '';
  bool _isAnalyzing = false;

  void _simulatePickImage() {
    setState(() { _hasImage = true; _imageName = 'kitchen_leak_photo.jpg'; });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('📷 Image selected: kitchen_leak_photo.jpg'), duration: Duration(seconds: 1)),
    );
  }

  void _analyze() {
    setState(() => _isAnalyzing = true);
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) { setState(() => _isAnalyzing = false); context.go('/ai-result'); }
    });
  }

  @override
  void dispose() { _descController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/home')),
        title: const Text('Report Issue'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          GestureDetector(
            onTap: _simulatePickImage,
            child: Container(
              width: double.infinity, height: 220,
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _hasImage ? AppColors.successGreen : AppColors.primaryBlue.withAlpha(60), width: 2),
              ),
              child: _hasImage
                  ? Stack(children: [
                      Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(20), borderRadius: BorderRadius.circular(20)),
                          child: const Icon(Icons.check_circle, color: AppColors.successGreen, size: 48),
                        ),
                        const SizedBox(height: 12),
                        Text(_imageName, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Tap to change image', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ])),
                      Positioned(top: 10, right: 10, child: GestureDetector(
                        onTap: () => setState(() { _hasImage = false; _imageName = ''; }),
                        child: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(20)),
                          child: Icon(Icons.close, color: isDark ? Colors.white : Colors.white, size: 18)),
                      )),
                    ])
                  : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.camera_alt_rounded, size: 36, color: AppColors.primaryBlue)),
                      const SizedBox(height: 14),
                      Text('Tap to select image', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text('Photos help AI detect the issue accurately', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                    ]),
            ),
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _Opt(icon: Icons.camera_alt, label: 'Camera', onTap: _simulatePickImage)),
            const SizedBox(width: 10),
            Expanded(child: _Opt(icon: Icons.photo_library, label: 'Gallery', onTap: _simulatePickImage)),
            const SizedBox(width: 10),
            Expanded(child: _Opt(icon: Icons.videocam, label: 'Video', onTap: _simulatePickImage)),
          ]),
          const SizedBox(height: 28),
          Text('Describe the problem', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          TextField(controller: _descController, maxLines: 4, decoration: const InputDecoration(hintText: 'e.g., Kitchen pipe leaking badly, water on floor')),
          const SizedBox(height: 24),
          Text('Location', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppColors.successGreen.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.my_location, color: AppColors.successGreen, size: 22)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  const Icon(Icons.check_circle, size: 14, color: AppColors.successGreen),
                  const SizedBox(width: 6),
                  Text('GPS Location Detected', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.successGreen)),
                ]),
                const SizedBox(height: 4),
                Text('Lat: 13.0827, Lng: 80.2707', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                Text('Chennai, Tamil Nadu', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
              ])),
            ]),
          ),
          const SizedBox(height: 32),
          PrimaryActionButton(label: 'Detect Problem with AI', icon: Icons.auto_awesome, isLoading: _isAnalyzing, onPressed: _analyze),
          const SizedBox(height: 24),
        ]),
      ),
    );
  }
}

class _Opt extends StatelessWidget {
  const _Opt({required this.icon, required this.label, required this.onTap});
  final IconData icon; final String label; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(onTap: onTap, child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
      child: Column(children: [Icon(icon, size: 20, color: AppColors.primaryBlue), const SizedBox(height: 4), Text(label, style: Theme.of(context).textTheme.labelSmall)]),
    ));
  }
}
