import 'package:flutter/material.dart';

import '../../../controllers/app_controller.dart';
import '../../../screens/settings_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({required this.controller, super.key});

  final AppController controller;

  @override
  Widget build(BuildContext context) {
    return SettingsScreen(controller: controller);
  }
}
