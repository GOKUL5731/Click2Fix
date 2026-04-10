import 'package:go_router/go_router.dart';

import '../screens/worker_screens.dart';

final workerRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(path: '/login', builder: (_, _) => const WorkerLoginScreen()),
    GoRoute(path: '/registration', builder: (_, _) => const WorkerRegistrationScreen()),
    GoRoute(path: '/aadhaar', builder: (_, _) => const AadhaarUploadScreen()),
    GoRoute(path: '/face', builder: (_, _) => const FaceVerificationScreen()),
    GoRoute(path: '/skills', builder: (_, _) => const SkillSelectionScreen()),
    GoRoute(path: '/area', builder: (_, _) => const WorkingAreaSetupScreen()),
    GoRoute(path: '/hours', builder: (_, _) => const WorkingHoursScreen()),
    GoRoute(path: '/dashboard', builder: (_, _) => const WorkerDashboardScreen()),
    GoRoute(path: '/requests', builder: (_, _) => const NearbyRequestsScreen()),
    GoRoute(path: '/request-detail', builder: (_, _) => const RequestDetailScreen()),
    GoRoute(path: '/quote', builder: (_, _) => const QuoteSubmissionScreen()),
    GoRoute(path: '/navigation', builder: (_, _) => const NavigationScreen()),
    GoRoute(path: '/active-booking', builder: (_, _) => const ActiveBookingScreen()),
    GoRoute(path: '/wallet', builder: (_, _) => const EarningsWalletScreen()),
    GoRoute(path: '/reviews', builder: (_, _) => const ReviewsScreen()),
    GoRoute(path: '/availability', builder: (_, _) => const AvailabilityToggleScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const WorkerProfileScreen()),
  ],
);

