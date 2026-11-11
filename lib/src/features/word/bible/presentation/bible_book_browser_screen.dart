import 'package:flutter/material.dart';

import '../../../../controllers/app_controller.dart';
import '../../../../screens/reader_screen.dart';
import '../../../../widgets/page_header.dart';
import '../../../../widgets/responsive_content.dart';
import '../application/bible_reader_request.dart';
import '../domain/bible_books.dart';
import '../domain/scripture_reference.dart';
import '../../translations/domain/bible_translation.dart';

class BibleBookBrowserScreen extends StatefulWidget {
  const BibleBookBrowserScreen({
    required this.controller,
    this.readerBuilder,
    super.key,
  });

  final AppController controller;
  final Widget Function(BuildContext context, BibleReaderRequest request)?
  readerBuilder;

  @override
  State<BibleBookBrowserScreen> createState() => _BibleBookBrowserScreenState();
}

class _BibleBookBrowserScreenState extends State<BibleBookBrowserScreen> {
  final _referenceKey = GlobalKey();
  final _viewportKey = GlobalKey();
  bool _compactSearch = false;
  AppController get controller => widget.controller;

  void _updateSearchVisibility() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final control = _referenceKey.currentContext?.findRenderObject();
      final viewport = _viewportKey.currentContext?.findRenderObject();
      if (control is! RenderBox || viewport is! RenderBox) return;
      final bottom = control.localToGlobal(Offset(0, control.size.height)).dy;
      final hidden = bottom <= viewport.localToGlobal(Offset.zero).dy;
      if (hidden != _compactSearch) setState(() => _compactSearch = hidden);
    });
  }

  void _openReference() {
    final request = BibleReaderRequest(
      references: [
        ScriptureReference(
          book: controller.lastReaderPosition?.book ?? 'Matthew',
          startChapter: controller.lastReaderPosition?.chapter ?? 5,
        ),
      ],
      initialTranslation:
          controller.lastReaderPosition?.translation ??
          _defaultTranslation(controller),
      expandGoTo: true,
    );
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (context) =>
            widget.readerBuilder?.call(context, request) ??
            ReaderScreen(controller: controller, request: request),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      key: _viewportKey,
      children: [
        NotificationListener<ScrollNotification>(
          onNotification: (_) {
            _updateSearchVisibility();
            return false;
          },
          child: ResponsiveContent(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                LayoutBuilder(
                  builder: (context, constraints) {
                    final action = OutlinedButton.icon(
                      key: _referenceKey,
                      onPressed: _openReference,
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Open a reference'),
                    );
                    if (constraints.maxWidth < 600) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Bible',
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                          const SizedBox(height: 12),
                          action,
                        ],
                      );
                    }
                    return PageHeader(
                      title: 'Bible',
                      subtitle: 'Choose a book, then select a chapter.',
                      action: action,
                    );
                  },
                ),
                const SizedBox(height: 24),
                _BookSection(
                  title: 'Old Testament',
                  books: bibleBooks
                      .where((book) => book.testament == 'OT')
                      .toList(),
                  onSelected: (book) => _openBook(context, book),
                ),
                const SizedBox(height: 32),
                _BookSection(
                  title: 'New Testament',
                  books: bibleBooks
                      .where((book) => book.testament == 'NT')
                      .toList(),
                  onSelected: (book) => _openBook(context, book),
                ),
              ],
            ),
          ),
        ),
        if (_compactSearch)
          Positioned(
            right: 16,
            bottom: 16,
            child: SafeArea(
              child: IconButton.filled(
                tooltip: 'Search Bible',
                onPressed: _openReference,
                icon: const Icon(Icons.search),
              ),
            ),
          ),
      ],
    );
  }

  void _openBook(BuildContext context, BibleBook book) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BibleChapterSelectorScreen(
          controller: controller,
          book: book,
          readerBuilder: widget.readerBuilder,
        ),
      ),
    );
  }
}

class BibleChapterSelectorScreen extends StatelessWidget {
  const BibleChapterSelectorScreen({
    required this.controller,
    required this.book,
    this.readerBuilder,
    super.key,
  });

  final AppController controller;
  final BibleBook book;
  final Widget Function(BuildContext context, BibleReaderRequest request)?
  readerBuilder;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(book.name)),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final columns = switch (constraints.maxWidth) {
              >= 900 => 10,
              >= 600 => 8,
              >= 420 => 6,
              _ => 4,
            };
            return GridView.builder(
              padding: const EdgeInsets.all(24),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.25,
              ),
              itemCount: book.chapterCount,
              itemBuilder: (context, index) {
                final chapter = index + 1;
                return Semantics(
                  button: true,
                  label: '${book.name} chapter $chapter',
                  child: OutlinedButton(
                    onPressed: () => _openChapter(context, chapter),
                    child: Text('$chapter'),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  void _openChapter(BuildContext context, int chapter) {
    final request = BibleReaderRequest.manual(
      references: <ScriptureReference>[
        ScriptureReference(book: book.name, startChapter: chapter),
      ],
      initialTranslation:
          controller.lastReaderPosition?.translation ??
          _defaultTranslation(controller),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (context) =>
            readerBuilder?.call(context, request) ??
            ReaderScreen(controller: controller, request: request),
      ),
    );
  }
}

class _BookSection extends StatelessWidget {
  const _BookSection({
    required this.title,
    required this.books,
    required this.onSelected,
  });

  final String title;
  final List<BibleBook> books;
  final ValueChanged<BibleBook> onSelected;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = switch (constraints.maxWidth) {
              >= 900 => (constraints.maxWidth - 48) / 4,
              >= 600 => (constraints.maxWidth - 32) / 3,
              _ => (constraints.maxWidth - 16) / 2,
            };
            return Wrap(
              spacing: 16,
              runSpacing: 12,
              children: books
                  .map(
                    (book) => SizedBox(
                      width: width,
                      child: Card(
                        child: InkWell(
                          onTap: () => onSelected(book),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  book.name,
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text('${book.chapterCount} chapters'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
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
