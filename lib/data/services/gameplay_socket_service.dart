import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../domain/models/geo_point.dart' as domain;
import '../../domain/models/location_item.dart';
import '../../domain/models/player_state.dart';
import '../../domain/models/round_result.dart';
import '../../domain/logic/duel_calculator.dart';

class GameplaySocketService {
  WebSocketChannel? _wsChannel;
  StreamSubscription? _wsSubscription;
  bool serverOnline = false;

  Function(String matchId, PlayerState opponent)? onMatchFoundCallback;
  Function(String error)? onRoomErrorCallback;
  Completer<String?>? roomCreatedCompleter;
  Completer<DuelRoundResult>? roundResultCompleter;
  
  final opponentGuessedController = StreamController<int>.broadcast();

  LocationItem? activeLocation;
  int activeRoundNumber = 1;

  void connectWebSocket(String url) {
    disconnectWebSocket();
    try {
      _wsChannel = WebSocketChannel.connect(Uri.parse(url));
      _wsSubscription = _wsChannel!.stream.listen(
        _handleServerMessage,
        onError: (err) {
          debugPrint('WebSocket error: $err');
          serverOnline = false;
        },
        onDone: () {
          debugPrint('WebSocket closed');
        },
      );
      serverOnline = true;
    } catch (e) {
      debugPrint('WebSocket connection failed: $e');
      serverOnline = false;
    }
  }

  void disconnectWebSocket() {
    _wsSubscription?.cancel();
    _wsSubscription = null;
    _wsChannel?.sink.close();
    _wsChannel = null;
    serverOnline = false;
  }

  void send(Map<String, dynamic> data) {
    _wsChannel?.sink.add(jsonEncode(data));
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
          onMatchFoundCallback?.call(matchId, opponent);
          break;

        case 'room_created':
          final roomCode = data['roomCode'] as String?;
          if (roomCreatedCompleter != null && !roomCreatedCompleter!.isCompleted) {
            roomCreatedCompleter!.complete(roomCode);
          }
          break;

        case 'room_error':
          final msg = data['message'] as String? ?? 'Ошибка комнаты';
          onRoomErrorCallback?.call(msg);
          break;

        case 'opponent_guessed':
          final round = data['roundNumber'] as int? ?? 1;
          opponentGuessedController.add(round);
          break;

        case 'round_result':
          if (roundResultCompleter != null && !roundResultCompleter!.isCompleted) {
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

            final loc = activeLocation!;
            final result = DuelRoundResult(
              roundNumber: data['roundNumber'] as int? ?? activeRoundNumber,
              location: loc,
              playerGuess: pGuess,
              opponentGuess: oGuess,
              playerHealthRemaining: data['playerHealth'] as int? ?? 6000,
              opponentHealthRemaining: data['opponentHealth'] as int? ?? 6000,
              multiplier: DuelCalculator.getMultiplierForRound(activeRoundNumber),
            );
            roundResultCompleter!.complete(result);
          }
          break;
      }
    } catch (e) {
      debugPrint('Error parsing server message: $e');
    }
  }
}
