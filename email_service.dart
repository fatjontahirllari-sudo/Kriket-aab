import 'package:supabase_flutter/supabase_flutter.dart';

/// Service for sending transactional emails via Supabase Edge Function + Resend.
class EmailService {
  static EmailService? _instance;
  static EmailService get instance => _instance ??= EmailService._();
  EmailService._();

  static const String _functionName = 'send-email';

  SupabaseClient get _client => Supabase.instance.client;

  /// Send a welcome/registration email after successful sign-up.
  Future<void> sendRegistrationEmail({
    required String to,
    required String name,
  }) async {
    await _send(payload: {'type': 'registration', 'to': to, 'name': name});
  }

  /// Send a transfer confirmation email after a successful money transfer.
  Future<void> sendTransferEmail({
    required String to,
    required String name,
    required String amount,
    required String recipient,
  }) async {
    await _send(
      payload: {
        'type': 'transfer',
        'to': to,
        'name': name,
        'amount': amount,
        'recipient': recipient,
      },
    );
  }

  /// Send a password reset email with a reset link.
  Future<void> sendPasswordResetEmail({
    required String to,
    required String name,
    required String resetLink,
  }) async {
    await _send(
      payload: {
        'type': 'password_reset',
        'to': to,
        'name': name,
        'resetLink': resetLink,
      },
    );
  }

  /// Send a security alert email for suspicious login activity.
  Future<void> sendSecurityAlertEmail({
    required String to,
    required String name,
    String? device,
    String? location,
  }) async {
    await _send(
      payload: {
        'type': 'security_alert',
        'to': to,
        'name': name,
        'device': device ?? 'Unknown Device',
        'location': location ?? 'Unknown Location',
      },
    );
  }

  Future<void> _send({required Map<String, dynamic> payload}) async {
    try {
      await _client.functions.invoke(_functionName, body: payload);
    } catch (_) {
      // Silently fail — email is non-blocking
    }
  }
}
