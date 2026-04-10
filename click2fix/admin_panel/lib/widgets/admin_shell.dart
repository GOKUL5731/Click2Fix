import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AdminShell extends StatelessWidget {
  const AdminShell({required this.title, required this.children, super.key});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final destinations = <({String label, String route})>[
      (label: 'Dashboard', route: '/dashboard'),
      (label: 'Users', route: '/users'),
      (label: 'Workers', route: '/workers'),
      (label: 'Emergencies', route: '/emergency'),
      (label: 'Revenue', route: '/revenue'),
      (label: 'Fraud', route: '/fraud'),
    ];
    final selectedIndex = destinations
        .indexWhere((item) => item.route == GoRouterState.of(context).uri.path)
        .clamp(0, destinations.length - 1)
        .toInt();

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Row(
        children: [
          if (MediaQuery.sizeOf(context).width >= 900)
            NavigationRail(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) => context.go(destinations[index].route),
              labelType: NavigationRailLabelType.all,
              destinations: destinations
                  .map((item) => NavigationRailDestination(icon: const Icon(Icons.circle_outlined), label: Text(item.label)))
                  .toList(),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}
