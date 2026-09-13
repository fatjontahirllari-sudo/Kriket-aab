import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import './widgets/balance_card_widget.dart';
import './widgets/home_app_bar_widget.dart';
import './widgets/quick_actions_widget.dart';
import './widgets/transaction_list_widget.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // TODO: Replace with Riverpod/Bloc for production
  bool _balanceVisible = true;

  void _toggleBalanceVisibility() {
    setState(() => _balanceVisible = !_balanceVisible);
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.of(context).size.width >= 600;

    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      body: SafeArea(
        bottom: false,
        child: isTablet
            ? _TabletLayout(
                balanceVisible: _balanceVisible,
                onToggleBalance: _toggleBalanceVisibility,
              )
            : _PhoneLayout(
                balanceVisible: _balanceVisible,
                onToggleBalance: _toggleBalanceVisibility,
              ),
      ),
    );
  }
}

// ── Phone layout ──────────────────────────────────────────────────
class _PhoneLayout extends StatelessWidget {
  final bool balanceVisible;
  final VoidCallback onToggleBalance;

  const _PhoneLayout({
    required this.balanceVisible,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: HomeAppBarWidget(
            balanceVisible: balanceVisible,
            onToggleBalance: onToggleBalance,
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: BalanceCardWidget(balanceVisible: balanceVisible),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: QuickActionsWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 28)),
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: TransactionListWidget(),
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// ── Tablet layout ─────────────────────────────────────────────────
class _TabletLayout extends StatelessWidget {
  final bool balanceVisible;
  final VoidCallback onToggleBalance;

  const _TabletLayout({
    required this.balanceVisible,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                HomeAppBarWidget(
                  balanceVisible: balanceVisible,
                  onToggleBalance: onToggleBalance,
                ),
                const SizedBox(height: 16),
                BalanceCardWidget(balanceVisible: balanceVisible),
                const SizedBox(height: 24),
                const QuickActionsWidget(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(0, 24, 24, 24),
            child: const TransactionListWidget(),
          ),
        ),
      ],
    );
  }
}
