import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_theme.dart';
import '../../providers/session_provider.dart';
import '../../services/booking_service.dart';
import '../../widgets/gradient_header.dart';

class WorkerDashboardScreen extends ConsumerStatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  ConsumerState<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends ConsumerState<WorkerDashboardScreen> {
  DateTime? _lastBackPressTime;
  bool _isMarkingDone = false;
  // In a real app, this would be fetched from the API
  String? _activeBookingId;

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
          content: Text('âœ… Job marked as complete! User has been notified.'),
          backgroundColor: AppColors.successGreen,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isMarkingDone = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to complete booking: $e'), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressTime == null ||
            now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
          _lastBackPressTime = now;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Press back again to exit'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GradientHeader(
                title: 'Hi, ${session.name ?? 'Worker'}! ðŸ”§',
                subtitle: 'You have 3 new requests nearby',
                gradient: const LinearGradient(colors: [Color(0xFF1565C0), Color(0xFF0D47A1), Color(0xFF01579B)]),
                trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                  _Btn(icon: Icons.notifications_outlined, onTap: () => context.go('/notifications')),
                  const SizedBox(width: 8),
                  _Btn(icon: Icons.person_outline, onTap: () => context.go('/worker/profile')),
                ]),
                child: Row(children: [
                  _StatPill(label: 'Today', value: 'â‚¹1,250', icon: Icons.currency_rupee),
                  const SizedBox(width: 10),
                  _StatPill(label: 'Rating', value: '4.8 â˜…', icon: Icons.star),
                  const SizedBox(width: 10),
                  _StatPill(label: 'Jobs', value: '127', icon: Icons.check_circle),
                ]),
              ),
              const SizedBox(height: 20),

              // Availability toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withAlpha(15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.successGreen.withAlpha(40)),
                  ),
                  child: Row(children: [
                    Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.successGreen)),
                    const SizedBox(width: 10),
                    Text('You are Online', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.successGreen)),
                    const Spacer(),
                    Text('Available for jobs', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                  ]),
                ),
              ),
              const SizedBox(height: 20),

              // Active Job Card with Mark Done
              if (_activeBookingId != null) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [AppColors.primaryBlue.withAlpha(20), AppColors.primaryBlue.withAlpha(10)]),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.primaryBlue.withAlpha(60)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Icon(Icons.work, color: AppColors.primaryBlue, size: 20),
                          const SizedBox(width: 8),
                          Text('Active Job', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.primaryBlue, fontWeight: FontWeight.w700)),
                        ]),
                        const SizedBox(height: 12),
                        const Text('Job in progress â€” tap below when work is done'),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isMarkingDone ? null : _markJobDone,
                            icon: _isMarkingDone
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Icon(Icons.check_circle_outline),
                            label: Text(_isMarkingDone ? 'Completing...' : 'Mark Job as Done âœ“'),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.successGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Quick Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(children: [
                  Expanded(child: _ActionCard(icon: Icons.map, label: 'Nearby\nRequests', color: AppColors.primaryBlue, onTap: () => context.go('/worker/requests'))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(icon: Icons.account_balance_wallet, label: 'My\nEarnings', color: AppColors.trustGold, onTap: () => context.go('/worker/earnings'))),
                  const SizedBox(width: 12),
                  Expanded(child: _ActionCard(icon: Icons.history, label: 'Job\nHistory', color: AppColors.successGreen, onTap: () => context.go('/history'))),
                ]),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Text('New Requests', style: Theme.of(context).textTheme.headlineSmall),
              ),
              const SizedBox(height: 12),

              ..._requests.map((r) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: AppColors.primaryBlue.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                        child: Icon(r.icon, color: AppColors.primaryBlue, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(r.title, style: Theme.of(context).textTheme.titleSmall),
                        Text(r.location, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                      ])),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: r.urgencyColor.withAlpha(15), borderRadius: BorderRadius.circular(12)),
                        child: Text(r.urgency, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: r.urgencyColor)),
                      ),
                    ]),
                    const SizedBox(height: 12),
                    Row(children: [
                      Icon(Icons.location_on, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(r.distance, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
                      const SizedBox(width: 14),
                      Icon(Icons.currency_rupee, size: 14, color: AppColors.textHint),
                      const SizedBox(width: 4),
                      Text(r.priceRange, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppColors.textHint)),
                      const Spacer(),
                      SizedBox(
                        height: 34,
                        child: FilledButton(
                          onPressed: () => context.go('/worker/quote'),
                          child: const Text('Send Quote', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                    ]),
                  ]),
                ),
              )),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  static final _requests = [
    (title: 'Kitchen Pipe Leaking', location: 'T. Nagar, Chennai', distance: '2.4 km', priceRange: 'â‚¹300â€“500', urgency: 'High', urgencyColor: AppColors.emergencyRed, icon: Icons.plumbing),
    (title: 'Fan Not Working', location: 'Anna Nagar, Chennai', distance: '3.8 km', priceRange: 'â‚¹200â€“400', urgency: 'Medium', urgencyColor: AppColors.trustGold, icon: Icons.electrical_services),
    (title: 'Door Hinge Broken', location: 'Adyar, Chennai', distance: '5.1 km', priceRange: 'â‚¹150â€“300', urgency: 'Low', urgencyColor: AppColors.successGreen, icon: Icons.carpenter),
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
      decoration: BoxDecoration(color: Colors.white.withAlpha(25), borderRadius: BorderRadius.circular(12)),
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
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
    decoration: BoxDecoration(color: Colors.white.withAlpha(20), borderRadius: BorderRadius.circular(10)),
    child: Column(children: [
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(color: Colors.white60, fontSize: 10)),
    ]),
  ));
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({required this.icon, required this.label, required this.color, required this.onTap});
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : AppColors.divider),
        ),
        child: Column(children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: color.withAlpha(15), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 10),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600), textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}

