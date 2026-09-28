import 'scripture_reference.dart';

class ReferenceParseIssue {
  const ReferenceParseIssue({required this.input, required this.message});

  final String input;
  final String message;
}

class ReferenceParseResult {
  const ReferenceParseResult({required this.references, required this.issues});

  final List<ScriptureReference> references;
  final List<ReferenceParseIssue> issues;

  bool get isValid => references.isNotEmpty && issues.isEmpty;
}
