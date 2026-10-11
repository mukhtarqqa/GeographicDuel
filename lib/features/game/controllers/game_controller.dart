import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../domain/models/geo_point.dart' as domain;
import '../../../domain/models/location_item.dart';
import '../../../domain/models/player_state.dart';
import '../../../domain/models/round_result.dart';
import '../../../domain/logic/duel_calculator.dart';
import '../../../data/firebase/firebase_duel_service.dart';

class GameController extends ChangeNotifier {
  final String matchId;
  final PlayerState player;
  final PlayerState opponent;
  final Function(DuelRoundResult) onRoundFinished;
  final VoidCallback onForfeit;

  GameController({
    required this.matchId,
    required this.player,
    required this.opponent,
    required this.onRoundFinished,
    required this.onForfeit,
  });

  LocationItem? _currentLocation;
  LocationItem? get currentLocation => _currentLocation;

  int _roundNumber = 1;
  int get roundNumber => _roundNumber;

  bool _isRoundActive = false;
  bool get isRoundActive => _isRoundActive;

  int _timeRemaining = 60;
  int get timeRemaining => _timeRemaining;

  bool _isGuessing = false;
  bool get isGuessing => _isGuessing;

  domain.GeoPoint? _playerGuess;
  domain.GeoPoint? get playerGuess => _playerGuess;

  bool _opponentHasGuessed = false;
  bool get opponentHasGuessed => _opponentHasGuessed;

  Timer? _timer;
  StreamSubscription? _opponentGuessSub;

  void startRound(LocationItem location, int roundNum) {
    _currentLocation = location;
    _roundNumber = roundNum;
    _timeRemaining = 60;
    _isRoundActive = true;
    _isGuessing = false;
    _playerGuess = null;
    _opponentHasGuessed = false;

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tickTimer);

    _opponentGuessSub?.cancel();
    _opponentGuessSub = FirebaseDuelService.instance.onOpponentGuessed.listen((round) {
      if (round == _roundNumber) {
        _opponentHasGuessed = true;
        if (_timeRemaining > 15) {
          _timeRemaining = 15;
        }
        notifyListeners();
        
        if (_playerGuess != null) {
          submitGuess();
        }
      }
    });

    notifyListeners();
  }

  void _tickTimer(Timer t) {
    if (_timeRemaining > 0 && _isRoundActive) {
      _timeRemaining--;
      if (_timeRemaining <= 0) {
        submitGuess(); // Auto-submit when time runs out
      }
      notifyListeners();
    } else {
      t.cancel();
    }
  }

  void setGuess(domain.GeoPoint guess) {
    if (!_isRoundActive || _isGuessing) return;
    _playerGuess = guess;
    notifyListeners();
    
    // If opponent already guessed, or after a short delay (1.2s), resolve round
    if (_opponentHasGuessed) {
      submitGuess();
    } else {
      // Give opponent a few seconds to finish or trigger immediate resolution
      Timer(const Duration(milliseconds: 1400), () {
        if (!_isGuessing) {
          _opponentHasGuessed = true;
          submitGuess();
        }
      });
    }
  }

  Future<void> submitGuess() async {
    if (!_isRoundActive || _isGuessing || _currentLocation == null) return;

    _isGuessing = true;
    _isRoundActive = false;
    _timer?.cancel();
    notifyListeners();

    try {
      final result = await FirebaseDuelService.instance.submitGuess(
        matchId: matchId,
        roundNumber: _roundNumber,
        playerGuess: _playerGuess,
        location: _currentLocation!,
        playerHealth: player.health,
        opponentHealth: opponent.health,
        multiplier: DuelCalculator.getMultiplierForRound(_roundNumber),
      );

      onRoundFinished(result);
    } catch (e) {
      debugPrint('Error submitting guess: $e');
      // On error, trigger a forfeit or just continue with zero score
      onForfeit();
    }
  }

  void forceForfeit() {
    _isRoundActive = false;
    _timer?.cancel();
    _opponentGuessSub?.cancel();
    onForfeit();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _opponentGuessSub?.cancel();
    super.dispose();
  }
}
