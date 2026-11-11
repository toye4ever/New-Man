import 'package:flutter/material.dart';

class ScriptureSearchPreview extends StatelessWidget {
  const ScriptureSearchPreview({
    required this.text,
    required this.query,
    super.key,
  });
  final String text;
  final String query;
  @override
  Widget build(BuildContext context) {
    final words = RegExp(
      r'[a-zA-Z0-9]+',
    ).allMatches(query).map((m) => RegExp.escape(m.group(0)!)).toList();
    final pattern = words.isEmpty
        ? null
        : RegExp('\\b(${words.join('|')})\\b', caseSensitive: false);
    final matches = pattern?.allMatches(text).toList() ?? [];
    var start = matches.isEmpty || matches.first.start < 80
        ? 0
        : matches.first.start - 60;
    if (start > 0) {
      final boundary = text.indexOf(' ', start);
      if (boundary >= 0) start = boundary + 1;
    }
    final end = (start + 240).clamp(0, text.length);
    final preview =
        '${start > 0 ? '…' : ''}${text.substring(start, end)}${end < text.length ? '…' : ''}';
    final spans = <TextSpan>[];
    var cursor = 0;
    for (final match in pattern?.allMatches(preview) ?? <RegExpMatch>[]) {
      spans.add(TextSpan(text: preview.substring(cursor, match.start)));
      spans.add(
        TextSpan(
          text: preview.substring(match.start, match.end),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      );
      cursor = match.end;
    }
    spans.add(TextSpan(text: preview.substring(cursor)));
    return Text.rich(
      TextSpan(children: spans),
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
    );
  }
}
