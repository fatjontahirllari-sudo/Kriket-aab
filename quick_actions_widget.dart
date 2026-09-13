// ANATOMY LOCKED: Row of 3 circular icon containers + labels below

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/app_providers.dart';
import '../../../l10n/app_strings.dart';

class QuickActionsWidget extends StatelessWidget {
  const QuickActionsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().languageCode;
    final actions = [
      _QuickAction(
        label: AppStrings.get('send', locale),
        icon: Icons.north_east_rounded,
        onTap: () => context.push(AppRoutes.sendMoney),
      ),
      _QuickAction(
        label: AppStrings.get('receive', locale),
        icon: Icons.south_west_rounded,
        onTap: () => context.push(AppRoutes.receiveMoney),
      ),
      _QuickAction(
        label: AppStrings.get('swap', locale),
        icon: Icons.swap_horiz_rounded,
        onTap: () {},
      ),
      _QuickAction(
        label: AppStrings.get('savings', locale),
        icon: Icons.savings_outlined,
        onTap: () => context.go(AppRoutes.savings),
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: actions.map((a) => _QuickActionButton(action: a)).toList(),
    );
  }
}

class _QuickAction {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });
}

class _QuickActionButton extends StatefulWidget {
  final _QuickAction action;

  const _QuickActionButton({required this.action});

  @override
  State<_QuickActionButton> createState() => _QuickActionButtonState();
}

class _QuickActionButtonState extends State<_QuickActionButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _scaleController.forward();
      },
      onTapUp: (_) {
        _scaleController.reverse();
        widget.action.onTap();
      },
      onTapCancel: () => _scaleController.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF2A2A3A), width: 1),
              ),
              child: Icon(
                widget.action.icon,
                color: AppTheme.textPrimaryDark,
                size: 24,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.action.label,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondaryDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
