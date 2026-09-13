import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/biometric_service.dart';
import '../../services/session_service.dart';
import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';

/// Shown on every app launch when biometric login is enabled.
/// Prompts fingerprint / Face ID, then restores the Supabase session.
class BiometricLockScreen extends StatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  State<BiometricLockScreen> createState() => _BiometricLockScreenState();
}

class _BiometricLockScreenState extends State<BiometricLockScreen> {
  bool _authenticating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    // Trigger biometric prompt automatically on first frame
    WidgetsBinding.instance.addPostFrameCallback((_) => _authenticate());
  }

  Future<void> _authenticate() async {
    if (_authenticating || !mounted) return;

    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    try {
      // Step 1: Show native biometric prompt
      final success = await BiometricService.instance.authenticate(
        reason: 'Verify your identity to access kriket',
      );

      if (!mounted) return;

      if (!success) {
        setState(() {
          _authenticating = false;
          _errorMessage = 'Authentication failed. Tap to try again.';
        });
        return;
      }

      // Step 2: Retrieve securely stored session tokens
      final tokens = await BiometricService.instance.getBiometricSession();

      if (!mounted) return;

      if (tokens == null) {
        // No stored tokens — fall back to login
        debugPrint('[BiometricLock] No stored tokens — redirecting to login.');
        context.go(AppRoutes.signUpLogin);
        return;
      }

      // Step 3: Restore Supabase session.
      // Strategy: use the refresh token directly via refreshSession after
      // setting the session. If the access token is expired, refreshSession
      // will use the refresh token to get a new one.
      bool sessionRestored = false;
      final client = Supabase.instance.client;

      // First check if there's already a live session (unlikely on cold launch but possible)
      final existingSession = client.auth.currentSession;
      if (existingSession != null) {
        await SessionService.instance.persistSession(existingSession);
        await BiometricService.instance.storeBiometricSession(
          accessToken: existingSession.accessToken,
          refreshToken:
              existingSession.refreshToken ?? tokens['refresh_token']!,
        );
        sessionRestored = true;
        debugPrint('[BiometricLock] Existing live session found.');
      }

      if (!sessionRestored) {
        // Try refreshing the session using the stored refresh token.
        // We call setSession with the refresh token as both args to prime
        // the Supabase client, then immediately refresh to get fresh tokens.
        try {
          final refreshToken = tokens['refresh_token']!;
          final accessToken = tokens['access_token'] ?? '';

          // Attempt setSession — may succeed if access token is still valid
          if (accessToken.isNotEmpty) {
            try {
              final setResult = await client.auth.setSession(
                refreshToken,
                accessToken: accessToken,
              );
              if (setResult.session != null) {
                await SessionService.instance.persistSession(
                  setResult.session!,
                );
                await BiometricService.instance.storeBiometricSession(
                  accessToken: setResult.session!.accessToken,
                  refreshToken: setResult.session!.refreshToken ?? refreshToken,
                );
                sessionRestored = true;
                debugPrint('[BiometricLock] Session restored via setSession.');
              }
            } catch (e) {
              debugPrint(
                '[BiometricLock] setSession failed (token likely expired): $e',
              );
            }
          }

          // If setSession failed or access token was empty, use recoverSession
          // by calling refreshSession which uses the refresh token internally
          if (!sessionRestored) {
            // Manually set the refresh token in the client's recovery path
            // by using recoverSession with just the refresh token
            try {
              // Use the Supabase auth API to exchange refresh token for new session
              final response = await client.auth.setSession(refreshToken);
              if (response.session != null) {
                await SessionService.instance.persistSession(response.session!);
                await BiometricService.instance.storeBiometricSession(
                  accessToken: response.session!.accessToken,
                  refreshToken: response.session!.refreshToken ?? refreshToken,
                );
                sessionRestored = true;
                debugPrint(
                  '[BiometricLock] Session restored via setSession(refreshToken only).',
                );
              }
            } catch (e) {
              debugPrint('[BiometricLock] setSession(refreshToken) failed: $e');
            }
          }

          // Last resort: try refreshSession (works if client has any session state)
          if (!sessionRestored) {
            try {
              final refreshed = await client.auth.refreshSession();
              if (refreshed.session != null) {
                await SessionService.instance.persistSession(
                  refreshed.session!,
                );
                await BiometricService.instance.storeBiometricSession(
                  accessToken: refreshed.session!.accessToken,
                  refreshToken: refreshed.session!.refreshToken ?? refreshToken,
                );
                sessionRestored = true;
                debugPrint(
                  '[BiometricLock] Session restored via refreshSession.',
                );
              }
            } catch (e) {
              debugPrint('[BiometricLock] refreshSession failed: $e');
            }
          }
        } catch (e) {
          debugPrint('[BiometricLock] Session restore error: $e');
        }
      }

      if (!mounted) return;

      if (sessionRestored) {
        context.go(AppRoutes.home);
      } else {
        // Session is truly expired — clear everything and go to login
        await SessionService.instance.clearSession();
        await BiometricService.instance.setEnabled(false);
        if (mounted) context.go(AppRoutes.signUpLogin);
      }
    } catch (e) {
      debugPrint('[BiometricLock] Unexpected error: $e');
      if (!mounted) return;
      setState(() {
        _authenticating = false;
        _errorMessage = 'Biometric authentication unavailable. Try again.';
      });
    }
  }

  void _goToLogin() {
    context.go(AppRoutes.signUpLogin);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0F),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Fingerprint icon
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withAlpha(20),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppTheme.primary.withAlpha(60),
                    width: 2,
                  ),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppTheme.primary,
                  size: 52,
                ),
              ),

              const SizedBox(height: 32),

              const Text(
                'Welcome back',
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 10),

              const Text(
                'Verify your identity to continue',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Manrope',
                  fontSize: 15,
                  color: Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),

              const SizedBox(height: 40),

              // Authenticate button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _authenticating ? null : _authenticate,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withAlpha(80),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  icon: _authenticating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.fingerprint_rounded, size: 22),
                  label: Text(
                    _authenticating ? 'Verifying...' : 'Use Biometrics',
                    style: const TextStyle(
                      fontFamily: 'Manrope',
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.error.withAlpha(20),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.error.withAlpha(60)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: AppTheme.error,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: 'Manrope',
                            color: AppTheme.error,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Use another login method
              TextButton(
                onPressed: _goToLogin,
                child: const Text(
                  'Use another login method',
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    color: Color(0xFF9CA3AF),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
