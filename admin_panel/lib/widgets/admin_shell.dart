import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/admin_theme.dart';

class _NavItem {
  const _NavItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

class AdminShell extends StatelessWidget {
  const AdminShell({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  List<_NavItem> _destinationsForPath(String path) {
    if (path.startsWith('/worker')) {
      return const [
        _NavItem(
            label: 'Worker Home',
            route: '/worker-home',
            icon: Icons.engineering_outlined),
        _NavItem(
            label: 'Jobs',
            route: '/worker-jobs',
            icon: Icons.handyman_outlined),
        _NavItem(
            label: 'Wallet',
            route: '/worker-wallet',
            icon: Icons.account_balance_wallet_outlined),
        _NavItem(label: 'Switch Role', route: '/', icon: Icons.swap_horiz),
      ];
    }

    if (path.startsWith('/user')) {
      return const [
        _NavItem(
            label: 'User Home', route: '/user-home', icon: Icons.home_outlined),
        _NavItem(
            label: 'Bookings',
            route: '/user-bookings',
            icon: Icons.calendar_month_outlined),
        _NavItem(
            label: 'Payments',
            route: '/user-wallet',
            icon: Icons.payments_outlined),
        _NavItem(label: 'Switch Role', route: '/', icon: Icons.swap_horiz),
      ];
    }

    return const [
      _NavItem(
          label: 'Dashboard',
          route: '/dashboard',
          icon: Icons.dashboard_outlined),
      _NavItem(label: 'Workers', route: '/workers', icon: Icons.badge_outlined),
      _NavItem(
          label: 'Bookings',
          route: '/bookings',
          icon: Icons.event_note_outlined),
      _NavItem(label: 'Fraud', route: '/fraud', icon: Icons.shield_outlined),
      _NavItem(
          label: 'Revenue', route: '/revenue', icon: Icons.insights_outlined),
      _NavItem(label: 'Switch Role', route: '/', icon: Icons.swap_horiz),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final path = GoRouterState.of(context).uri.path;
    final destinations = _destinationsForPath(path);
    final selectedIndex = destinations
        .indexWhere((item) => item.route == path)
        .clamp(0, destinations.length - 1)
        .toInt();
    final isDesktop = MediaQuery.sizeOf(context).width >= 980;
    final mobileDestinations = destinations.take(4).toList();
    final mobileSelectedIndex = mobileDestinations
        .indexWhere((item) => item.route == path)
        .clamp(0, mobileDestinations.length - 1)
        .toInt();

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: OutlinedButton.icon(
              onPressed: () => context.go('/'),
              icon: const Icon(Icons.login_outlined, size: 18),
              label: const Text('Role Portal'),
            ),
          ),
        ],
      ),
      body: Row(
        children: [
          if (isDesktop)
            NavigationRail(
              elevation: 0,
              indicatorColor: AdminColors.primaryBlue.withValues(alpha: 0.12),
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) =>
                  context.go(destinations[index].route),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((item) => NavigationRailDestination(
                        icon: Icon(item.icon),
                        selectedIcon:
                            Icon(item.icon, color: AdminColors.primaryBlue),
                        label: Text(item.label),
                      ))
                  .toList(),
            ),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Theme.of(context).colorScheme.surface,
                    Theme.of(context).colorScheme.surface.withValues(alpha: 0.8),
                  ],
                ),
              ),
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: children,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: isDesktop
          ? null
          : NavigationBar(
              selectedIndex: mobileSelectedIndex,
              onDestinationSelected: (index) =>
                  context.go(mobileDestinations[index].route),
              destinations: mobileDestinations
                  .map(
                    (item) => NavigationDestination(
                      icon: Icon(item.icon),
                      label: item.label,
                    ),
                  )
                  .toList(),
            ),
    );
  }
}
