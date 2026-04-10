import 'package:go_router/go_router.dart';

import '../screens/admin_screens.dart';

final adminRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, __) => const AccessPortalScreen()),
    GoRoute(path: '/login', builder: (_, __) => const AdminLoginScreen()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/user-home', builder: (_, __) => const UserHomeScreen()),
    GoRoute(
        path: '/user-bookings', builder: (_, __) => const UserBookingsScreen()),
    GoRoute(path: '/user-wallet', builder: (_, __) => const UserWalletScreen()),
    GoRoute(path: '/worker-home', builder: (_, __) => const WorkerHomeScreen()),
    GoRoute(path: '/worker-jobs', builder: (_, __) => const WorkerJobsScreen()),
    GoRoute(
        path: '/worker-wallet', builder: (_, __) => const WorkerWalletScreen()),
    GoRoute(path: '/users', builder: (_, __) => const UserManagementScreen()),
    GoRoute(
        path: '/workers', builder: (_, __) => const WorkerManagementScreen()),
    GoRoute(
        path: '/worker-verification',
        builder: (_, __) => const WorkerVerificationScreen()),
    GoRoute(
        path: '/documents', builder: (_, __) => const DocumentReviewScreen()),
    GoRoute(
        path: '/fraud',
        builder: (_, __) => const FraudDetectionDashboardScreen()),
    GoRoute(
        path: '/bookings', builder: (_, __) => const BookingManagementScreen()),
    GoRoute(
        path: '/complaints',
        builder: (_, __) => const ComplaintManagementScreen()),
    GoRoute(
        path: '/emergency',
        builder: (_, __) => const EmergencyMonitoringScreen()),
    GoRoute(
        path: '/revenue', builder: (_, __) => const RevenueDashboardScreen()),
    GoRoute(
        path: '/analytics',
        builder: (_, __) => const AnalyticsDashboardScreen()),
    GoRoute(path: '/pricing', builder: (_, __) => const PricingControlScreen()),
    GoRoute(
        path: '/categories',
        builder: (_, __) => const CategoryManagementScreen()),
    GoRoute(
        path: '/broadcasts',
        builder: (_, __) => const NotificationBroadcastingScreen()),
  ],
);
