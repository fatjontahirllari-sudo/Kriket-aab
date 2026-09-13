import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import '../providers/app_providers.dart';
import '../l10n/app_strings.dart';

class ComingSoonScreen extends StatefulWidget {
  final String titleKey;
  final String? customTitle;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.titleKey,
    this.customTitle,
    required this.icon,
  });

  @override
  State<ComingSoonScreen> createState() => _ComingSoonScreenState();
}

class _ComingSoonScreenState extends State<ComingSoonScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;
  bool _notified = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getTitle(String locale) {
    if (widget.customTitle != null) return widget.customTitle!;
    return AppStrings.get(widget.titleKey, locale);
  }

  String _getComingSoonLabel(String locale) {
    const map = {
      'en': 'Coming Soon',
      'sq': 'Së Shpejti',
      'el': 'Έρχεται Σύντομα',
    };
    return map[locale] ?? 'Coming Soon';
  }

  String _getDescription(String locale) {
    const map = {
      'en': 'This feature will be available in a future update.',
      'sq':
          'Kjo veçori do të jetë e disponueshme në një përditësim të ardhshëm.',
      'el': 'Αυτή η λειτουργία θα είναι διαθέσιμη σε μελλοντική ενημέρωση.',
    };
    return map[locale] ?? 'This feature will be available in a future update.';
  }

  String _getNotifyLabel(String locale) {
    const map = {'en': 'Notify Me', 'sq': 'Njoftomë', 'el': 'Ειδοποίησέ με'};
    return map[locale] ?? 'Notify Me';
  }

  String _getNotifiedLabel(String locale) {
    const map = {
      'en': "You're on the list!",
      'sq': 'Jeni në listë!',
      'el': 'Είστε στη λίστα!',
    };
    return map[locale] ?? "You're on the list!";
  }

  String _getBackLabel(String locale) {
    const map = {'en': 'Go Back', 'sq': 'Kthehu', 'el': 'Πίσω'};
    return map[locale] ?? 'Go Back';
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleProvider>().languageCode;
    final isDark = context.watch<ThemeProvider>().isDark;
    final bg = isDark ? AppTheme.backgroundDark : AppTheme.backgroundLight;
    final surface = isDark ? AppTheme.surfaceVariantDark : Colors.white;
    final textPrimary = isDark
        ? AppTheme.textPrimaryDark
        : const Color(0xFF1A1A2E);
    final textSecondary = isDark
        ? AppTheme.textSecondaryDark
        : const Color(0xFF6B7280);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: textPrimary,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          _getTitle(locale),
          style: GoogleFonts.inter(
            color: textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Animated icon container
                ScaleTransition(
                  scale: _pulseAnimation,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppTheme.primary, AppTheme.secondary],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withAlpha(77),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: Icon(widget.icon, color: Colors.white, size: 50),
                  ),
                ),

                const SizedBox(height: 32),

                // "Coming Soon" badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primary.withAlpha(38),
                        AppTheme.secondary.withAlpha(38),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(102),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    _getComingSoonLabel(locale),
                    style: GoogleFonts.inter(
                      color: AppTheme.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Feature title
                Text(
                  _getTitle(locale),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),

                const SizedBox(height: 12),

                // Description
                Text(
                  _getDescription(locale),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: textSecondary,
                    fontSize: 15,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 40),

                // Notify Me button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: _notified
                      ? Container(
                          decoration: BoxDecoration(
                            color: AppTheme.successContainer,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: AppTheme.success.withAlpha(102),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle_rounded,
                                color: AppTheme.success,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getNotifiedLabel(locale),
                                style: GoogleFonts.inter(
                                  color: AppTheme.success,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ElevatedButton(
                          onPressed: () => setState(() => _notified = true),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.notifications_outlined,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _getNotifyLabel(locale),
                                style: GoogleFonts.inter(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),

                const SizedBox(height: 16),

                // Go back button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: textSecondary,
                      side: BorderSide(
                        color: isDark
                            ? AppTheme.textMutedDark
                            : const Color(0xFFD1D5DB),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      _getBackLabel(locale),
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
