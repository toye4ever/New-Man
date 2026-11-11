import 'package:flutter/material.dart';

import '../application/scripture_search.dart';
import 'scripture_search_preview.dart';

/// Returns a selected passage to the existing Reader, keeping query and
/// loading/error/empty states on their own route rather than in the passage.
class ScriptureSearchResultsScreen extends StatefulWidget {
  const ScriptureSearchResultsScreen({
    required this.query,
    required this.search,
    super.key,
  });
  final String query;
  final ScriptureSearch search;

  @override
  State<ScriptureSearchResultsScreen> createState() =>
      _ScriptureSearchResultsScreenState();
}

class _ScriptureSearchResultsScreenState
    extends State<ScriptureSearchResultsScreen> {
  late Future<List<ScriptureSearchResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = widget.search.search(widget.query);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Scripture search')),
    body: SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                'Results for “${widget.query}”',
                key: const ValueKey('search-query'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ScriptureSearchResult>>(
              future: _results,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Scripture search is unavailable. Check the installed KJV Bible.',
                        ),
                        TextButton(
                          onPressed: () => setState(() {
                            _results = widget.search.search(widget.query);
                          }),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                final results = snapshot.data ?? [];
                if (results.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      'No Scripture matches. Try a reference, quotation, or another topic.',
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(8, 0, 8, 24),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final result = results[index];
                    return ListTile(
                      title: Text(result.reference.display),
                      subtitle: ScriptureSearchPreview(
                        text: result.preview.isEmpty
                            ? result.topic ?? ''
                            : result.preview,
                        query: widget.query,
                      ),
                      onTap: () => Navigator.pop(context, result),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    ),
  );
}
