import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/admin_theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/kpi_card.dart';

enum AccessRole { user, worker, admin }

extension on AccessRole {
  String get label => switch (this) {
        AccessRole.user => 'User',
        AccessRole.worker => 'Worker',
        AccessRole.admin => 'Admin',
      };

  String get subtitle => switch (this) {
        AccessRole.user => 'Book repairs, compare quotes, and track jobs.',
        AccessRole.worker => 'Manage requests, quotes, and earnings.',
        AccessRole.admin => 'Monitor operations, fraud, and revenue.',
      };

  IconData get icon => switch (this) {
        AccessRole.user => Icons.home_repair_service_outlined,
        AccessRole.worker => Icons.engineering_outlined,
        AccessRole.admin => Icons.admin_panel_settings_outlined,
      };

  Color get accent => switch (this) {
        AccessRole.user => const Color(0xFF0F4C81),
        AccessRole.worker => const Color(0xFF0B8F6A),
        AccessRole.admin => const Color(0xFFFF7A18),
      };

  String get route => switch (this) {
        AccessRole.user => '/user-home',
        AccessRole.worker => '/worker-home',
        AccessRole.admin => '/dashboard',
      };

  String get actionLabel => switch (this) {
        AccessRole.user => 'Enter User Hub',
        AccessRole.worker => 'Enter Worker Hub',
        AccessRole.admin => 'Enter Admin Console',
      };
}

class AccessPortalScreen extends StatefulWidget {
  const AccessPortalScreen({super.key, this.initialRole = AccessRole.user});

  final AccessRole initialRole;

  @override
  State<AccessPortalScreen> createState() => _AccessPortalScreenState();
}

class _AccessPortalScreenState extends State<AccessPortalScreen> {
  late AccessRole _selectedRole = widget.initialRole;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.sizeOf(context).width > 980;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFEAF4FF),
              Color(0xFFFDF8EF),
              Color(0xFFFFF1E8),
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1200),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: isWide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: _buildHero(context)),
                          const SizedBox(width: 20),
                          SizedBox(width: 470, child: _buildRoleLogin(context)),
                        ],
                      )
                    : ListView(
                        children: [
                          _buildHero(context),
                          const SizedBox(height: 18),
                          _buildRoleLogin(context),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHero(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white,
                border:
                    Border.all(color: AdminColors.primaryBlue.withOpacity(0.2)),
              ),
              child: const Text('Click2Fix Unified Access'),
            ),
            const SizedBox(height: 20),
            Text(
              'One Portal, Role-Based Access',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AdminColors.slateInk,
                  ),
            ),
            const SizedBox(height: 12),
            Text(
              'Switch between User, Worker, and Admin experiences from a single login page.',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AdminColors.slateInk.withOpacity(0.8),
                  ),
            ),
            const SizedBox(height: 24),
            _FeatureStripe(
              icon: Icons.security_outlined,
              title: 'Role-based entry',
              body:
                  'Each role gets tailored navigation and tools right after login.',
            ),
            const SizedBox(height: 10),
            _FeatureStripe(
              icon: Icons.bolt_outlined,
              title: 'Fast operator workflow',
              body: 'Jump from monitoring to escalation with fewer clicks.',
            ),
            const SizedBox(height: 10),
            _FeatureStripe(
              icon: Icons.auto_graph_outlined,
              title: 'Live operational view',
              body:
                  'Track bookings, fraud risk, and payout signals from one place.',
            ),
            const Spacer(),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                Chip(label: Text('User Journeys')),
                Chip(label: Text('Worker Ops')),
                Chip(label: Text('Admin Command')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleLogin(BuildContext context) {
    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 420),
      tween: Tween(begin: 0.98, end: 1),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Choose Role',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              SegmentedButton<AccessRole>(
                segments: AccessRole.values
                    .map(
                      (role) => ButtonSegment<AccessRole>(
                        value: role,
                        icon: Icon(role.icon),
                        label: Text(role.label),
                      ),
                    )
                    .toList(),
                selected: {_selectedRole},
                onSelectionChanged: (value) =>
                    setState(() => _selectedRole = value.first),
              ),
              const SizedBox(height: 16),
              Text(
                _selectedRole.subtitle,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: Colors.black87),
              ),
              const SizedBox(height: 18),
              if (_selectedRole == AccessRole.admin) ...[
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Admin email',
                    prefixIcon: Icon(Icons.alternate_email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(_obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined),
                    ),
                  ),
                ),
              ] else ...[
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone number',
                    prefixText: '+91 ',
                    prefixIcon: Icon(Icons.phone_android_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                const TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'OTP (Demo)',
                    prefixIcon: Icon(Icons.password_outlined),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _selectedRole.accent,
                    minimumSize: const Size.fromHeight(50),
                  ),
                  onPressed: () => context.go(_selectedRole.route),
                  icon: Icon(_selectedRole.icon),
                  label: Text(_selectedRole.actionLabel),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Demo mode: role determines destination dashboard.',
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: Colors.black54),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) =>
      const AccessPortalScreen(initialRole: AccessRole.admin);
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Admin Command Center',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Total Users', value: '12,400', delta: '+4.2%')),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Active Workers', value: '1,850', delta: '+2.1%')),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Open Bookings',
                      value: '84',
                      delta: '-0.8%',
                      positive: false)),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Emergency SLA', value: '97.4%', delta: '+1.9%')),
            ],
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Operational Pulse',
            body:
                'Peak bookings detected between 7:00 PM and 9:00 PM. Add 12 temporary workers to prevent SLA slips.',
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Risk Watch',
            body:
                '3 workers flagged for unusual cancellation spikes and rapid price swings.',
            danger: true,
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Revenue Opportunity',
            body:
                'Appliance repair demand is up 18% in South Zone. Raise promo budgets for next 48 hours.',
          ),
        ],
      );
}

