import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../config/app_theme.dart';
import '../providers/session_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsState();
}

class _SettingsState extends ConsumerState<SettingsScreen> {
  bool _darkMode = false;
  bool _notifications = true;
  bool _locationSharing = true;
  String _language = 'English';
  String _appVersionLabel = '…';

  @override
  void initState() {
    super.initState();
    PackageInfo.fromPlatform().then((info) {
      if (mounted) {
        setState(() => _appVersionLabel = 'v${info.version} (+${info.buildNumber})');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, size: 20), onPressed: () => context.go('/profile')),
        title: const Text('Settings'),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _Section(title: 'Appearance'),
        _ToggleTile(icon: Icons.dark_mode, label: 'Dark Mode', value: _darkMode, onChanged: (v) => setState(() => _darkMode = v)),
        _DropdownTile(icon: Icons.language, label: 'Language', value: _language,
          options: const ['English', 'Tamil', 'Hindi', 'Telugu'],
          onChanged: (v) => setState(() => _language = v)),
        const SizedBox(height: 16),
        _Section(title: 'Privacy'),
        _ToggleTile(icon: Icons.notifications, label: 'Push Notifications', value: _notifications, onChanged: (v) => setState(() => _notifications = v)),
        _ToggleTile(icon: Icons.location_on, label: 'Location Sharing', value: _locationSharing, onChanged: (v) => setState(() => _locationSharing = v)),
        const SizedBox(height: 16),
        _Section(title: 'Account'),
        _ActionTile(icon: Icons.lock, label: 'Change Phone Number', onTap: () {}),
        _ActionTile(icon: Icons.delete_outline, label: 'Delete Account', color: AppColors.emergencyRed, onTap: () {}),
        const SizedBox(height: 16),
        _Section(title: 'About'),
        _ActionTile(icon: Icons.description, label: 'Terms of Service', onTap: () {}),
        _ActionTile(icon: Icons.privacy_tip, label: 'Privacy Policy', onTap: () {}),
        _ActionTile(icon: Icons.info, label: 'App Version', trailing: _appVersionLabel, onTap: () {}),
        const SizedBox(height: 24),
        SizedBox(width: double.infinity, child: OutlinedButton.icon(
          onPressed: () { ref.read(sessionProvider.notifier).logout(); context.go('/login'); },
          icon: const Icon(Icons.logout, color: AppColors.emergencyRed),
          label: const Text('Logout', style: TextStyle(color: AppColors.emergencyRed)),
          style: OutlinedButton.styleFrom(side: const BorderSide(color: AppColors.emergencyRed), padding: const EdgeInsets.all(14)),
        )),
      ]),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(title, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: AppColors.textSecondary)),
  );
}

class _ToggleTile extends StatelessWidget {
  const _ToggleTile({required this.icon, required this.label, required this.value, required this.onChanged});
  final IconData icon; final String label; final bool value; final ValueChanged<bool> onChanged;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue), const SizedBox(width: 14),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        Switch(value: value, onChanged: onChanged, activeThumbColor: AppColors.primaryBlue),
      ]),
    );
  }
}

class _DropdownTile extends StatelessWidget {
  const _DropdownTile({required this.icon, required this.label, required this.value, required this.options, required this.onChanged});
  final IconData icon; final String label; final String value; final List<String> options; final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
      child: Row(children: [
        Icon(icon, size: 20, color: AppColors.primaryBlue), const SizedBox(width: 14),
        Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall)),
        DropdownButton<String>(
          value: value, underline: const SizedBox(),
          items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) { if (v != null) onChanged(v); },
        ),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.label, required this.onTap, this.color, this.trailing});
  final IconData icon; final String label; final VoidCallback onTap; final Color? color; final String? trailing;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(color: isDark ? AppColors.cardDark : Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: isDark ? Colors.white10 : AppColors.divider)),
        child: Row(children: [
          Icon(icon, size: 20, color: color ?? AppColors.textSecondary), const SizedBox(width: 14),
          Expanded(child: Text(label, style: Theme.of(context).textTheme.titleSmall?.copyWith(color: color))),
          if (trailing != null)
            Text(trailing!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textHint))
          else
            Icon(Icons.chevron_right, size: 20, color: AppColors.textHint),
        ]),
      ),
    );
  }
}
