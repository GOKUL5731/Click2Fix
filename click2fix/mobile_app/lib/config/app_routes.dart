import 'package:go_router/go_router.dart';

import '../screens/user_screens.dart';

final userRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/otp', builder: (_, __) => const OtpVerificationScreen()),
    GoRoute(path: '/face', builder: (_, __) => const FaceVerificationScreen()),
    GoRoute(path: '/home', builder: (_, __) => const HomeDashboardScreen()),
    GoRoute(path: '/upload', builder: (_, __) => const UploadIssueScreen()),
    GoRoute(
        path: '/ai-result',
        builder: (_, __) => const AiDetectionResultScreen()),
    GoRoute(
        path: '/workers', builder: (_, __) => const WorkerComparisonScreen()),
    GoRoute(
        path: '/worker-detail', builder: (_, __) => const WorkerDetailScreen()),
    GoRoute(
        path: '/booking-confirmation',
        builder: (_, __) => const BookingConfirmationScreen()),
    GoRoute(path: '/tracking', builder: (_, __) => const LiveTrackingScreen()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/voice-call', builder: (_, __) => const VoiceCallScreen()),
    GoRoute(path: '/payment', builder: (_, __) => const PaymentScreen()),
    GoRoute(path: '/review', builder: (_, __) => const ReviewRatingScreen()),
    GoRoute(path: '/history', builder: (_, __) => const BookingHistoryScreen()),
    GoRoute(path: '/invoice', builder: (_, __) => const InvoiceScreen()),
    GoRoute(
        path: '/notifications',
        builder: (_, __) => const NotificationCenterScreen()),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const SettingsScreen()),
    GoRoute(
        path: '/emergency', builder: (_, __) => const EmergencyRequestScreen()),
  ],
);
