import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAuthService {
  static GoogleAuthService? _instance;
  static GoogleAuthService get instance => _instance ??= GoogleAuthService._();

  GoogleAuthService._();

  // ─── OAuth Client IDs ────────────────────────────────────────────────────
  // GOOGLE_WEB_CLIENT_ID  : Web application OAuth 2.0 client ID from Google Cloud.
  //   This is the "serverClientId" — it tells Google to include an ID token
  //   in the response, and the token audience will be this client ID.
  //   Supabase's signInWithIdToken validates the token against this same client ID.
  //
  // GOOGLE_ANDROID_CLIENT_ID : Android OAuth 2.0 client ID from Google Cloud.
  //   This is registered in Google Cloud with:
  //     - Package name : com.example.kriket
  //     - SHA-1 fingerprint : the debug keystore SHA-1 (see note below)
  //   It is NOT passed to the Flutter GoogleSignIn constructor.
  //   Without google-services.json, GMS still uses it if it matches the
  //   installed package + SHA-1 combination at runtime.
  //
  // ─── SHA-1 NOTE ──────────────────────────────────────────────────────────
  // This project signs ALL builds (including release) with the DEBUG keystore:
  //   signingConfig = signingConfigs.getByName("debug")   ← build.gradle.kts
  //
  // The debug keystore SHA-1 is shown in Rocket → Launch → APK.
  // You MUST register that exact SHA-1 under the Android OAuth client in:
  //   Google Cloud Console → APIs & Services → Credentials → [Android client]
  //
  // Package name to register: com.example.kriket
  // ─────────────────────────────────────────────────────────────────────────

  static const String _webClientId = String.fromEnvironment(
    'GOOGLE_WEB_CLIENT_ID',
    defaultValue: '',
  );

  static const String _androidClientId = String.fromEnvironment(
    'GOOGLE_ANDROID_CLIENT_ID',
    defaultValue: '',
  );

  /// Prints a diagnostic summary to the debug console.
  /// Call this from main() or a debug screen to verify configuration.
  static void printDiagnostics() {
    debugPrint('══════════════════════════════════════════════════');
    debugPrint('[GoogleAuth] DIAGNOSTIC REPORT');
    debugPrint('──────────────────────────────────────────────────');
    debugPrint('[GoogleAuth] Android package name : com.example.kriket');
    debugPrint(
      '[GoogleAuth] Signing config       : debug keystore (all builds)',
    );
    debugPrint('[GoogleAuth] SHA-1 source         : Rocket → Launch → APK');
    debugPrint(
      '[GoogleAuth] Web client ID set    : ${_webClientId.isNotEmpty}',
    );
    debugPrint(
      '[GoogleAuth] Android client ID set: ${_androidClientId.isNotEmpty}',
    );
    debugPrint('──────────────────────────────────────────────────');
    debugPrint('[GoogleAuth] Google Cloud checklist:');
    debugPrint('  1. Android OAuth client → Package: com.example.kriket');
    debugPrint('  2. Android OAuth client → SHA-1: <from Rocket Launch→APK>');
    debugPrint('  3. Web OAuth client → Authorized JS origins include app URL');
    debugPrint('  4. Supabase Dashboard → Auth → Providers → Google → Enabled');
    debugPrint(
      '  5. Supabase Google provider → Client ID = GOOGLE_WEB_CLIENT_ID',
    );
    debugPrint(
      '  6. Supabase Google provider → Client Secret = Web client secret',
    );
    debugPrint('══════════════════════════════════════════════════');
  }

  /// Signs in with Google and authenticates with Supabase.
  /// Returns the authenticated [User] on success, null if user cancelled,
  /// or throws a descriptive [AuthException] on failure.
  Future<User?> signInWithGoogle() async {
    if (kIsWeb) {
      // Web: use Supabase OAuth redirect flow
      await Supabase.instance.client.auth.signInWithOAuth(
        OAuthProvider.google,
        redirectTo: 'https://kriket7980.builtwithrocket.new',
      );
      return null;
    }

    // ── Pre-flight checks ──────────────────────────────────────────────────
    debugPrint('[GoogleAuth] ── Starting Google Sign-In ──');
    debugPrint('[GoogleAuth] Package name     : com.example.kriket');
    debugPrint(
      '[GoogleAuth] Web client ID    : ${_webClientId.isNotEmpty ? "✓ present" : "✗ MISSING — set GOOGLE_WEB_CLIENT_ID"}',
    );
    debugPrint(
      '[GoogleAuth] Android client ID: ${_androidClientId.isNotEmpty ? "✓ present" : "✗ MISSING — set GOOGLE_ANDROID_CLIENT_ID"}',
    );

    if (_webClientId.isEmpty) {
      throw const AuthException(
        'Google Sign-In is not configured: GOOGLE_WEB_CLIENT_ID is missing. '
        'Add it in your environment variables.',
      );
    }

    // ── Build GoogleSignIn instance ────────────────────────────────────────
    // serverClientId = Web OAuth client ID.
    // This is the ONLY client ID that should be passed here.
    // The Android client ID is handled by GMS natively (via package name + SHA-1).
    // Passing the Android client ID as `clientId` would change the token audience
    // and cause Supabase's signInWithIdToken to reject the token.
    final GoogleSignIn googleSignIn = GoogleSignIn(
      serverClientId: _webClientId,
      scopes: ['email', 'profile'],
    );

    // Force account picker on every sign-in attempt
    try {
      await googleSignIn.signOut();
    } catch (e) {
      debugPrint('[GoogleAuth] Pre-signOut (non-fatal): $e');
    }

    // ── Trigger account picker ─────────────────────────────────────────────
    GoogleSignInAccount? googleUser;
    try {
      googleUser = await googleSignIn.signIn();
    } catch (e) {
      debugPrint('[GoogleAuth] googleSignIn.signIn() error: $e');
      final msg = e.toString();
      if (msg.contains('10') || msg.contains('DEVELOPER_ERROR')) {
        throw AuthException(
          'Google Sign-In configuration error (code 10 / DEVELOPER_ERROR). '
          'This means the SHA-1 fingerprint of the APK signing certificate '
          'is NOT registered in the Android OAuth client in Google Cloud. '
          'Steps to fix:\n'
          '  1. Go to Rocket → Launch → APK and copy the SHA-1 shown there.\n'
          '  2. Open Google Cloud Console → APIs & Services → Credentials.\n'
          '  3. Edit the Android OAuth client for package "com.example.kriket".\n'
          '  4. Add the SHA-1 fingerprint and save.\n'
          'Raw error: $msg',
        );
      }
      rethrow;
    }

    if (googleUser == null) {
      debugPrint('[GoogleAuth] User cancelled sign-in.');
      return null;
    }

    debugPrint('[GoogleAuth] Account selected: ${googleUser.email}');

    // ── Get tokens ─────────────────────────────────────────────────────────
    GoogleSignInAuthentication googleAuth;
    try {
      googleAuth = await googleUser.authentication;
    } catch (e) {
      debugPrint('[GoogleAuth] Failed to get authentication tokens: $e');
      rethrow;
    }

    final String? idToken = googleAuth.idToken;
    final String? accessToken = googleAuth.accessToken;

    debugPrint(
      '[GoogleAuth] ID token present    : ${idToken != null ? "✓" : "✗ MISSING"}',
    );
    debugPrint(
      '[GoogleAuth] Access token present: ${accessToken != null ? "✓" : "✗ MISSING"}',
    );

    if (idToken == null) {
      throw const AuthException(
        'Google Sign-In failed: No ID token received from Google. '
        'This usually means the Web OAuth client ID (serverClientId) is wrong '
        'or the SHA-1 fingerprint is not registered in the Android OAuth client. '
        'Check GOOGLE_WEB_CLIENT_ID and the SHA-1 in Google Cloud Console.',
      );
    }

    // ── Exchange with Supabase ─────────────────────────────────────────────
    debugPrint('[GoogleAuth] Exchanging ID token with Supabase...');
    try {
      final AuthResponse response = await Supabase.instance.client.auth
          .signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: idToken,
            accessToken: accessToken,
          );
      debugPrint(
        '[GoogleAuth] ✓ Supabase sign-in success: ${response.user?.email}',
      );
      return response.user;
    } catch (e) {
      debugPrint('[GoogleAuth] Supabase signInWithIdToken failed: $e');
      final msg = e.toString().toLowerCase();
      if (msg.contains('invalid') ||
          msg.contains('audience') ||
          msg.contains('iss')) {
        throw AuthException(
          'Supabase rejected the Google ID token. '
          'Verify that the Client ID in Supabase Dashboard → Auth → Providers → Google '
          'matches GOOGLE_WEB_CLIENT_ID exactly. '
          'Raw error: $e',
        );
      }
      rethrow;
    }
  }

  /// Signs out from both Google and Supabase.
  Future<void> signOut() async {
    if (!kIsWeb) {
      try {
        final GoogleSignIn googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (_) {
        // Ignore Google sign-out errors
      }
    }
    await Supabase.instance.client.auth.signOut();
  }
}
