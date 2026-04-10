import 'package:go_router/go_router.dart';

import '../screens/user_screens.dart';

final userRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, _) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, _) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (_, _) => const OtpVerificationScreen()),
    GoRoute(path: '/face', builder: (_, _) => const FaceVerificationScreen()),
    GoRoute(path: '/home', builder: (_, _) => const HomeDashboardScreen()),
    GoRoute(path: '/upload', builder: (_, _) => const UploadIssueScreen()),
    GoRoute(path: '/ai-result', builder: (_, _) => const AiDetectionResultScreen()),
    GoRoute(path: '/workers', builder: (_, _) => const WorkerComparisonScreen()),
    GoRoute(path: '/worker-detail', builder: (_, _) => const WorkerDetailScreen()),
    GoRoute(path: '/booking-confirmation', builder: (_, _) => const BookingConfirmationScreen()),
    GoRoute(path: '/tracking', builder: (_, _) => const LiveTrackingScreen()),
    GoRoute(path: '/chat', builder: (_, _) => const ChatScreen()),
    GoRoute(path: '/voice-call', builder: (_, _) => const VoiceCallScreen()),
    GoRoute(path: '/payment', builder: (_, _) => const PaymentScreen()),
    GoRoute(path: '/review', builder: (_, _) => const ReviewRatingScreen()),
    GoRoute(path: '/history', builder: (_, _) => const BookingHistoryScreen()),
    GoRoute(path: '/invoice', builder: (_, _) => const InvoiceScreen()),
    GoRoute(path: '/notifications', builder: (_, _) => const NotificationCenterScreen()),
    GoRoute(path: '/profile', builder: (_, _) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/emergency', builder: (_, _) => const EmergencyRequestScreen()),
  ],
);

