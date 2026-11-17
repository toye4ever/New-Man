import 'package:flutter/material.dart';

import '../../bible/domain/scripture_anchor.dart';
import '../application/saved_scripture_repository.dart';
import '../domain/saved_scripture.dart';

/// Owns only an in-memory draft. Cancellation never persists its text.
class PrivateNoteDialog extends StatefulWidget {
  PrivateNoteDialog({
    required this.repository,
    required List<ScriptureAnchor> anchors,
    super.key,
  }) : anchors = List.unmodifiable(anchors);

  final SavedScriptureRepository repository;
  final List<ScriptureAnchor> anchors;

  @override
  State<PrivateNoteDialog> createState() => _PrivateNoteDialogState();
}

class _PrivateNoteDialogState extends State<PrivateNoteDialog> {
  final _text = TextEditingController();
  final _createdAt = DateTime.now().toUtc();
  late final _noteId = 'note-${_createdAt.microsecondsSinceEpoch}';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    final body = _text.text.trim();
    if (body.isEmpty) {
      setState(() => _error = 'Enter a note before saving.');
      return;
    }
    final route = ModalRoute.of(context);
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.repository.saveNote(
        ScriptureNote(
          id: _noteId,
          anchors: widget.anchors,
          body: body,
          createdAt: _createdAt,
          updatedAt: DateTime.now().toUtc(),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the note. Please try again.';
      });
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    // Finish this dialog only; another route may have opened during the save.
    if (route != null && route.isActive) {
      final navigator = Navigator.of(context);
      if (route.isCurrent) {
        navigator.pop(true);
      } else {
        navigator.removeRoute(route, true);
      }
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: AlertDialog(
      title: Text(
        'Private note — ${widget.anchors.map((a) => a.display).join(', ')}',
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _text,
            enabled: !_saving,
            minLines: 3,
            maxLines: 8,
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Semantics(liveRegion: true, child: Text(_error!)),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Saving…' : 'Save'),
        ),
      ],
    ),
  );
}
