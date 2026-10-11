import 'package:flutter_test/flutter_test.dart';
import 'package:geographic_duel/duel_logic.dart';
import 'package:geographic_duel/atlas_map.dart';

void main() {
  test('identical coordinates have no distance and maximum points', () {
    expect(RoundResult.target.distanceTo(RoundResult.target), 0);
    expect(RoundResult.score(0), 5000);
  });

  test('approved example matches the original prototype', () {
    final result = RoundResult(const GeoPoint(45.8, 3.4));
    expect(result.distance!.round(), 55);
    expect(result.playerScore, 4821);
    expect(result.opponentScore, 3182);
    expect(result.damage, 1639);
    expect(result.remainingHealth, 4361);
    expect(result.won, isTrue);
  });

  test('no confirmed answer is zero points, not the draft position', () {
    final result = RoundResult(null);
    expect(result.playerScore, 0);
    expect(result.won, isFalse);
    expect(result.remainingHealth, 2818);
  });

  test('matching opponent answer produces a tie without damage', () {
    final result = RoundResult(RoundResult.opponent);
    expect(result.tied, isTrue);
    expect(result.damage, 0);
  });

  test('invalid coordinates and score inputs are rejected', () {
    expect(const GeoPoint(91, 0).isValid, isFalse);
    expect(GeoPoint(double.nan, 0).isValid, isFalse);
    expect(() => RoundResult.score(-1), throwsArgumentError);
    expect(
      () => const GeoPoint(0, 200).distanceTo(RoundResult.target),
      throwsArgumentError,
    );
  });

  test('map taps and markers use inverse projections', () {
    for (final point in [
      const GeoPoint(43.2, 76.9),
      const GeoPoint(-30, -70),
      const GeoPoint(0, 179.5),
      RoundResult.target,
    ]) {
      final restored = AtlasProjection.invert(AtlasProjection.project(point));
      expect(restored.latitude, closeTo(point.latitude, .000001));
      expect(restored.longitude, closeTo(point.longitude, .000001));
    }
  });
}
