import 'dart:async';

import '../domain/guard_qualification.dart';
import '../domain/guard_readiness.dart';
import 'guard_readiness_service.dart';
import 'guard_qualification_service.dart';

typedef GuardQualificationListener = void Function();

class GuardQualificationController {
  GuardQualificationController({
    required GuardQualificationService service,
    GuardReadinessService? readinessService,
    this.readinessTimeout = const Duration(seconds: 5),
    DateTime Function()? availabilityClock,
    this.availabilityLifetime = const Duration(seconds: 30),
    this.pollingInterval = const Duration(seconds: 1),
  }) : _availabilityClock = availabilityClock ?? DateTime.now,
       _service = service,
       _readinessService = readinessService ?? createGuardReadinessService();

  final GuardQualificationService _service;
  final Duration? pollingInterval;
  final GuardReadinessService _readinessService;
  final Duration readinessTimeout;
  final Duration availabilityLifetime;
  GuardReadinessReport? _availability;
  final DateTime Function() _availabilityClock;
  DateTime? _availabilityExpiresAt;
  bool get _availabilityFresh =>
      _availabilityExpiresAt != null &&
      _availabilityClock().isBefore(_availabilityExpiresAt!);
  int _availabilityGeneration = 0;
  int _draftGeneration = 0;
  bool _availabilityLoading = false;
  Timer? _availabilityDeadline;
  Completer<GuardReadinessReport?>? _availabilityRequest;
  bool _startChecking = false;
  bool _availabilityFailed = false;
  // Display history is not permission to edit or dispatch a native Start.
  final Set<GuardQualificationTarget> _displayedTargets = {};

  bool get availabilityLoading => _availabilityLoading;
  bool get startChecking => _startChecking;
  int get draftRevision => _draftGeneration;
  Set<GuardQualificationTarget> get displayedTargets =>
      Set.unmodifiable(_displayedTargets);
  GuardReadinessState? availabilityState(GuardQualificationTarget target) {
    if (!_availabilityFresh) return null;
    final matches = _availability?.targets.where(
      (item) => item.target.id == target.id,
    );
    return matches?.length == 1 ? matches!.single.state : null;
  }

  Set<GuardQualificationTarget> get selectableTargets => Set.unmodifiable(
    GuardQualificationTarget.values.where(
      (target) =>
          _availabilityFresh &&
          !_availabilityLoading &&
          _availability?.platform == GuardPlatform.android &&
          _availability?.hasProbeFailure == false &&
          switch (availabilityState(target)) {
            GuardReadinessState.versionUnqualified ||
            GuardReadinessState.enforcementUnavailable ||
            GuardReadinessState.ready => true,
            _ => false,
          },
    ),
  );

  String get availabilityMessage {
    if (_availabilityLoading) {
      return 'Checking installed test apps... Last-confirmed choices remain visible; they are not authorized yet.';
    }
    if (_availabilityFailed || _availability == null) {
      return 'App availability is unavailable. Last-confirmed choices are not authorized. Refresh availability to retry.';
    }
    if (!_availabilityFresh) {
      return 'App availability is stale. Last-confirmed choices remain visible. Start checks them again before starting; refresh to change choices.';
    }
    if (GuardQualificationTarget.values.every(
      (target) => availabilityState(target) == GuardReadinessState.notInstalled,
    )) {
      return 'None of the four supported apps is installed. Install a supported app, then refresh availability.';
    }
    return 'Only confirmed installed and enabled apps can be selected. Installed does not mean qualified. Unavailable apps require an availability refresh.';
  }

