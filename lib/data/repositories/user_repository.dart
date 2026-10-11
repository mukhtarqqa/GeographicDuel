import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/user_profile.dart';

class UserRepository {
  static final UserRepository _instance = UserRepository._internal();
  UserRepository._internal();
  static UserRepository get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  Future<UserProfile> getUserProfile(String uid) async {
    final doc = await _firestore.collection(_collection).doc(uid).get();
    if (doc.exists) {
      return UserProfile.fromFirestore(doc);
    } else {
      // Create new profile if not exists
      final newProfile = UserProfile(
        uid: uid,
        displayName: 'Guest #${uid.length > 4 ? uid.substring(0, 4) : uid}',
        eloRating: 1200,
        matchesPlayed: 0,
        matchesWon: 0,
        createdAt: DateTime.now(),
      );
      await _firestore.collection(_collection).doc(uid).set(newProfile.toFirestore());
      return newProfile;
    }
  }

  Stream<UserProfile?> streamUserProfile(String uid) {
    return _firestore
        .collection(_collection)
        .doc(uid)
        .snapshots()
        .map((doc) => doc.exists ? UserProfile.fromFirestore(doc) : null);
  }

  Future<List<UserProfile>> getLeaderboard({int limit = 20}) async {
    final querySnapshot = await _firestore
        .collection(_collection)
        .orderBy('eloRating', descending: true)
        .limit(limit)
        .get();

    return querySnapshot.docs.map((doc) => UserProfile.fromFirestore(doc)).toList();
  }
}
