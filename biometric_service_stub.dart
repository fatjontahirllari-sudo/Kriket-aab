/// Stub implementation for web — biometrics are not supported.
Future<bool> checkBiometricAvailability() async => false;

Future<bool> performBiometricAuth({required String reason}) async => false;