  // Explicit entry/resume/refresh only; native status polling never probes packages.
  Future<bool> refreshAvailability() async {
    _cancelAvailability();
    if (_disposed ||
        _snapshot?.platform != GuardPlatform.android ||
        _snapshot?.serviceConnected != true ||
        _mayBeActive ||
        _commandInProgress ||
        _snapshot?.status == GuardQualificationStatus.unavailable) {
      return false;
    }
    // Reconnection leaves native interrupted/error status intact. A connected,
    // conclusively inactive lease may build a fresh draft without resetting
    // native status or claiming Accessibility filters have been cleaned up.
    final token = ++_availabilityGeneration;
    final draftGeneration = _draftGeneration;
    final generation = _generation;
    _availabilityExpiresAt = null;
    _availabilityLoading = true;
    final request = Completer<GuardReadinessReport?>();
    _availabilityRequest = request;
    final deadline = Timer(readinessTimeout, () => request.complete(null));
    _availabilityDeadline = deadline;
    _notify();
    if (_disposed || token != _availabilityGeneration) return false;
    void finish(GuardReadinessReport? report) {
      // Backend work may finish after cancellation; it owns no state or timer.
      if (request.isCompleted) return;
      deadline.cancel();
      request.complete(report);
    }

    Future.sync(_readinessService.checkReadiness).then<void>(
      finish,
      onError: (Object error, StackTrace stackTrace) => finish(null),
    );
    final report = await request.future;
    if (_disposed || token != _availabilityGeneration) return false;
    _availabilityDeadline = null;
    _availabilityRequest = null;
    _availabilityLoading = false;
    if (generation != _generation || draftGeneration != _draftGeneration) {
      _notify();
      return false;
    }
    if (report == null ||
        report.hasProbeFailure ||
        report.platform != GuardPlatform.android) {
      _availabilityFailed = true;
      _notify();
      return false;
    }
    _availabilityFailed = false;
    _availability = report;
    _availabilityExpiresAt = _availabilityClock().add(availabilityLifetime);
    _displayedTargets
      ..clear()
      ..addAll(selectableTargets);
    if (!_mayBeActive && !_commandInProgress && _snapshot?.isActive != true) {
      final previousSelectionLength = _selection.length;
      _selection.removeWhere(
        (target) => switch (availabilityState(target)) {
          GuardReadinessState.notInstalled ||
          GuardReadinessState.disabled ||
          GuardReadinessState.versionUnknown ||
          GuardReadinessState.unsupportedPlatform => true,
          _ => false,
        },
      );
      if (_selection.length != previousSelectionLength) _draftGeneration++;
    }
    _notify();
    return true;
  }

  void _cancelAvailability() {
    _availabilityGeneration++;
    _availabilityDeadline?.cancel();
    _availabilityDeadline = null;
    final request = _availabilityRequest;
    _availabilityRequest = null;
    if (request != null && !request.isCompleted) request.complete(null);
    _availabilityLoading = false;
  }

  Future<void> refreshOnReturn() async {
    await refreshStatus();
    await refreshAvailability();
  }

  final Set<GuardQualificationListener> _listeners = {};
  final Set<GuardQualificationTarget> _selection = {};
  GuardQualificationSnapshot? _snapshot;
  Timer? _timer;
  bool _disclosureAccepted = false;
  bool _commandInProgress = false;
  bool _refreshInProgress = false;
  // Until a conclusive native status arrives, host recreation may have left a
  // process-local Android lease running. Recovery controls stay available.
  bool _mayBeActive = true;
  // A conclusive terminal native state proves restriction is inactive, but it
  // does not prove that Android Accessibility access was revoked.
  bool _revocationRecoveryNeeded = false;
  bool _disposed = false;
  int _generation = 0;
  String? _message;
  String? _connectionMessage;

  GuardQualificationSnapshot? get snapshot => _snapshot;
  Set<GuardQualificationTarget> get selection => Set.unmodifiable(_selection);
  bool get disclosureAccepted => _disclosureAccepted;
  bool get commandInProgress => _commandInProgress;
  bool get mayBeActive => _mayBeActive;
  bool get hasAccessibilityRecoveryRoute =>
      _mayBeActive ||
      _revocationRecoveryNeeded ||
      _snapshot?.serviceConnected == true;
  String? get message => _message ?? _connectionMessage;
  // A stale draft may request revalidation; start() separately requires a fresh
  // successful probe bound to the confirmed, unchanged draft.
  bool get canStart =>
      !_disposed &&
      !_startChecking &&
      !_commandInProgress &&
      !_mayBeActive &&
      _disclosureAccepted &&
      _selection.isNotEmpty &&
      !_availabilityLoading &&
      !_availabilityFailed &&
      _displayedTargets.containsAll(_selection) &&
      _snapshot?.serviceConnected == true &&
      _snapshot?.isActive != true;
  bool get canOpenAccessibilitySettings =>
      !_commandInProgress &&
      _snapshot?.isSupported != false &&
      (_disclosureAccepted || hasAccessibilityRecoveryRoute);

  void addListener(GuardQualificationListener listener) {
    if (!_disposed) _listeners.add(listener);
  }

  void removeListener(GuardQualificationListener listener) {
    _listeners.remove(listener);
  }

