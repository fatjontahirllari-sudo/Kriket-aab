import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../theme/app_theme.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({super.key});

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  bool _loading = true;
  bool _starting = false;
  String? _status;
  String? _diditUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStatus();
  }

  /// Returns the current session's access token, or null if not logged in.
  String? _getAccessToken() {
    return Supabase.instance.client.auth.currentSession?.accessToken;
  }

  Future<void> _fetchStatus() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final accessToken = _getAccessToken();
      if (accessToken == null) {
        setState(
          () => _error = 'You must be logged in to check verification status.',
        );
        return;
      }

      final res = await Supabase.instance.client.functions.invoke(
        'didit-kyc',
        body: {'action': 'get-status'},
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      final data = res.data;
      if (data is Map) {
        final kyc = data['kyc'];
        if (kyc is Map) {
          setState(() {
            _status = kyc['status'] as String?;
            _diditUrl = kyc['didit_url'] as String?;
          });
        } else {
          setState(() {
            _status = null;
            _diditUrl = null;
          });
        }
      } else {
        setState(() => _error = 'Unexpected response from server.');
      }
    } catch (e) {
      setState(() => _error = 'Failed to load verification status.');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _startVerification() async {
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      final accessToken = _getAccessToken();
      if (accessToken == null) {
        setState(() => _error = 'You must be logged in to start verification.');
        return;
      }

      final res = await Supabase.instance.client.functions.invoke(
        'didit-kyc',
        body: {'action': 'create-session'},
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      final data = res.data;
      if (data is! Map) {
        setState(() => _error = 'Unexpected response from server.');
        return;
      }

      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        final errMsg =
            data['error'] as String? ?? 'No verification URL received.';
        setState(() => _error = errMsg);
        return;
      }

      setState(() {
        _status = 'pending';
        _diditUrl = url;
      });

      await _openUrl(url);
    } catch (e) {
      setState(
        () => _error = 'Could not start verification. Please try again.',
      );
    } finally {
      setState(() => _starting = false);
    }
  }

  Future<void> _openUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not open verification link.');
      }
    }
  }

  /// For pending sessions, fetch a fresh verification URL from Didit
  /// (the stored URL may have expired) and open it.
  Future<void> _continueVerification() async {
    setState(() {
      _starting = true;
      _error = null;
    });

    try {
      // Try the stored URL first; if unavailable, create a new session
      final urlToOpen = _diditUrl;
      if (urlToOpen != null && urlToOpen.isNotEmpty) {
        await _openUrl(urlToOpen);
        // If _openUrl set an error, try creating a fresh session instead
        if (_error != null) {
          setState(() => _error = null);
          await _startVerification();
        }
      } else {
        // No stored URL — create a fresh session
        await _startVerification();
      }
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: AppTheme.textPrimaryDark,
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Identity Verification',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: AppTheme.textPrimaryDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatusCard(status: _status),
                    const SizedBox(height: 20),
                    if (_error != null) ...[
                      _ErrorBanner(message: _error!),
                      const SizedBox(height: 16),
                    ],
                    if (_status == null || _status == 'declined') ...[
                      const _StepsSection(),
                      const SizedBox(height: 24),
                    ],
                    if (_status == 'pending') ...[
                      OutlinedButton.icon(
                        onPressed: _starting ? null : _continueVerification,
                        icon: _starting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.primary,
                                ),
                              )
                            : const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Continue Verification'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primary,
                          side: const BorderSide(color: AppTheme.primary),
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
                      const SizedBox(height: 12),
                    ],
                    if (_status != 'verified') ...[
                      ElevatedButton(
                        onPressed: _starting ? null : _startVerification,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: const Color(0xFF003322),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                          textStyle: const TextStyle(
                            fontFamily: 'Manrope',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        child: _starting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF003322),
                                ),
                              )
                            : Text(
                                _status == 'pending'
                                    ? 'Restart Verification'
                                    : _status == 'declined'
                                    ? 'Try Again'
                                    : 'Start Verification',
                              ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: _fetchStatus,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Refresh Status'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondaryDark,
                        textStyle: const TextStyle(
                          fontFamily: 'Manrope',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withAlpha(20),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.warning.withAlpha(60),
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: AppTheme.warning,
                              size: 18,
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'For the best experience, use the mobile app to complete identity verification.',
                                style: TextStyle(
                                  fontFamily: 'Manrope',
                                  fontSize: 12,
                                  color: AppTheme.textSecondaryDark,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String? status;
  const _StatusCard({required this.status});

  IconData get _icon {
    switch (status) {
      case 'verified':
        return Icons.verified_rounded;
      case 'pending':
      case 'in_review':
        return Icons.hourglass_top_rounded;
      case 'declined':
        return Icons.cancel_rounded;
      default:
        return Icons.verified_user_rounded;
    }
  }

  Color get _color {
    switch (status) {
      case 'verified':
        return AppTheme.success;
      case 'pending':
      case 'in_review':
        return AppTheme.warning;
      case 'declined':
        return AppTheme.error;
      default:
        return AppTheme.primary;
    }
  }

  String get _title {
    switch (status) {
      case 'verified':
        return 'Identity Verified';
      case 'pending':
        return 'Verification Pending';
      case 'in_review':
        return 'Under Review';
      case 'declined':
        return 'Verification Declined';
      default:
        return 'Verify Your Identity';
    }
  }

  String get _subtitle {
    switch (status) {
      case 'verified':
        return 'Your identity has been successfully verified. You have full access to all features.';
      case 'pending':
        return 'Your verification is in progress. Please complete the verification flow.';
      case 'in_review':
        return 'Our team is reviewing your documents. This usually takes a few minutes.';
      case 'declined':
        return 'Your verification was not successful. Please try again with clear documents.';
      default:
        return 'Complete identity verification to unlock all features of your account.';
    }
  }

  String get _badgeLabel {
    switch (status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'in_review':
        return 'In Review';
      case 'declined':
        return 'Declined';
      default:
        return 'Not Started';
    }
  }

  IconData get _badgeIcon {
    switch (status) {
      case 'verified':
        return Icons.check_circle_rounded;
      case 'pending':
        return Icons.schedule_rounded;
      case 'in_review':
        return Icons.rate_review_rounded;
      case 'declined':
        return Icons.cancel_rounded;
      default:
        return Icons.radio_button_unchecked_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: AppTheme.cardGradient,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primary.withAlpha(40)),
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _color.withAlpha(30),
            ),
            child: Icon(_icon, color: _color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            _title,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontWeight: FontWeight.w800,
              fontSize: 20,
              color: AppTheme.textPrimaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle,
            style: const TextStyle(
              fontFamily: 'Manrope',
              fontSize: 13,
              color: AppTheme.textSecondaryDark,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: _color.withAlpha(30),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _color.withAlpha(80)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(_badgeIcon, color: _color, size: 14),
                const SizedBox(width: 6),
                Text(
                  _badgeLabel,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: _color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'Manrope',
                fontSize: 13,
                color: AppTheme.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepsSection extends StatelessWidget {
  const _StepsSection();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What to expect',
          style: TextStyle(
            fontFamily: 'Manrope',
            fontWeight: FontWeight.w700,
            fontSize: 16,
            color: AppTheme.textPrimaryDark,
          ),
        ),
        const SizedBox(height: 12),
        _StepTile(
          step: '1',
          title: 'Prepare your ID',
          subtitle: 'National ID, passport, or driver\'s license',
        ),
        const SizedBox(height: 8),
        _StepTile(
          step: '2',
          title: 'Take a selfie',
          subtitle: 'A clear photo of your face in good lighting',
        ),
        const SizedBox(height: 8),
        _StepTile(
          step: '3',
          title: 'Wait for review',
          subtitle: 'Verification usually completes within minutes',
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final String step;
  final String title;
  final String subtitle;

  const _StepTile({
    required this.step,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariantDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A3A)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppTheme.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                step,
                style: const TextStyle(
                  fontFamily: 'Manrope',
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: AppTheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppTheme.textPrimaryDark,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Manrope',
                    fontSize: 12,
                    color: AppTheme.textSecondaryDark,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
