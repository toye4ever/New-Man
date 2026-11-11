import '../domain/guard_qualification.dart';
import '../platform/method_channel_guard_qualification.dart';

abstract interface class GuardQualificationService
    implements GuardQualificationGateway {
  void cancelPending();
}

GuardQualificationService createGuardQualificationService() =>
    DefaultGuardQualificationService(
      gateway: createGuardQualificationGateway(),
    );

class DefaultGuardQualificationService implements GuardQualificationService {
  const DefaultGuardQualificationService({
    required GuardQualificationGateway gateway,
  }) : _gateway = gateway;

  final GuardQualificationGateway _gateway;

  @override
  Future<GuardQualificationSnapshot> getStatus() => _gateway.getStatus();

  @override
  Future<GuardQualificationSnapshot> start(
    GuardQualificationStartRequest request,
  ) => _gateway.start(request);

  @override
  Future<GuardQualificationSnapshot> pause() => _gateway.pause();

  @override
  Future<GuardQualificationSnapshot> resume() => _gateway.resume();

  @override
  Future<GuardQualificationSnapshot> end() => _gateway.end();

  @override
  Future<void> openAccessibilitySettings() =>
      _gateway.openAccessibilitySettings();

  @override
  void cancelPending() {
    final gateway = _gateway;
    if (gateway is GuardQualificationPendingCalls) {
      (gateway as GuardQualificationPendingCalls).cancelPending();
    }
  }
}
