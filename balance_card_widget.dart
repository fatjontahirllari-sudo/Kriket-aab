// ANATOMY LOCKED: gradient card, "Current Balance" label top-left,
// large balance center-left, card number + expiry bottom-left,
// "Add Money" CTA button bottom-right

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';
import '../../../providers/app_providers.dart';
import '../../../l10n/app_strings.dart';

class BalanceCardWidget extends StatefulWidget {
  final bool balanceVisible;

  const BalanceCardWidget({super.key, required this.balanceVisible});

  @override
  State<BalanceCardWidget> createState() => _BalanceCardWidgetState();
}

class _BalanceCardWidgetState extends State<BalanceCardWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;
  late Animation<double> _glowAnimation;

  double? _balance;
  String? _cardNumber;
  String? _cardExpiry;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _glowAnimation = CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }

      final response = await Supabase.instance.client
          .from('user_profiles')
          .select('balance, card_number, card_expiry')
          .eq('id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _loading = false;
          if (response != null) {
            _balance = (response['balance'] as num?)?.toDouble();
            _cardNumber = response['card_number'] as String?;
            _cardExpiry = response['card_expiry'] as String?;
          }
        });
      }
    } catch (e) {
      debugPrint('[BalanceCard] Failed to load profile: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().languageCode;

    // Display card number: show last 4 digits masked, or placeholder
    final cardDisplay = _cardNumber != null && _cardNumber!.length >= 4
        ? '${_cardNumber!.substring(0, 4)} ••••'
        : '•••• ••••';
    final expiryDisplay = (_cardExpiry != null && _cardExpiry!.isNotEmpty)
        ? _cardExpiry!
        : '––/––';

    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (_, child) => Container(
        height: 196,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D3B2A), Color(0xFF0A2535), Color(0xFF0D1E33)],
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(
                0.15 + _glowAnimation.value * 0.12,
              ),
              blurRadius: 32 + _glowAnimation.value * 16,
              offset: const Offset(0, 8),
              spreadRadius: 0,
            ),
          ],
          border: Border.all(color: AppTheme.primary.withAlpha(46), width: 1),
        ),
        child: child,
      ),
      child: Stack(
        children: [
          // Circuit pattern overlay
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(painter: _CircuitPatternPainter()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: label + Kriket logo
                Row(
                  children: [
                    Text(
                      AppStrings.get('current_balance', locale),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.white.withAlpha(166),
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withAlpha(51),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 12,
                            color: AppTheme.primary,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Kriket',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Balance amount
                _loading
                    ? Container(
                        height: 34,
                        width: 140,
                        decoration: BoxDecoration(
                          color: Colors.white.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: widget.balanceVisible
                            ? Text(
                                _balance != null
                                    ? '\$${_formatBalance(_balance!)}'
                                    : '—',
                                key: const ValueKey('visible'),
                                style: const TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  letterSpacing: -0.5,
                                ),
                              )
                            : const Text(
                                '••••••••',
                                key: ValueKey('hidden'),
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 34,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                  letterSpacing: 4,
                                ),
                              ),
                      ),

                const Spacer(),

                // Bottom row: card number + expiry + CTA
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Num',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: Colors.white.withAlpha(128),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          cardDisplay,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Exp.',
                          style: TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 10,
                            color: Colors.white.withAlpha(128),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          expiryDisplay,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Add Money CTA button
                    GestureDetector(
                      onTap: () {},
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(115),
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(color: Colors.white.withAlpha(38)),
                        ),
                        child: Text(
                          AppStrings.get('add_money', locale),
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatBalance(double balance) {
    final parts = balance.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    final buffer = StringBuffer();
    for (int i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) buffer.write(',');
      buffer.write(intPart[i]);
    }
    return '$buffer.$decPart';
  }
}

// ── Circuit board decorative painter ─────────────────────────────
class _CircuitPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withAlpha(8)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Horizontal lines
    for (double y = 20; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width * 0.6, y), paint);
    }
    // Vertical lines
    for (double x = 40; x < size.width; x += 60) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height * 0.5), paint);
    }
    // Dots
    final dotPaint = Paint()
      ..color = Colors.white.withAlpha(15)
      ..style = PaintingStyle.fill;
    for (double x = 40; x < size.width; x += 60) {
      for (double y = 20; y < size.height; y += 40) {
        canvas.drawCircle(Offset(x, y), 2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
