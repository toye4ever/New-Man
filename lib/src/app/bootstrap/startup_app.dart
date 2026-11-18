import 'package:flutter/material.dart';

import '../new_man_app.dart';
import '../theme/new_man_theme.dart';
import 'local_data_bootstrap.dart';

Future<Widget> buildStartupApp(
  Future<LocalDataBootstrapResult> Function() bootstrap,
) async {
  final LocalDataBootstrapResult localData;
  try {
    localData = await bootstrap();
  } on LocalDataRecoveryRequired {
    return const _LocalDataBlockedApp();
  }

  return NewManApp(
    controller: localData.controller,
    taskService: localData.taskService,
  );
}

/// This screen has no access to the database, preferences, or app shell.
class _LocalDataBlockedApp extends StatelessWidget {
  const _LocalDataBlockedApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'New Man',
      debugShowCheckedModeBanner: false,
      theme: NewManTheme.light,
      darkTheme: NewManTheme.dark,
      home: Scaffold(
        appBar: AppBar(title: const Text('New Man')),
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'New Man paused to protect your data',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'New Man couldn’t verify its saved data. '
                      'Your existing data was left in place.',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Don’t uninstall New Man or clear its storage. '
                      'That won’t fix this and could remove your saved data.',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
