import 'geo_point.dart';

class LocationItem {
  const LocationItem({
    required this.id,
    required this.title,
    required this.country,
    required this.coordinates,
    this.imageUrl = '',
    this.imageAsset = 'assets/scene.jpg',
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
  final String imageUrl;
  final String imageAsset;
  final GeoPoint simulatedOpponentOffset;

  String get effectiveImage => imageUrl.isNotEmpty ? imageUrl : imageAsset;
  bool get isNetworkImage => imageUrl.isNotEmpty && imageUrl.startsWith('http');

  GeoPoint get simulatedOpponentGuess => GeoPoint(
        (coordinates.latitude + simulatedOpponentOffset.latitude)
            .clamp(-85.0, 85.0),
        (coordinates.longitude + simulatedOpponentOffset.longitude)
            .clamp(-180.0, 180.0),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'country': country,
        'region': region,
        'description': description,
        'lat': coordinates.latitude,
        'lng': coordinates.longitude,
        'imageUrl': imageUrl,
      };

  factory LocationItem.fromMap(Map<String, dynamic> map) {
    return LocationItem(
      id: map['id'] as String? ?? 'loc',
      title: map['title'] as String? ?? 'Анықталмаған орын',
      country: map['country'] as String? ?? 'Әлем',
      region: map['region'] as String? ?? '',
      description: map['description'] as String? ?? '',
      coordinates: GeoPoint(
        (map['lat'] as num?)?.toDouble() ?? 0.0,
        (map['lng'] as num?)?.toDouble() ?? 0.0,
      ),
      imageUrl: map['imageUrl'] as String? ?? '',
    );
  }
}
