import 'package:go_router/go_router.dart';

import '../screens/worker_screens.dart';

final workerRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, __) => const WorkerLoginScreen()),
    GoRoute(
        path: '/registration',
        builder: (_, __) => const WorkerRegistrationScreen()),
    GoRoute(path: '/aadhaar', builder: (_, __) => const AadhaarUploadScreen()),
    GoRoute(path: '/face', builder: (_, __) => const FaceVerificationScreen()),
    GoRoute(path: '/skills', builder: (_, __) => const SkillSelectionScreen()),
    GoRoute(path: '/area', builder: (_, __) => const WorkingAreaSetupScreen()),
    GoRoute(path: '/hours', builder: (_, __) => const WorkingHoursScreen()),
    GoRoute(
        path: '/dashboard', builder: (_, __) => const WorkerDashboardScreen()),
    GoRoute(
        path: '/requests', builder: (_, __) => const NearbyRequestsScreen()),
    GoRoute(
        path: '/request-detail',
        builder: (_, __) => const RequestDetailScreen()),
    GoRoute(path: '/quote', builder: (_, __) => const QuoteSubmissionScreen()),
    GoRoute(path: '/navigation', builder: (_, __) => const NavigationScreen()),
    GoRoute(
        path: '/active-booking',
        builder: (_, __) => const ActiveBookingScreen()),
    GoRoute(path: '/wallet', builder: (_, __) => const EarningsWalletScreen()),
    GoRoute(path: '/reviews', builder: (_, __) => const ReviewsScreen()),
    GoRoute(
        path: '/availability',
        builder: (_, __) => const AvailabilityToggleScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const WorkerProfileScreen()),
  ],
);
