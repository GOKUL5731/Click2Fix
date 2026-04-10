import 'package:flutter/material.dart';

class C2fScaffold extends StatelessWidget {
  const C2fScaffold({
    required this.title,
    required this.children,
    this.actions,
    super.key,
  });

  final String title;
  final List<Widget> children;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), actions: actions),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: children,
        ),
      ),
    );
  }
}

