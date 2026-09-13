import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';

import '../../../theme/app_theme.dart';
import '../../../widgets/status_badge_widget.dart';
import '../models/transaction_model.dart';
import '../../../providers/app_providers.dart';
import '../../../l10n/app_strings.dart';
import '../../transaction_detail_screen/transaction_detail_screen.dart';

class TransactionListWidget extends StatefulWidget {
  const TransactionListWidget({super.key});

  @override
  State<TransactionListWidget> createState() => _TransactionListWidgetState();
}

class _TransactionListWidgetState extends State<TransactionListWidget> {
  late Future<List<TransactionModel>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _transactionsFuture = _fetchTransactions();
  }

  Future<List<TransactionModel>> _fetchTransactions() async {
    final client = Supabase.instance.client;
    final userId = client.auth.currentUser?.id;
    if (userId == null) return [];

    final response = await client
        .from('transactions')
        .select()
        .eq('user_id', userId)
        .order('transaction_date', ascending: false)
        .limit(20);

    return (response as List)
        .map((item) => TransactionModel.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().languageCode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header
        Row(
          children: [
            Text(
              AppStrings.get('recent_transactions', locale),
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppTheme.textPrimaryDark,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {},
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                AppStrings.get('see_all', locale),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: AppTheme.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        FutureBuilder<List<TransactionModel>>(
          future: _transactionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return _buildLoadingSkeleton();
            }

            if (snapshot.hasError) {
              return _buildErrorState(snapshot.error.toString());
            }

            final transactions = snapshot.data ?? [];

            if (transactions.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _StaggeredTransactionItem(
                data: transactions[index].toDisplayMap(),
                index: index,
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(
        5,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            height: 70,
            decoration: BoxDecoration(
              color: AppTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const SizedBox(width: 14),
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: AppTheme.textMutedDark.withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 12,
                        width: 120,
                        decoration: BoxDecoration(
                          color: AppTheme.textMutedDark.withAlpha(40),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        height: 10,
                        width: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.textMutedDark.withAlpha(25),
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    final locale = context.read<LocaleProvider>().languageCode;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: AppTheme.error, size: 32),
          const SizedBox(height: 8),
          Text(
            AppStrings.get('could_not_load', locale),
            style: TextStyle(
              color: AppTheme.textPrimaryDark,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          TextButton(
            onPressed: () {
              setState(() {
                _transactionsFuture = _fetchTransactions();
              });
            },
            child: Text(
              AppStrings.get('retry', locale),
              style: TextStyle(color: AppTheme.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final locale = context.read<LocaleProvider>().languageCode;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32),
      alignment: Alignment.center,
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_outlined,
            color: AppTheme.textMutedDark,
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            AppStrings.get('no_transactions', locale),
            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ── Staggered entrance transaction item ───────────────────────────
class _StaggeredTransactionItem extends StatefulWidget {
  final Map<String, dynamic> data;
  final int index;

  const _StaggeredTransactionItem({required this.data, required this.index});

  @override
  State<_StaggeredTransactionItem> createState() =>
      _StaggeredTransactionItemState();
}

class _StaggeredTransactionItemState extends State<_StaggeredTransactionItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0.04, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );

    Future.delayed(
      Duration(milliseconds: (widget.index * 55).clamp(0, 400)),
      () {
        if (mounted) _controller.forward();
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: TransactionItemWidget(data: widget.data),
      ),
    );
  }
}

// ── Transaction item — ANATOMY LOCKED ────────────────────────────
class TransactionItemWidget extends StatelessWidget {
  final Map<String, dynamic> data;

  const TransactionItemWidget({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isCredit = data['isCredit'] as bool;
    final amount = data['amount'] as double;
    final statusStr = data['status'] as String;
    final status = statusStr == 'pending'
        ? TransactionStatus.pending
        : statusStr == 'failed'
        ? TransactionStatus.failed
        : TransactionStatus.completed;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => TransactionDetailScreen(transaction: data),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        splashColor: AppTheme.primary.withAlpha(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: AppTheme.surfaceDark,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: statusStr == 'pending'
                  ? AppTheme.warning.withAlpha(64)
                  : const Color(0xFF1E1E2A),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Circular avatar
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Color(data['avatarColor'] as int).withAlpha(46),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _iconFromName(data['icon'] as String),
                  color: Color(data['avatarColor'] as int),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Name + date + category
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['name'] as String,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppTheme.textPrimaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      data['date'] as String,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppTheme.textMutedDark,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Amount + status
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isCredit ? '+' : '-'}\$${_formatAmount(amount)}',
                    style: TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isCredit
                          ? AppTheme.success
                          : AppTheme.textPrimaryDark,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 4),
                  StatusBadgeWidget(status: status, compact: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 1000) {
      final parts = amount.toStringAsFixed(2).split('.');
      final intPart = parts[0];
      final buffer = StringBuffer();
      for (int i = 0; i < intPart.length; i++) {
        if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
        buffer.write(intPart[i]);
      }
      return '$buffer.${parts[1]}';
    }
    return amount.toStringAsFixed(2);
  }

  IconData _iconFromName(String name) {
    switch (name) {
      case 'arrow_downward_rounded':
        return Icons.arrow_downward_rounded;
      case 'arrow_upward_rounded':
        return Icons.arrow_upward_rounded;
      case 'play_circle_outline_rounded':
        return Icons.play_circle_outline_rounded;
      case 'mail_outline_rounded':
        return Icons.mail_outline_rounded;
      case 'business_center_outlined':
        return Icons.business_center_outlined;
      case 'shopping_cart_outlined':
        return Icons.shopping_cart_outlined;
      case 'bolt_rounded':
        return Icons.bolt_rounded;
      case 'directions_car_outlined':
        return Icons.directions_car_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }
}
