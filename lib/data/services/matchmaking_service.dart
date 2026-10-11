import 'dart:async';
import 'dart:math' as math;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/player_state.dart';

class MatchmakingService {
  final FirebaseFirestore? firestore;
  final _random = math.Random();

  MatchmakingService({this.firestore});

  void startBotMatchmaking(Function(String matchId, PlayerState opponent) onMatchFound) {
    // Временно отключили ботов. Всегда ожидаем живого игрока через Firebase.
    // Если нужно вернуть заглушку, раскомментируйте код ниже:
    /*
    final bots = [
      PlayerState(id: 'bot_marco', name: 'Марко Поло', rating: 1340, health: 6000),
      PlayerState(id: 'bot_amelia', name: 'Амелия Эрхарт', rating: 1410, health: 6000),
    ];
    final selectedBot = bots[_random.nextInt(bots.length)];
    Timer(const Duration(milliseconds: 1400), () {
      onMatchFound('match_bot_${DateTime.now().millisecondsSinceEpoch}', selectedBot);
    });
    */
  }

  Future<void> startFirebaseMatchmaking(
    PlayerState user, 
    Function(String matchId, PlayerState opponent) onMatchFound
  ) async {
    if (firestore == null) {
      startBotMatchmaking(onMatchFound);
      return;
    }

    try {
      final queueQuery = await firestore!.collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .orderBy('joinedAt')
          .limit(1)
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
    } catch (_) {
      startBotMatchmaking(onMatchFound);
    }
  }

  Future<void> cancelMatchmaking(String userId) async {
    if (firestore != null) {
      await firestore!.collection('matchmaking').doc(userId).delete().catchError((_) {});
    }
  }
}
