import 'package:flutter/material.dart';

import '../../../../controllers/app_controller.dart';
import '../../../../services/bible_version_repository.dart';
import '../../../../widgets/page_header.dart';
import '../../../../widgets/responsive_content.dart';
import '../domain/bible_translation.dart';
import '../domain/translation_state.dart';

class TranslationManagerScreen extends StatelessWidget {
  const TranslationManagerScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final states = <TranslationAvailability>[
      for (final definition in translationCatalog)
        controller.translationAvailability(definition.translation),
    ];
    final groups = <_TranslationGroup>[
      _TranslationGroup(
        title: 'INSTALLED',
        states: states
            .where(
              (state) =>
                  state.kind == TranslationAvailabilityKind.installedOffline,
            )
            .toList(),
      ),
      _TranslationGroup(
        title: 'ONLINE',
        states: states
            .where((state) => state.kind == TranslationAvailabilityKind.online)
            .toList(),
      ),
      _TranslationGroup(
        title: 'INSTALLING',
        states: states.where((state) => state.isBusy).toList(),
      ),
      _TranslationGroup(
        title: 'AVAILABLE TO DOWNLOAD',
        states: states
            .where(
              (state) =>
                  state.kind == TranslationAvailabilityKind.downloadAvailable ||
                  state.kind == TranslationAvailabilityKind.failed,
            )
            .toList(),
      ),
      _TranslationGroup(
        title: 'SETUP REQUIRED',
        states: states
            .where(
              (state) =>
                  state.kind == TranslationAvailabilityKind.setupRequired,
            )
            .toList(),
      ),
    ];

    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PageHeader(
            title: 'Bible Versions',
            subtitle:
                'Offline downloads and online providers are shown according to what each translation actually supports.',
          ),
          const SizedBox(height: 24),
          for (final group in groups)
            if (group.states.isNotEmpty) ...<Widget>[
              Text(group.title, style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 10),
              for (final state in group.states) ...<Widget>[
                _TranslationTile(controller: controller, state: state),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 14),
            ],
        ],
      ),
    );
  }
}

class _TranslationTile extends StatelessWidget {
  const _TranslationTile({required this.controller, required this.state});

  final AppController controller;
  final TranslationAvailability state;

  @override
  Widget build(BuildContext context) {
    final definition = state.definition;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                CircleAvatar(child: Icon(_iconFor(state.kind))),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '${definition.displayName} (${definition.abbreviation})',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(_description(state)),
                    ],
                  ),
                ),
                if (state.canInstall)
                  FilledButton.tonalIcon(
                    onPressed: () => _install(context),
                    icon: Icon(
                      state.kind == TranslationAvailabilityKind.failed
                          ? Icons.refresh
                          : Icons.download_outlined,
                    ),
                    label: Text(
                      state.kind == TranslationAvailabilityKind.failed
                          ? 'Retry'
                          : 'Download',
                    ),
                  ),
              ],
            ),
            if (state.isBusy) ...<Widget>[
              const SizedBox(height: 14),
              Semantics(
                label: state.progress == null
                    ? state.shortStatus
                    : '${state.shortStatus} ${(state.progress! * 100).round()} percent',
                child: LinearProgressIndicator(value: state.progress),
              ),
              const SizedBox(height: 6),
              Text(
                state.progress == null
                    ? '${state.shortStatus}…'
                    : '${state.shortStatus} ${(state.progress! * 100).round()}%',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _install(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      await controller.installTranslation(state.definition.translation);
      messenger.showSnackBar(
        SnackBar(
          content: Text('${state.definition.abbreviation} is ready offline.'),
        ),
      );
    } on TranslationInstallationException catch (error) {
      messenger.showSnackBar(SnackBar(content: Text(error.message)));
    }
  }
}

class _TranslationGroup {
  const _TranslationGroup({required this.title, required this.states});

  final String title;
  final List<TranslationAvailability> states;
}

IconData _iconFor(TranslationAvailabilityKind kind) => switch (kind) {
  TranslationAvailabilityKind.installedOffline => Icons.offline_pin_outlined,
  TranslationAvailabilityKind.downloadAvailable => Icons.download_outlined,
  TranslationAvailabilityKind.downloading => Icons.downloading_outlined,
  TranslationAvailabilityKind.processing => Icons.settings_outlined,
  TranslationAvailabilityKind.failed => Icons.error_outline,
  TranslationAvailabilityKind.online => Icons.cloud_outlined,
  TranslationAvailabilityKind.setupRequired => Icons.lock_outline,
};

String _description(TranslationAvailability state) => switch (state.kind) {
  TranslationAvailabilityKind.installedOffline =>
    'Available offline. Scripture text is stored on this device.',
  TranslationAvailabilityKind.downloadAvailable =>
    'Complete public-domain package available for offline reading.',
  TranslationAvailabilityKind.downloading =>
    state.progress == null
        ? 'Downloading the KJV package. Exact progress is unavailable.'
        : 'Downloading the KJV package with measured transfer progress.',
  TranslationAvailabilityKind.processing =>
    'Download complete. Verifying and preparing Scripture for offline use.',
  TranslationAvailabilityKind.failed =>
    'The previous installation did not finish. Your existing data was not removed.',
  TranslationAvailabilityKind.online =>
    'Available through the configured provider. Internet is required; no offline download is offered.',
  TranslationAvailabilityKind.setupRequired =>
    'Online provider setup is required. This translation is not downloadable for offline use.',
};
