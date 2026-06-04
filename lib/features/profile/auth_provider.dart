import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

class AppAuthProvider with ChangeNotifier {
  User? _user;
  bool _isAnonymous = true;
  bool _initialized = false;

  User? get user => _user;
  bool get isAnonymous => _isAnonymous;
  bool get isLoggedIn => _user != null && !_isAnonymous && Firebase.apps.isNotEmpty;
  bool get initialized => _initialized;
  bool get firebaseReady => Firebase.apps.isNotEmpty;

  AuthProvider() {
    if (Firebase.apps.isNotEmpty) {
      _listen();
    } else {
      _initialized = true;
      notifyListeners();
    }
  }

  void _listen() {
    FirebaseAuth.instance.authStateChanges().listen(_onAuthChanged);
  }

  void _onAuthChanged(User? user) {
    _user = user;
    _isAnonymous = user?.isAnonymous ?? true;
    _initialized = true;
    notifyListeners();
  }

  Future<String?> signIn(String email, String password) async {
    if (Firebase.apps.isEmpty) return 'Firebase chưa sẵn sàng';
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Đăng nhập thất bại';
    }
  }

  Future<String?> signUp(String email, String password) async {
    if (Firebase.apps.isEmpty) return 'Firebase chưa sẵn sàng';
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message ?? 'Đăng ký thất bại';
    }
  }

  Future<void> signOut() async {
    if (Firebase.apps.isEmpty) return;
    await FirebaseAuth.instance.signOut();
    await FirebaseAuth.instance.signInAnonymously();
  }
}
