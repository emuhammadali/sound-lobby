import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'features/auth/screens/auth_gate.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/lobby/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const SoundLobbyApp());
}

class SoundLobbyApp extends StatelessWidget {
  const SoundLobbyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SoundLobby',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF6C63FF),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const _Root(),
    );
  }
}

class _Root extends StatefulWidget {
  const _Root();

  @override
  State<_Root> createState() => _RootState();
}

class _RootState extends State<_Root> {
  bool _splashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 3000), () {
      if (mounted) setState(() => _splashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) return const SplashScreen();
    return const _AuthRouter();
  }
}

// ── Handles all auth routing including email verification ─────────────────────

class _AuthRouter extends StatefulWidget {
  const _AuthRouter();

  @override
  State<_AuthRouter> createState() => _AuthRouterState();
}

class _AuthRouterState extends State<_AuthRouter> with WidgetsBindingObserver {
  User? _user;
  bool _emailVerified = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Called every time the app comes back to foreground
  // This catches the case where user verified in browser then switches back
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _reloadUser();
    }
  }

  Future<void> _init() async {
    // Listen to auth state changes (sign in / sign out)
    FirebaseAuth.instance.authStateChanges().listen((user) async {
      if (!mounted) return;

      if (user == null) {
        setState(() {
          _user = null;
          _emailVerified = false;
          _loading = false;
        });
        return;
      }

      // Reload to get fresh emailVerified status
      await user.reload();
      final fresh = FirebaseAuth.instance.currentUser;

      if (!mounted) return;
      setState(() {
        _user = fresh;
        _emailVerified = fresh?.emailVerified ?? false;
        _loading = false;
      });
    });
  }

  // Called by verification screen's "I've verified" button and on app resume
  Future<void> _reloadUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await user.reload();
    final fresh = FirebaseAuth.instance.currentUser;
    if (!mounted) return;

    setState(() {
      _user = fresh;
      _emailVerified = fresh?.emailVerified ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F0F1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF6C63FF)),
        ),
      );
    }

    if (_user == null) {
      return AuthGate(onUserNeedsVerificationCheck: _reloadUser);
    }

    if (!_emailVerified) {
      return AuthGate(onUserNeedsVerificationCheck: _reloadUser);
    }

    return const HomeScreen();
  }
}