import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../widgets/app_button.dart';

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
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Live Tracking', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textDark),
      ),
      body: Column(
        children: [
          // Map placeholder
          Expanded(
            flex: 3,
            child: Container(
              width: double.infinity,
              color: AppColors.divider.withOpacity(0.5),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.map_outlined, size: 80, color: AppColors.primary.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        const Text('Live Map View', style: TextStyle(fontSize: 18, color: AppColors.textLight, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        const Text('Worker location updates in real-time', style: TextStyle(fontSize: 14, color: AppColors.textHint)),
                      ],
                    ),
                  ),
                  // Worker marker
                  Positioned(
                    left: 40 + (_workerProgress * (MediaQuery.of(context).size.width - 120)),
                    top: 60 + (_workerProgress * 80),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: const Icon(Icons.engineering, color: Colors.white, size: 24),
                    ),
                  ),
                  // User marker
                  Positioned(
                    right: 40,
                    bottom: 60,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                        boxShadow: [
                          BoxShadow(color: AppColors.success.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5)),
                        ],
                      ),
                      child: const Icon(Icons.home, color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Bottom panel
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text('R', style: TextStyle(color: AppColors.primary, fontSize: 24, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Ravi Kumar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                          const SizedBox(height: 4),
                          Text(
                            _status,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: _workerProgress >= 0.9 ? AppColors.success : AppColors.textLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => context.go('/chat'),
                      icon: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 20),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Progress bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: _workerProgress,
                    minHeight: 8,
                    backgroundColor: AppColors.divider,
                    color: _workerProgress >= 0.9 ? AppColors.success : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('ETA', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    Text('${((1 - _workerProgress) * 18).toInt()} min', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Distance', style: TextStyle(color: AppColors.textLight, fontSize: 13)),
                    Text('${(_workerProgress * 2.4).toStringAsFixed(1)} km away', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textDark, fontSize: 13)),
                  ],
                ),
                const SizedBox(height: 24),
                if (_workerProgress >= 0.9)
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Proceed to Payment',
                      onPressed: () => context.go('/payment'),
                      icon: const Icon(Icons.payment, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
