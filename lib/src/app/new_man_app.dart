import 'package:flutter/material.dart';

import '../controllers/app_controller.dart';
import '../features/accountability/presentation/accountability_screen.dart';
import '../features/focus/presentation/focus_screen.dart';
import '../features/settings/presentation/more_screen.dart';
import '../features/today/presentation/today_screen.dart';
import '../features/tasks/application/task_service.dart';
import '../features/word/presentation/word_screen.dart';
import 'theme/new_man_theme.dart';

class NewManApp extends StatelessWidget {
  const NewManApp({required this.controller, this.taskService, super.key});

  final AppController controller;
  final TaskService? taskService;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Man',
      debugShowCheckedModeBanner: false,
      theme: NewManTheme.light,
      darkTheme: NewManTheme.dark,
      themeMode: ThemeMode.system,
      home: AnimatedBuilder(
        animation: controller,
        builder: (context, _) =>
            NewManShell(controller: controller, taskService: taskService),
      ),
    );
  }
}

class NewManShell extends StatelessWidget {
  const NewManShell({required this.controller, this.taskService, super.key});

  final AppController controller;
  final TaskService? taskService;

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
      TodayScreen(taskService: taskService),
      WordScreen(controller: controller),
      const FocusScreen(),
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
