import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'email_verification_screen.dart';

class AuthGate extends StatefulWidget {
  final Future<void> Function() onUserNeedsVerificationCheck;

  const AuthGate({
    super.key,
    required this.onUserNeedsVerificationCheck,
  });

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // 'login' | 'register' | 'verify'
  String _screen = 'login';
  String _pendingEmail = '';

  void _goToLogin() => setState(() => _screen = 'login');
  void _goToRegister() => setState(() => _screen = 'register');

  void _onRegistered(String email) {
    setState(() {
      _pendingEmail = email;
      _screen = 'verify';
    });
  }

  void _onCancelVerification() {
    setState(() {
      _pendingEmail = '';
      _screen = 'register';
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_screen) {
      case 'verify':
        return EmailVerificationScreen(
          email: _pendingEmail,
          onCancel: _onCancelVerification,
          onCheckVerification: widget.onUserNeedsVerificationCheck,
        );
      case 'register':
        return RegisterScreen(
          onGoToLogin: _goToLogin,
          onRegistered: _onRegistered,
        );
      default:
        return LoginScreen(
          onGoToRegister: _goToRegister,
          onSignedIn: widget.onUserNeedsVerificationCheck,
        );
    }
  }
}