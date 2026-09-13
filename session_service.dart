import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Manages secure persistent login using flutter_secure_storage.
/// Stores the Supabase session so the user stays logged in across app restarts.
class SessionService {
  static SessionService? _instance;
  static SessionService get instance => _instance ??= SessionService._();
  SessionService._();

  static const _kAccessToken = 'sb_access_token';
  static const _kRefreshToken = 'sb_refresh_token';

  /// Platform-aware secure storage instance.
  /// On web, flutter_secure_storage uses localStorage — no platform options needed.
  FlutterSecureStorage get _storage {
    if (kIsWeb) {
      return const FlutterSecureStorage();
    }
    return const FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
      iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
    );
  }

  /// Persist the current Supabase session securely.
  Future<void> persistSession(Session session) async {
    if (session.accessToken.isEmpty) return;
    try {
      await _storage.write(key: _kAccessToken, value: session.accessToken);
      await _storage.write(
        key: _kRefreshToken,
        value: session.refreshToken ?? '',
      );
      debugPrint('[SessionService] Session persisted.');
    } catch (e) {
      debugPrint('[SessionService] Failed to persist session: $e');
    }
  }

  /// Attempt to restore a previously saved session.
  /// Returns true if a valid session was restored, false otherwise.
  Future<bool> restoreSession() async {
    try {
      final client = Supabase.instance.client;

      // Fast path: Supabase already has a live in-memory session
      // (e.g. supabase_flutter restored it from its own persistence layer).
      final existingSession = client.auth.currentSession;
      if (existingSession != null && !_isExpired(existingSession)) {
        debugPrint(
          '[SessionService] Live Supabase session found — no restore needed.',
        );
        // Keep our secure storage in sync
        await persistSession(existingSession);
        return true;
      }

      // Slow path: try our securely stored tokens
      final accessToken = await _storage.read(key: _kAccessToken);
      final refreshToken = await _storage.read(key: _kRefreshToken);

      if (accessToken == null || accessToken.isEmpty) {
        debugPrint('[SessionService] No stored access token.');
        return false;
      }
      if (refreshToken == null || refreshToken.isEmpty) {
        debugPrint('[SessionService] No stored refresh token.');
        return false;
      }

      try {
        // setSession requires refresh token as first arg; access token is optional named param
        final response = await client.auth.setSession(
          refreshToken,
          accessToken: accessToken,
        );
        if (response.session != null) {
          await persistSession(response.session!);
          debugPrint('[SessionService] Session restored via setSession.');
          return true;
        }
      } catch (e) {
        debugPrint(
          '[SessionService] setSession failed: $e — trying refreshSession',
        );
      }

      // Access token expired — try refreshing using the stored refresh token
      try {
        final refreshed = await client.auth.refreshSession();
        if (refreshed.session != null) {
          await persistSession(refreshed.session!);
          debugPrint('[SessionService] Session restored via refreshSession.');
          return true;
        }
      } catch (e) {
        debugPrint('[SessionService] refreshSession failed: $e');
      }

      // Both attempts failed — clear stale tokens
      await clearSession();
      return false;
    } catch (e) {
      debugPrint('[SessionService] Session restore failed: $e');
      await clearSession();
      return false;
    }
  }

  /// Returns true if the session's access token is expired.
  bool _isExpired(Session session) {
    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;
    // Consider expired if less than 60 seconds remain
    final expiry = DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000);
    return DateTime.now().isAfter(expiry.subtract(const Duration(seconds: 60)));
  }

  /// Clear all stored session data (call on sign-out or invalid session).
  Future<void> clearSession() async {
    try {
      await _storage.delete(key: _kAccessToken);
      await _storage.delete(key: _kRefreshToken);
      debugPrint('[SessionService] Session cleared.');
    } catch (e) {
      debugPrint('[SessionService] Failed to clear session: $e');
    }
  }

  /// Returns true if stored credentials exist (does not validate them).
  Future<bool> hasStoredSession() async {
    try {
      final token = await _storage.read(key: _kAccessToken);
      return token != null && token.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
