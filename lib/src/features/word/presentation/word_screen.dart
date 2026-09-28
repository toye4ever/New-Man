import 'package:flutter/material.dart';

import '../../../controllers/app_controller.dart';
import '../../../screens/home_screen.dart';
import '../../../screens/plans_screen.dart';
import '../bible/presentation/bible_book_browser_screen.dart';
import '../translations/presentation/translation_manager_screen.dart';
import '../saved_scripture/presentation/saved_scripture_screen.dart';

class WordScreen extends StatelessWidget {
  const WordScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      HomeScreen(controller: controller),
      PlansScreen(controller: controller),
      BibleBookBrowserScreen(controller: controller),
      TranslationManagerScreen(controller: controller),
      SavedScriptureScreen(controller: controller),
    ];

    return Column(
      children: <Widget>[
        SafeArea(
          bottom: false,
          child: Material(
            color: Theme.of(context).colorScheme.surfaceContainer,
            child: SizedBox(
              width: double.infinity,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: SegmentedButton<int>(
                  segments: const <ButtonSegment<int>>[
                    ButtonSegment<int>(
                      value: 0,
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text('Word'),
                    ),
                    ButtonSegment<int>(
                      value: 1,
                      icon: Icon(Icons.library_books_outlined),
                      label: Text('Plans'),
                    ),
                    ButtonSegment<int>(
                      value: 2,
                      icon: Icon(Icons.menu_book_outlined),
                      label: Text('Bible'),
                    ),
                    ButtonSegment<int>(
                      value: 3,
                      icon: Icon(Icons.translate),
                      label: Text('Versions'),
                    ),
                    ButtonSegment<int>(
                      value: 4,
                      icon: Icon(Icons.bookmark_outline),
                      label: Text('Saved'),
                    ),
                  ],
                  selected: <int>{controller.selectedWordDestination},
                  onSelectionChanged: (selection) {
                    controller.selectWordDestination(selection.single);
                  },
                ),
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: controller.selectedWordDestination,
            children: pages,
          ),
        ),
      ],
    );
  }
}
