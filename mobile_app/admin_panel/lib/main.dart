import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/admin_routes.dart';
import 'config/admin_theme.dart';

void main() {
  runApp(const ProviderScope(child: Click2FixAdminPanel()));
}

class Click2FixAdminPanel extends ConsumerWidget {
  const Click2FixAdminPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'Click2Fix Admin',
      debugShowCheckedModeBanner: false,
      theme: AdminTheme.light,
      darkTheme: AdminTheme.dark,
      routerConfig: adminRouter,
    );
  }
}