  Future<void> initialize() async {
    if (_disposed || _timer != null) return;
    await refreshStatus();
    await refreshAvailability();
    if (_disposed || pollingInterval == null) return;
    _timer = Timer.periodic(pollingInterval!, (_) => refreshStatus());
  }

  void acceptDisclosure({int? expectedDraftRevision}) {
    if (_disposed ||
        _snapshot?.isActive == true ||
        (expectedDraftRevision != null &&
            expectedDraftRevision != _draftGeneration)) {
      return;
    }
    _draftGeneration++;
    _disclosureAccepted = true;
    _message = null;
    _connectionMessage = null;
    _notify();
  }

  void setSelected(GuardQualificationTarget target, bool selected) {
    if (_disposed || _snapshot?.isActive == true || _commandInProgress) {
      return;
    }
    if (selected && !selectableTargets.contains(target)) return;
    if (_selection.contains(target) == selected) return;
    _draftGeneration++;
    if (selected) {
      _selection.add(target);
    } else {
      _selection.remove(target);
    }
    _message = null;
    _notify();
  }

  Future<void> refreshStatus() async {
    if (_disposed || _refreshInProgress || _commandInProgress) return;
    _refreshInProgress = true;
    final generation = _generation;
    try {
      final snapshot = await _service.getStatus();
      if (_canApply(generation)) _applySnapshot(snapshot);
    } catch (_) {
      if (_canApply(generation)) {
        _cancelAvailability();
        _revocationRecoveryNeeded =
            _revocationRecoveryNeeded || _snapshot?.serviceConnected == true;
        _invalidateDraft(clearSelection: false, invalidateAvailability: true);
        _snapshot = null;
        _message =
            'Test status is unavailable. Refresh or end the test to recover.';
        _notify();
      }
    } finally {
      _refreshInProgress = false;
    }
  }

  Future<bool> start({int? confirmedDraftRevision}) async {
    if (!canStart ||
        (confirmedDraftRevision != null &&
            confirmedDraftRevision != _draftGeneration)) {
      return false;
    }
    final selected = Set<GuardQualificationTarget>.of(_selection);
    final generation = _generation;
    final draftGeneration = _draftGeneration;
    _startChecking = true;
    _notify();
    final fresh = await refreshAvailability();
    _startChecking = false;
    if (!fresh ||
        !_availabilityFresh ||
        draftGeneration != _draftGeneration ||
        !_canApply(generation) ||
        !canStart ||
        !selectableTargets.containsAll(selected) ||
        selected.length != _selection.length ||
        !_selection.containsAll(selected)) {
      _notify();
      return false;
    }
    final request = GuardQualificationStartRequest(
      selectedTargets: _selection,
      durationMinutes: 15,
      disclosureAccepted: true,
    );
    return _runCommand(
      () => _service.start(request),
      startMayHaveSucceeded: true,
    );
  }

  Future<bool> pause() async =>
      _startChecking ? false : _runCommand(_service.pause);

  Future<bool> resume() async {
    final resumed = await _runCommand(_service.resume);
    if (resumed) await refreshStatus();
    return resumed;
  }

  Future<bool> end() async {
    final ended = await _runCommand(_service.end, preserveEndAccess: true);
    if (ended && !_disposed) {
      _invalidateDraft();
      _mayBeActive = false;
      _notify();
    }
    return ended;
  }

  Future<bool> openAccessibilitySettings() async {
    if (_disposed || !canOpenAccessibilitySettings) {
      return false;
    }
    _generation++;
    _cancelAvailability();
    _invalidateDraft(invalidateAvailability: true);
    _commandInProgress = true;
    _message = null;
    _notify();
    try {
      await _service.openAccessibilitySettings();
      return !_disposed;
    } catch (_) {
      if (!_disposed) {
        _message = 'Android Accessibility settings could not be opened.';
        _notify();
      }
      return false;
    } finally {
      if (!_disposed) {
        _commandInProgress = false;
        _notify();
      }
    }
  }

