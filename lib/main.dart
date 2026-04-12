import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_routes.dart';
import 'config/app_theme.dart';

Future<void> _initFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (e, st) {
    debugPrint('Firebase.initializeApp skipped: $e\n$st');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initFirebase();
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
      builder: (context, child) {
        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) {
            if (didPop) return;
            if (appRouter.canPop()) {
              appRouter.pop();
            }
          },
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
