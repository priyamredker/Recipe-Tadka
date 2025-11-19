import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/app_user.dart';

class AuthService with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: [
      'email',
    ],
  );

  // CHANGE THIS to your own student admin email:
  static const String studentAdminEmail = 'student_admin@gmail.com';
  static const String professorAdminEmail = 'vpg@gmail.com';

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _loading = false;
  bool get loading => _loading;

  AuthService() {
    _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  bool get isLoggedIn => _currentUser != null;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isVIP => _currentUser?.premium == true;

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
      notifyListeners();
      return;
    }

    final uid = firebaseUser.uid;
    final email = firebaseUser.email ?? '';

    final docRef = _db.collection('users').doc(uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      // first time login – create user doc
      final isAdminEmail =
          email == studentAdminEmail || email == professorAdminEmail;

      await docRef.set({
        'email': email,
        'role': isAdminEmail ? 'admin' : 'user',
        'premium': false,
        'createdAt': DateTime.now(),
        'updatedAt': DateTime.now(),
      });

      _currentUser = AppUser(
        uid: uid,
        email: email,
        role: isAdminEmail ? 'admin' : 'user',
        premium: false,
      );
    } else {
      _currentUser = AppUser.fromMap(doc.id, doc.data()!);
    }

    notifyListeners();
  }

  Future<String?> signUp(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> signIn(String email, String password) async {
    try {
      _loading = true;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<String?> signInWithGoogle() async {
    try {
      _loading = true;
      notifyListeners();

      // Ensure we start from a clean session
      await _googleSignIn.signOut();

      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // User cancelled the sign-in flow
        return 'Sign in canceled';
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    } catch (e) {
      return 'Google sign-in failed: $e';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {
      // Ignore Google sign-out failures to avoid blocking the user
    }
    await _auth.signOut();
  }
}
