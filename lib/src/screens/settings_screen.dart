import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../widgets/page_header.dart';
import '../widgets/responsive_content.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PageHeader(
            title: 'Settings',
            subtitle:
                'Manage device voices, reminders, and future synchronization.',
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.translate),
              title: const Text('Bible versions'),
              subtitle: const Text(
                'View truthful offline, online, download, and provider-setup states in Word.',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () {
                controller.selectDestination(1);
                controller.selectWordDestination(4);
              },
            ),
          ),
          const SizedBox(height: 16),
          const _SettingTile(
            icon: Icons.record_voice_over,
            title: 'Voice and playback',
            subtitle:
                'The reader lists voices installed by Android or Windows. Voice packs are managed in device settings, separately from Bible versions.',
          ),
          const SizedBox(height: 12),
          const _SettingTile(
            icon: Icons.notifications_outlined,
            title: 'Reminders',
            subtitle:
                'Each plan stores a reminder time. Native scheduled notifications remain a later milestone.',
          ),
          const SizedBox(height: 12),
          const _SettingTile(
            icon: Icons.sync,
            title: 'Cross-device sync',
            subtitle:
                'The MVP is local-first. Optional Supabase account sync will be added after the core planner is stable.',
          ),
        ],
      ),
    );
  }
}

class _SettingTile extends StatelessWidget {
  const _SettingTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle),
      ),
    );
  }
}
