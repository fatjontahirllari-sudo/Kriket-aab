import 'package:flutter/material.dart';
import '../../widgets/coming_soon_widget.dart';

class PdfStatementsScreen extends StatelessWidget {
  const PdfStatementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ComingSoonScreen(
      titleKey: 'statements',
      icon: Icons.description_rounded,
    );
  }
}
