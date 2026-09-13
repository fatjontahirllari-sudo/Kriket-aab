import 'package:flutter/material.dart';
import '../../widgets/coming_soon_widget.dart';

class LiveSupportChatScreen extends StatelessWidget {
  const LiveSupportChatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      titleKey: 'support',
      icon: Icons.support_agent_rounded,
    );
  }
}
