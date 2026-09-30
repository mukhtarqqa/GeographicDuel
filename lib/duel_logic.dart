import 'dart:math' as math;
import 'domain/models/geo_point.dart';

export 'domain/models/geo_point.dart';

class RoundResult {
  RoundResult(this.guess);
  static const target = GeoPoint(45.52824, 2.81401);
  static const opponent = GeoPoint(46.4, 11.5);
  final GeoPoint? guess;
  double? get distance => guess?.distanceTo(target);
  double get opponentDistance => opponent.distanceTo(target);
  static int score(double km) {
    if (!km.isFinite || km < 0) throw ArgumentError.value(km, 'km');
    return (5000 * math.exp(-km / 1500)).round();
  }

  int get playerScore => distance == null ? 0 : score(distance!);
  int get opponentScore => score(opponentDistance);
  int get damage => (playerScore - opponentScore).abs();
  bool get won => playerScore > opponentScore;
  bool get tied => playerScore == opponentScore;
  int get remainingHealth => math.max(0, 6000 - damage);
  String get title => tied
      ? 'Одинаково точно.'
      : won
      ? 'Вы оказались ближе.'
      : 'На этот раз — Алина.';
}

String grouped(int value) => value.toString().replaceAllMapped(
  RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
  (m) => '${m[1]}\u00a0',
);
