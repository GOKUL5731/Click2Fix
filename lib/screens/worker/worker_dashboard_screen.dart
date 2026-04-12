import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../services/booking_service.dart';
import '../../services/api_client.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_card.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  DateTime? _lastBackPressTime;
  bool _isMarkingDone = false;
  String? _activeBookingId;

  static const _activeStatuses = {
    'pending',
    'confirmed',
    'worker_on_way',
    'arrived',
    'work_started',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadActiveBooking());
  }

  Future<void> _loadActiveBooking() async {
    try {
      final session = ref.read(sessionProvider);
      final client = ref.read(apiClientProvider);
      client.setToken(session.token);
      final bookingService = BookingService(client);
      final history = await bookingService.getHistory();
      for (final raw in history) {
        if (raw is! Map) continue;
        final map = Map<String, dynamic>.from(raw);
        final status = map['booking_status'] as String?;
        if (status != null && _activeStatuses.contains(status)) {
          final id = map['id']?.toString();
          if (id != null && id.isNotEmpty) {
            if (mounted) setState(() => _activeBookingId = id);
            return;
          }
        }
      }
      if (mounted) setState(() => _activeBookingId = null);
    } catch (_) {
      if (mounted) setState(() => _activeBookingId = null);
    }
  }

  Future<void> _markJobDone() async {
    if (_activeBookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No active booking to complete'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isMarkingDone = true);
    try {
      final session = ref.read(sessionProvider);
      final client = ref.read(apiClientProvider);
      client.setToken(session.token);
      final bookingService = BookingService(client);
      await bookingService.completeBooking(_activeBookingId!);

      if (!mounted) return;
      setState(() {
        _isMarkingDone = false;
        _activeBookingId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Job marked complete. The customer has been notified for a rating.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingDone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete booking: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Press back again to exit'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(32), bottomRight: Radius.circular(32)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, ${session.name?.split(' ').first ?? 'Worker'}! 🔧',
                              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                            const SizedBox(height: 4),
                            const Text('You have 3 new requests nearby', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            _Btn(icon: Icons.notifications_outlined, onTap: () => context.go('/notifications')),
                            const SizedBox(width: 8),
                            _Btn(icon: Icons.person_outline, onTap: () => context.go('/worker/profile')),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        _StatPill(label: 'Today', value: '₹1,250', icon: Icons.currency_rupee),
                        const SizedBox(width: 12),
                        _StatPill(label: 'Rating', value: '4.8 ★', icon: Icons.star),
                        const SizedBox(width: 12),
                        _StatPill(label: 'Jobs', value: '127', icon: Icons.check_circle),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Availability toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    decoration: BoxDecoration(color: AppColors.success.withOpacity(0.05)),
                    child: Row(
                      children: [
                        Container(
                          width: 12, height: 12,
                          decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.success, boxShadow: [BoxShadow(color: AppColors.success.withOpacity(0.4), blurRadius: 4)]),
                        ),
                        const SizedBox(width: 12),
                        const Text('You are Online', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 16)),
                        const Spacer(),
                        const Text('Available for jobs', style: TextStyle(color: AppColors.textLight, fontSize: 12)),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),

              // Active Job Card
              if (_activeBookingId != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.05)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Icon(Icons.handyman, color: AppColors.primary, size: 20),
                              ),
                              const SizedBox(width: 12),
                              const Text('Active Job', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary)),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Text('Job in progress — tap below when work is done.', style: TextStyle(color: AppColors.textDark, fontSize: 14)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: AppButton(
                              onPressed: _isMarkingDone ? () {} : _markJobDone,
                              text: _isMarkingDone ? 'Completing...' : 'Mark Job as Done ✓',
                              icon: _isMarkingDone ? null : const Icon(Icons.check_circle, color: Colors.white),
                              isLoading: _isMarkingDone,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(child: _ActionCard(icon: Icons.map, label: 'Nearby Requests', color: AppColors.primary, onTap: () => context.go('/worker/requests'))),
                    const SizedBox(width: 16),
                    Expanded(child: _ActionCard(icon: Icons.account_balance_wallet, label: 'My Earnings', color: AppColors.accent, onTap: () => context.go('/worker/earnings'))),
                    const SizedBox(width: 16),
                    Expanded(child: _ActionCard(icon: Icons.history, label: 'Job History', color: AppColors.success, onTap: () => context.go('/history'))),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: const Text('New Requests', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark)),
              ),
              const SizedBox(height: 16),

              ..._requests.map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                            child: Icon(r.icon, color: AppColors.primary, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark)),
                                const SizedBox(height: 4),
                                Text(r.location, style: const TextStyle(color: AppColors.textLight, fontSize: 12)),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(color: r.urgencyColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                            child: Text(r.urgency, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: r.urgencyColor)),
                          ),
                        ],
                      ),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1)),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(r.distance, style: const TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
                          const SizedBox(width: 16),
                          const Icon(Icons.payments_outlined, size: 16, color: AppColors.textHint),
                          const SizedBox(width: 4),
                          Text(r.priceRange, style: const TextStyle(color: AppColors.textHint, fontSize: 13, fontWeight: FontWeight.w500)),
                          const Spacer(),
                          SizedBox(
                            width: 110,
                            child: AppButton(
                              text: 'Send Quote',
                              onPressed: () => context.go('/worker/quote'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  static final _requests = [
    (title: 'Kitchen Pipe Leaking', location: 'T. Nagar, Chennai', distance: '2.4 km', priceRange: '₹300–500', urgency: 'High', urgencyColor: AppColors.error, icon: Icons.plumbing),
    (title: 'Fan Not Working', location: 'Anna Nagar, Chennai', distance: '3.8 km', priceRange: '₹200–400', urgency: 'Medium', urgencyColor: AppColors.accent, icon: Icons.electrical_services),
    (title: 'Door Hinge Broken', location: 'Adyar, Chennai', distance: '5.1 km', priceRange: '₹150–300', urgency: 'Low', urgencyColor: AppColors.success, icon: Icons.carpenter),
  ];
}

class _Btn extends StatelessWidget {
  const _Btn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.white, size: 20),
    ),
  );
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      ),
    ),
  );
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.divider),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 4, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textDark), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
