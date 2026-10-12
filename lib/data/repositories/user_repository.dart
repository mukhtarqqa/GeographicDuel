import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_profile.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  UserRepository._internal();
  static UserRepository get instance => _instance;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }
  final String _collection = 'users';

  Future<UserProfile> getUserProfile(String uid) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final doc = await firestore.collection(_collection).doc(uid).get();
        if (doc.exists) {
          return UserProfile.fromFirestore(doc);
        } else {
          // Create new profile if not exists
          final newProfile = UserProfile(
            uid: uid,
            displayName: 'Зерттеуші #${uid.length > 4 ? uid.substring(0, 4) : uid}',
            eloRating: 1240,
            matchesPlayed: 0,
            matchesWon: 0,
            createdAt: DateTime.now(),
          );
          await firestore.collection(_collection).doc(uid).set(newProfile.toFirestore());
          return newProfile;
        }
      } catch (e) {
        // Fallback below
      }
    }

    return UserProfile(
      uid: uid,
      displayName: 'Зерттеуші',
      eloRating: 1240,
      matchesPlayed: 0,
      matchesWon: 0,
      createdAt: DateTime.now(),
    );
  }

  Stream<UserProfile?> streamUserProfile(String uid) {
    final firestore = _firestore;
    if (firestore == null) {
      return Stream.value(UserProfile(
        uid: uid,
        displayName: 'Зерттеуші',
        eloRating: 1240,
        matchesPlayed: 0,
        matchesWon: 0,
        createdAt: DateTime.now(),
      ));
    }
    return firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }

  Future<List<UserProfile>> getLeaderboard({int limit = 20}) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        final querySnapshot = await firestore
            .collection(_collection)
            .orderBy('eloRating', descending: true)
            .limit(limit)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          return querySnapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
        }
      } catch (e) {
        // Fallback to default leaderboard
      }
    }

    // Әдепкі офлайн / локальді көшбасшылар кестесі
    return [
      UserProfile(uid: 'u_1', displayName: 'Шоқан Уәлиханов', eloRating: 1680, matchesPlayed: 50, matchesWon: 42, createdAt: DateTime.now()),
      UserProfile(uid: 'u_2', displayName: 'Әлкей Марғұлан', eloRating: 1540, matchesPlayed: 45, matchesWon: 35, createdAt: DateTime.now()),
      UserProfile(uid: 'u_3', displayName: 'Марко Поло', eloRating: 1490, matchesPlayed: 40, matchesWon: 29, createdAt: DateTime.now()),
      UserProfile(uid: 'u_4', displayName: 'Фернан Магеллан', eloRating: 1420, matchesPlayed: 34, matchesWon: 26, createdAt: DateTime.now()),
      UserProfile(uid: 'u_5', displayName: 'Қаныш Сәтбаев', eloRating: 1380, matchesPlayed: 28, matchesWon: 19, createdAt: DateTime.now()),
      UserProfile(uid: 'u_6', displayName: 'Зерттеуші (Сіз)', eloRating: 1240, matchesPlayed: 18, matchesWon: 14, createdAt: DateTime.now()),
      UserProfile(uid: 'u_7', displayName: 'Ибн Баттута', eloRating: 1190, matchesPlayed: 22, matchesWon: 11, createdAt: DateTime.now()),
    ];
  }

  /// Пайдаланушының есімін/лақап атын жаңарту
  Future<void> updateDisplayName(String uid, String newName) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection(_collection).doc(uid).set({
          'displayName': newName.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Fallback
      }
    }
  }

  /// Пайдаланушының аватарын/фотосын жаңарту
  Future<void> updatePhotoUrl(String uid, String photoUrl) async {
    final firestore = _firestore;
    if (firestore != null) {
      try {
        await firestore.collection(_collection).doc(uid).set({
          'photoUrl': photoUrl.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        // Fallback
      }
    }
  }
}
