import 'dart:async';
import '../models/geo_point.dart' as domain;
import '../models/location_item.dart';
import '../models/player_state.dart';
import '../models/round_result.dart';

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

  Stream<int> get onOpponentGuessed;
  Future<String?> createRoom({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  });
  Future<void> joinRoom({
    required String roomCode,
    required Function(String matchId, PlayerState opponent) onMatchFound,
    required Function(String error) onError,
  });
  
  BackendMode get activeBackendMode;
  bool get isServerAvailable;
  void setMode(BackendMode mode);
}
