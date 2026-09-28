import '../domain/scripture_reference.dart';

class ScriptureTextResult {
  const ScriptureTextResult({
    required this.reference,
    required this.text,
    this.notice,
  });

  final String reference;
  final String text;
  final String? notice;
}

class ScriptureUnavailableException implements Exception {
  const ScriptureUnavailableException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Translation/provider-independent Scripture text boundary.
abstract interface class ScriptureRepository {
  Future<ScriptureTextResult> getPassage(ScriptureReference reference);
}
