// V3 Glassmorphism AppBar — BackdropFilter blur, transparent, content shows through
// LOCKED: BackdropFilter is mandatory

import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class KriketAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool showBack;
  final List<Widget>? actions;
  final Widget? leading;
  final bool transparent;

  const KriketAppBar({
    super.key,
    required this.title,
    this.showBack = false,
    this.actions,
    this.leading,
    this.transparent = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: preferredSize.height + MediaQuery.of(context).padding.top,
          padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
          decoration: BoxDecoration(
            color: transparent
                ? Colors.transparent
                : AppTheme.backgroundDark.withAlpha(179),
            border: transparent
                ? null
                : const Border(
                    bottom: BorderSide(color: Color(0xFF1E1E2A), width: 1),
                  ),
          ),
          child: Row(
            children: [
              const SizedBox(width: 8),
              if (showBack)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariantDark,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: AppTheme.textPrimaryDark,
                    ),
                  ),
                )
              else if (leading != null)
                leading!
              else
                const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.textPrimaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                  textAlign: showBack ? TextAlign.center : TextAlign.start,
                ),
              ),
              if (actions != null) ...actions!,
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
