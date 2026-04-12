import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (required for FCM and other Firebase services)
  await Firebase.initializeApp();

  // Initialize push notifications
  await PushNotificationService().initialize();

  runApp(const ProviderScope(child: Click2FixApp()));
}

class Click2FixApp extends StatelessWidget {
  const Click2FixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Click2Fix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      routerConfig: appRouter,
    );
  }
}
