import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // Register — creates account, saves to Firestore, sends verification email
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final user = credential.user!;

    // Save profile to Firestore immediately
    await _firestore.collection('users').doc(user.uid).set({
      'fullName': fullName,
      'email': email,
    });

    // Send verification email
    await user.sendEmailVerification();

    return user;
  }

  // Re-send verification email
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // Check if current user's email is verified (reloads from Firebase)
  Future<bool> checkEmailVerified() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // Delete unverified account (if user cancels verification)
  Future<void> deleteUnverifiedAccount() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      // Also remove Firestore doc
      await _firestore.collection('users').doc(user.uid).delete();
      await user.delete();
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    // Reload to get fresh verification status
    await credential.user!.reload();
    final fresh = _auth.currentUser!;

    if (!fresh.emailVerified) {
      // Don't sign out — let _AuthRouter show the verification screen
      throw Exception(
          'Please verify your email before signing in. Check your inbox.');
    }

    final doc = await _firestore.collection('users').doc(fresh.uid).get();

    return UserModel.fromMap(doc.data()!, fresh.uid);
  }

  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
