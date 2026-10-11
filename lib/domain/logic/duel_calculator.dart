import 'dart:math' as math;

class DuelCalculator {
  static const double baseCoefficient = 1500.0;
  static const int maxPoints = 5000;

  /// Score formula: round(5000 * exp(-distanceKm / 1500))
  static int calculateScore(double? distanceKm) {
    if (distanceKm == null) return 0;
    if (distanceKm < 0) {
      throw ArgumentError('Distance cannot be negative');
    }
    return (maxPoints * math.exp(-distanceKm / baseCoefficient)).round();
  }

  /// Round multiplier for classic GeoGuessr duel escalation
  static double getMultiplierForRound(int roundNumber) {
    switch (roundNumber) {
      case 1:
        return 1.0;
      case 2:
        return 1.2;
      case 3:
        return 1.5;
      case 4:
        return 2.0;
      default:
        return 2.5;
    }
  }

  /// Calculates damage dealt to the loser of the round, factoring in the round multiplier
  static int calculateDamage({
    required int playerScore,
    required int opponentScore,
    double multiplier = 1.0,
  }) {
    final rawDiff = (playerScore - opponentScore).abs();
    return (rawDiff * multiplier).round();
  }

  /// Elo rating change calculation: K = 24
  static int calculateEloChange({
    required int playerRating,
    required int opponentRating,
    required bool playerWon,
    bool isDraw = false,
    int kFactor = 24,
  }) {
    final expectedScore = 1.0 /
        (1.0 + math.pow(10.0, (opponentRating - playerRating) / 400.0));
    final actualScore = isDraw ? 0.5 : (playerWon ? 1.0 : 0.0);
    return (kFactor * (actualScore - expectedScore)).round();
  }
}
