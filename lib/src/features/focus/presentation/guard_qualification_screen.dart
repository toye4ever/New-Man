import 'package:flutter/material.dart';

import '../application/guard_qualification_controller.dart';
import '../application/guard_qualification_service.dart';
import '../application/guard_readiness_service.dart';
import '../domain/guard_qualification.dart';

class GuardQualificationScreen extends StatefulWidget {
  const GuardQualificationScreen({
    this.controller,
    this.service,
    this.readinessService,
    super.key,
  });

  final GuardQualificationController? controller;
  final GuardQualificationService? service;
  final GuardReadinessService? readinessService;

  @override
  State<GuardQualificationScreen> createState() =>
      _GuardQualificationScreenState();
}

class _GuardQualificationScreenState extends State<GuardQualificationScreen>
    with WidgetsBindingObserver {
  late final GuardQualificationController _controller;
  late final bool _ownsController;
  bool _handlingBack = false;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        GuardQualificationController(
          readinessService: widget.readinessService,
          service: widget.service ?? createGuardQualificationService(),
        );
    _controller.addListener(_onControllerChanged);
    WidgetsBinding.instance.addObserver(this);
    _controller.initialize();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _controller.refreshOnReturn();
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onControllerChanged);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _showDisclosure() async {
    final revision = _controller.draftRevision;
    final accepted = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Before this test'),
        content: const SingleChildScrollView(
          child: Text(
            'During a running test, New Man checks app-change identities from '
            'other apps so a queued selected-app event cannot affect recovery '
            'screens. It returns you Home only when you open an entire '
            'YouTube, Instagram, Facebook, or TikTok app you explicitly '
            'selected.\n\nNew Man '
            'reads no screen content, text, messages, or screenshots. It '
            'saves no app history and sends nothing. Outside a running test, '
            'it does not process app-change identities. Android Accessibility '
            'can be revoked at any time. Enabling the service alone does not '
            'consent to or start a test.\n\nFor initial setup, this disclosure lets '
            'you open Android Settings. After enabling Accessibility and returning '
            'here, review and agree again for a fresh test, then select apps and '
            'confirm Start. Connection changes clear the previous agreement and selection.',
          ),
        ),
        actions: <Widget>[
          TextButton(
            key: const Key('decline-disclosure-button'),
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Not now'),
          ),
          FilledButton(
            key: const Key('accept-disclosure-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('I understand'),
          ),
        ],
      ),
    );
    if (accepted == true) {
      _controller.acceptDisclosure(expectedDraftRevision: revision);
    }
  }

  Future<void> _confirmStart() async {
    final revision = _controller.draftRevision;
    final labels = _controller.selection
        .map((target) => target.label)
        .join(' and ');
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start 15-minute test?'),
        content: Text(
          'The entire $labels ${_controller.selection.length == 1 ? 'app' : 'apps'} '
          'will be restricted for 15 minutes. This is not a Shorts- or '
          'Reels-only test. You can pause or end at any time.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            key: const Key('confirm-start-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Start entire-app test'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await _controller.start(confirmedDraftRevision: revision);
    }
  }

  Future<bool> _confirmEnd() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('End this test?'),
        content: const Text(
          'Ending releases all test restrictions immediately. It does not '
          'disable Android Accessibility; you can revoke that separately in Settings.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep test'),
          ),
          FilledButton(
            key: const Key('confirm-end-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('End test'),
          ),
        ],
      ),
    );
    if (confirmed != true) return false;
    return _controller.end();
  }

  Future<void> _confirmPause() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pause this test?'),
        content: const Text(
          'Pausing releases all test restrictions immediately and keeps the '
          'remaining time. Resuming requires current consent and a connected service.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep running'),
          ),
          FilledButton(
            key: const Key('confirm-pause-button'),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Pause test'),
          ),
        ],
      ),
    );
    if (confirmed == true) await _controller.pause();
  }

  Future<void> _handleBack(bool didPop) async {
    if (didPop || _handlingBack) return;
    if (!_mustConfirmExit) {
      Navigator.of(context).pop();
      return;
    }
    _handlingBack = true;
    final ended = await _confirmEnd();
    _handlingBack = false;
    if (ended && mounted) Navigator.of(context).pop();
  }

  bool get _mustConfirmExit =>
      _controller.snapshot?.isActive == true || _controller.mayBeActive;

  @override
  Widget build(BuildContext context) {
    final snapshot = _controller.snapshot;
    final supported = snapshot?.isSupported == true;
    final supportUnknown = snapshot == null && _controller.mayBeActive;
    return PopScope<void>(
      canPop: !_mustConfirmExit,
      onPopInvokedWithResult: (didPop, _) => _handleBack(didPop),
      child: Scaffold(
        appBar: AppBar(title: const Text('Whole-app test')),
        body: SafeArea(
          child: ListView(
            key: const Key('guard-qualification-scroll'),
            padding: const EdgeInsets.all(20),
            children: <Widget>[
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Text(
                        'Android qualification test',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This prototype is not qualified protection and does not '
                        'provide Focus history, reminders, or final Focus sessions.',
                      ),
                      const SizedBox(height: 16),
                      _StatusCard(snapshot: snapshot),
                      if (_controller.message != null) ...<Widget>[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _controller.message!,
                            key: const Key('guard-command-message'),
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 20),
                      if (supportUnknown)
                        const Text(
                          'The native test status is not confirmed yet. End and '
                          'Android Settings remain available for safe recovery.',
                        )
                      else if (!supported)
                        const Text(
                          'Whole-app testing and Android permission controls are '
                          'not available on this platform.',
                        )
                      else if (snapshot?.isActive != true) ...<Widget>[
                        Text(
                          'Choose entire apps',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const Text('All choices start unchecked.'),
                        const SizedBox(height: 8),
                        Text(
                          _controller.availabilityMessage,
                          key: const Key('guard-availability-message'),
                        ),
                        for (final target in _controller.displayedTargets)
                          CheckboxListTile(
                            key: Key('guard-target-${target.id}'),
                            contentPadding: EdgeInsets.zero,
                            title: Text('Entire ${target.label} app'),
                            subtitle: const Text(
                              'Returns Home when this app is opened during the test.',
                            ),
                            value: _controller.selection.contains(target),
                            onChanged:
                                supported &&
                                    !_controller.commandInProgress &&
                                    !_controller.startChecking &&
                                    _controller.selectableTargets.contains(
                                      target,
                                    )
                                ? (value) => _controller.setSelected(
                                    target,
                                    value ?? false,
                                  )
                                : null,
                          ),
                        TextButton.icon(
                          key: const Key('refresh-guard-availability-button'),
                          onPressed:
                              _controller.commandInProgress ||
                                  _controller.startChecking ||
                                  _controller.availabilityLoading
                              ? null
                              : _controller.refreshAvailability,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh app availability'),
                        ),
                        const _FeatureUnavailableCard(),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('review-disclosure-button'),
                          onPressed: supported && !_controller.commandInProgress
                              ? _showDisclosure
                              : null,
                          icon: Icon(
                            _controller.disclosureAccepted
                                ? Icons.check_circle_outline
                                : Icons.privacy_tip_outlined,
                          ),
                          label: Text(
                            _controller.disclosureAccepted
                                ? 'Disclosure accepted for this test'
                                : 'Review disclosure and consent',
                          ),
                        ),
                        const SizedBox(height: 8),
                        FilledButton.icon(
                          key: const Key('start-guard-test-button'),
                          onPressed: _controller.canStart
                              ? _confirmStart
                              : null,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(
                            _controller.startChecking
                                ? 'Checking apps before Start...'
                                : 'Start 15-minute test',
                          ),
                        ),
                      ] else ...<Widget>[
                        if (snapshot?.status ==
                            GuardQualificationStatus.running)
                          FilledButton.icon(
                            key: const Key('pause-guard-test-button'),
                            onPressed: _controller.commandInProgress
                                ? null
                                : _confirmPause,
                            icon: const Icon(Icons.pause),
                            label: const Text('Pause test'),
                          ),
                        if (snapshot?.status == GuardQualificationStatus.paused)
                          FilledButton.icon(
                            key: const Key('resume-guard-test-button'),
                            onPressed:
                                _controller.commandInProgress ||
                                    snapshot?.serviceConnected != true
                                ? null
                                : _controller.resume,
                            icon: const Icon(Icons.play_arrow),
                            label: const Text('Resume test'),
                          ),
                      ],
                      if (_mustConfirmExit) ...<Widget>[
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          key: const Key('end-guard-test-button'),
                          onPressed: _controller.commandInProgress
                              ? null
                              : _confirmEnd,
                          icon: const Icon(Icons.stop_circle_outlined),
                          label: const Text('End test'),
                        ),
                      ],
                      if (supported || supportUnknown) ...<Widget>[
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          key: const Key('open-accessibility-settings-button'),
                          onPressed: _controller.canOpenAccessibilitySettings
                              ? _controller.openAccessibilitySettings
                              : null,
                          icon: const Icon(Icons.settings_accessibility),
                          label: Text(
                            _controller.hasAccessibilityRecoveryRoute
                                ? 'Review or revoke Android Accessibility'
                                : 'Open Android Accessibility settings',
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextButton.icon(
                        key: const Key('refresh-guard-status-button'),
                        onPressed: _controller.commandInProgress
                            ? null
                            : _controller.refreshStatus,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Refresh test status'),
                      ),
                      if (supported || supportUnknown)
                        Text(
                          _controller.hasAccessibilityRecoveryRoute
                              ? 'The test is inactive unless the status above '
                                    'says running or paused. Android access may '
                                    'still be enabled, so you can review or '
                                    'revoke it in Accessibility settings. '
                                    'Opening Settings never starts a test.'
                              : 'Review and accept the disclosure before opening '
                                    'Android Accessibility settings to enable the '
                                    'test service. After returning, agree again '
                                    'and select apps for a fresh test. Enabling '
                                    'alone never starts a test.',
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.snapshot});

  final GuardQualificationSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final value = snapshot;
    final title = switch (value?.status) {
      GuardQualificationStatus.running => 'Test running',
      GuardQualificationStatus.paused => 'Test paused',
      GuardQualificationStatus.completed => 'Test completed',
      GuardQualificationStatus.ended => 'Test ended',
      GuardQualificationStatus.interrupted => 'Test interrupted',
      GuardQualificationStatus.error => 'Test stopped for safety',
      GuardQualificationStatus.unavailable => 'Android-only test unavailable',
      GuardQualificationStatus.idle =>
        value?.serviceConnected == true
            ? 'Ready to choose a test'
            : 'Accessibility service not connected',
      null => 'Checking test status',
    };
    final body = value?.isActive == true
        ? '${_minutes(value!.remainingMillis)} remaining. Selected: '
              '${value.selectedTargets.map((target) => target.label).join(', ')}.'
        : value?.status == GuardQualificationStatus.unavailable
        ? 'No Android channel or permission control is used on this platform.'
        : 'No app is restricted by merely installing or enabling the service.';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(body),
          ],
        ),
      ),
    );
  }

  static String _minutes(int millis) {
    final seconds = (millis / 1000).ceil();
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}

class _FeatureUnavailableCard extends StatelessWidget {
  const _FeatureUnavailableCard();

  @override
  Widget build(BuildContext context) => const Card(
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Feature-only tests are not available'),
          SizedBox(height: 6),
          Text(
            'YouTube Shorts and Instagram Reels are not selectable. They are '
            'never expanded into whole-app restrictions.',
          ),
        ],
      ),
    ),
  );
}
