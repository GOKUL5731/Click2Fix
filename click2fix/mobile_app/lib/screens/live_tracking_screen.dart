import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';

class LiveTrackingScreen extends StatefulWidget {
  const LiveTrackingScreen({super.key});
  @override
  State<LiveTrackingScreen> createState() => _LiveTrackingState();
}

class _LiveTrackingState extends State<LiveTrackingScreen> {
  double _workerProgress = 0.0;
  String _status = 'Worker is on the way';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 2), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() {
        _workerProgress = (_workerProgress + 0.08).clamp(0, 1);
        if (_workerProgress >= 0.5) _status = 'Worker is nearby';
        if (_workerProgress >= 0.9) { _status = 'Worker has arrived!'; t.cancel(); }
      });
    });
  }

  @override
  void dispose() { _timer?.cancel(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(title: const Text('Live Tracking')),
      body: Column(children: [
        // Map placeholder
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: isDark ? AppColors.cardDark : const Color(0xFFE8EAF6)),
            child: Stack(children: [
              Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.map_outlined, size: 80, color: AppColors.primaryBlue.withAlpha(60)),
                const SizedBox(height: 12),
                Text('Live Map View', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: 4),
                Text('Worker location updates in real-time', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint)),
              ])),
              // Worker marker
              Positioned(
                left: 40 + (_workerProgress * (MediaQuery.of(context).size.width - 120)),
                top: 60 + (_workerProgress * 80),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primaryBlue, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: AppColors.primaryBlue.withAlpha(60), blurRadius: 12)]),
                  child: const Icon(Icons.engineering, color: Colors.white, size: 20),
                ),
              ),
              // User marker
              Positioned(
                right: 40, bottom: 60,
                child: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.successGreen, borderRadius: BorderRadius.circular(20)),
                  child: const Icon(Icons.home, color: Colors.white, size: 20)),
              ),
            ]),
          ),
        ),
        // Bottom panel
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withAlpha(10), blurRadius: 20, offset: const Offset(0, -4))],
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 16),
            Row(children: [
              Container(width: 48, height: 48, decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(14)),
                child: const Center(child: Text('R', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w700)))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Ravi Kumar', style: Theme.of(context).textTheme.titleMedium),
                Text(_status, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: _workerProgress >= 0.9 ? AppColors.successGreen : AppColors.textSecondary)),
              ])),
              IconButton(onPressed: () => context.go('/chat'), icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.primaryBlue, size: 20))),
            ]),
            const SizedBox(height: 14),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(value: _workerProgress, minHeight: 8, backgroundColor: AppColors.divider, color: _workerProgress >= 0.9 ? AppColors.successGreen : AppColors.primaryBlue),
            ),
            const SizedBox(height: 8),
            Row(children: [
              Text('ETA: ${((1 - _workerProgress) * 18).toInt()} min', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
              const Spacer(),
              Text('${(_workerProgress * 2.4).toStringAsFixed(1)} km away', style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textSecondary)),
            ]),
            const SizedBox(height: 16),
            if (_workerProgress >= 0.9)
              SizedBox(width: double.infinity, height: 50, child: FilledButton(onPressed: () => context.go('/payment'), child: const Text('Proceed to Payment'))),
          ]),
        ),
      ]),
    );
  }
}
