import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/player_state.dart';

class MatchmakingService {
  final FirebaseFirestore? firestore;

  MatchmakingService({this.firestore});

  // Live multiplayer matchmaking via Firestore
  Future<void> startFirebaseMatchmaking(
    PlayerState user, 
    Function(String matchId, PlayerState opponent) onMatchFound
  ) async {
    if (firestore == null) return;

    try {
      final queueQuery = await firestore!.collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .limit(5)
          .get();

      if (queueQuery.docs.isNotEmpty) {
        final doc = queueQuery.docs.first;
        if (doc.id != user.id) {
          final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';

          await firestore!.collection('matches').doc(matchId).set({
            'player1': doc.id,
            'player1Name': doc.data()['name'],
            'player1Rating': doc.data()['rating'],
            'player1Health': 6000,
            'player2': user.id,
            'player2Name': user.name,
            'player2Rating': user.rating,
            'player2Health': 6000,
            'status': 'active',
            'currentRound': 1,
          });

          await doc.reference.update({
            'status': 'matched',
            'matchId': matchId,
          });

          final opponent = PlayerState(
            id: doc.id,
            name: doc.data()['name'] as String,
            rating: doc.data()['rating'] as int,
            health: 6000,
          );
          onMatchFound(matchId, opponent);
          return;
        }
      }

      final ticketRef = firestore!.collection('matchmaking').doc(user.id);
      await ticketRef.set({
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
        'name': user.name,
        'rating': user.rating,
      });
    } catch (e) {
      // Graceful error handling
    }
  }

  Future<void> cancelMatchmaking(String userId) async {
    if (firestore != null) {
      await firestore!.collection('matchmaking').doc(userId).delete().catchError((_) {});
    }
  }
}
