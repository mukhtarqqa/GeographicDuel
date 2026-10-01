import 'dart:async';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import '../../domain/models/geo_point.dart';
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';

abstract class IDuelService {
  Future<PlayerState> signInAnonymously();
  Future<PlayerState?> getCurrentUser();
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  });
  void cancelMatchmaking();
  Stream<Map<String, dynamic>?> listenToMatch(String matchId);
  Future<void> registerGuess({
    required String matchId,
    required int roundNumber,
    required GeoPoint guess,
  });
  Future<DuelRoundResult> submitGuess({
    required String matchId,
    required int roundNumber,
    required GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  });
}

/// Firebase & Local Hybrid Service
/// Implements standard Cloud Firestore / Cloud Functions protocols with instant offline fallback
class FirebaseDuelService implements IDuelService {
  static final FirebaseDuelService instance = FirebaseDuelService._();
  FirebaseDuelService._();

  PlayerState? _currentUser;
  Timer? _matchmakingTimer;
  final _random = math.Random();

  @override
  Future<PlayerState> signInAnonymously() async {
    if (_currentUser != null) return _currentUser!;

    try {
      final userCredential = await FirebaseAuth.instance.signInAnonymously();
      _currentUser = PlayerState(
        id: userCredential.user?.uid ?? 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Исследователь',
        rating: 1240,
        health: 6000,
      );
    } catch (e) {
      _currentUser = PlayerState(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Исследователь',
        rating: 1240,
        health: 6000,
      );
    }
    return _currentUser!;
  }

  @override
  Future<PlayerState?> getCurrentUser() async {
    return _currentUser ?? await signInAnonymously();
  }

  StreamSubscription? _matchmakingSub;

