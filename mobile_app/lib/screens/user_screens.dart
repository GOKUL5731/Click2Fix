import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../widgets/c2f_scaffold.dart';
import '../widgets/location_map_preview.dart';
import '../widgets/primary_action_button.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                AppConfig.appName,
                style: Theme.of(
                  context,
                ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              const Text(AppConfig.tagline, textAlign: TextAlign.center),
              const SizedBox(height: 32),
              PrimaryActionButton(
                label: 'Get Started',
                onPressed: () => context.go('/onboarding'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Welcome',
      children: [
        _InfoCard(title: 'Click', body: 'Capture the household problem.'),
        _InfoCard(
          title: 'Compare',
          body:
              'Choose by price, rating, distance, arrival time, and trust score.',
        ),
        _InfoCard(title: 'Fix', body: 'Track, chat, pay, and review.'),
        PrimaryActionButton(
          label: 'Continue',
          onPressed: () => context.go('/login'),
        ),
      ],
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Login',
      children: [
        const TextField(
          decoration: InputDecoration(
            labelText: 'Mobile number',
            prefixText: '+91 ',
          ),
          keyboardType: TextInputType.phone,
        ),
        const SizedBox(height: 16),
        PrimaryActionButton(
          label: 'Send OTP',
          onPressed: () => context.go('/otp'),
        ),
        TextButton(onPressed: () {}, child: const Text('Use email instead')),
      ],
    );
  }
}

class OtpVerificationScreen extends StatelessWidget {
  const OtpVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Verify OTP',
      children: [
        const TextField(
          decoration: InputDecoration(labelText: '6 digit OTP'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 16),
        PrimaryActionButton(
          label: 'Verify and Continue',
          onPressed: () => context.go('/face'),
        ),
        TextButton(onPressed: () {}, child: const Text('Resend OTP')),
      ],
    );
  }
}

class FaceVerificationScreen extends StatelessWidget {
  const FaceVerificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Face Verification',
      children: [
        const _CameraPlaceholder(label: 'Face capture'),
        PrimaryActionButton(
          label: 'Capture Face',
          onPressed: () => context.go('/home'),
        ),
        TextButton(
          onPressed: () => context.go('/home'),
          child: const Text('Skip for Now'),
        ),
      ],
    );
  }
}

class HomeDashboardScreen extends StatelessWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Click2Fix',
      actions: [
        IconButton(
          onPressed: () => context.go('/notifications'),
          icon: const Icon(Icons.notifications_outlined),
        ),
      ],
      children: [
        const Text('Good day'),
        LocationMapPreview(
          title: 'Current location',
          note: AppConfig.googleMapsApiKey.isEmpty
              ? 'Tip: pass --dart-define=GOOGLE_MAPS_API_KEY=your_key when running web builds.'
              : null,
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 140,
          child: FilledButton.icon(
            onPressed: () => context.go('/upload'),
            icon: const Icon(Icons.photo_camera, size: 42),
            label: const Text('Take Photo'),
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            OutlinedButton(
              onPressed: () => context.go('/upload'),
              child: const Text('Gallery'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/upload'),
              child: const Text('Video'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/upload'),
              child: const Text('Type Issue'),
            ),
            OutlinedButton(
              onPressed: () => context.go('/upload'),
              child: const Text('Voice'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        PrimaryActionButton(
          label: 'Emergency Fix',
          backgroundColor: AppColors.emergencyRed,
          onPressed: () => context.go('/emergency'),
        ),
        const SizedBox(height: 20),
        _InfoCard(title: 'Active Booking', body: 'No active booking'),
      ],
    );
  }
}

class UploadIssueScreen extends StatelessWidget {
  const UploadIssueScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Upload Issue',
      children: [
        const _CameraPlaceholder(label: 'Issue media'),
        const TextField(
          decoration: InputDecoration(labelText: 'Kitchen pipe leaking'),
          maxLines: 3,
        ),
        const TextField(
          decoration: InputDecoration(labelText: 'Location'),
          keyboardType: TextInputType.streetAddress,
        ),
        PrimaryActionButton(
          label: 'Detect Problem',
          onPressed: () => context.go('/ai-result'),
        ),
      ],
    );
  }
}

class AiDetectionResultScreen extends StatelessWidget {
  const AiDetectionResultScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'AI Result',
      children: [
        _InfoCard(
          title: 'Plumbing',
          body:
              'Confidence 95 percent. Urgency high. Estimated price INR 300 to INR 600.',
        ),
        PrimaryActionButton(
          label: 'Find Nearby Workers',
          onPressed: () => context.go('/workers'),
        ),
      ],
    );
  }
}

class WorkerComparisonScreen extends StatelessWidget {
  const WorkerComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Compare Workers',
      children: [
        const Wrap(
          spacing: 8,
          children: [
            Chip(label: Text('Lowest Price')),
            Chip(label: Text('Best Rating')),
            Chip(label: Text('Nearest')),
            Chip(label: Text('Fastest')),
          ],
        ),
        _WorkerCard(name: 'Ravi Kumar', price: 'INR 450', eta: '18 min'),
        _WorkerCard(name: 'Anil Raj', price: 'INR 520', eta: '12 min'),
      ],
    );
  }
}

