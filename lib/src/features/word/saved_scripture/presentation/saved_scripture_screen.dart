import 'package:flutter/material.dart';

import '../../../../controllers/app_controller.dart';
import '../../../../screens/reader_screen.dart';
import '../../bible/application/bible_reader_request.dart';
import '../../bible/domain/scripture_anchor.dart';
import '../application/saved_scripture_repository.dart';

class SavedScriptureScreen extends StatefulWidget {
  const SavedScriptureScreen({required this.controller, super.key});
  final AppController controller;

  @override
  State<SavedScriptureScreen> createState() => _SavedScriptureScreenState();
}

class _SavedScriptureScreenState extends State<SavedScriptureScreen> {
  int _section = 0;
  int _refresh = 0;
  SavedScriptureRepository get _repository =>
      widget.controller.savedScriptureRepository;
  void _reload() => setState(() => _refresh++);

  void _open(ScriptureAnchor anchor) => Navigator.of(context).push(
    MaterialPageRoute<void>(
      builder: (_) => ReaderScreen(
        controller: widget.controller,
        request: BibleReaderRequest.manual(references: [anchor.reference]),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: SegmentedButton<int>(
          segments: const [
            ButtonSegment(value: 0, label: Text('Bookmarks')),
            ButtonSegment(value: 1, label: Text('Highlights')),
            ButtonSegment(value: 2, label: Text('Notes')),
            ButtonSegment(value: 3, label: Text('History')),
          ],
          selected: {_section},
          onSelectionChanged: (value) =>
              setState(() => _section = value.single),
        ),
      ),
      Expanded(
        child: KeyedSubtree(
          key: ValueKey(_refresh),
          child: switch (_section) {
            0 => _items(
              _repository.loadBookmarks(),
              'No bookmarks yet.',
              (item) => item.anchor,
              (item) => _removeButton(
                'Remove bookmark',
                () => _repository.removeBookmark(item.anchor),
              ),
            ),
            1 => _items(
              _repository.loadHighlights(),
              'No highlights yet.',
              (item) => item.anchor,
              (item) => _removeButton(
                'Remove highlight',
                () => _repository.removeHighlight(item.anchor),
              ),
            ),
            2 => _items(
              _repository.loadNotes(),
              'No private notes yet.',
              (item) => item.anchor,
              (item) => _removeButton(
                'Delete note',
                () => _repository.deleteNote(item.id),
              ),
              subtitle: (item) => item.body,
              title: (item) => _formatAnchors(item.anchors),
            ),
            _ => Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () async {
                      await _repository.clearHistory();
                      _reload();
                    },
                    child: const Text('Clear history'),
                  ),
                ),
                Expanded(
                  child: _items(
                    _repository.loadHistory(),
                    'No reading history yet.',
                    (item) => item.anchor,
                    (item) => _removeButton(
                      'Delete history item',
                      () => _repository.deleteHistory(item.anchor),
                    ),
                  ),
                ),
              ],
            ),
          },
        ),
      ),
    ],
  );

  Widget _removeButton(String tooltip, Future<void> Function() remove) =>
      IconButton(
        tooltip: tooltip,
        icon: const Icon(Icons.delete_outline),
        onPressed: () async {
          await remove();
          _reload();
        },
      );

  Widget _items<T>(
    Future<List<T>> future,
    String empty,
    ScriptureAnchor Function(T) anchor,
    Widget Function(T) trailing, {
    String Function(T)? subtitle,
    String Function(T)? title,
  }) => FutureBuilder<List<T>>(
    future: future,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final items = snapshot.data!;
      if (items.isEmpty) return Center(child: Text(empty));
      return ListView(
        children: items
            .map(
              (item) => ListTile(
                title: Text(title?.call(item) ?? anchor(item).display),
                subtitle: subtitle == null
                    ? null
                    : Text(
                        subtitle(item),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                onTap: () => _open(anchor(item)),
                trailing: trailing(item),
              ),
            )
            .toList(),
      );
    },
  );

  String _formatAnchors(List<ScriptureAnchor> anchors) {
    if (anchors.length == 1) return anchors.single.display;
    final first = anchors.first;
    if (anchors.every((a) => a.book == first.book && a.chapter == first.chapter && a.startVerse != null && a.endVerse == null)) return '${first.book} ${first.chapter}:${anchors.map((a) => a.startVerse).join(', ')}';
    return anchors.map((a) => a.display).join(', ');
  }
}
