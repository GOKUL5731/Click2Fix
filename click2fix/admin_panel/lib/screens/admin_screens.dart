import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/admin_theme.dart';
import '../widgets/admin_shell.dart';
import '../widgets/kpi_card.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Click2Fix Admin', style: Theme.of(context).textTheme.headlineSmall),
                  const TextField(decoration: InputDecoration(labelText: 'Email')),
                  const TextField(decoration: InputDecoration(labelText: 'Password'), obscureText: true),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(onPressed: () => context.go('/dashboard'), child: const Text('Login')),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Dashboard',
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              SizedBox(width: 220, child: KpiCard(label: 'Total Users', value: '12,400')),
              SizedBox(width: 220, child: KpiCard(label: 'Total Workers', value: '1,850')),
              SizedBox(width: 220, child: KpiCard(label: 'Active Bookings', value: '84')),
              SizedBox(width: 220, child: KpiCard(label: 'Emergency Requests', value: '6')),
              SizedBox(width: 220, child: KpiCard(label: 'Total Revenue', value: 'INR 18.2L')),
            ],
          ),
          const _Panel(title: 'Daily, Weekly, Monthly Charts', body: 'Bookings, revenue, emergency SLA, and category demand.'),
          const _Panel(title: 'Fraud Alerts', body: 'Duplicate faces, unusual pricing, fake review clusters.'),
          const _Panel(title: 'Worker Approval Queue', body: 'Pending documents and face verification reviews.'),
        ],
      );
}

class UserManagementScreen extends StatelessWidget {
  const UserManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'User Management', body: 'Search users, check status, review booking history, and support notes.');
}

class WorkerManagementScreen extends StatelessWidget {
  const WorkerManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Worker Management', body: 'Workers, categories, availability, rating, trust score, and blacklist status.');
}

class WorkerVerificationScreen extends StatelessWidget {
  const WorkerVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Worker Verification',
        children: [
          const _Panel(title: 'Pending Worker', body: 'Ravi Kumar. Plumbing. Aadhaar pending. Selfie review needed.'),
          Wrap(
            spacing: 8,
            children: [
              FilledButton(onPressed: () {}, child: const Text('Approve')),
              OutlinedButton(onPressed: () {}, child: const Text('Reject')),
            ],
          ),
        ],
      );
}

class DocumentReviewScreen extends StatelessWidget {
  const DocumentReviewScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Document Review', body: 'Aadhaar viewer, extracted details, manual notes, approve, and reject.');
}

class FraudDetectionDashboardScreen extends StatelessWidget {
  const FraudDetectionDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Fraud Detection', body: 'Risk scores, duplicate faces, unusual pricing, cancellation spikes, and fake review clusters.');
}

class BookingManagementScreen extends StatelessWidget {
  const BookingManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Booking Management', body: 'Booking status, timeline, payment status, user, worker, and issue detail.');
}

class ComplaintManagementScreen extends StatelessWidget {
  const ComplaintManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Complaint Management', body: 'Complaint queue, SLA timer, refunds, escalations, and resolution notes.');
}

class EmergencyMonitoringScreen extends StatelessWidget {
  const EmergencyMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context) => AdminShell(
        title: 'Emergency Monitoring',
        children: const [
          _Panel(title: 'Live Emergency Queue', body: 'Gas leak. 2 workers alerted. SLA 02:40 remaining.'),
          _Panel(title: 'Escalations', body: 'Escalate if no worker accepts before SLA expiry.'),
        ],
      );
}

class RevenueDashboardScreen extends StatelessWidget {
  const RevenueDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Revenue Dashboard', body: 'GMV, platform fee, refunds, payouts, city filters, and category filters.');
}

class AnalyticsDashboardScreen extends StatelessWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Analytics Dashboard', body: 'Funnel, retention, category demand, worker supply heatmap, and response SLA.');
}

class PricingControlScreen extends StatelessWidget {
  const PricingControlScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Pricing Control', body: 'Market rates, city multipliers, emergency surcharge, and category price bands.');
}

class CategoryManagementScreen extends StatelessWidget {
  const CategoryManagementScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Category Management', body: 'Categories, skills, AI labels, icons, and active status.');
}

class NotificationBroadcastingScreen extends StatelessWidget {
  const NotificationBroadcastingScreen({super.key});

  @override
  Widget build(BuildContext context) => const _AdminModule(title: 'Notification Broadcasting', body: 'Audience, message, preview, schedule, and delivery status.');
}

class _AdminModule extends StatelessWidget {
  const _AdminModule({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => AdminShell(title: title, children: [_Panel(title: title, body: body)]);
}

class _Panel extends StatelessWidget {
  const _Panel({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(body),
              const SizedBox(height: 8),
              LinearProgressIndicator(color: AdminColors.primaryBlue, value: 0.7),
            ],
          ),
        ),
      );
}

