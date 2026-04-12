import 'package:go_router/go_router.dart';

import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/login_screen.dart';
import '../screens/email_login_screen.dart';
import '../screens/register_profile_screen.dart';
import '../screens/otp_screen.dart';
import '../screens/home_dashboard_screen.dart';
import '../screens/upload_issue_screen.dart';
import '../screens/ai_result_screen.dart';
import '../screens/worker_comparison_screen.dart';
import '../screens/worker_detail_screen.dart';
import '../screens/booking_confirmation_screen.dart';
import '../screens/live_tracking_screen.dart';
import '../screens/chat_screen.dart';
import '../screens/payment_screen.dart';
import '../screens/review_screen.dart';
import '../screens/booking_history_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/emergency_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/worker/worker_dashboard_screen.dart';
import '../screens/worker/quote_submission_screen.dart';
import '../screens/worker/earnings_screen.dart';
import '../screens/worker/worker_profile_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // ─── Auth Flow ───────────────────────────────
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/onboarding', builder: (context, state) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    GoRoute(path: '/email-login', builder: (context, state) => const EmailLoginScreen()),
    GoRoute(
      path: '/register-profile',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return RegisterProfileScreen(
          phone: extra?['phone'] as String? ?? '',
          isWorker: extra?['isWorker'] as bool? ?? false,
          firebaseToken: extra?['firebaseToken'] as String? ?? '',
        );
      },
    ),
    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        return OtpScreen(
          phone: extra?['phone'] as String?,
          isWorker: extra?['isWorker'] as bool? ?? false,
          isLoginMode: extra?['isLoginMode'] as bool? ?? true,
        );
      },
    ),

    // ─── User Flow ───────────────────────────────
    GoRoute(path: '/home', builder: (context, state) => const HomeDashboardScreen()),
    GoRoute(path: '/upload', builder: (context, state) => const UploadIssueScreen()),
    GoRoute(path: '/ai-result', builder: (context, state) => const AiResultScreen()),
    GoRoute(path: '/workers', builder: (context, state) => const WorkerComparisonScreen()),
    GoRoute(path: '/worker-detail', builder: (context, state) => const WorkerDetailScreen()),
    GoRoute(path: '/booking-confirmation', builder: (context, state) => const BookingConfirmationScreen()),
    GoRoute(path: '/tracking', builder: (context, state) => const LiveTrackingScreen()),
    GoRoute(path: '/chat', builder: (context, state) => const ChatScreen()),
    GoRoute(path: '/payment', builder: (context, state) => const PaymentScreen()),
    GoRoute(path: '/review', builder: (context, state) => const ReviewScreen()),
    GoRoute(path: '/history', builder: (context, state) => const BookingHistoryScreen()),
    GoRoute(path: '/profile', builder: (context, state) => const ProfileScreen()),
    GoRoute(path: '/settings', builder: (context, state) => const SettingsScreen()),
    GoRoute(path: '/emergency', builder: (context, state) => const EmergencyScreen()),
    GoRoute(path: '/notifications', builder: (context, state) => const NotificationsScreen()),
    GoRoute(path: '/issues', builder: (context, state) => const BookingHistoryScreen()), // Issues list

    // ─── Worker Flow ─────────────────────────────
    GoRoute(path: '/worker/dashboard', builder: (context, state) => const WorkerDashboardScreen()),
    GoRoute(path: '/worker/requests', builder: (context, state) => const WorkerDashboardScreen()),
    GoRoute(path: '/worker/quote', builder: (context, state) => const QuoteSubmissionScreen()),
    GoRoute(path: '/worker/earnings', builder: (context, state) => const EarningsScreen()),
    GoRoute(path: '/worker/profile', builder: (context, state) => const WorkerProfileScreen()),
  ],
);
