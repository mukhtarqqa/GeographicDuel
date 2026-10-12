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
    this.heading = 0,
    this.pitch = 0,
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
  final int heading;
  final int pitch;
  final GeoPoint simulatedOpponentOffset;

  String get effectiveImage => imageUrl.isNotEmpty ? imageUrl : imageAsset;
  bool get isNetworkImage => imageUrl.isNotEmpty && imageUrl.startsWith('http');

  String get googleStreetViewWebUrl =>
      'https://www.google.com/maps/@?api=1&map_action=pano&viewpoint=${coordinates.latitude},${coordinates.longitude}';

  String getGoogleStreetViewEmbedUrl(String apiKey) {
    if (apiKey.isEmpty) {
      return 'https://maps.google.com/maps?q=&layer=c&cbll=${coordinates.latitude},${coordinates.longitude}&cbp=11,$heading,0,$pitch,0&output=svembed';
    }
    return 'https://www.google.com/maps/embed/v1/streetview?key=$apiKey&location=${coordinates.latitude},${coordinates.longitude}&heading=$heading&pitch=$pitch&fov=90';
  }

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
        'heading': heading,
        'pitch': pitch,
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
      heading: (map['heading'] as num?)?.toInt() ?? 0,
      pitch: (map['pitch'] as num?)?.toInt() ?? 0,
    );
  }
}
