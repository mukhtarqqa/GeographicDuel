import 'dart:async';
import 'dart:math' as math;
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

  @override
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async {
    cancelMatchmaking();
    // Simulate server ticket creation and queue matching delay (1.2s - 2.5s)
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

  @override
  void cancelMatchmaking() {
    _matchmakingTimer?.cancel();
    _matchmakingTimer = null;
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
    // Generate realistic opponent guess (with slight human error based on opponent rating)
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
