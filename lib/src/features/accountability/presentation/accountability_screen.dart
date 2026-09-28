import 'package:flutter/material.dart';

import '../../../shared/widgets/milestone_placeholder.dart';

class AccountabilityScreen extends StatelessWidget {
  const AccountabilityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const MilestonePlaceholder(
      title: 'Accountability',
      description:
          'Trusted partners and consent-based check-ins are reserved for a later milestone.',
      icon: Icons.handshake_outlined,
    );
  }
}