  @override
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async {
    cancelMatchmaking();

    final player = await getCurrentUser();
    if (player == null) return;

    try {
      final firestore = FirebaseFirestore.instance;
      final matchmakingRef = firestore.collection('matchmaking');

      // Look for a waiting player
      final querySnapshot = await matchmakingRef.limit(1).get();

      if (querySnapshot.docs.isNotEmpty) {
        // Match found!
        final opponentDoc = querySnapshot.docs.first;
        final opponentData = opponentDoc.data();

        final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
        final opponentId = opponentDoc.id;
        final opponentName = opponentData['name'] ?? 'Соперник';
        final opponentRating = opponentData['rating'] ?? 1000;

        await opponentDoc.reference.delete(); // Remove them from queue

        // Create match document
        await firestore.collection('matches').doc(matchId).set({
          'player1': player.id,
          'player2': opponentId,
          'player1Name': player.name,
          'player2Name': opponentName,
          'status': 'active',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final opponent = PlayerState(
          id: opponentId,
          name: opponentName,
          rating: opponentRating,
          health: 6000,
        );
        onMatchFound(matchId, opponent);
      } else {
        // Enter queue
        await matchmakingRef.doc(player.id).set({
          'name': player.name,
          'rating': player.rating,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Wait to be matched
        _matchmakingSub = firestore.collection('matches')
          .where('player2', isEqualTo: player.id)
          .snapshots()
          .listen((snapshot) {
            if (snapshot.docs.isNotEmpty) {
              final matchDoc = snapshot.docs.first;
              final matchData = matchDoc.data();

              final opponentId = matchData['player1'];
              final opponentName = matchData['player1Name'] ?? 'Соперник';
              final opponentRating = 1200; // Simplified

              final opponent = PlayerState(
                id: opponentId,
                name: opponentName,
                rating: opponentRating,
                health: 6000,
              );

              _matchmakingSub?.cancel();
              onMatchFound(matchDoc.id, opponent);
            }
        });
      }
    } catch (e) {
      // Fallback to offline mock behavior if Firestore fails
      final delayMs = 1200 + _random.nextInt(1000);
      _matchmakingTimer = Timer(Duration(milliseconds: delayMs), () {
        final opponents = [
          PlayerState(id: 'opp_1', name: 'Алина', rating: 1285, health: 6000),
          PlayerState(id: 'opp_2', name: 'Максим', rating: 1190, health: 6000),
          PlayerState(id: 'opp_3', name: 'София', rating: 1310, health: 6000),
          PlayerState(id: 'opp_4', name: 'Данияр', rating: 1250, health: 6000),
        ];
        final opponent = opponents[_random.nextInt(opponents.length)];
        final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
        onMatchFound(matchId, opponent);
      });
    }
  }

  @override
  void cancelMatchmaking() {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
    _matchmakingSub?.cancel();
    _matchmakingSub = null;
    if (_currentUser != null) {
      try {
        FirebaseFirestore.instance.collection('matchmaking').doc(_currentUser!.id).delete();
      } catch (_) {}
    }
  }

  @override
  Stream<Map<String, dynamic>?> listenToMatch(String matchId) {
    try {
      return FirebaseFirestore.instance
          .collection('matches')
          .doc(matchId)
          .snapshots()
          .map((snapshot) => snapshot.data());
    } catch (e) {
      return Stream.value(null);
    }
  }

  @override
  Future<void> registerGuess({
    required String matchId,
    required int roundNumber,
    required GeoPoint guess,
  }) async {
    final playerId = _currentUser?.id;
    if (playerId == null) return;

    try {
      final matchRef = FirebaseFirestore.instance.collection('matches').doc(matchId);
      await matchRef.set({
        'guesses': {
          roundNumber.toString(): {
            playerId: {
              'lat': guess.latitude,
              'lon': guess.longitude,
            }
          }
        }
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  @override
  Future<DuelRoundResult> submitGuess({
    required String matchId,
    required int roundNumber,
    required GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  }) async {
    try {
      final matchRef = FirebaseFirestore.instance.collection('matches').doc(matchId);
      final playerId = _currentUser?.id;

      if (playerId != null) {
        // We write our guess just in case registerGuess didn't fire (e.g. time ran out before user guessed)
        if (playerGuess != null) {
          await registerGuess(matchId: matchId, roundNumber: roundNumber, guess: playerGuess);
        }

        final matchDoc = await matchRef.get();
        final data = matchDoc.data() ?? {};
        final guesses = data['guesses']?[roundNumber.toString()] ?? {};

        // Identify opponent ID
        final p1 = data['player1'];
        final p2 = data['player2'];
        final opponentId = playerId == p1 ? p2 : p1;

        GeoPoint? opponentGuess;
        if (guesses[opponentId] != null) {
          opponentGuess = GeoPoint(guesses[opponentId]['lat'], guesses[opponentId]['lon']);
        } else {
          // Simulate missing opponent guess
          final jitterLat = (_random.nextDouble() - 0.5) * 6.0;
          final jitterLon = (_random.nextDouble() - 0.5) * 8.0;
          opponentGuess = GeoPoint(
            (location.simulatedOpponentGuess.latitude + jitterLat).clamp(-85.0, 85.0),
            (location.simulatedOpponentGuess.longitude + jitterLon).clamp(-180.0, 180.0),
          );
        }

        return DuelRoundResult(
          roundNumber: roundNumber,
          location: location,
          playerGuess: playerGuess,
          opponentGuess: opponentGuess,
          playerHealthRemaining: playerHealth,
          opponentHealthRemaining: opponentHealth,
          multiplier: multiplier,
        );
      }
    } catch (e) {
      // Fallback
    }

    // Fallback: Generate realistic opponent guess (with slight human error based on opponent rating)
    final jitterLat = (_random.nextDouble() - 0.5) * 6.0;
    final jitterLon = (_random.nextDouble() - 0.5) * 8.0;
    final opponentGuess = GeoPoint(
      (location.simulatedOpponentGuess.latitude + jitterLat).clamp(-85.0, 85.0),
      (location.simulatedOpponentGuess.longitude + jitterLon).clamp(-180.0, 180.0),
    );

    final roundResult = DuelRoundResult(
      roundNumber: roundNumber,
      location: location,
      playerGuess: playerGuess,
      opponentGuess: opponentGuess,
      playerHealthRemaining: playerHealth,
      opponentHealthRemaining: opponentHealth,
      multiplier: multiplier,
    );

    return roundResult;
  }
}
