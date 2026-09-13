import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum TransactionStatus { completed, pending, failed }

class StatusBadgeWidget extends StatelessWidget {
  final TransactionStatus status;
  final bool compact;

  const StatusBadgeWidget({
    super.key,
    required this.status,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;
    String label;
    IconData icon;

    switch (status) {
      case TransactionStatus.completed:
        bg = AppTheme.successContainer;
        fg = AppTheme.success;
        label = 'Completed';
        icon = Icons.check_circle_outline_rounded;
        break;
      case TransactionStatus.pending:
        bg = AppTheme.warningContainer;
        fg = AppTheme.warning;
        label = 'Pending';
        icon = Icons.schedule_rounded;
        break;
      case TransactionStatus.failed:
        bg = AppTheme.errorContainer;
        fg = AppTheme.error;
        label = 'Failed';
        icon = Icons.error_outline_rounded;
        break;
    }

    if (compact) {
      return Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(100),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Manrope',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: fg,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
