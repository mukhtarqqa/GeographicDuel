import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/models/geo_point.dart' as domain;
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../domain/logic/duel_calculator.dart';
import '../../firebase_options.dart';

enum BackendMode {
  auto,
  onlineServer,
  firebase,
  bot,
}

abstract class IDuelService {
  Future<PlayerState> signInAnonymously();
  Future<PlayerState?> getCurrentUser();
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
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

  // Extended multiplayer features with default fallbacks
  Stream<int> get onOpponentGuessed => const Stream.empty();
  Future<String?> createRoom({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async => null;
  Future<void> joinRoom({
    required String roomCode,
    required Function(String matchId, PlayerState opponent) onMatchFound,
    required Function(String error) onError,
  }) async {}
  BackendMode get activeBackendMode => BackendMode.bot;
  bool get isServerAvailable => false;
  void setMode(BackendMode mode) {}
}

class FirebaseDuelService implements IDuelService {
  static IDuelService instance = FirebaseDuelService._();
  FirebaseDuelService._() {
    checkServerAvailability();
  }

  PlayerState? _currentUser;
  final _random = math.Random();
  BackendMode _mode = BackendMode.auto;
  bool _serverOnline = false;

  // Realtime WebSocket Channel
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  Function(String matchId, PlayerState opponent)? _onMatchFoundCallback;
  Function(String error)? _onRoomErrorCallback;
  Completer<DuelRoundResult>? _roundResultCompleter;
  Completer<String?>? _roomCreatedCompleter;
  LocationItem? _activeLocation;
  int _activeRoundNumber = 1;
  StreamSubscription<DocumentSnapshot>? _firebaseMatchSubscription;
  StreamSubscription<DocumentSnapshot>? _firebaseTicketSubscription;

  final _opponentGuessedController = StreamController<int>.broadcast();
  @override
  Stream<int> get onOpponentGuessed => _opponentGuessedController.stream;

  @override
  BackendMode get activeBackendMode {
    if (_mode != BackendMode.auto) return _mode;
    if (_serverOnline) return BackendMode.onlineServer;
    if (DefaultFirebaseOptions.isConfigured) return BackendMode.firebase;
    return BackendMode.bot;
  }

  @override
  bool get isServerAvailable => _serverOnline;

  @override
  void setMode(BackendMode mode) {
    _mode = mode;
  }

  String get _serverHttpUrl => 'http://localhost:8088';
  String get _serverWsUrl => 'ws://localhost:8088';

  Future<bool> checkServerAvailability() async {
    try {
      final response = await http.get(Uri.parse('$_serverHttpUrl/health'))
          .timeout(const Duration(milliseconds: 1200));
      _serverOnline = (response.statusCode == 200);
    } catch (_) {
      _serverOnline = false;
    }
    return _serverOnline;
  }

  FirebaseFirestore? get _firestore {
    if (!DefaultFirebaseOptions.isConfigured) return null;
    try {
      return FirebaseFirestore.instance;
    } catch (_) {
      return null;
    }
  }

  FirebaseAuth? get _auth {
    if (!DefaultFirebaseOptions.isConfigured) return null;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PlayerState> signInAnonymously() async {
    if (_currentUser != null) return _currentUser!;

    // Check Firebase if configured
    if (DefaultFirebaseOptions.isConfigured) {
      try {
        final auth = _auth;
        final firestore = _firestore;
        if (auth != null) {
          UserCredential userCredential = await auth.signInAnonymously();
          User? user = userCredential.user;

          if (user != null) {
            _currentUser = PlayerState(
              id: user.uid,
              name: 'Исследователь ${user.uid.substring(0, math.min(4, user.uid.length))}',
              rating: 1240,
              health: 6000,
            );

            await firestore?.collection('users').doc(user.uid).set({
              'name': _currentUser!.name,
              'rating': _currentUser!.rating,
              'lastActive': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

            return _currentUser!;
          }
        }
      } catch (e) {
        debugPrint('Firebase Auth notice: $e');
      }
    }

    // Default local profile
    _currentUser = PlayerState(
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

  // --- WebSocket Connection Management ---
  void _connectWebSocket() {
    _disconnectWebSocket();
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(_serverWsUrl));
      _wsSubscription = _wsChannel!.stream.listen(
        _handleServerMessage,
        onError: (err) {
          debugPrint('WebSocket error: $err');
          _serverOnline = false;
        },
        onDone: () {
          debugPrint('WebSocket closed');
        },
      );
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      _serverOnline = false;
    }
  }

  void _disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
  }

  void _handleServerMessage(dynamic message) {
    try {
      final data = jsonDecode(message as String) as Map<String, dynamic>;
      final type = data['type'] as String?;

      switch (type) {
        case 'match_found':
          final matchId = data['matchId'] as String;
          final oppData = data['opponent'] as Map<String, dynamic>;
          final opponent = PlayerState(
            id: oppData['id'] as String,
            name: oppData['name'] as String,
            rating: oppData['rating'] as int,
            health: oppData['health'] as int? ?? 6000,
          );
          _onMatchFoundCallback?.call(matchId, opponent);
          break;

        case 'room_created':
          final roomCode = data['roomCode'] as String?;
          if (_roomCreatedCompleter != null && !_roomCreatedCompleter!.isCompleted) {
            _roomCreatedCompleter!.complete(roomCode);
          }
          break;

        case 'room_error':
          final msg = data['message'] as String? ?? 'Ошибка комнаты';
          _onRoomErrorCallback?.call(msg);
          break;

        case 'opponent_guessed':
          final round = data['roundNumber'] as int? ?? 1;
          _opponentGuessedController.add(round);
          break;

        case 'round_result':
          if (_roundResultCompleter != null && !_roundResultCompleter!.isCompleted) {
            final pGuessMap = data['playerGuess'] as Map<String, dynamic>?;
            final oGuessMap = data['opponentGuess'] as Map<String, dynamic>?;

            domain.GeoPoint? pGuess;
            if (pGuessMap != null) {
              pGuess = domain.GeoPoint(
                (pGuessMap['latitude'] as num).toDouble(),
                (pGuessMap['longitude'] as num).toDouble(),
              );
            }

            domain.GeoPoint? oGuess;
            if (oGuessMap != null) {
              oGuess = domain.GeoPoint(
                (oGuessMap['latitude'] as num).toDouble(),
                (oGuessMap['longitude'] as num).toDouble(),
              );
            }

            final loc = _activeLocation!;
            final result = DuelRoundResult(
              roundNumber: data['roundNumber'] as int? ?? _activeRoundNumber,
              location: loc,
              playerGuess: pGuess,
              opponentGuess: oGuess,
              playerHealthRemaining: data['playerHealth'] as int? ?? 6000,
              opponentHealthRemaining: data['opponentHealth'] as int? ?? 6000,
              multiplier: DuelCalculator.getMultiplierForRound(_activeRoundNumber),
            );
            _roundResultCompleter!.complete(result);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error parsing server message: $e');
    }
  }

  // --- Matchmaking & Room Management ---
  @override
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async {
    cancelMatchmaking();
    _onMatchFoundCallback = onMatchFound;
    final user = await getCurrentUser();
    if (user == null) return;

    // Check if real server is available
    await checkServerAvailability();

    if (activeBackendMode == BackendMode.onlineServer && _serverOnline) {
      _connectWebSocket();
      _wsChannel?.sink.add(jsonEncode({
        'type': 'join_queue',
        'player': {
          'id': user.id,
          'name': user.name,
          'rating': user.rating,
        },
      }));
      return;
    }

    // Check if Firebase is active
    if (activeBackendMode == BackendMode.firebase) {
      _startFirebaseMatchmaking(user, onMatchFound);
      return;
    }

    // Default to Smart Bot Matchmaking
    _startBotMatchmaking(onMatchFound);
  }

  @override
  Future<String?> createRoom({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async {
    cancelMatchmaking();
    _onMatchFoundCallback = onMatchFound;
    final user = await getCurrentUser();
    if (user == null) return null;

    final isUp = await checkServerAvailability();
    if (!isUp) return null;

    _roomCreatedCompleter = Completer<String?>();
    _connectWebSocket();

    _wsChannel?.sink.add(jsonEncode({
      'type': 'create_room',
      'player': {
        'id': user.id,
        'name': user.name,
        'rating': user.rating,
      },
    }));

    return _roomCreatedCompleter!.future.timeout(
      const Duration(seconds: 4),
      onTimeout: () => null,
    );
  }

  @override
  Future<void> joinRoom({
    required String roomCode,
    required Function(String matchId, PlayerState opponent) onMatchFound,
    required Function(String error) onError,
  }) async {
    cancelMatchmaking();
    _onMatchFoundCallback = onMatchFound;
    _onRoomErrorCallback = onError;
    final user = await getCurrentUser();
    if (user == null) return;

    final isUp = await checkServerAvailability();
    if (!isUp) {
      onError('WebSocket сервер не запущен на порту 8088. Запустите: npm start в папке server');
      return;
    }

    _connectWebSocket();
    _wsChannel?.sink.add(jsonEncode({
      'type': 'join_room',
      'roomCode': roomCode,
      'player': {
        'id': user.id,
        'name': user.name,
        'rating': user.rating,
      },
    }));
  }

  void _startBotMatchmaking(Function(String matchId, PlayerState opponent) onMatchFound) {
    final bots = [
      PlayerState(id: 'bot_marco', name: 'Марко Поло', rating: 1340, health: 6000),
      PlayerState(id: 'bot_amelia', name: 'Амелия Эрхарт', rating: 1410, health: 6000),
      PlayerState(id: 'bot_magellan', name: 'Фернан Магеллан', rating: 1280, health: 6000),
      PlayerState(id: 'bot_columbus', name: 'Христофор Колумб', rating: 1190, health: 6000),
    ];
    final selectedBot = bots[_random.nextInt(bots.length)];

    Timer(const Duration(milliseconds: 1400), () {
      onMatchFound('match_bot_${DateTime.now().millisecondsSinceEpoch}', selectedBot);
    });
  }

  void _startFirebaseMatchmaking(PlayerState user, Function(String matchId, PlayerState opponent) onMatchFound) async {
    final firestore = _firestore;
    if (firestore == null) {
      _startBotMatchmaking(onMatchFound);
      return;
    }

    try {
      final queueQuery = await firestore.collection('matchmaking')
          .where('status', isEqualTo: 'waiting')
          .orderBy('joinedAt')
          .limit(1)
          .get();

      if (queueQuery.docs.isNotEmpty) {
        final doc = queueQuery.docs.first;
        if (doc.id != user.id) {
          final matchId = 'match_${DateTime.now().millisecondsSinceEpoch}';

          await firestore.collection('matches').doc(matchId).set({
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
          _listenToFirebaseMatch(matchId, user.id, onMatchFound, opponent);
          return;
        }
      }

      final ticketRef = firestore.collection('matchmaking').doc(user.id);
      await ticketRef.set({
        'status': 'waiting',
        'joinedAt': FieldValue.serverTimestamp(),
        'name': user.name,
        'rating': user.rating,
      });

      // Listen for when we get matched
      _firebaseTicketSubscription?.cancel();
      _firebaseTicketSubscription = ticketRef.snapshots().listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        if (data != null && data['status'] == 'matched' && data['matchId'] != null) {
          final matchId = data['matchId'] as String;
          // Get opponent data from match
          firestore.collection('matches').doc(matchId).get().then((matchDoc) {
            if (matchDoc.exists) {
              final matchData = matchDoc.data()!;
              final isPlayer1 = matchData['player1'] == user.id;
              final opponent = PlayerState(
                id: isPlayer1 ? matchData['player2'] : matchData['player1'],
                name: isPlayer1 ? matchData['player2Name'] : matchData['player1Name'],
                rating: isPlayer1 ? matchData['player2Rating'] : matchData['player1Rating'],
                health: matchData['player2Health'] as int? ?? 6000,
              );
              _listenToFirebaseMatch(matchId, user.id, onMatchFound, opponent);
              // Clear our ticket
              ticketRef.delete();
              _firebaseTicketSubscription?.cancel();
            }
          });
        }
      });
    } catch (_) {
      _startBotMatchmaking(onMatchFound);
    }
  }

  void _listenToFirebaseMatch(String matchId, String userId, Function(String matchId, PlayerState opponent) onMatchFound, PlayerState opponent) {
    onMatchFound(matchId, opponent);

    _firebaseMatchSubscription?.cancel();
    _firebaseMatchSubscription = _firestore?.collection('matches').doc(matchId).snapshots().listen((snapshot) {
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      final isPlayer1 = data['player1'] == userId;

      final guesses = data['guesses'] as Map<String, dynamic>? ?? {};

      // Iterate through guesses for active round instead of currentRound field because currentRound is shared.
      // Alternatively, we use _activeRoundNumber from the local state.
      final targetRound = _activeRoundNumber;
      final targetRoundData = guesses[targetRound.toString()] as Map<String, dynamic>?;

      if (targetRoundData != null) {
        final opponentGuess = isPlayer1 ? targetRoundData['player2'] : targetRoundData['player1'];
        if (opponentGuess != null) {
           _opponentGuessedController.add(targetRound);
        }

        final myGuess = isPlayer1 ? targetRoundData['player1'] : targetRoundData['player2'];

        // If both have guessed
        if (myGuess != null && opponentGuess != null && _roundResultCompleter != null && !_roundResultCompleter!.isCompleted) {
          domain.GeoPoint? pGuess;
          if (myGuess['latitude'] != null) {
            pGuess = domain.GeoPoint((myGuess['latitude'] as num).toDouble(), (myGuess['longitude'] as num).toDouble());
          }
          domain.GeoPoint? oGuess;
          if (opponentGuess['latitude'] != null) {
            oGuess = domain.GeoPoint((opponentGuess['latitude'] as num).toDouble(), (opponentGuess['longitude'] as num).toDouble());
          }

          // Calculate damage locally
          final loc = _activeLocation!;
          double d1 = 20000;
          double d2 = 20000;

          double calcDist(double lat1, double lon1, double lat2, double lon2) {
            final R = 6371;
            final dLat = (lat2 - lat1) * math.pi / 180;
            final dLon = (lon2 - lon1) * math.pi / 180;
            final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
                math.cos(lat1 * math.pi / 180) * math.cos(lat2 * math.pi / 180) *
                math.sin(dLon / 2) * math.sin(dLon / 2);
            final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
            return R * c;
          }

          if (pGuess != null) {
             d1 = calcDist(loc.coordinates.latitude, loc.coordinates.longitude, pGuess.latitude, pGuess.longitude);
          }
          if (oGuess != null) {
             d2 = calcDist(loc.coordinates.latitude, loc.coordinates.longitude, oGuess.latitude, oGuess.longitude);
          }

          final multiplier = DuelCalculator.getMultiplierForRound(targetRound);
          final pScore = DuelCalculator.calculateScore(d1);
          final oScore = DuelCalculator.calculateScore(d2);
          final damage = DuelCalculator.calculateDamage(
            playerScore: pScore,
            opponentScore: oScore,
            multiplier: multiplier
          );

          int pHealth = isPlayer1 ? (data['player1Health'] as int? ?? 6000) : (data['player2Health'] as int? ?? 6000);
          int oHealth = isPlayer1 ? (data['player2Health'] as int? ?? 6000) : (data['player1Health'] as int? ?? 6000);

          if (d1 < d2) {
            oHealth = math.max(0, oHealth - damage);
          } else if (d2 < d1) {
            pHealth = math.max(0, pHealth - damage);
          }

          // Player 1 commits the calculated health state and advances round
          if (isPlayer1) {
             _firestore?.collection('matches').doc(matchId).update({
                'player1Health': pHealth,
                'player2Health': oHealth,
                'currentRound': targetRound + 1,
             });
          }

          final result = DuelRoundResult(
            roundNumber: targetRound,
            location: loc,
            playerGuess: pGuess,
            opponentGuess: oGuess,
            playerHealthRemaining: pHealth,
            opponentHealthRemaining: oHealth,
            multiplier: multiplier,
          );
          _roundResultCompleter!.complete(result);
        }
      }
    });
  }

  @override
  void cancelMatchmaking() {
    _wsChannel?.sink.add(jsonEncode({'type': 'cancel_queue'}));
    _disconnectWebSocket();
    _firebaseMatchSubscription?.cancel();
    _firebaseTicketSubscription?.cancel();
    _onMatchFoundCallback = null;
    _onRoomErrorCallback = null;

    if (_currentUser != null && _firestore != null) {
      _firestore?.collection('matchmaking').doc(_currentUser!.id).delete().catchError((_) {});
    }
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
    _activeLocation = location;
    _activeRoundNumber = roundNumber;

    // 1. If connected to Realtime Server
    if (_serverOnline && _wsChannel != null && !matchId.startsWith('match_bot_')) {
      _roundResultCompleter = Completer<DuelRoundResult>();

      _wsChannel!.sink.add(jsonEncode({
        'type': 'submit_guess',
        'matchId': matchId,
        'roundNumber': roundNumber,
        'guess': playerGuess != null
            ? {'latitude': playerGuess.latitude, 'longitude': playerGuess.longitude}
            : null,
      }));

      return _roundResultCompleter!.future.timeout(
        const Duration(seconds: 20),
        onTimeout: () {
          return _generateDeterministicResult(
            roundNumber: roundNumber,
            playerGuess: playerGuess,
            location: location,
            playerHealth: playerHealth,
            opponentHealth: opponentHealth,
            multiplier: multiplier,
          );
        },
      );
    }

    // 2. If using Firebase mode
    if (activeBackendMode == BackendMode.firebase && !matchId.startsWith('match_bot_') && _firestore != null && _currentUser != null) {
       _roundResultCompleter = Completer<DuelRoundResult>();

       final matchRef = _firestore!.collection('matches').doc(matchId);

       try {
         final doc = await matchRef.get();
         if (doc.exists) {
           final isPlayer1 = doc.data()!['player1'] == _currentUser!.id;
           final playerKey = isPlayer1 ? 'player1' : 'player2';

           final guessData = playerGuess != null ? {
             'latitude': playerGuess.latitude,
             'longitude': playerGuess.longitude,
           } : {'skipped': true};

           await matchRef.set({
             'guesses': {
               roundNumber.toString(): {
                 playerKey: guessData
               }
             }
           }, SetOptions(merge: true));
         }

         return _roundResultCompleter!.future.timeout(
           const Duration(seconds: 20),
           onTimeout: () {
             return _generateDeterministicResult(
               roundNumber: roundNumber,
               playerGuess: playerGuess,
               location: location,
               playerHealth: playerHealth,
               opponentHealth: opponentHealth,
               multiplier: multiplier,
             );
           },
         );
       } catch (e) {
         debugPrint('Firebase submit guess error: $e');
       }
    }

    // 3. Offline / Smart AI Bot Mode
    return _generateDeterministicResult(
      roundNumber: roundNumber,
      playerGuess: playerGuess,
      location: location,
      playerHealth: playerHealth,
      opponentHealth: opponentHealth,
      multiplier: multiplier,
    );
  }

  DuelRoundResult _generateDeterministicResult({
    required int roundNumber,
    required domain.GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  }) {
    // Generate an intelligent bot guess near the location
    final jitterLat = (_random.nextDouble() - 0.5) * 5.0;
    final jitterLon = (_random.nextDouble() - 0.5) * 6.5;

    final opponentGuess = domain.GeoPoint(
      (location.simulatedOpponentGuess.latitude + jitterLat).clamp(-85.0, 85.0),
      (location.simulatedOpponentGuess.longitude + jitterLon).clamp(-180.0, 180.0),
    );

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
}
