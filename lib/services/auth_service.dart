import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/models/user_profile.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  AuthService._internal();
  static AuthService get instance => _instance;

  FirebaseAuth? get _auth {
    try {
      return FirebaseAuth.instance;
    } catch (e) {
      return null;
    }
  }

  User? get currentUser {
    try {
      return _auth?.currentUser;
    } catch (_) {
      return null;
    }
  }

  Stream<User?> get authStateChanges {
    try {
      return _auth?.authStateChanges() ?? const Stream.empty();
    } catch (_) {
      return const Stream.empty();
    }
  }

  /// Электрондық пошта және құпиясөз арқылы жаңа пайдаланушыны тіркеу
  Future<UserCredential?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth іске қосылмаған');
    }

    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;
    if (user != null) {
      final name = displayName.trim().isNotEmpty ? displayName.trim() : 'Зерттеуші';
      try {
        await user.updateDisplayName(name);
      } catch (_) {}

      // Пайдаланушының бастапқы профилін Firestore-ға сақтау
      try {
        final profile = UserProfile(
          uid: user.uid,
          displayName: name,
          eloRating: 1200,
          matchesPlayed: 0,
          matchesWon: 0,
          createdAt: DateTime.now(),
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set(profile.toFirestore());
      } catch (e) {
        debugPrint('Firestore-ға профиль сақтау ескертпесі: $e');
      }
    }

    return credential;
  }

  /// Электрондық пошта және құпиясөз арқылы авторизациядан өту (кіру)
  Future<UserCredential?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth іске қосылмаған');
    }

    return await auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  /// Google аккаунты арқылы кіру (Google Sign-In)
  Future<UserCredential?> signInWithGoogle() async {
    final auth = _auth;
    if (auth == null) {
      throw Exception('Firebase Auth іске қосылмаған');
    }

    try {
      final googleProvider = GoogleAuthProvider();
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      googleProvider.setCustomParameters({'prompt': 'select_account'});

      final credential = await auth.signInWithPopup(googleProvider);
      final user = credential.user;
      if (user != null) {
        final name = (user.displayName != null && user.displayName!.isNotEmpty)
            ? user.displayName!
            : (user.email?.split('@').first ?? 'Зерттеуші');

        try {
          final profile = UserProfile(
            uid: user.uid,
            displayName: name,
            eloRating: 1200,
            matchesPlayed: 0,
            matchesWon: 0,
            createdAt: DateTime.now(),
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(profile.toFirestore(), SetOptions(merge: true));
        } catch (e) {
          debugPrint('Firestore-ға профиль сақтау ескертпесі: $e');
        }
      }
      return credential;
    } catch (e) {
      debugPrint('Google арқылы кіру қатесі: $e');
      rethrow;
    }
  }

  /// Қонақ ретінде (анонимді) жылдам кіру
  Future<User?> signInAnonymously() async {
    try {
      final auth = _auth;
      if (auth == null) return null;
      if (currentUser != null && !currentUser!.isAnonymous) {
        return currentUser;
      }
      final UserCredential userCredential = await auth.signInAnonymously();
      return userCredential.user;
    } catch (e) {
      debugPrint('Қонақ ретінде кіру қатесі: $e');
      return null;
    }
  }

  /// Жүйеден шығу (Сессияны толық тазарту)
  Future<void> signOut() async {
    try {
      await _auth?.signOut();
    } catch (e) {
      debugPrint('Шығу кезіндегі қате: $e');
    }
  }

  /// Профиль есімін жаңарту
  Future<void> updateDisplayName(String newName) async {
    try {
      await currentUser?.updateDisplayName(newName.trim());
    } catch (e) {
      debugPrint('Firebase Auth есімді жаңарту қатесі: $e');
    }
  }

  /// Профиль аватарын/суретін жаңарту
  Future<void> updatePhotoUrl(String photoUrl) async {
    try {
      await currentUser?.updatePhotoURL(photoUrl.trim());
    } catch (e) {
      debugPrint('Firebase Auth фото жаңарту қатесі: $e');
    }
  }

  /// Қателерді қазақ тіліне аудару
  static String getKazakhErrorMessage(dynamic error) {
    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'popup-closed-by-user':
          return 'Google терезесі жабылды. Қайталап көріңіз.';
        case 'cancelled-popup-request':
          return 'Авторизация тоқтатылды.';
        case 'popup-blocked':
          return 'Браузерде қалқымалы терезеге (popup) рұқсат беріңіз.';
        case 'email-already-in-use':
          return 'Бұл электрондық пошта жүйеде тіркелген.';
        case 'invalid-email':
          return 'Электрондық пошта пішімі қате.';
        case 'weak-password':
          return 'Құпиясөз тым қарапайым (кемінде 6 таңба қажет).';
        case 'user-not-found':
          return 'Бұл электрондық поштамен тіркелген пайдаланушы табылмады.';
        case 'wrong-password':
        case 'invalid-credential':
          return 'Электрондық пошта немесе құпиясөз қате.';
        case 'network-request-failed':
          return 'Интернет байланысы жоқ немесе желіде қате орын алды.';
        case 'too-many-requests':
          return 'Тым көп әрекет жасалды. Күте тұрыңыз.';
        case 'operation-not-allowed':
          return 'Бұл авторизация түрі Firebase консолінде өшірілген.';
        default:
          return error.message ?? 'Авторизация қатесі орын алды.';
      }
    }
    return error.toString();
  }
}
