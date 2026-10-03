import 'dart:async';
import 'dart:math' as math;
import '../../domain/models/geo_point.dart' as domain;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  Future<void> markPlayerGuessed({
    required String matchId,
    required int roundNumber,
    required domain.GeoPoint guess,
  });
  void listenToOpponentGuess({
    required String matchId,
    required int roundNumber,
    required void Function() onOpponentGuessed,
  });
  void stopListeningToOpponentGuess();
  Future<DuelRoundResult> submitGuess({
    required String matchId,
    required int roundNumber,
    required domain.GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  });
}

class FirebaseDuelService implements IDuelService {
  static IDuelService instance = FirebaseDuelService._();
  FirebaseDuelService._();

  PlayerState? _currentUser;
  final _random = math.Random();

  // Realtime matches implementation
  StreamSubscription? _matchSubscription;
  StreamSubscription? _opponentGuessSubscription;
  bool _isPlayer1 = true;
  String? _currentMatchId;
  Completer<DuelRoundResult>? _roundCompleter;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  @override
  Future<PlayerState> signInAnonymously() async {
    if (_currentUser != null) return _currentUser!;

    try {
      UserCredential userCredential = await _auth.signInAnonymously();
      User? user = userCredential.user;

      if (user != null) {
         _currentUser = PlayerState(
          id: user.uid,
          name: 'Игрок ${user.uid.substring(0, 4)}',
          rating: 1240,
          health: 6000,
        );

        // Setup initial user data in firestore
        await _firestore.collection('users').doc(user.uid).set({
            'name': _currentUser!.name,
            'rating': _currentUser!.rating,
            'lastActive': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (e) {
      // Fallback
    }

    _currentUser ??= PlayerState(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Исследователь',
      rating: 1240,
      health: 6000,
    );

    return _currentUser!;
  }

  @override
  Future<PlayerState?> getCurrentUser() async {
    return _currentUser ?? await signInAnonymously();
  }

  @override
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async {
    cancelMatchmaking();
    final user = await getCurrentUser();
    if (user == null) return;

    // Simple matchmaking logic
    // 1. Look for waiting players
    final queueQuery = await _firestore.collection('matchmaking')
        .where('status', isEqualTo: 'waiting')
        .orderBy('joinedAt')
        .limit(1)
        .get();

    if (queueQuery.docs.isNotEmpty) {
        final doc = queueQuery.docs.first;
        if (doc.id != user.id) {
            // Join match
            final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';

            // Setup match
            await _firestore.collection('matches').doc(matchId).set({
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

            // Update matchmaking ticket
            await doc.reference.update({
                'status': 'matched',
                'matchId': matchId,
            });

            _currentMatchId = matchId;
            _isPlayer1 = false;
            final opponent = PlayerState(
                id: doc.id,
                name: doc.data()['name'] as String,
                rating: doc.data()['rating'] as int,
                health: 6000,
            );
            onMatchFound(matchId, opponent);
            _listenToMatch(matchId);
            return;
        }
    }

    // 2. Add to queue
    final ticketRef = _firestore.collection('matchmaking').doc(user.id);
    await ticketRef.set({
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
        'name': user.name,
        'rating': user.rating,
    });

    // Listen for changes to ticket
    _matchSubscription = ticketRef.snapshots().listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data() as Map<String, dynamic>;

        if (data['status'] == 'matched' && data.containsKey('matchId')) {
            _matchSubscription?.cancel();
            final matchId = data['matchId'] as String;
            _currentMatchId = matchId;

            // We need to fetch match to get opponent
            _firestore.collection('matches').doc(matchId).get().then((matchDoc) {
                if (!matchDoc.exists) return;
                final matchData = matchDoc.data()!;

                _isPlayer1 = matchData['player1'] == user.id;

                final oppId = _isPlayer1 ? matchData['player2'] : matchData['player1'];
                final oppName = _isPlayer1 ? matchData['player2Name'] : matchData['player1Name'];
                final oppRating = _isPlayer1 ? matchData['player2Rating'] : matchData['player1Rating'];

                final opponent = PlayerState(
                    id: oppId,
                    name: oppName,
                    rating: oppRating,
                    health: 6000,
                );
                onMatchFound(matchId, opponent);
                _listenToMatch(matchId);
            });
        }
    });
  }

  void _listenToMatch(String matchId) {
      _matchSubscription?.cancel();
      _matchSubscription = _firestore.collection('matches').doc(matchId)
          .collection('rounds').snapshots().listen((snapshot) {
           for (var change in snapshot.docChanges) {
               if (change.type == DocumentChangeType.modified || change.type == DocumentChangeType.added) {
                   final data = change.doc.data()!;
                   if (data.containsKey('p1Guess') && data.containsKey('p2Guess')) {
                       // Both guesses are in!
                       // This can be used for generic processing, but handled specifically per round below
                   }
               }
           }
      });
  }

  @override
  void cancelMatchmaking() {
    _matchSubscription?.cancel();
    _matchSubscription = null;
    _opponentGuessSubscription?.cancel();
    _opponentGuessSubscription = null;

    if (_currentUser != null) {
        _firestore.collection('matchmaking').doc(_currentUser!.id).delete().catchError((_) {});
    }
  }

  @override
  Future<void> markPlayerGuessed({
    required String matchId,
    required int roundNumber,
    required domain.GeoPoint guess,
  }) async {
    final roundRef = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc('round_$roundNumber');

    final guessData = {
      'lat': guess.latitude,
      'lng': guess.longitude,
      'timestamp': FieldValue.serverTimestamp(),
    };

    if (_isPlayer1) {
      await roundRef.set({'p1Guess': guessData}, SetOptions(merge: true));
    } else {
      await roundRef.set({'p2Guess': guessData}, SetOptions(merge: true));
    }
  }

  @override
  void listenToOpponentGuess({
    required String matchId,
    required int roundNumber,
    required void Function() onOpponentGuessed,
  }) {
    stopListeningToOpponentGuess();

    final roundRef = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc('round_$roundNumber');

    _opponentGuessSubscription = roundRef.snapshots().listen((snapshot) {
      if (snapshot.exists) {
        final data = snapshot.data();
        if (data != null) {
          final opponentGuessKey = _isPlayer1 ? 'p2Guess' : 'p1Guess';
          if (data.containsKey(opponentGuessKey)) {
            onOpponentGuessed();
          }
        }
      }
    });
  }

  @override
  void stopListeningToOpponentGuess() {
    _opponentGuessSubscription?.cancel();
    _opponentGuessSubscription = null;
  }

  @override
  Future<DuelRoundResult> submitGuess({
    required String matchId,
    required int roundNumber,
    required domain.GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  }) async {
    final roundRef = _firestore
        .collection('matches')
        .doc(matchId)
        .collection('rounds')
        .doc('round_$roundNumber');

    if (playerGuess != null) {
      // Just to be sure it's saved (might have been saved by markPlayerGuessed)
      final guessData = {
        'lat': playerGuess.latitude,
        'lng': playerGuess.longitude,
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (_isPlayer1) {
        await roundRef.set({'p1Guess': guessData}, SetOptions(merge: true));
      } else {
        await roundRef.set({'p2Guess': guessData}, SetOptions(merge: true));
      }
    } else {
      // No guess submitted in time
      final guessData = {
        'lat': null,
        'lng': null,
        'timestamp': FieldValue.serverTimestamp(),
      };
      if (_isPlayer1) {
        await roundRef.set({'p1Guess': guessData}, SetOptions(merge: true));
      } else {
        await roundRef.set({'p2Guess': guessData}, SetOptions(merge: true));
      }
    }

    // Wait for opponent guess
    domain.GeoPoint? finalOpponentGuess;

    try {
      final docSnapshot = await roundRef.get();
      final data = docSnapshot.data() ?? {};
      final opponentGuessKey = _isPlayer1 ? 'p2Guess' : 'p1Guess';

      if (data.containsKey(opponentGuessKey)) {
        final oppData = data[opponentGuessKey];
        if (oppData != null && oppData['lat'] != null && oppData['lng'] != null) {
          finalOpponentGuess = domain.GeoPoint(oppData['lat'], oppData['lng']);
        }
      } else {
        // Wait for it via stream
        final completer = Completer<domain.GeoPoint?>();
        final sub = roundRef.snapshots().listen((snap) {
          if (snap.exists) {
            final snapData = snap.data();
            if (snapData != null && snapData.containsKey(opponentGuessKey)) {
              final oppData = snapData[opponentGuessKey];
              if (oppData != null && oppData['lat'] != null && oppData['lng'] != null) {
                completer.complete(domain.GeoPoint(oppData['lat'], oppData['lng']));
              } else {
                completer.complete(null);
              }
            }
          }
        });

        // Timeout in case opponent drops
        finalOpponentGuess = await completer.future.timeout(
          const Duration(seconds: 15),
          onTimeout: () => null,
        ).whenComplete(() => sub.cancel());
      }
    } catch (e) {
      // Fallback
    }

    // Stop listening just in case
    stopListeningToOpponentGuess();

    // If opponent didn't guess, simulate one for now to keep game going if they dropped
    if (finalOpponentGuess == null) {
       final jitterLat = (_random.nextDouble() - 0.5) * 6.0;
       final jitterLon = (_random.nextDouble() - 0.5) * 8.0;
       finalOpponentGuess = domain.GeoPoint(
         (location.simulatedOpponentGuess.latitude + jitterLat).clamp(-85.0, 85.0),
         (location.simulatedOpponentGuess.longitude + jitterLon).clamp(-180.0, 180.0),
       );
    }

    final roundResult = DuelRoundResult(
      roundNumber: roundNumber,
      location: location,
      playerGuess: playerGuess,
      opponentGuess: finalOpponentGuess,
      playerHealthRemaining: playerHealth,
      opponentHealthRemaining: opponentHealth,
      multiplier: multiplier,
    );

    return roundResult;
  }
}
