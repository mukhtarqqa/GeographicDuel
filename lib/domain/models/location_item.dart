import 'geo_point.dart';

class LocationItem {
  const LocationItem({
    required this.id,
    required this.title,
    required this.country,
    required this.coordinates,
    required this.imageAsset,
    this.region = '',
    this.description = '',
    this.simulatedOpponentOffset = const GeoPoint(4.2, 5.1),
  });

  final String id;
  final String title;
  final String country;
  final String region;
  final String description;
  final GeoPoint coordinates;
  final String imageAsset;
  final GeoPoint simulatedOpponentOffset;

  GeoPoint get simulatedOpponentGuess => GeoPoint(
        (coordinates.latitude + simulatedOpponentOffset.latitude)
            .clamp(-85.0, 85.0),
        (coordinates.longitude + simulatedOpponentOffset.longitude)
            .clamp(-180.0, 180.0),
      );
}
