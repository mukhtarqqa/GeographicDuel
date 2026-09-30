import 'dart:math' as math;

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;

  bool get isValid =>
      !latitude.isNaN &&
      !longitude.isNaN &&
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180;

  String get label {
    final ns = latitude >= 0 ? 'N' : 'S';
    final ew = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(2)}° $ns, ${longitude.abs().toStringAsFixed(2)}° $ew';
  }

  /// Haversine spherical distance in kilometers
  double distanceTo(GeoPoint other) {
    if (!isValid || !other.isValid) {
      throw ArgumentError('Invalid coordinates for distance calculation');
    }
    const radiusKm = 6371.0088;
    final dLat = (other.latitude - latitude) * math.pi / 180;
    final dLon = (other.longitude - longitude) * math.pi / 180;
    final a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(latitude * math.pi / 180) *
            math.cos(other.latitude * math.pi / 180) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusKm * c;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GeoPoint &&
          (other.latitude - latitude).abs() < 1e-6 &&
          (other.longitude - longitude).abs() < 1e-6;

  @override
  int get hashCode => Object.hash(
        (latitude * 1e5).round(),
        (longitude * 1e5).round(),
      );

  @override
  String toString() => 'GeoPoint($latitude, $longitude)';
}
