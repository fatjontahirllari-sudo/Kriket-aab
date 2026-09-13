import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../theme/app_theme.dart';
import '../../routes/app_routes.dart';
import '../../providers/app_providers.dart';
import '../../l10n/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _pushNotifications = true;
  bool _transactionAlerts = true;
  bool _savingsReminders = false;
  bool _isLoggingOut = false;
  String? _kycStatus; // loaded from kyc_verifications table

  User? get _user => Supabase.instance.client.auth.currentUser;

  String get _displayName {
    final meta = _user?.userMetadata;
    if (meta != null && meta['full_name'] != null) {
      return meta['full_name'] as String;
    }
    final email = _user?.email ?? '';
    if (email.isNotEmpty) return email.split('@').first;
    return 'User';
  }

  String get _email => _user?.email ?? '—';

  String get _initials {
    final parts = _displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return _displayName.isNotEmpty ? _displayName[0].toUpperCase() : 'U';
  }

  Future<void> _logout() async {
    final confirmed = await _showLogoutDialog();
    if (!confirmed) return;
    setState(() => _isLoggingOut = true);
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) context.go(AppRoutes.signUpLogin);
    } catch (e) {
      if (mounted) {
        setState(() => _isLoggingOut = false);
        final locale = context.read<LocaleProvider>().languageCode;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.get('logout_failed', locale)),
            backgroundColor: AppTheme.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  Future<bool> _showLogoutDialog() async {
    final locale = context.read<LocaleProvider>().languageCode;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppTheme.surfaceVariantDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(
              AppStrings.get('log_out_q', locale),
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryDark,
              ),
            ),
            content: Text(
              AppStrings.get('log_out_desc', locale),
              style: const TextStyle(
                fontFamily: 'Manrope',
                color: AppTheme.textSecondaryDark,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(
                  AppStrings.get('cancel', locale),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(
                  AppStrings.get('log_out', locale),
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    color: AppTheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _showBiometricPrompt(BiometricProvider biometricProvider) async {
    final locale = context.read<LocaleProvider>().languageCode;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.get('biometric_mobile_only', locale)),
          backgroundColor: AppTheme.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final newValue = !biometricProvider.biometricEnabled;
    await biometricProvider.setBiometric(newValue);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            newValue
                ? AppStrings.get('biometric_enabled', locale)
                : AppStrings.get('biometric_disabled', locale),
          ),
          backgroundColor: newValue
              ? AppTheme.success
              : AppTheme.textSecondaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadKycStatus();
  }

  Future<void> _loadKycStatus() async {
    try {
      final client = Supabase.instance.client;
      final userId = client.auth.currentUser?.id;
      if (userId == null) return;

      final data = await client
          .from('kyc_verifications')
          .select('status')
          .eq('user_id', userId)
          .maybeSingle();

      if (mounted) {
        setState(() {
          _kycStatus = data?['status'] as String?;
        });
      }
    } catch (_) {
      // Silently ignore — KYC table may not exist yet
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final biometricProvider = context.watch<BiometricProvider>();
    final locale = localeProvider.languageCode;
    final isDark = themeProvider.isDark;
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
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // ── App Bar ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Row(
                  children: [
                    Text(
                      AppStrings.get('profile', locale),
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Avatar + Account Info ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: AppTheme.cardGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppTheme.primary.withAlpha(40),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [AppTheme.primary, Color(0xFF00A875)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primary.withAlpha(80),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _initials,
                            style: const TextStyle(
                              fontFamily: 'Manrope',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF003322),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _displayName,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: AppTheme.textPrimaryDark,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _email,
                              style: const TextStyle(
                                fontFamily: 'Manrope',
                                color: AppTheme.textSecondaryDark,
                                fontSize: 13,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            _KycStatusBadge(
                              kycStatus: _kycStatus,
                              locale: locale,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Quick Feature Links ───────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('features', locale),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                      childAspectRatio: 1.1,
                      children: [
                        _featureCard(
                          Icons.currency_exchange_rounded,
                          AppStrings.get('exchange_rates', locale),
                          AppRoutes.exchangeRates,
                          surface,
                          textPrimary,
                          isDark,
                        ),
                        _featureCard(
                          Icons.bar_chart_rounded,
                          AppStrings.get('analytics', locale),
                          AppRoutes.analytics,
                          surface,
                          textPrimary,
                          isDark,
                        ),
                        _featureCard(
                          Icons.credit_card_rounded,
                          AppStrings.get('virtual_card', locale),
                          AppRoutes.virtualCard,
                          surface,
                          textPrimary,
                          isDark,
                        ),
                        _featureCard(
                          Icons.picture_as_pdf_rounded,
                          AppStrings.get('statements', locale),
                          AppRoutes.statements,
                          surface,
                          textPrimary,
                          isDark,
                        ),
                        _featureCard(
                          Icons.verified_user_rounded,
                          AppStrings.get('kyc', locale),
                          AppRoutes.kyc,
                          surface,
                          textPrimary,
                          isDark,
                        ),
                        _featureCard(
                          Icons.support_agent_rounded,
                          AppStrings.get('support', locale),
                          AppRoutes.support,
                          surface,
                          textPrimary,
                          isDark,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // ── Appearance & Language ─────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('settings', locale),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Dark mode toggle
                    _settingsTile(
                      icon: isDark
                          ? Icons.dark_mode_rounded
                          : Icons.light_mode_rounded,
                      title: AppStrings.get('dark_mode', locale),
                      subtitle: isDark
                          ? AppStrings.get('dark_theme_active', locale)
                          : AppStrings.get('light_theme_active', locale),
                      trailing: Switch(
                        value: isDark,
                        onChanged: (_) => themeProvider.toggleTheme(),
                        activeThumbColor: AppTheme.primary,
                      ),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // Language selector
                    _settingsTile(
                      icon: Icons.language_rounded,
                      title: AppStrings.get('language', locale),
                      subtitle: localeProvider.languageName,
                      trailing: PopupMenuButton<String>(
                        color: isDark
                            ? AppTheme.surfaceVariantDark
                            : Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        icon: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.primary,
                        ),
                        onSelected: localeProvider.setLocale,
                        itemBuilder: (_) => LocaleProvider
                            .supportedLanguages
                            .entries
                            .map(
                              (e) => PopupMenuItem(
                                value: e.key,
                                child: Row(
                                  children: [
                                    Text(
                                      _langFlag(e.key),
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      e.value,
                                      style: TextStyle(
                                        fontFamily: 'Manrope',
                                        color: textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (e.key == locale) ...[
                                      const Spacer(),
                                      const Icon(
                                        Icons.check_rounded,
                                        color: AppTheme.primary,
                                        size: 18,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            )
                            .toList(),
                      ),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    // Biometric toggle
                    _settingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: AppStrings.get('biometric', locale),
                      subtitle: AppStrings.get('biometric_sub', locale),
                      trailing: Switch(
                        value: biometricProvider.biometricEnabled,
                        onChanged: (_) =>
                            _showBiometricPrompt(biometricProvider),
                        activeThumbColor: AppTheme.primary,
                      ),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // ── Security ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('security', locale),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _navTile(
                      Icons.security_rounded,
                      AppStrings.get('security', locale),
                      AppRoutes.security,
                      surface,
                      textPrimary,
                      textSecondary,
                      isDark,
                    ),
                  ],
                ),
              ),
            ),

            // ── Notifications ─────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.get('notifications', locale),
                      style: TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _settingsTile(
                      icon: Icons.notifications_rounded,
                      title: AppStrings.get('push_notifications', locale),
                      subtitle: AppStrings.get(
                        'push_notifications_sub',
                        locale,
                      ),
                      trailing: Switch(
                        value: _pushNotifications,
                        onChanged: (v) =>
                            setState(() => _pushNotifications = v),
                        activeThumbColor: AppTheme.primary,
                      ),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _settingsTile(
                      icon: Icons.receipt_long_rounded,
                      title: AppStrings.get('transaction_alerts', locale),
                      subtitle: AppStrings.get(
                        'transaction_alerts_sub',
                        locale,
                      ),
                      trailing: Switch(
                        value: _transactionAlerts,
                        onChanged: (v) =>
                            setState(() => _transactionAlerts = v),
                        activeThumbColor: AppTheme.primary,
                      ),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 8),
                    _settingsTile(
                      icon: Icons.savings_rounded,
                      title: AppStrings.get('savings_reminders', locale),
                      subtitle: AppStrings.get('savings_reminders_sub', locale),
                      trailing: Switch(
                        value: _savingsReminders,
                        onChanged: (v) => setState(() => _savingsReminders = v),
                        activeThumbColor: AppTheme.primary,
                      ),
                      surface: surface,
                      textPrimary: textPrimary,
                      textSecondary: textSecondary,
                      isDark: isDark,
                    ),
                  ],
                ),
              ),
            ),

            // ── Logout ────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isLoggingOut ? null : _logout,
                    icon: _isLoggingOut
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppTheme.error,
                            ),
                          )
                        : const Icon(Icons.logout_rounded, size: 18),
                    label: Text(AppStrings.get('logout', locale)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.error,
                      side: const BorderSide(color: AppTheme.error),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Manrope',
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _featureCard(
    IconData icon,
    String label,
    String route,
    Color surface,
    Color textPrimary,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 20),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Manrope',
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required Color surface,
    required Color textPrimary,
    required Color textSecondary,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppTheme.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          trailing,
        ],
      ),
    );
  }

  Widget _navTile(
    IconData icon,
    String title,
    String route,
    Color surface,
    Color textPrimary,
    Color textSecondary,
    bool isDark,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A3A) : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppTheme.primary, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: textSecondary,
              size: 14,
            ),
          ],
        ),
      ),
    );
  }

  String _langFlag(String code) {
    const flags = {'en': '🇬🇧', 'sq': '🇦🇱', 'el': '🇬🇷'};
    return flags[code] ?? '🌐';
  }
}

// ── KYC Status Badge ──────────────────────────────────────────────────────────
class _KycStatusBadge extends StatelessWidget {
  final String? kycStatus;
  final String locale;

  const _KycStatusBadge({required this.kycStatus, required this.locale});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;

    switch (kycStatus) {
      case 'verified':
        color = AppTheme.success;
        label = AppStrings.get('verified', locale);
        break;
      case 'pending':
      case 'in_review':
        color = AppTheme.warning;
        label = AppStrings.get('pending', locale);
        break;
      case 'declined':
        color = AppTheme.error;
        label = AppStrings.get('declined', locale);
        break;
      default:
        color = AppTheme.primary;
        label = 'KYC Required';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Manrope',
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
