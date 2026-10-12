import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String uid;
  final String displayName;
  final int eloRating;
  final int matchesPlayed;
  final int matchesWon;
  final DateTime createdAt;
  final String? photoUrl;

  UserProfile({
    required this.uid,
    required this.displayName,
    required this.eloRating,
    required this.matchesPlayed,
    required this.matchesWon,
    required this.createdAt,
    this.photoUrl,
  });

  factory UserProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserProfile(
      uid: data['uid'] ?? doc.id,
      displayName: data['displayName'] ?? data['name'] ?? 'Guest',
      eloRating: data['eloRating']?.toInt() ?? data['rating']?.toInt() ?? 1200,
      matchesPlayed: data['matchesPlayed']?.toInt() ?? 0,
      matchesWon: data['matchesWon']?.toInt() ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      photoUrl: data['photoUrl'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'uid': uid,
      'displayName': displayName,
      'eloRating': eloRating,
      'matchesPlayed': matchesPlayed,
      'matchesWon': matchesWon,
      'createdAt': Timestamp.fromDate(createdAt),
      if (photoUrl != null) 'photoUrl': photoUrl,
    };
  }
}
