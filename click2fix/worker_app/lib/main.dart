import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';

void main() {
  runApp(const ProviderScope(child: Click2FixWorkerApp()));
}

class Click2FixWorkerApp extends ConsumerWidget {
  const Click2FixWorkerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Click2Fix Worker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      routerConfig: workerRouter,
    );
  }
}

