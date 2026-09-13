import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/app_strings.dart';
import '../../providers/app_providers.dart';
import '../../theme/app_theme.dart';
import './widgets/receive_link_widget.dart';
import './widgets/request_step_widget.dart';
import './widgets/request_tracker_widget.dart';

enum _ReceiveTab { request, tracker }

class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen>
    with SingleTickerProviderStateMixin {
  _ReceiveTab _activeTab = _ReceiveTab.request;
  bool _showLink = false;
  Map<String, dynamic>? _lastContact;
  double _lastAmount = 0;
  String _lastNote = '';

  late AnimationController _tabAnimController;
  late Animation<double> _tabAnimation;

  @override
  void initState() {
    super.initState();
    _tabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );
    _tabAnimation = CurvedAnimation(
      parent: _tabAnimController,
      curve: Curves.easeOutCubic,
    );
    _tabAnimController.forward();
  }

  @override
  void dispose() {
    _tabAnimController.dispose();
    super.dispose();
  }

  void _switchTab(_ReceiveTab tab) {
    if (_activeTab == tab) return;
    _tabAnimController.forward(from: 0);
    setState(() {
      _activeTab = tab;
      _showLink = false;
    });
  }

  void _onRequestCreated(
    Map<String, dynamic> contact,
    double amount,
    String note,
  ) {
    setState(() {
      _lastContact = contact;
      _lastAmount = amount;
      _lastNote = note;
      _showLink = true;
    });
  }

  void _onDone() {
    setState(() {
      _showLink = false;
      _activeTab = _ReceiveTab.tracker;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().languageCode;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        child: Column(
          children: [
            // AppBar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariantDark,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 16,
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      AppStrings.get('receive_money', locale),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppTheme.textPrimaryDark,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 40),
                ],
              ),
            ),

            // Tab switcher (hidden when showing link)
            if (!_showLink) ...[
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 4,
                ),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceVariantDark,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      _TabButton(
                        label: AppStrings.get('request', locale),
                        icon: Icons.south_west_rounded,
                        isSelected: _activeTab == _ReceiveTab.request,
                        onTap: () => _switchTab(_ReceiveTab.request),
                      ),
                      _TabButton(
                        label: AppStrings.get('tracker', locale),
                        icon: Icons.track_changes_rounded,
                        isSelected: _activeTab == _ReceiveTab.tracker,
                        onTap: () => _switchTab(_ReceiveTab.tracker),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Content
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                  child: SlideTransition(
                    position:
                        Tween<Offset>(
                          begin: const Offset(0.03, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                    child: child,
                  ),
                ),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_showLink && _lastContact != null) {
      return ReceiveLinkWidget(
        key: const ValueKey('link'),
        contact: _lastContact!,
        amount: _lastAmount,
        note: _lastNote,
        onDone: _onDone,
      );
    }

    switch (_activeTab) {
      case _ReceiveTab.request:
        return RequestStepWidget(
          key: const ValueKey('request'),
          onRequestCreated: _onRequestCreated,
        );
      case _ReceiveTab.tracker:
        return const RequestTrackerWidget(key: ValueKey('tracker'));
    }
  }
}

// ── Tab button ────────────────────────────────────────────────────
class _TabButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.surfaceDark : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected
                    ? AppTheme.primary
                    : AppTheme.textSecondaryDark,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primary
                      : AppTheme.textSecondaryDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
