import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../features/focus/presentation/focus_screen.dart';
import '../features/settings/domain/appearance_preferences.dart';
import '../features/accountability/presentation/accountability_screen.dart';
import '../features/settings/presentation/more_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/tasks/application/task_service.dart';
import '../features/word/presentation/word_screen.dart';
import 'developer_tools_policy.dart';
import 'theme/new_man_theme.dart';

class NewManApp extends StatelessWidget {
  const NewManApp({required this.controller, this.taskService, super.key});

  final AppController controller;
  final TaskService? taskService;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) => MaterialApp(
        title: 'New Man',
        debugShowCheckedModeBanner: false,
        theme: NewManTheme.build(
          Brightness.light,
          controller.appearance.accent,
        ),
        darkTheme: NewManTheme.build(
          Brightness.dark,
          controller.appearance.accent,
        ),
        themeMode: switch (controller.appearance.mode) {
          AppearanceMode.system => ThemeMode.system,
          AppearanceMode.light => ThemeMode.light,
          AppearanceMode.dark => ThemeMode.dark,
        },
        home: NewManShell(controller: controller, taskService: taskService),
      ),
    );
  }
}

class NewManShell extends StatelessWidget {
  const NewManShell({
    required this.controller,
    this.taskService,
    this.developerToolsOptIn,
    super.key,
  });

  final AppController controller;
  final TaskService? taskService;

  /// Optional define value seam for deterministic shell tests. The actual build
  /// mode is always checked by [developerGuardToolsEnabled].
  final bool? developerToolsOptIn;

  static const _destinations = <NavigationDestination>[
    NavigationDestination(
      icon: Icon(Icons.today_outlined),
      selectedIcon: Icon(Icons.today),
      label: 'Today',
    ),
    NavigationDestination(
      icon: Icon(Icons.auto_stories_outlined),
      selectedIcon: Icon(Icons.auto_stories),
      label: 'Word',
    ),
    NavigationDestination(
      icon: Icon(Icons.center_focus_strong_outlined),
      selectedIcon: Icon(Icons.center_focus_strong),
      label: 'Focus',
    ),
    NavigationDestination(
      icon: Icon(Icons.handshake_outlined),
      selectedIcon: Icon(Icons.handshake),
      label: 'Accountability',
    ),
    NavigationDestination(
      icon: Icon(Icons.more_horiz),
      selectedIcon: Icon(Icons.more),
      label: 'More',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      TodayScreen(
        taskService: taskService,
        onOpenWord: () => controller.selectDestination(1),
      ),
      WordScreen(controller: controller),
      developerGuardToolsEnabled(
            isDebugMode: kDebugMode,
            optedIn: developerToolsOptIn ?? developerGuardToolsOptedIn,
          )
          ? const FocusScreen()
          : const _DeferredFocusScreen(),
      const AccountabilityScreen(),
      MoreScreen(controller: controller),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 960;
        final content = IndexedStack(
          index: controller.selectedDestination,
          children: pages,
        );

        if (wide) {
          return Scaffold(
            body: Row(
              children: <Widget>[
                NavigationRail(
                  selectedIndex: controller.selectedDestination,
                  onDestinationSelected: controller.selectDestination,
                  labelType: NavigationRailLabelType.all,
                  leading: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: _NewManMark(),
                  ),
                  destinations: _destinations
                      .map(
                        (item) => NavigationRailDestination(
                          icon: item.icon,
                          selectedIcon: item.selectedIcon,
                          label: Text(item.label),
                        ),
                      )
                      .toList(),
                ),
                const VerticalDivider(width: 1),
                Expanded(child: content),
              ],
            ),
          );
        }

        return Scaffold(
          body: content,
          bottomNavigationBar: NavigationBar(
            selectedIndex: controller.selectedDestination,
            onDestinationSelected: controller.selectDestination,
            destinations: _destinations,
          ),
        );
      },
    );
  }
}

class _DeferredFocusScreen extends StatelessWidget {
  const _DeferredFocusScreen();

  @override
  Widget build(BuildContext context) => const SafeArea(
    child: Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Focus tools are not part of this beta.',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
}

class _NewManMark extends StatelessWidget {
  const _NewManMark();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'New Man',
      child: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.auto_stories,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}
