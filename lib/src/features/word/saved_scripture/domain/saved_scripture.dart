import '../../bible/domain/scripture_anchor.dart';

enum HighlightStyle { gold, green, blue, rose }

extension HighlightStyleLabel on HighlightStyle {
  String get storageValue => name;
  String get label => switch (this) {
    HighlightStyle.gold => 'Gold',
    HighlightStyle.green => 'Green',
    HighlightStyle.blue => 'Blue',
    HighlightStyle.rose => 'Rose',
  };

  static HighlightStyle fromStorage(String value) =>
      HighlightStyle.values.firstWhere(
        (style) => style.storageValue == value,
        orElse: () => HighlightStyle.gold,
      );
}

class ScriptureBookmark {
  const ScriptureBookmark({required this.anchor, required this.createdAt});
  final ScriptureAnchor anchor;
  final DateTime createdAt;
}

class ScriptureHighlight {
  const ScriptureHighlight({
    required this.anchor,
    required this.style,
    required this.updatedAt,
  });
  final ScriptureAnchor anchor;
  final HighlightStyle style;
  final DateTime updatedAt;
}

class ScriptureNote {
  ScriptureNote({
    required this.id,
    required List<ScriptureAnchor> anchors,
    required this.body,
    required this.createdAt,
    required this.updatedAt,
  }) : anchors = List<ScriptureAnchor>.unmodifiable(anchors);
  final String id;
  final List<ScriptureAnchor> anchors;
  ScriptureAnchor get anchor => anchors.first;
  final String body;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ReadingHistoryItem {
  const ReadingHistoryItem({required this.anchor, required this.openedAt});
  final ScriptureAnchor anchor;
  final DateTime openedAt;
}
