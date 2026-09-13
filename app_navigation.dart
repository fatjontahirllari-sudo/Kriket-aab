import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../presentation/virtual_card_screen/virtual_card_screen.dart';
import '../providers/app_providers.dart';
import '../theme/app_theme.dart';

// V3 Liquid Glass BottomNav — BackdropFilter blur + frosted surface + animated pill
// LOCKED: BackdropFilter blur is mandatory. Never remove.

class _TabSpec {
  final String labelKey;
  final IconData icon;
  final IconData selectedIcon;
  final int? branchIndex; // null = stub tab

  const _TabSpec({
    required this.labelKey,
    required this.icon,
    required this.selectedIcon,
    this.branchIndex,
  });
}

class AppNavigation extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppNavigation({required this.navigationShell, super.key});

  @override
  State<AppNavigation> createState() => _AppNavigationState();
}

class _AppNavigationState extends State<AppNavigation>
    with SingleTickerProviderStateMixin {
  // TODO: Replace with Riverpod for production
  int _selectedVisualIndex = 0;

  late AnimationController _pillController;
  late Animation<double> _pillAnimation;
  int _prevIndex = 0;

  final List<_TabSpec> _tabs = const [
    _TabSpec(
      labelKey: 'home',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      branchIndex: 0,
    ),
    _TabSpec(
      labelKey: 'savings',
      icon: Icons.savings_outlined,
      selectedIcon: Icons.savings_rounded,
      branchIndex: 1,
    ),
    _TabSpec(
      labelKey: 'cards',
      icon: Icons.credit_card_outlined,
      selectedIcon: Icons.credit_card_rounded,
      branchIndex: 2, // now wired to VirtualCardScreen branch
    ),
    _TabSpec(
      labelKey: 'profile',
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      branchIndex: 3,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pillController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _pillAnimation = CurvedAnimation(
      parent: _pillController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _pillController.dispose();
    super.dispose();
  }

  void _onTabTapped(int visualIndex) {
    final spec = _tabs[visualIndex];

    // Stub tab — silently ignore
    if (spec.branchIndex == null) return;

    if (_selectedVisualIndex == visualIndex) return;

    setState(() {
      _prevIndex = _selectedVisualIndex;
      _selectedVisualIndex = visualIndex;
    });

    _pillController.forward(from: 0);
    widget.navigationShell.goBranch(
      spec.branchIndex!,
      initialLocation: spec.branchIndex == widget.navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final locale = context.watch<LocaleProvider>().languageCode;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        // LOCKED: BackdropFilter blur — never remove
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark.withAlpha(184),
            border: const Border(
              top: BorderSide(color: Color(0xFF2A2A3A), width: 1),
            ),
          ),
          padding: EdgeInsets.only(
            top: 12,
            bottom: bottomPadding + 12,
            left: 8,
            right: 8,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_tabs.length, (i) {
              final tab = _tabs[i];
              final isSelected = _selectedVisualIndex == i;
              final isStub = tab.branchIndex == null;

              return Expanded(
                child: GestureDetector(
                  onTap: () => _onTabTapped(i),
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(
                      vertical: 6,
                      horizontal: 4,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withAlpha(38)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            isSelected ? tab.selectedIcon : tab.icon,
                            key: ValueKey(isSelected),
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondaryDark,
                            size: 22,
                          ),
                        ),
                        const SizedBox(height: 4),
                        AnimatedDefaultTextStyle(
                          duration: const Duration(milliseconds: 200),
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? AppTheme.primary
                                : AppTheme.textSecondaryDark,
                          ),
                          child: Text(AppStrings.get(tab.labelKey, locale)),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
