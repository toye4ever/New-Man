import 'package:flutter/material.dart';

import '../../../../controllers/app_controller.dart';
import '../../../../services/reference_parser.dart';
import '../../../../screens/reader_screen.dart';
import '../../../../widgets/page_header.dart';
import '../../../../widgets/responsive_content.dart';
import '../application/bible_reader_request.dart';
import '../../translations/domain/bible_translation.dart';

class OpenBibleScreen extends StatefulWidget {
  const OpenBibleScreen({
    required this.controller,
    this.readerBuilder,
    super.key,
  });

  final AppController controller;
  final Widget Function(BuildContext context, BibleReaderRequest request)?
  readerBuilder;

  @override
  State<OpenBibleScreen> createState() => _OpenBibleScreenState();
}

class _OpenBibleScreenState extends State<OpenBibleScreen> {
  final _referenceController = TextEditingController(text: 'Matthew 5');
  final _parser = ReferenceParser();
  String? _error;

  @override
  void dispose() {
    _referenceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ResponsiveContent(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const PageHeader(
            title: 'Open Bible',
            subtitle:
                'Open Scripture directly. A reading plan is not required.',
          ),
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _referenceController,
                    decoration: InputDecoration(
                      labelText: 'Book, chapter, or passage',
                      hintText: 'Romans 8:1-4',
                      helperText: 'Examples: Matthew 5, John 1-3, Romans 8:1-4',
                      errorText: _error,
                      border: const OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.go,
                    onSubmitted: (_) => _openBible(),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _openBible,
                    icon: const Icon(Icons.menu_book_outlined),
                    label: const Text('Open Bible'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openBible() {
    final result = _parser.parse(_referenceController.text);
    if (!result.isValid) {
      setState(() {
        _error = result.issues.isEmpty
            ? 'Enter a Bible book and chapter.'
            : result.issues.first.message;
      });
      return;
    }

    setState(() => _error = null);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) {
          final request = BibleReaderRequest.manual(
            references: result.references,
            initialTranslation:
                widget.controller.lastReaderPosition?.translation ??
                _defaultTranslation(widget.controller),
          );
          return widget.readerBuilder?.call(context, request) ??
              ReaderScreen(controller: widget.controller, request: request);
        },
      ),
    );
  }
}

BibleTranslation _defaultTranslation(AppController controller) {
  if (controller.installedTranslations.contains(BibleTranslation.kjv)) {
    return BibleTranslation.kjv;
  }
  if (controller.installedTranslations.contains(BibleTranslation.nlt)) {
    return BibleTranslation.nlt;
  }
  return BibleTranslation.kjv;
}