class WorkerDetailScreen extends StatelessWidget {
  const WorkerDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Worker Detail',
      children: [
        _InfoCard(
          title: 'Ravi Kumar',
          body: '4.8 rating. Trust score 92. Verified plumbing worker.',
        ),
        _InfoCard(title: 'Arrival', body: '18 min away. 2.4 km distance.'),
        PrimaryActionButton(
          label: 'Book Worker',
          onPressed: () => context.go('/booking-confirmation'),
        ),
      ],
    );
  }
}

class BookingConfirmationScreen extends StatelessWidget {
  const BookingConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Confirm Booking',
      children: [
        _InfoCard(
          title: 'Kitchen pipe leak',
          body: 'Ravi Kumar. INR 450. Arrival 18 min.',
        ),
        PrimaryActionButton(
          label: 'Confirm Booking',
          onPressed: () => context.go('/tracking'),
        ),
      ],
    );
  }
}

class LiveTrackingScreen extends StatelessWidget {
  const LiveTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) => C2fScaffold(
    title: 'Live Tracking',
    children: [
      const _InfoCard(
        title: 'Status',
        body: 'Worker is on the way. ETA 18 min.',
      ),
      LocationMapPreview(
        title: 'Worker route',
        latitude: 12.9732,
        longitude: 77.6022,
        note: 'Live polyline and turn-by-turn can be added over this map.',
      ),
      PrimaryActionButton(
        label: 'Open Chat',
        onPressed: () => context.go('/chat'),
      ),
    ],
  );
}

class ChatScreen extends StatelessWidget {
  const ChatScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleScreen(
    title: 'Chat',
    body: 'Share photos, notes, and location updates with the worker.',
    primaryLabel: 'Voice Call',
    route: '/voice-call',
  );
}

class VoiceCallScreen extends StatelessWidget {
  const VoiceCallScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleScreen(
    title: 'Voice Call',
    body: 'Connected with worker.',
    primaryLabel: 'Go to Payment',
    route: '/payment',
  );
}

class PaymentScreen extends StatelessWidget {
  const PaymentScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleScreen(
    title: 'Payment',
    body: 'Amount due INR 450.',
    primaryLabel: 'Pay Now',
    route: '/review',
  );
}

class ReviewRatingScreen extends StatelessWidget {
  const ReviewRatingScreen({super.key});

  @override
  Widget build(BuildContext context) => _SimpleScreen(
    title: 'Review',
    body: 'Rate the completed work.',
    primaryLabel: 'Submit Review',
    route: '/invoice',
  );
}

class BookingHistoryScreen extends StatelessWidget {
  const BookingHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleScreen(
    title: 'Booking History',
    body: 'Completed and active bookings.',
  );
}

class InvoiceScreen extends StatelessWidget {
  const InvoiceScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleScreen(
    title: 'Invoice',
    body: 'Invoice C2F-0001. Total INR 450.',
  );
}

class NotificationCenterScreen extends StatelessWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleScreen(
    title: 'Notifications',
    body: 'Quotes, booking updates, and payment alerts.',
  );
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleScreen(
    title: 'Profile',
    body: 'Profile, addresses, payment methods, and support.',
  );
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const _SimpleScreen(
    title: 'Settings',
    body: 'Theme, language, notifications, devices, and logout.',
  );
}

class EmergencyRequestScreen extends StatelessWidget {
  const EmergencyRequestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: 'Emergency',
      children: [
        _InfoCard(
          title: 'Critical Help',
          body: 'Gas leak, electrical short circuit, or major water leakage.',
        ),
        PrimaryActionButton(
          label: 'Start Emergency Booking',
          backgroundColor: AppColors.emergencyRed,
          onPressed: () => context.go('/tracking'),
        ),
      ],
    );
  }
}

class _SimpleScreen extends StatelessWidget {
  const _SimpleScreen({
    required this.title,
    required this.body,
    this.primaryLabel,
    this.route,
  });

  final String title;
  final String body;
  final String? primaryLabel;
  final String? route;

  @override
  Widget build(BuildContext context) {
    return C2fScaffold(
      title: title,
      children: [
        _InfoCard(title: title, body: body),
        if (primaryLabel != null && route != null)
          PrimaryActionButton(
            label: primaryLabel!,
            onPressed: () => context.go(route!),
          ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Card(
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
}

class _CameraPlaceholder extends StatelessWidget {
  const _CameraPlaceholder({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.camera_alt_outlined, size: 48),
            const SizedBox(height: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}

class _WorkerCard extends StatelessWidget {
  const _WorkerCard({
    required this.name,
    required this.price,
    required this.eta,
  });

  final String name;
  final String price;
  final String eta;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.trustGold,
          child: Text(name.isEmpty ? '?' : name[0]),
        ),
        title: Text(name),
        subtitle: Text('4.8 rating. 2.4 km. $eta. Trust score 92.'),
        trailing: Text(price),
        onTap: () => context.go('/worker-detail'),
      ),
    );
  }
}
