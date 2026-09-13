import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

final _auth = LocalAuthentication();

/// Check if the device supports biometric authentication.
/// Returns true if at least one biometric type is enrolled.
Future<bool> checkBiometricAvailability() async {
  try {
    // First check if the device hardware supports biometrics
    final canCheck = await _auth.canCheckBiometrics;
    final isDeviceSupported = await _auth.isDeviceSupported();
    if (!canCheck && !isDeviceSupported) return false;

    // Check if any biometrics are enrolled
    final available = await _auth.getAvailableBiometrics();
    return available.isNotEmpty;
  } on PlatformException catch (e) {
    // Log but don't crash — device may not support biometrics
    // ignore: avoid_print
    print('[BiometricNative] checkBiometricAvailability error: $e');
    return false;
  } catch (_) {
    return false;
  }
}

/// Perform the actual biometric authentication prompt.
/// NOTE: biometricOnly is intentionally false — Android requires this to be
/// false for BiometricPrompt to work correctly on many devices. The system
/// will still prefer biometrics and only fall back to PIN/pattern if needed.
Future<bool> performBiometricAuth({required String reason}) async {
  try {
    final result = await _auth.authenticate(
      localizedReason: reason,
      options: const AuthenticationOptions(
        // biometricOnly: false allows Android BiometricPrompt to work
        // correctly — setting it to true causes failures on many devices
        biometricOnly: false,
        stickyAuth: true,
        useErrorDialogs: true,
        sensitiveTransaction: true,
      ),
    );
    return result;
  } on PlatformException catch (e) {
    // ignore: avoid_print
    print(
      '[BiometricNative] performBiometricAuth error: ${e.code} ${e.message}',
    );
    return false;
  } catch (_) {
    return false;
  }
}
