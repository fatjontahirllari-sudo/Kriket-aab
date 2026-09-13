import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../presentation/sign_up_login_screen/sign_up_login_screen.dart';
import '../presentation/home_screen/home_screen.dart';
import '../presentation/send_money_screen/send_money_screen.dart';
import '../presentation/savings_screen/savings_screen.dart';
import '../presentation/virtual_card_screen/virtual_card_screen.dart';
import '../presentation/receive_money_screen/receive_money_screen.dart';
import '../presentation/profile_screen/profile_screen.dart';
import '../presentation/sign_up_screen/sign_up_screen.dart';
import '../presentation/exchange_rates_screen/exchange_rates_screen.dart';
import '../presentation/spending_analytics_screen/spending_analytics_screen.dart';
import '../presentation/pdf_statements_screen/pdf_statements_screen.dart';
import '../presentation/kyc_verification_screen/kyc_verification_screen.dart';
import '../presentation/security_settings_screen/security_settings_screen.dart';
import '../presentation/live_support_chat_screen/live_support_chat_screen.dart';
import '../presentation/forgot_password_screen/forgot_password_screen.dart';
import '../presentation/reset_password_screen/reset_password_screen.dart';
import '../widgets/app_scaffold.dart';
import '../services/session_service.dart';
import '../services/biometric_service.dart';
import '../presentation/biometric_lock_screen/biometric_lock_screen.dart';

// ── Route path constants ───────────────────────────────────────────
class AppRoutes {
  static const String initial = '/';
  static const String signUpLogin = '/sign-up-login-screen';
  static const String signUp = '/sign-up-screen';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String home = '/home-screen';
  static const String sendMoney = '/send-money-screen';
  static const String receiveMoney = '/receive-money-screen';
  static const String savings = '/savings-screen';
  static const String profile = '/profile-screen';
  static const String exchangeRates = '/exchange-rates-screen';
  static const String analytics = '/spending-analytics-screen';
  static const String virtualCard = '/virtual-card-screen';
  static const String statements = '/pdf-statements-screen';
  static const String kyc = '/kyc-verification-screen';
  static const String security = '/security-settings-screen';
  static const String support = '/live-support-chat-screen';
  static const String biometricLock = '/biometric-lock-screen';
}

CustomTransitionPage _slidePage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  return CustomTransitionPage(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    transitionsBuilder: (context, animation, _, child) => SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
      child: child,
    ),
  );
}

// ── Splash screen that restores session ───────────────────────────
class _SplashRedirect extends StatefulWidget {
  const _SplashRedirect();

  @override
  State<_SplashRedirect> createState() => _SplashRedirectState();
}

class _SplashRedirectState extends State<_SplashRedirect> {
  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  Future<void> _checkSession() async {
    // ── NEW APPROACH ──────────────────────────────────────────────
    // Check biometric eligibility FIRST, before attempting session restore.
    // This ensures the biometric prompt appears on cold launch even when
    // the Supabase in-memory session is empty (access token may be expired,
    // but the refresh token is still valid — BiometricLockScreen handles refresh).

    final biometricEnabled = await BiometricService.instance.isEnabled();
    final biometricAvailable = await BiometricService.instance.isAvailable();

    if (!mounted) return;

    if (biometricEnabled && biometricAvailable) {
      // Check that we have stored tokens (refresh token is enough)
      final tokens = await BiometricService.instance.getBiometricSession();
      if (!mounted) return;

      if (tokens != null &&
          tokens['refresh_token'] != null &&
          tokens['refresh_token']!.isNotEmpty) {
        // We have everything needed — show biometric prompt immediately.
        // BiometricLockScreen will restore the session after auth succeeds.
        debugPrint(
          '[Splash] Biometric enabled + tokens exist → biometric lock screen',
        );
        context.go(AppRoutes.biometricLock);
        return;
      }
      // Tokens missing despite biometric being enabled — fall through to normal session check
      debugPrint(
        '[Splash] Biometric enabled but no stored tokens — falling back to session check',
      );
    }

    // ── Normal path: no biometric, or tokens missing ──────────────
    // Try to restore the Supabase session from secure storage
    final restored = await SessionService.instance.restoreSession();
    if (!mounted) return;

    if (restored) {
      context.go(AppRoutes.home);
    } else {
      context.go(AppRoutes.signUpLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Minimal splash while session check runs
    return const Scaffold(
      backgroundColor: Color(0xFF0A0A0F),
      body: Center(
        child: CircularProgressIndicator(
          color: Color(0xFF6C63FF),
          strokeWidth: 2,
        ),
      ),
    );
  }
}

// ── Router instance ────────────────────────────────────────────────
final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.initial,
  routes: [
    // Root — session check splash
    GoRoute(
      path: AppRoutes.initial,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const _SplashRedirect(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        ),
      ),
    ),

    // Sign Up
    GoRoute(
      path: AppRoutes.signUp,
      pageBuilder: (context, state) =>
          _slidePage(context, state, const SignUpScreen()),
    ),

    // Auth
    GoRoute(
      path: AppRoutes.signUpLogin,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SignUpLoginScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        ),
      ),
    ),

    // Forgot Password
    GoRoute(
      path: AppRoutes.forgotPassword,
      pageBuilder: (c, s) => _slidePage(c, s, const ForgotPasswordScreen()),
    ),

    // Reset Password (deep link target from email)
    GoRoute(
      path: AppRoutes.resetPassword,
      pageBuilder: (c, s) => _slidePage(c, s, const ResetPasswordScreen()),
    ),

    // Send Money
    GoRoute(
      path: AppRoutes.sendMoney,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SendMoneyScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
    ),

    // Receive Money
    GoRoute(
      path: AppRoutes.receiveMoney,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const ReceiveMoneyScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, _, child) => SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: FadeTransition(opacity: animation, child: child),
        ),
      ),
    ),

    // New feature screens (push navigation)
    GoRoute(
      path: AppRoutes.exchangeRates,
      pageBuilder: (c, s) => _slidePage(c, s, const ExchangeRatesScreen()),
    ),
    GoRoute(
      path: AppRoutes.analytics,
      pageBuilder: (c, s) => _slidePage(c, s, const SpendingAnalyticsScreen()),
    ),
    GoRoute(
      path: AppRoutes.statements,
      pageBuilder: (c, s) => _slidePage(c, s, const PdfStatementsScreen()),
    ),
    GoRoute(
      path: AppRoutes.kyc,
      pageBuilder: (c, s) => _slidePage(c, s, const KycVerificationScreen()),
    ),
    GoRoute(
      path: AppRoutes.security,
      pageBuilder: (c, s) => _slidePage(c, s, const SecuritySettingsScreen()),
    ),
    GoRoute(
      path: AppRoutes.support,
      pageBuilder: (c, s) => _slidePage(c, s, const LiveSupportChatScreen()),
    ),

    // Biometric lock screen
    GoRoute(
      path: AppRoutes.biometricLock,
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BiometricLockScreen(),
        transitionDuration: const Duration(milliseconds: 280),
        transitionsBuilder: (context, animation, _, child) => FadeTransition(
          opacity: CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          ),
          child: child,
        ),
      ),
    ),

    // Shell — bottom nav tabs
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppScaffold(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.home,
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.savings,
              builder: (context, state) => const SavingsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.virtualCard,
              builder: (context, state) => const VirtualCardScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: AppRoutes.profile,
              builder: (context, state) => const ProfileScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);
