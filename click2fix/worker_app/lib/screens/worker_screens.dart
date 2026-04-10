import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../widgets/action_button.dart';
import '../widgets/location_map_preview.dart';
import '../widgets/worker_scaffold.dart';

class WorkerLoginScreen extends StatelessWidget {
  const WorkerLoginScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Worker Login',
        children: [
          const TextField(
              decoration: InputDecoration(labelText: 'Mobile number'),
              keyboardType: TextInputType.phone),
          ActionButton(
              label: 'Send OTP', onPressed: () => context.go('/registration')),
        ],
      );
}

class WorkerRegistrationScreen extends StatelessWidget {
  const WorkerRegistrationScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Registration',
        children: [
          const TextField(decoration: InputDecoration(labelText: 'Full name')),
          const TextField(
              decoration: InputDecoration(labelText: 'Experience in years'),
              keyboardType: TextInputType.number),
          ActionButton(
              label: 'Continue', onPressed: () => context.go('/aadhaar')),
        ],
      );
}

class AadhaarUploadScreen extends StatelessWidget {
  const AadhaarUploadScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleWorkerScreen(
        title: 'Aadhaar Upload',
        body: 'Upload Aadhaar front and back with consent.',
        label: 'Continue',
        route: '/face',
      );
}

class FaceVerificationScreen extends StatelessWidget {
  const FaceVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleWorkerScreen(
        title: 'Face Verification',
        body: 'Capture selfie for face match review.',
        label: 'Continue',
        route: '/skills',
      );
}

class SkillSelectionScreen extends StatelessWidget {
  const SkillSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Skills',
        children: [
          const Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilterChip(
                  label: Text('Plumbing'), selected: true, onSelected: null),
              FilterChip(
                  label: Text('Electrical'), selected: false, onSelected: null),
              FilterChip(
                  label: Text('Carpentry'), selected: false, onSelected: null),
              FilterChip(
                  label: Text('Cleaning'), selected: false, onSelected: null),
              FilterChip(
                  label: Text('Painting'), selected: false, onSelected: null),
              FilterChip(
                  label: Text('Appliance Repair'),
                  selected: false,
                  onSelected: null),
            ],
          ),
          ActionButton(
              label: 'Set Service Area', onPressed: () => context.go('/area')),
        ],
      );
}

class WorkingAreaSetupScreen extends StatelessWidget {
  const WorkingAreaSetupScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Service Area',
        children: [
          const _InfoCard(
              title: 'Service Radius', body: 'Set radius and working zones.'),
          const LocationMapPreview(
            title: 'Coverage preview',
            note: 'Draw editable service polygons in the next iteration.',
          ),
          ActionButton(
              label: 'Set Hours', onPressed: () => context.go('/hours')),
        ],
      );
}

class WorkingHoursScreen extends StatelessWidget {
  const WorkingHoursScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleWorkerScreen(
        title: 'Working Hours',
        body: 'Choose available days, time slots, and emergency availability.',
        label: 'Open Dashboard',
        route: '/dashboard',
      );
}

class WorkerDashboardScreen extends StatelessWidget {
  const WorkerDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Worker Dashboard',
        children: [
          SwitchListTile(
              value: true,
              onChanged: (_) => context.go('/availability'),
              title: const Text('Available')),
          _InfoCard(
              title: 'Today',
              body: '3 nearby requests. Wallet INR 2450. Rating 4.8.'),
          ActionButton(
              label: 'Nearby Requests',
              onPressed: () => context.go('/requests')),
          OutlinedButton(
              onPressed: () => context.go('/wallet'),
              child: const Text('Earnings and Wallet')),
          OutlinedButton(
              onPressed: () => context.go('/profile'),
              child: const Text('Profile')),
        ],
      );
}

class NearbyRequestsScreen extends StatelessWidget {
  const NearbyRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Nearby Requests',
        children: [
          _RequestCard(
              title: 'Pipe leakage', body: 'Plumbing. 2.1 km. High urgency.'),
          _RequestCard(
              title: 'Fan not working',
              body: 'Electrical. 4.2 km. Medium urgency.'),
        ],
      );
}

class RequestDetailScreen extends StatelessWidget {
  const RequestDetailScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Request Detail',
        children: [
          const _InfoCard(
            title: 'Issue Summary',
            body:
                'Issue image, category, distance, suggested price, and user location.',
          ),
          const LocationMapPreview(
            title: 'Customer location',
            latitude: 12.9804,
            longitude: 77.6046,
          ),
          ActionButton(
              label: 'Send Quote', onPressed: () => context.go('/quote')),
        ],
      );
}

class QuoteSubmissionScreen extends StatelessWidget {
  const QuoteSubmissionScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Quote',
        children: [
          const TextField(
              decoration: InputDecoration(labelText: 'Price'),
              keyboardType: TextInputType.number),
          const TextField(
              decoration: InputDecoration(labelText: 'Arrival time in minutes'),
              keyboardType: TextInputType.number),
          const TextField(
              decoration: InputDecoration(labelText: 'Message'), maxLines: 3),
          ActionButton(
              label: 'Send Quote', onPressed: () => context.go('/navigation')),
        ],
      );
}

class NavigationScreen extends StatelessWidget {
  const NavigationScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Navigation',
        children: [
          const _InfoCard(
              title: 'Route',
              body: 'Route to customer with ETA and call shortcut.'),
          const LocationMapPreview(
            title: 'Turn-by-turn map',
            latitude: 12.9756,
            longitude: 77.6112,
          ),
          ActionButton(
              label: 'Start Booking',
              onPressed: () => context.go('/active-booking')),
        ],
      );
}

class ActiveBookingScreen extends StatelessWidget {
  const ActiveBookingScreen({super.key});

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: 'Active Booking',
        children: [
          _InfoCard(
              title: 'Status',
              body: 'Accepted, on the way, arrived, work started, completed.'),
          ActionButton(
              label: 'Mark Completed',
              onPressed: () => context.go('/wallet'),
              color: AppColors.successGreen),
        ],
      );
}

class EarningsWalletScreen extends StatelessWidget {
  const EarningsWalletScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleWorkerScreen(
      title: 'Earnings',
      body: 'Wallet balance INR 2450. Payouts and booking earnings.');
}

class ReviewsScreen extends StatelessWidget {
  const ReviewsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleWorkerScreen(
      title: 'Reviews', body: 'Average rating 4.8. Trust score 92.');
}

class AvailabilityToggleScreen extends StatelessWidget {
  const AvailabilityToggleScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleWorkerScreen(
      title: 'Availability',
      body: 'Switch availability on or off and set next available time.');
}

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleWorkerScreen(
      title: 'Worker Profile',
      body: 'Identity, badges, skills, service area, documents, and support.');
}

class _SimpleWorkerScreen extends StatelessWidget {
  const _SimpleWorkerScreen(
      {required this.title, required this.body, this.label, this.route});

  final String title;
  final String body;
  final String? label;
  final String? route;

  @override
  Widget build(BuildContext context) => WorkerScaffold(
        title: title,
        children: [
          _InfoCard(title: title, body: body),
          if (label != null && route != null)
            ActionButton(label: label!, onPressed: () => context.go(route!)),
        ],
      );
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

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
            ],
          ),
        ),
      );
}

class _RequestCard extends StatelessWidget {
  const _RequestCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
        child: ListTile(
          title: Text(title),
          subtitle: Text(body),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.go('/request-detail'),
        ),
      );
}
