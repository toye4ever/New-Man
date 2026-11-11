import 'package:flutter/material.dart';

import '../application/guard_qualification_service.dart';
import '../application/guard_readiness_service.dart';
import '../domain/guard_qualification.dart';
import '../domain/guard_readiness.dart';
import 'guard_qualification_screen.dart';

class FocusScreen extends StatefulWidget {
  const FocusScreen({
    this.readinessService,
    this.qualificationService,
    super.key,
  });

  final GuardReadinessService? readinessService;
  final GuardQualificationService? qualificationService;

  @override
  State<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends State<FocusScreen> with WidgetsBindingObserver {
  late GuardReadinessService _service;
  late GuardQualificationService _qualificationService;
  GuardReadinessReport? _report;
  GuardQualificationSnapshot? _qualificationSnapshot;
  bool _checking = false;
  bool _hasChecked = false;
  bool _qualificationChecking = true;
  bool _qualificationUncertain = false;
  late bool _ownsQualificationService;
  int _requestToken = 0;
  int _qualificationRequestToken = 0;

  @override
  void initState() {
    super.initState();
    _service = widget.readinessService ?? createGuardReadinessService();
    _ownsQualificationService = widget.qualificationService == null;
    _qualificationService =
        widget.qualificationService ?? createGuardQualificationService();
    WidgetsBinding.instance.addObserver(this);
    _refreshQualificationStatus(notifyBeforeRequest: false);
  }

  @override
  void didUpdateWidget(FocusScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.readinessService != widget.readinessService) {
      _service = widget.readinessService ?? createGuardReadinessService();
      _report = null;
      _checking = false;
      _hasChecked = false;
      _requestToken++;
    }
    if (oldWidget.qualificationService != widget.qualificationService) {
      if (_ownsQualificationService) _qualificationService.cancelPending();
      _ownsQualificationService = widget.qualificationService == null;
      _qualificationService =
          widget.qualificationService ?? createGuardQualificationService();
      _qualificationSnapshot = null;
      _qualificationChecking = true;
      _qualificationUncertain = false;
      _qualificationRequestToken++;
      _refreshQualificationStatus(notifyBeforeRequest: false);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshQualificationStatus();
      if (_hasChecked && !_checking) _checkProtection();
    }
  }

  Future<void> _refreshQualificationStatus({
    bool notifyBeforeRequest = true,
  }) async {
    final token = ++_qualificationRequestToken;
    _qualificationChecking = true;
    if (notifyBeforeRequest && mounted) setState(() {});
    try {
      final snapshot = await _qualificationService.getStatus();
      if (!mounted || token != _qualificationRequestToken) return;
      setState(() {
        _qualificationSnapshot = snapshot;
        _qualificationUncertain = false;
      });
    } catch (_) {
      if (!mounted || token != _qualificationRequestToken) return;
      setState(() {
        _qualificationSnapshot = null;
        _qualificationUncertain = true;
      });
    } finally {
      if (mounted && token == _qualificationRequestToken) {
        setState(() => _qualificationChecking = false);
      }
    }
  }

