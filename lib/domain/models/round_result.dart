import '../models/geo_point.dart';
import '../models/location_item.dart';
import '../logic/duel_calculator.dart';

class DuelRoundResult {
  DuelRoundResult({
    required this.roundNumber,
    required this.location,
    required this.playerGuess,
    required this.opponentGuess,
    required this.playerHealthRemaining,
    required this.opponentHealthRemaining,
    this.multiplier = 1.0,
  }) {
    if (playerGuess != null && playerGuess!.isValid) {
      playerDistance = playerGuess!.distanceTo(location.coordinates);
      playerScore = DuelCalculator.calculateScore(playerDistance);
    } else {
      playerDistance = null;
      playerScore = 0;
    }

    if (opponentGuess != null && opponentGuess!.isValid) {
      opponentDistance = opponentGuess!.distanceTo(location.coordinates);
      opponentScore = DuelCalculator.calculateScore(opponentDistance);
    } else {
      opponentDistance = null;
      opponentScore = 0;
    }

    damage = DuelCalculator.calculateDamage(
      playerScore: playerScore,
      opponentScore: opponentScore,
      multiplier: multiplier,
    );

    if (playerScore > opponentScore) {
      outcome = RoundOutcome.playerWon;
    } else if (opponentScore > playerScore) {
      outcome = RoundOutcome.opponentWon;
    } else {
      outcome = RoundOutcome.tie;
    }
  }

  final int roundNumber;
  final LocationItem location;
  final GeoPoint? playerGuess;
  final GeoPoint? opponentGuess;
  final double multiplier;

  late final double? playerDistance;
  late final double? opponentDistance;
  late final int playerScore;
  late final int opponentScore;
  late final int damage;
  late final RoundOutcome outcome;

  final int playerHealthRemaining;
  final int opponentHealthRemaining;

  bool get playerWon => outcome == RoundOutcome.playerWon;
  bool get opponentWon => outcome == RoundOutcome.opponentWon;
  bool get isTie => outcome == RoundOutcome.tie;

  String get summaryTitle {
    switch (outcome) {
      case RoundOutcome.playerWon:
        return 'Вы оказались ближе!';
      case RoundOutcome.opponentWon:
        return 'Соперник оказался ближе';
      case RoundOutcome.tie:
        return 'Ничья в раунде';
    }
  }
}

enum RoundOutcome {
  playerWon,
  opponentWon,
  tie,
}
