import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';
import 'services/push_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PushNotificationService().initialize();
  runApp(const ProviderScope(child: Click2FixUserApp()));
}

class Click2FixUserApp extends ConsumerWidget {
  const Click2FixUserApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Click2Fix',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: userRouter,
    );
  }
}