class UserHomeScreen extends StatelessWidget {
  const UserHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'User Experience Hub',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Open Requests', value: '3', delta: '+1 today')),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Avg Quote Time',
                      value: '7 min',
                      delta: '-1.2 min')),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Saved This Month',
                      value: 'INR 1,250',
                      delta: '+8.1%')),
            ],
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Upcoming Service',
            body:
                'Plumbing visit confirmed for 7:30 PM. Worker ETA and live tracking become available 20 minutes before start.',
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Quick Actions',
            body:
                'Upload issue, compare quotes, or request emergency support from the same dashboard.',
          ),
        ],
      );
}

class UserBookingsScreen extends StatelessWidget {
  const UserBookingsScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'User Bookings',
        children: const [
          _ActivityTile(
            title: 'Kitchen Pipe Leak',
            subtitle: 'Ravi Kumar • Confirmed • ETA 18 min',
            badge: 'Live',
          ),
          _ActivityTile(
            title: 'Ceiling Fan Repair',
            subtitle: 'Anil Raj • Completed • Rated 5/5',
            badge: 'Done',
          ),
          _ActivityTile(
            title: 'Washing Machine Noise',
            subtitle: 'Quotes received: 4 • Awaiting selection',
            badge: 'Pending',
          ),
        ],
      );
}

class UserWalletScreen extends StatelessWidget {
  const UserWalletScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'User Payments',
        children: const [
          _SignalPanel(
            title: 'Payment Health',
            body:
                'Saved cards: 2. UPI linked: yes. Last payment status: successful.',
          ),
          SizedBox(height: 12),
          _SignalPanel(
            title: 'Recent Transactions',
            body:
                'INR 450 • Plumbing • Paid by UPI\nINR 820 • Electrical • Paid by Card',
          ),
        ],
      );
}

class WorkerHomeScreen extends StatelessWidget {
  const WorkerHomeScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Worker Operations',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Nearby Requests', value: '6', delta: '+2')),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Acceptance Rate', value: '82%', delta: '+3.4%')),
              SizedBox(
                  width: 240,
                  child: KpiCard(
                      label: 'Today Earnings',
                      value: 'INR 2,450',
                      delta: '+11.0%')),
            ],
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Priority Job',
            body:
                'Gas stove issue marked critical near Indiranagar. Suggested quote range INR 500 - 700.',
          ),
          const SizedBox(height: 12),
          const _SignalPanel(
            title: 'Profile Strength',
            body:
                'Trust score 92. Add one more verification document to unlock premium request queue.',
          ),
        ],
      );
}

