import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart' hide GeoPoint;
import '../../domain/models/geo_point.dart' as domain;
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../domain/logic/duel_calculator.dart';
import '../../services/auth_service.dart';
import '../repositories/user_repository.dart';
import '../services/location_api_service.dart';

enum BackendMode {
  firebase,
}

abstract class IDuelService {
  Future<PlayerState> signInAnonymously();
  Future<PlayerState?> getCurrentUser();
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
  });
  void cancelMatchmaking();
  Future<DuelRoundResult> submitGuess({
    required String matchId,
    required int roundNumber,
    required domain.GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  });

  Stream<int> get onOpponentGuessed => const Stream.empty();
  Stream<DocumentSnapshot>? streamMatch(String matchId);
  Future<void> signalNextRoundReady({required String matchId, required int roundNumber});
  Future<int> recordMatchResult({
    required String matchId,
    required bool won,
    required int myRating,
    required int oppRating,
  });
  Future<List<LocationItem>> getMatchLocations(String matchId);

  Future<String?> createRoom({
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
  }) async => null;
  Future<void> joinRoom({
    required String roomCode,
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
    required Function(String error) onError,
  }) async {}
  BackendMode get activeBackendMode => BackendMode.firebase;
}

class FirebaseDuelService implements IDuelService {
  static IDuelService instance = FirebaseDuelService._();
  FirebaseDuelService._();

  PlayerState? _currentUser;
  final _random = math.Random();

  StreamSubscription<DocumentSnapshot>? _roomSubscription;
  Function(String matchId, PlayerState opponent, List<LocationItem> locations)? _onMatchFoundCallback;

  final _opponentGuessedController = StreamController<int>.broadcast();
  @override
  Stream<int> get onOpponentGuessed => _opponentGuessedController.stream;

  @override
  BackendMode get activeBackendMode => BackendMode.firebase;

  FirebaseFirestore? get _firestore {
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  void clearSession() {
    _currentUser = null;
  }

  @override
  Future<PlayerState> signInAnonymously() async {
    final user = await AuthService.instance.signInAnonymously();
    if (user != null) {
      final userProfile = await UserRepository.instance.getUserProfile(user.uid);
      _currentUser = PlayerState(
        id: user.uid,
        name: userProfile.displayName,
        rating: userProfile.eloRating,
        health: 6000,
      );
      return _currentUser!;
    }

    _currentUser = PlayerState(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Зерттеуші',
      rating: 1200,
      health: 6000,
    );
    return _currentUser!;
  }

  @override
  Future<PlayerState?> getCurrentUser() async {
    final authUser = AuthService.instance.currentUser;
    if (authUser != null) {
      final userProfile = await UserRepository.instance.getUserProfile(authUser.uid);
      _currentUser = PlayerState(
        id: authUser.uid,
        name: userProfile.displayName,
        rating: userProfile.eloRating,
        health: 6000,
        photoUrl: userProfile.photoUrl ?? authUser.photoURL,
      );
      return _currentUser;
    }
    return _currentUser;
  }

  @override
  Stream<DocumentSnapshot>? streamMatch(String matchId) {
    return _firestore?.collection('matches').doc(matchId).snapshots();
  }

  @override
  Future<List<LocationItem>> getMatchLocations(String matchId) async {
    final firestore = _firestore;
    if (firestore == null) return LocationApiService.instance.generateMatchLocations(count: 10);

    try {
      final doc = await firestore.collection('matches').doc(matchId).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        final rawList = data['locations'] as List<dynamic>?;
        if (rawList != null && rawList.isNotEmpty) {
          return rawList.map((m) => LocationItem.fromMap(Map<String, dynamic>.from(m as Map))).toList();
        }
      }
    } catch (e) {
      debugPrint('Error getting match locations: $e');
    }
    return LocationApiService.instance.generateMatchLocations(count: 10);
  }

