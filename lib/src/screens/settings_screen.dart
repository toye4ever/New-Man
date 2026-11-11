import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../app/theme/new_man_theme.dart';
import '../features/settings/domain/appearance_preferences.dart';
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
            subtitle: 'Choose your appearance and manage device preferences.',
          ),
          const SizedBox(height: 24),
          _AppearanceSettings(controller: controller),
          const SizedBox(height: 16),
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
                controller.selectWordDestination(3);
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
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.article_outlined),
              title: const Text('Open-source licenses'),
              subtitle: const Text(
                'View licenses for software used by New Man.',
              ),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () =>
                  showLicensePage(context: context, applicationName: 'New Man'),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppearanceSettings extends StatelessWidget {
  const _AppearanceSettings({required this.controller});
  final AppController controller;

  Future<void> _save(
    BuildContext context, {
    AppearanceMode? mode,
    AccentColor? accent,
  }) async {
    try {
      await controller.setAppearance(mode: mode, accent: accent);
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not save appearance. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: controller,
    builder: (context, _) => Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Appearance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            const Text('Display mode'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final mode in AppearanceMode.values)
                  ChoiceChip(
                    label: Text(switch (mode) {
                      AppearanceMode.system => 'System',
                      AppearanceMode.light => 'Light',
                      AppearanceMode.dark => 'Dark',
                    }),
                    selected: controller.appearance.mode == mode,
                    onSelected: controller.savingAppearance
                        ? null
                        : (_) => _save(context, mode: mode),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            const Text('Accent color'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final accent in AccentColor.values)
                  ChoiceChip(
                    avatar: CircleAvatar(
                      backgroundColor: NewManTheme.buttonColor(
                        accent,
                        Theme.of(context).brightness,
                      ),
                    ),
                    label: Text(switch (accent) {
                      AccentColor.blue => 'Blue',
                      AccentColor.green => 'Green',
                      AccentColor.brown => 'Brown',
                    }),
                    selected: controller.appearance.accent == accent,
                    onSelected: controller.savingAppearance
                        ? null
                        : (_) => _save(context, accent: accent),
                  ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
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