  Future<void> _openQualificationTest() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => GuardQualificationScreen(
          service: _qualificationService,
          readinessService: _service,
        ),
      ),
    );
    if (mounted) await _refreshQualificationStatus();
  }

  Future<void> _checkProtection() async {
    final token = ++_requestToken;
    setState(() {
      _checking = true;
      _hasChecked = true;
    });

    GuardReadinessReport report;
    try {
      report = await _service.checkReadiness();
    } catch (_) {
      report = GuardReadinessReport.probeFailed();
    }
    if (!mounted || token != _requestToken) return;
    setState(() {
      _checking = false;
      _report = report;
    });
  }

  @override
  void dispose() {
    _requestToken++;
    _qualificationRequestToken++;
    if (_ownsQualificationService) _qualificationService.cancelPending();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final report = _report;
    return SafeArea(
      child: ListView(
        key: const Key('focus-readiness-scroll'),
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Icon(
                    Icons.center_focus_strong_outlined,
                    size: 52,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Focus',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Focus and Guard are in preparation. Nothing is blocked '
                    'merely by opening this screen or checking readiness.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          Text(
                            'Whole-app qualification test',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _qualificationSnapshot?.isActive == true
                                ? 'A ${_qualificationSnapshot!.status.name} '
                                      'whole-app TEST is active in this New Man '
                                      'process. Return to it to pause, end, or '
                                      'review recovery controls.'
                                : _qualificationUncertain
                                ? 'The native TEST status could not be confirmed. '
                                      'Use recovery to check, end, or revoke access; '
                                      'do not assume that no test is active.'
                                : _qualificationChecking
                                ? 'Checking only New Man\'s own native test lease. '
                                      'No installed-app readiness query is running.'
                                : 'Android can run a separate, opt-in 15-minute '
                                      'test for entire YouTube, Instagram, '
                                      'Facebook, or TikTok apps. '
                                      'Qualification is pending, and Shorts/Reels-only '
                                      'tests are unavailable.',
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            key: const Key('open-guard-qualification-button'),
                            onPressed: _openQualificationTest,
                            icon: const Icon(Icons.science_outlined),
                            label: Text(
                              _qualificationSnapshot?.isActive == true
                                  ? 'Return to active TEST'
                                  : _qualificationUncertain
                                  ? 'Recover whole-app TEST'
                                  : 'Open whole-app test',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    key: const Key('check-protection-button'),
                    onPressed: _checking ? null : _checkProtection,
                    icon: _checking
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.shield_outlined),
                    label: Text(
                      report?.hasProbeFailure == true
                          ? 'Try again'
                          : 'Check protection',
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_checking)
                    const _StatusCard(
                      title: 'Checking protection status',
                      body: 'Reading only the four supported app identities.',
                    )
                  else if (report == null)
                    const _StatusCard(
                      title: 'Not checked',
                      body:
                          'Choose Check protection to read installed, enabled, '
                          'and version status for YouTube, Instagram, Facebook, '
                          'and TikTok.',
                    )
                  else if (report.hasProbeFailure)
                    const _StatusCard(
                      title: 'Protection status unavailable',
                      body:
                          'The status could not be verified. Nothing was changed '
                          'or enabled. You can try again.',
                    )
                  else ...<Widget>[
                    const _StatusCard(
                      title: 'Qualification status',
                      body:
                          'Installed does not mean protected. Each target and '
                          'exact app version must be qualified separately.',
                    ),
                    const SizedBox(height: 12),
                    ...report.targets.map(
                      (target) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _TargetStatusCard(readiness: target),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(body),
        ],
      ),
    ),
  );
}

class _TargetStatusCard extends StatelessWidget {
  const _TargetStatusCard({required this.readiness});

  final GuardTargetReadiness readiness;

  @override
  Widget build(BuildContext context) => Card(
    child: ListTile(
      leading: Icon(_icon, color: Theme.of(context).colorScheme.primary),
      title: Text(readiness.target.label),
      subtitle: Text(_description),
      isThreeLine: readiness.versionCode != null,
    ),
  );

  IconData get _icon => switch (readiness.state) {
    GuardReadinessState.notInstalled => Icons.download_outlined,
    GuardReadinessState.disabled => Icons.pause_circle_outline,
    GuardReadinessState.unsupportedPlatform => Icons.block_outlined,
    GuardReadinessState.ready => Icons.verified_user_outlined,
    _ => Icons.info_outline,
  };

  String get _description {
    final version = readiness.versionCode == null
        ? ''
        : ' Version ${readiness.versionName ?? 'unknown'} '
              '(${readiness.versionCode}).';
    return switch (readiness.state) {
      GuardReadinessState.probeFailed => 'Status unavailable.',
      GuardReadinessState.unsupportedPlatform =>
        'This target is not supported on this platform.',
      GuardReadinessState.notInstalled => 'App not installed.',
      GuardReadinessState.disabled => 'App is disabled.$version',
      GuardReadinessState.versionUnknown =>
        'The installed app version could not be verified.',
      GuardReadinessState.versionUnqualified =>
        'This exact target and app version are not qualified.$version',
      GuardReadinessState.enforcementUnavailable =>
        'Qualified version found, but protection is not implemented.$version',
      GuardReadinessState.ready =>
        'Qualified protection implementation is available.$version',
    };
  }
}
