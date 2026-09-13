import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Conditional import: local_auth is not supported on web
import 'biometric_service_stub.dart'
    if (dart.library.io) 'biometric_service_native.dart';

/// Public interface for biometric authentication.
/// On web, all biometric operations are no-ops / return false.
class BiometricService {
  static BiometricService? _instance;
  static BiometricService get instance => _instance ??= BiometricService._();
  BiometricService._();

  static const _kBiometricEnabled = 'biometric_enabled';
  static const _kAccessToken = 'bio_access_token';
  static const _kRefreshToken = 'bio_refresh_token';

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

  // ── Availability ──────────────────────────────────────────────────

  /// Returns true if the device supports biometric authentication.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;
    return checkBiometricAvailability();
  }

  // ── Preference ────────────────────────────────────────────────────

  /// Whether the user has enabled biometric login.
  Future<bool> isEnabled() async {
    if (kIsWeb) return false;
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_kBiometricEnabled) ?? false;
  }

  /// Enable or disable biometric login.
  Future<void> setEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kBiometricEnabled, value);
    if (!value) {
      await _clearTokens();
    }
  }

  // ── Session token storage ─────────────────────────────────────────

  /// Store Supabase session tokens securely for biometric-protected retrieval.
  Future<void> storeBiometricSession({
    required String accessToken,
    required String refreshToken,
  }) async {
    if (accessToken.isEmpty || refreshToken.isEmpty) return;
    try {
      await _storage.write(key: _kAccessToken, value: accessToken);
      await _storage.write(key: _kRefreshToken, value: refreshToken);
      debugPrint('[BiometricService] Session tokens stored securely.');
    } catch (e) {
      debugPrint('[BiometricService] Failed to store tokens: $e');
    }
  }

  /// Retrieve stored biometric session tokens.
  /// Returns null if tokens are missing or empty.
  Future<Map<String, String>?> getBiometricSession() async {
    try {
      final access = await _storage.read(key: _kAccessToken);
      final refresh = await _storage.read(key: _kRefreshToken);
      if (access == null || access.isEmpty) return null;
      if (refresh == null || refresh.isEmpty) return null;
      return {'access_token': access, 'refresh_token': refresh};
    } catch (e) {
      debugPrint('[BiometricService] Failed to read tokens: $e');
      return null;
    }
  }

  Future<void> _clearTokens() async {
    try {
      await _storage.delete(key: _kAccessToken);
      await _storage.delete(key: _kRefreshToken);
    } catch (_) {}
  }

  // ── Authentication ────────────────────────────────────────────────

  /// Prompt the user for biometric authentication.
  /// Returns true if authentication succeeded.
  Future<bool> authenticate({
    String reason = 'Confirm your identity to continue',
  }) async {
    if (kIsWeb) return false;
    return performBiometricAuth(reason: reason);
  }
}
