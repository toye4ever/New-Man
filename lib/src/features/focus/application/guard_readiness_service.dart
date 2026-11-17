import '../domain/guard_readiness.dart';
import '../platform/method_channel_guard_readiness.dart';

abstract interface class GuardReadinessService {
  Future<GuardReadinessReport> checkReadiness();
}

GuardReadinessService createGuardReadinessService() =>
    DefaultGuardReadinessService(probe: MethodChannelGuardReadinessProbe());

class DefaultGuardReadinessService implements GuardReadinessService {
  const DefaultGuardReadinessService({
    required GuardReadinessProbe probe,
    GuardReadinessEvaluator evaluator = const GuardReadinessEvaluator(),
  }) : _probe = probe,
       _evaluator = evaluator;

  final GuardReadinessProbe _probe;
  final GuardReadinessEvaluator _evaluator;

  @override
  Future<GuardReadinessReport> checkReadiness() async {
    try {
      // Bound only the read; timeout does not cancel or change native state.
      final snapshot = await _probe.probe().timeout(const Duration(seconds: 5));
      return _evaluator.evaluate(snapshot);
    } catch (_) {
      return GuardReadinessReport.probeFailed();
    }
  }
}
