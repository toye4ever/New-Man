import 'package:flutter/material.dart';

import '../../../shared/widgets/milestone_placeholder.dart';

class FocusScreen extends StatelessWidget {
  const FocusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MilestonePlaceholder(
      title: 'Focus',
      description:
          'Focus sessions and attention-protection tools are reserved for a later milestone.',
      icon: Icons.center_focus_strong_outlined,
    );
  }
}