class WorkerJobsScreen extends StatelessWidget {
  const WorkerJobsScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Worker Jobs',
        children: const [
          _ActivityTile(
            title: 'Pipe Leakage - 2.1 km',
            subtitle: 'High urgency • Suggested INR 450',
            badge: 'New',
          ),
          _ActivityTile(
            title: 'Fan Not Working - 4.2 km',
            subtitle: 'Medium urgency • Suggested INR 600',
            badge: 'New',
          ),
          _ActivityTile(
            title: 'Bathroom Fitting Change',
            subtitle: 'Accepted • User awaiting ETA update',
            badge: 'Active',
          ),
        ],
      );
}

class WorkerWalletScreen extends StatelessWidget {
  const WorkerWalletScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Worker Wallet',
        children: const [
          _SignalPanel(
            title: 'Payout Summary',
            body:
                'Available balance: INR 2,450\nNext payout cycle: Tonight 10:00 PM',
          ),
          SizedBox(height: 12),
          _SignalPanel(
            title: 'Weekly Performance',
            body:
                'Completed jobs: 23\nAverage rating: 4.8\nCancellation rate: 2.3%',
          ),
        ],
      );
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
      title: 'User Management',
      body:
          'Search users, check status, review booking history, and support notes.');
}

class WorkerManagementScreen extends StatelessWidget {
  const WorkerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Worker Management',
        body:
            'Workers, categories, availability, rating, trust score, and blacklist status.',
      );
}

class WorkerVerificationScreen extends StatelessWidget {
  const WorkerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Worker Verification',
        children: [
          const _SignalPanel(
            title: 'Pending Worker',
            body:
                'Ravi Kumar • Plumbing • Aadhaar pending • Selfie review needed.',
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.check),
                  label: const Text('Approve')),
              OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.close),
                  label: const Text('Reject')),
            ],
          ),
        ],
      );
}

class DocumentReviewScreen extends StatelessWidget {
  const DocumentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
      title: 'Document Review',
      body:
          'Aadhaar viewer, extracted details, manual notes, approve, and reject.');
}

class FraudDetectionDashboardScreen extends StatelessWidget {
  const FraudDetectionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Fraud Detection',
        body:
            'Risk scores, duplicate faces, unusual pricing, cancellation spikes, and fake review clusters.',
      );
}

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Booking Management',
        body:
            'Booking status, timeline, payment status, user, worker, and issue detail.',
      );
}

class ComplaintManagementScreen extends StatelessWidget {
  const ComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Complaint Management',
        body:
            'Complaint queue, SLA timer, refunds, escalations, and resolution notes.',
      );
}

class EmergencyMonitoringScreen extends StatelessWidget {
  const EmergencyMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Emergency Monitoring',
        body: 'Live emergency queue, SLA timers, and escalation controls.',
      );
}

class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
      title: 'Revenue Dashboard',
      body:
          'GMV, platform fee, refunds, payouts, city filters, and category filters.');
}

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Analytics Dashboard',
        body:
            'Funnel, retention, category demand, worker supply heatmap, and response SLA.',
      );
}

class PricingControlScreen extends StatelessWidget {
  const PricingControlScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Pricing Control',
        body:
            'Market rates, city multipliers, emergency surcharge, and category price bands.',
      );
}

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
      title: 'Category Management',
      body: 'Categories, skills, AI labels, icons, and active status.');
}

class NotificationBroadcastingScreen extends StatelessWidget {
  const NotificationBroadcastingScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(
        title: 'Notification Broadcasting',
        body: 'Audience, message, preview, schedule, and delivery status.',
      );
}

class _AdminModule extends StatelessWidget {
  const _AdminModule({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AdminShell(
        title: title,
        children: [
          _SignalPanel(title: title, body: body),
        ],
      );
}

class _FeatureStripe extends StatelessWidget {
  const _FeatureStripe({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AdminColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalPanel extends StatelessWidget {
  const _SignalPanel({
    required this.title,
    required this.body,
    this.danger = false,
  });

  final String title;
  final String body;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final stripe = danger ? AdminColors.emergencyRed : AdminColors.primaryBlue;

    return Card(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              Colors.white,
              stripe.withOpacity(0.08),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 10,
                height: 60,
                decoration: BoxDecoration(
                  color: stripe,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(body),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String badge;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: Chip(label: Text(badge)),
      ),
    );
  }
}
