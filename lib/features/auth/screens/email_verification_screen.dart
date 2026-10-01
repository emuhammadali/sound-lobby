import 'dart:async';
import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../shared/widgets/app_button.dart';

class EmailVerificationScreen extends StatefulWidget {
  final String email;
  final VoidCallback onCancel;
  final Future<void> Function() onCheckVerification;

  const EmailVerificationScreen({
    super.key,
    required this.email,
    required this.onCancel,
    required this.onCheckVerification,
  });

  @override
  State<EmailVerificationScreen> createState() =>
      _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();

  bool _checking = false;
  bool _resending = false;
  bool _cancelling = false;
  String? _error;
  String? _success;

  // Auto-check every 4 seconds
  Timer? _autoCheckTimer;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _startAutoCheck();
  }

  @override
  void dispose() {
    _autoCheckTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _startAutoCheck() {
    _autoCheckTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerification(auto: true),
    );
  }

  Future<void> _checkVerification({bool auto = false}) async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _error = null;
      if (!auto) _success = null;
    });

    try {
      await widget.onCheckVerification();

      if (mounted && !auto) {
        setState(() => _error =
            'Email not verified yet. Please click the link in your inbox.');
      }
    } catch (e) {
      if (mounted && !auto) {
        setState(() => _error = e.toString().replaceAll('Exception: ', ''));
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;
    setState(() {
      _resending = true;
      _error = null;
      _success = null;
    });

    try {
      await _authService.resendVerificationEmail();
      if (!mounted) return;
      setState(() {
        _success = 'Verification email resent!';
        _resendCooldown = 30;
      });

      // Cooldown countdown
      _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _resendCooldown--);
        if (_resendCooldown <= 0) t.cancel();
      });
    } catch (e) {
      if (mounted) {
        setState(() => _error = 'Failed to resend. Try again shortly.');
      }
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  Future<void> _cancel() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A2E),
        title: const Text('Cancel Registration',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This will delete your account. You can register again anytime.',
          style: TextStyle(color: Color(0xFF9E9EC8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Go back',
                style: TextStyle(color: Color(0xFF9E9EC8))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancel registration',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;
    setState(() => _cancelling = true);

    try {
      _autoCheckTimer?.cancel();
      await _authService.deleteUnverifiedAccount();
      if (mounted) widget.onCancel();
    } catch (e) {
      if (mounted) {
        setState(() {
          _cancelling = false;
          _error = 'Could not cancel. Try again.';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            children: [
              const Spacer(),

              // Icon
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A2E),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF6C63FF), width: 2),
                ),
                child: const Icon(Icons.mark_email_unread_outlined,
                    color: Color(0xFF6C63FF), size: 42),
              ),
              const SizedBox(height: 28),

              const Text(
                'Verify your email',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'We sent a verification link to:',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6), fontSize: 14),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                widget.email,
                style: const TextStyle(
                  color: Color(0xFF6C63FF),
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Click the link in the email to verify your account. This screen will update automatically.',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Auto-check pulse indicator
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      color: const Color(0xFF6C63FF),
                      strokeWidth: 2,
                      value: _checking ? null : 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Checking automatically...',
                    style: TextStyle(color: Color(0xFF9E9EC8), fontSize: 12),
                  ),
                ],
              ),

              // Error / success messages
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.redAccent, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_error!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],
              if (_success != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2ECC71).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFF2ECC71).withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          color: Color(0xFF2ECC71), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(_success!,
                            style: const TextStyle(
                                color: Color(0xFF2ECC71), fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              const Spacer(),

              // I've verified button
              AppButton(
                label: "I've Verified My Email",
                isLoading: _checking,
                onPressed: () => _checkVerification(auto: false),
              ),
              const SizedBox(height: 12),

              // Resend
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed:
                      (_resendCooldown > 0 || _resending) ? null : _resend,
                  icon: _resending
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Color(0xFF6C63FF)),
                        )
                      : const Icon(Icons.refresh,
                          color: Color(0xFF6C63FF), size: 18),
                  label: Text(
                    _resendCooldown > 0
                        ? 'Resend in ${_resendCooldown}s'
                        : 'Resend Email',
                    style: const TextStyle(color: Color(0xFF6C63FF)),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                      color: _resendCooldown > 0
                          ? const Color(0xFF6C63FF).withValues(alpha: 0.3)
                          : const Color(0xFF6C63FF),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Cancel
              TextButton(
                onPressed: _cancelling ? null : _cancel,
                child: _cancelling
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.redAccent),
                      )
                    : const Text(
                        'Cancel registration',
                        style: TextStyle(color: Colors.redAccent, fontSize: 13),
                      ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