  // --- Real Firestore Matchmaking ---
  @override
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
  }) async {
    cancelMatchmaking();
    _onMatchFoundCallback = onMatchFound;
    final user = await getCurrentUser();
    if (user == null) return;

    final firestore = _firestore;
    if (firestore == null) {
      debugPrint('Firestore is not available');
      return;
    }

    try {
      // 1. Look for waiting opponents in the queue (no composite index needed)
      final queueQuery = await firestore.collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .limit(10)
          .get();

      DocumentSnapshot? oppDoc;
      for (final doc in queueQuery.docs) {
        if (doc.id != user.id) {
          oppDoc = doc;
          break;
        }
      }

      if (oppDoc != null) {
        final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';
        final oppData = oppDoc.data() as Map<String, dynamic>;

        // Generate 10 synchronized locations for this match
        final locations = LocationApiService.instance.generateMatchLocations(count: 10);
        final locationsMap = locations.map((l) => l.toMap()).toList();

        await firestore.collection('matches').doc(matchId).set({
          'player1': oppDoc.id,
          'player1Name': oppData['name'] ?? 'Қарсылас',
          'player1Rating': oppData['rating'] ?? 1200,
          'player1Health': 6000,
          'player2': user.id,
          'player2Name': user.name,
          'player2Rating': user.rating,
          'player2Health': 6000,
          'status': 'playing',
          'currentRound': 1,
          'p1ReadyNext': false,
          'p2ReadyNext': false,
          'locations': locationsMap,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await oppDoc.reference.update({
          'status': 'matched',
          'matchId': matchId,
        });

        final opponent = PlayerState(
          id: oppDoc.id,
          name: oppData['name'] as String? ?? 'Қарсылас',
          rating: (oppData['rating'] as num?)?.toInt() ?? 1200,
          health: 6000,
        );
        onMatchFound(matchId, opponent, locations);
        return;
      }

      // 2. Put self into the matchmaking queue and wait for second player
      final ticketRef = firestore.collection('matchmaking').doc(user.id);
      await ticketRef.set({
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
        'name': user.name,
        'rating': user.rating,
      });

      _roomSubscription?.cancel();
      _roomSubscription = ticketRef.snapshots().listen((ticketDoc) async {
        if (!ticketDoc.exists) return;
        final ticketData = ticketDoc.data();
        if (ticketData != null && ticketData['status'] == 'matched' && ticketData['matchId'] != null) {
          final matchId = ticketData['matchId'] as String;
          final matchDoc = await firestore.collection('matches').doc(matchId).get();
          if (matchDoc.exists) {
            final matchData = matchDoc.data()!;
            final opponentId = matchData['player2'] as String? ?? '';
            final opponentName = matchData['player2Name'] as String? ?? 'Қарсылас';
            final opponentRating = (matchData['player2Rating'] as num?)?.toInt() ?? 1200;
            final opponent = PlayerState(
              id: opponentId,
              name: opponentName,
              rating: opponentRating,
              health: 6000,
            );

            final rawLocs = matchData['locations'] as List<dynamic>?;
            final locations = rawLocs != null
                ? rawLocs.map((m) => LocationItem.fromMap(Map<String, dynamic>.from(m as Map))).toList()
                : LocationApiService.instance.generateMatchLocations(count: 10);

            _roomSubscription?.cancel();
            _roomSubscription = null;
            ticketRef.delete().catchError((_) {});
            _onMatchFoundCallback?.call(matchId, opponent, locations);
          }
        }
      });
    } catch (e) {
      debugPrint('Firestore Matchmaking error: $e');
    }
  }

  @override
  void cancelMatchmaking() {
    _roomSubscription?.cancel();
    _roomSubscription = null;
    _onMatchFoundCallback = null;

    if (_currentUser != null && _firestore != null) {
      _firestore?.collection('matchmaking').doc(_currentUser!.id).delete().catchError((_) {});
    }
  }

  // --- Real Custom Room Duels ---
  @override
  Future<String?> createRoom({
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
  }) async {
    cancelMatchmaking();
    _onMatchFoundCallback = onMatchFound;
    final user = await getCurrentUser();
    if (user == null) return null;

    final firestore = _firestore;
    if (firestore == null) return null;

    try {
      final randomCode = (_random.nextInt(900000) + 100000).toString(); // 6-digit code
      final matchId = 'room_$randomCode';

      final locations = LocationApiService.instance.generateMatchLocations(count: 10);
      final locationsMap = locations.map((l) => l.toMap()).toList();

      await firestore.collection('matches').doc(matchId).set({
        'roomCode': randomCode,
        'status': 'waiting',
        'createdAt': FieldValue.serverTimestamp(),
        'creatorId': user.id,
        'player1': user.id,
        'player1Name': user.name,
        'player1Rating': user.rating,
        'player1Health': 6000,
        'player2Health': 6000,
        'currentRound': 1,
        'p1ReadyNext': false,
        'p2ReadyNext': false,
        'locations': locationsMap,
      });

      _roomSubscription = firestore.collection('matches').doc(matchId).snapshots().listen((doc) {
        if (!doc.exists) return;
        final data = doc.data()!;
        if ((data['status'] == 'playing' || data['status'] == 'active') && data['player2'] != null) {
          final opponent = PlayerState(
            id: data['player2'] as String,
            name: data['player2Name'] as String,
            rating: (data['player2Rating'] as num?)?.toInt() ?? 1200,
            health: (data['player2Health'] as num?)?.toInt() ?? 6000,
          );
          _roomSubscription?.cancel();
          _roomSubscription = null;
          _onMatchFoundCallback?.call(matchId, opponent, locations);
        }
      });

      return randomCode;
    } catch (e) {
      debugPrint('Error creating Firestore room: $e');
      return null;
    }
  }

  @override
  Future<void> joinRoom({
    required String roomCode,
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
    required Function(String error) onError,
  }) async {
    cancelMatchmaking();
    _onMatchFoundCallback = onMatchFound;
    final user = await getCurrentUser();
    if (user == null) return;

    final firestore = _firestore;
    if (firestore == null) {
      onError('Firebase байланысы жоқ');
      return;
    }

    try {
      final querySnap = await firestore.collection('matches')
          .where('roomCode', isEqualTo: roomCode.trim())
          .limit(1)
          .get();

      if (querySnap.docs.isEmpty) {
        onError('Бөлме табылмады. Кодты тексеріңіз.');
        return;
      }

      final docSnap = querySnap.docs.first;
      final data = docSnap.data();
      if (data['status'] != 'waiting') {
        onError('Ойын басталып кеткен немесе бөлме толы');
        return;
      }

      final docRef = docSnap.reference;
      await docRef.update({
        'player2': user.id,
        'player2Name': user.name,
        'player2Rating': user.rating,
        'player2Health': 6000,
        'status': 'playing',
      });

      final matchId = docSnap.id;
      final opponent = PlayerState(
        id: data['player1'] as String,
        name: data['player1Name'] as String,
        rating: (data['player1Rating'] as num?)?.toInt() ?? 1200,
        health: (data['player1Health'] as num?)?.toInt() ?? 6000,
      );

      final rawLocs = data['locations'] as List<dynamic>?;
      final locations = rawLocs != null
          ? rawLocs.map((m) => LocationItem.fromMap(Map<String, dynamic>.from(m as Map))).toList()
          : LocationApiService.instance.generateMatchLocations(count: 10);

      _onMatchFoundCallback?.call(matchId, opponent, locations);
    } catch (e) {
      debugPrint('Error joining Firestore room: $e');
      onError('Бөлмеге қосылу кезінде қате орын алды');
    }
  }

  // --- Real Guess Submission & Round Synchronization ---
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
    final firestore = _firestore;
    final user = await getCurrentUser();

    if (firestore != null && user != null) {
      try {
        final matchRef = firestore.collection('matches').doc(matchId);
        final matchDoc = await matchRef.get();
        if (matchDoc.exists) {
          final matchData = matchDoc.data()!;
          final isPlayer1 = matchData['player1'] == user.id;

          final roundRef = matchRef.collection('rounds').doc('$roundNumber');
          final guessData = {
            'hasGuessed': true,
            'latitude': playerGuess?.latitude,
            'longitude': playerGuess?.longitude,
            'submittedAt': FieldValue.serverTimestamp(),
          };

          await roundRef.set(
            isPlayer1 ? {'p1Guess': guessData} : {'p2Guess': guessData},
            SetOptions(merge: true),
          );

          final roundCompleter = Completer<DuelRoundResult>();
          StreamSubscription<DocumentSnapshot>? roundSub;

          roundSub = roundRef.snapshots().listen((snapshot) async {
            if (!snapshot.exists) return;
            final data = snapshot.data();
            if (data == null) return;

            final p1GuessData = data['p1Guess'] as Map<String, dynamic>?;
            final p2GuessData = data['p2Guess'] as Map<String, dynamic>?;

            final myGuessData = isPlayer1 ? p1GuessData : p2GuessData;
            final oppGuessData = isPlayer1 ? p2GuessData : p1GuessData;

            if (oppGuessData != null && oppGuessData['hasGuessed'] == true) {
              _opponentGuessedController.add(roundNumber);
            }

            if (myGuessData != null &&
                myGuessData['hasGuessed'] == true &&
                oppGuessData != null &&
                oppGuessData['hasGuessed'] == true &&
                !roundCompleter.isCompleted) {
              domain.GeoPoint? pGuess;
              if (myGuessData['latitude'] != null && myGuessData['longitude'] != null) {
                pGuess = domain.GeoPoint(
                  (myGuessData['latitude'] as num).toDouble(),
                  (myGuessData['longitude'] as num).toDouble(),
                );
              }

              domain.GeoPoint? oGuess;
              if (oppGuessData['latitude'] != null && oppGuessData['longitude'] != null) {
                oGuess = domain.GeoPoint(
                  (oppGuessData['latitude'] as num).toDouble(),
                  (oppGuessData['longitude'] as num).toDouble(),
                );
              }

              final p1ActualGuess = isPlayer1 ? pGuess : oGuess;
              final p2ActualGuess = isPlayer1 ? oGuess : pGuess;

              // Compute distances & damage
              final p1Distance = p1ActualGuess != null ? location.coordinates.distanceTo(p1ActualGuess) : null;
              final p2Distance = p2ActualGuess != null ? location.coordinates.distanceTo(p2ActualGuess) : null;

              final p1Score = DuelCalculator.calculateScore(p1Distance);
              final p2Score = DuelCalculator.calculateScore(p2Distance);
              final roundDamage = DuelCalculator.calculateDamage(
                playerScore: p1Score,
                opponentScore: p2Score,
                multiplier: multiplier,
              );

              int newP1Health = (matchData['player1Health'] as num?)?.toInt() ?? 6000;
              int newP2Health = (matchData['player2Health'] as num?)?.toInt() ?? 6000;

              if (p1Score < p2Score) {
                newP1Health = math.max(0, newP1Health - roundDamage);
              } else if (p2Score < p1Score) {
                newP2Health = math.max(0, newP2Health - roundDamage);
              }

              // Update match document with new healths & check if game is finished
              if (isPlayer1) {
                final isMatchOver = newP1Health <= 0 || newP2Health <= 0 || roundNumber >= 10;
                final updates = <String, dynamic>{
                  'player1Health': newP1Health,
                  'player2Health': newP2Health,
                };
                if (isMatchOver) {
                  updates['status'] = 'finished';
                  updates['winnerId'] = newP1Health > newP2Health
                      ? matchData['player1']
                      : (newP2Health > newP1Health ? matchData['player2'] : 'draw');
                }
                await matchRef.update(updates).catchError((_) {});
              }

              final myRemainingHealth = isPlayer1 ? newP1Health : newP2Health;
              final oppRemainingHealth = isPlayer1 ? newP2Health : newP1Health;

              final result = DuelRoundResult(
                roundNumber: roundNumber,
                location: location,
                playerGuess: pGuess,
                opponentGuess: oGuess,
                playerHealthRemaining: myRemainingHealth,
                opponentHealthRemaining: oppRemainingHealth,
                multiplier: multiplier,
              );

              roundSub?.cancel();
              roundCompleter.complete(result);
            }
          });

          return await roundCompleter.future;
        }
      } catch (e) {
        debugPrint('Error in Firestore submitGuess: $e');
      }
    }

    throw StateError('Firebase байланысы жоқ. Екі ойыншының жауабын синхрондау мүмкін болмады.');
  }

  // --- Synchronized Next Round Signal ---
  @override
  Future<void> signalNextRoundReady({
    required String matchId,
    required int roundNumber,
  }) async {
    final firestore = _firestore;
    final user = await getCurrentUser();
    if (firestore == null || user == null) return;

    try {
      final matchRef = firestore.collection('matches').doc(matchId);
      final matchDoc = await matchRef.get();
      if (!matchDoc.exists) return;

      final matchData = matchDoc.data()!;
      final isPlayer1 = matchData['player1'] == user.id;

      if (isPlayer1) {
        final p2Ready = matchData['p2ReadyNext'] == true;
        if (p2Ready) {
          await matchRef.update({
            'currentRound': roundNumber + 1,
            'p1ReadyNext': false,
            'p2ReadyNext': false,
          });
        } else {
          await matchRef.update({'p1ReadyNext': true});
        }
      } else {
        final p1Ready = matchData['p1ReadyNext'] == true;
        if (p1Ready) {
          await matchRef.update({
            'currentRound': roundNumber + 1,
            'p1ReadyNext': false,
            'p2ReadyNext': false,
          });
        } else {
          await matchRef.update({'p2ReadyNext': true});
        }
      }
    } catch (e) {
      debugPrint('Error signaling next round: $e');
    }
  }

  // --- Real Elo Rating Calculation & Firestore Update ---
  @override
  Future<int> recordMatchResult({
    required String matchId,
    required bool won,
    required int myRating,
    required int oppRating,
  }) async {
    final eloDelta = DuelCalculator.calculateEloChange(
      playerRating: myRating,
      opponentRating: oppRating,
      playerWon: won,
    );

    final newRating = math.max(100, myRating + eloDelta);
    final user = await getCurrentUser();

    if (user != null) {
      _currentUser = user.copyWith(rating: newRating);
      if (_firestore != null) {
        try {
          final userRef = _firestore!.collection('users').doc(user.id);
          await userRef.set({
            'eloRating': newRating,
            'matchesPlayed': FieldValue.increment(1),
            won ? 'wins' : 'losses': FieldValue.increment(1),
            'updatedAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        } catch (e) {
          debugPrint('Error updating user Elo rating in Firestore: $e');
        }
      }
    }

    return eloDelta;
  }
}