  Future<bool> _runCommand(
    Future<GuardQualificationSnapshot> Function() command, {
    bool startMayHaveSucceeded = false,
    bool preserveEndAccess = false,
  }) async {
    if (_disposed || _commandInProgress) return false;
    _commandInProgress = true;
    _cancelAvailability();
    final generation = ++_generation;
    _message = null;
    _notify();
    try {
      final snapshot = await command();
      if (!_canApply(generation)) return false;
      _applySnapshot(snapshot);
      return true;
    } catch (_) {
      if (!_canApply(generation)) return false;
      _invalidateDraft(clearSelection: false, invalidateAvailability: true);
      _mayBeActive =
          startMayHaveSucceeded ||
          preserveEndAccess ||
          _snapshot?.isActive == true;
      _message = startMayHaveSucceeded
          ? 'Start result is uncertain. The test was not retried; status was refreshed.'
          : 'The command result is uncertain. Status was refreshed.';
      try {
        final recovered = await _service.getStatus();
        if (!_canApply(generation)) return false;
        _applySnapshot(recovered, keepMessage: true);
      } catch (_) {
        if (_canApply(generation)) {
          _snapshot = null;
          _notify();
        }
      }
      return false;
    } finally {
      if (_canApply(generation)) {
        _commandInProgress = false;
        _notify();
      }
    }
  }

  void _applySnapshot(
    GuardQualificationSnapshot snapshot, {
    bool keepMessage = false,
  }) {
    final previous = _snapshot;
    final wasActive = previous?.isActive == true;
    final resetDraft = _requiresFreshDraft(previous, snapshot);
    if (snapshot.isActive || resetDraft) _cancelAvailability();
    _snapshot = snapshot;
    _mayBeActive = snapshot.isActive;
    _revocationRecoveryNeeded =
        snapshot.isSupported &&
        (_revocationRecoveryNeeded ||
            wasActive ||
            snapshot.isActive ||
            _terminalRecoveryStatuses.contains(snapshot.status) ||
            _terminalRecoveryDetailCodes.contains(snapshot.detailCode));
    if (snapshot.isActive) {
      _selection
        ..clear()
        ..addAll(snapshot.selectedTargets);
      _disclosureAccepted = snapshot.disclosureAccepted;
    } else if (resetDraft) {
      _invalidateDraft(
        invalidateAvailability:
            previous == null ||
            previous.serviceConnected != snapshot.serviceConnected,
      );
    }
    if (!keepMessage) {
      _message = null;
    }
    if (previous != null &&
        previous.serviceConnected != snapshot.serviceConnected) {
      _connectionMessage =
          'Accessibility connection changed. Review the disclosure and agree again, then select apps for a fresh test. Enabling alone never starts a test.';
    }
    _notify();
  }

  bool _requiresFreshDraft(
    GuardQualificationSnapshot? previous,
    GuardQualificationSnapshot next,
  ) {
    if (next.isActive) return false;
    if (previous == null || previous.isActive) return true;

    // A repeated, unchanged inactive snapshot is only a status confirmation.
    // Preserve consent and selection entered after that state arrived. Any
    // lifecycle or prerequisite change invalidates the draft so a reconnect,
    // permission loss, interruption, or newly terminal state cannot reuse it.
    return previous.platform != next.platform ||
        previous.status != next.status ||
        previous.serviceConnected != next.serviceConnected ||
        previous.disclosureAccepted != next.disclosureAccepted ||
        previous.detailCode != next.detailCode;
  }

  bool _canApply(int generation) => !_disposed && generation == _generation;

  void _invalidateDraft({
    bool clearSelection = true,
    bool invalidateAvailability = false,
  }) {
    _draftGeneration++;
    _disclosureAccepted = false;
    if (clearSelection) _selection.clear();
    if (invalidateAvailability) _availabilityExpiresAt = null;
  }

  void _notify() {
    if (_disposed) return;
    for (final listener in List<GuardQualificationListener>.of(_listeners)) {
      listener();
    }
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _generation++;
    _cancelAvailability();
    _availabilityExpiresAt = null;
    _timer?.cancel();
    _timer = null;
    _service.cancelPending();
    _listeners.clear();
  }
}

const _terminalRecoveryStatuses = <GuardQualificationStatus>{
  GuardQualificationStatus.completed,
  GuardQualificationStatus.ended,
  GuardQualificationStatus.interrupted,
  GuardQualificationStatus.error,
};

const _terminalRecoveryDetailCodes = <String?>{
  'service_interrupted',
  'service_disconnected',
  'service_reconnected',
  'consent_withdrawn',
  'prerequisite_lost',
  'global_action_failed',
  'event_delivery_unavailable',
  'clock_invalid',
  'interrupted',
  'error',
};
