import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/app_theme.dart';
import '../../../routes/app_routes.dart';
import '../../../providers/app_providers.dart';
import '../../../l10n/app_strings.dart';

class HomeAppBarWidget extends StatelessWidget {
  final bool balanceVisible;
  final VoidCallback onToggleBalance;

  const HomeAppBarWidget({
    super.key,
    required this.balanceVisible,
    required this.onToggleBalance,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = context.watch<LocaleProvider>().languageCode;

    // Use real authenticated user data
    final user = Supabase.instance.client.auth.currentUser;
    final displayName = _resolveDisplayName(user);
    final initials = _resolveInitials(displayName);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting(locale),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondaryDark,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                displayName,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.textPrimaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const Spacer(),

          // Notification bell
          GestureDetector(
            onTap: () {},
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariantDark,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    color: AppTheme.textPrimaryDark,
                    size: 22,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Avatar
          GestureDetector(
            onTap: () => context.push(AppRoutes.profile),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppTheme.primary, Color(0xFF00A875)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withAlpha(77),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF003322),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Resolve a human-readable display name from the Supabase user.
  String _resolveDisplayName(User? user) {
    if (user == null) return '';
    // Try user_metadata first (Google Sign-In populates full_name / name)
    final meta = user.userMetadata;
    if (meta != null) {
      final fullName = meta['full_name'] as String? ?? meta['name'] as String?;
      if (fullName != null && fullName.trim().isNotEmpty) {
        return fullName.trim();
      }
    }
    // Fall back to email prefix
    final email = user.email ?? '';
    if (email.isNotEmpty) {
      return email.split('@').first;
    }
    return 'User';
  }

  /// Generate up to 2 uppercase initials from a display name.
  String _resolveInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name[0].toUpperCase();
  }

  String _greeting(String locale) {
    final hour = DateTime.now().hour;
    if (hour < 12) return AppStrings.get('good_morning', locale);
    if (hour < 17) return AppStrings.get('good_afternoon', locale);
    return AppStrings.get('good_evening', locale);
  }
}
