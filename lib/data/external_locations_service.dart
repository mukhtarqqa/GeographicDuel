import 'dart:convert';
import 'package:http/http.dart' as http;
import '../domain/models/geo_point.dart';
import '../domain/models/location_item.dart';
import 'locations_catalog.dart';

class ExternalLocationsService {
  static const String _wikiApiUrl = "https://en.wikipedia.org/w/api.php";

  static Future<LocationItem> getRandomLocation() async {
    try {
      // First, get a random article with coordinates using Wikipedia API
      final url = Uri.parse("$_wikiApiUrl?action=query&list=random&rnnamespace=0&rnlimit=10&format=json");
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List pages = data['query']['random'];

        for (var page in pages) {
           final title = page['title'];
           final pageId = page['id'];

           // Fetch coordinates and extract for this page
           final detailsUrl = Uri.parse("$_wikiApiUrl?action=query&prop=coordinates|extracts&exintro=1&explaintext=1&pageids=$pageId&format=json");
           final detailsResponse = await http.get(detailsUrl);

           if (detailsResponse.statusCode == 200) {
              final detailsData = jsonDecode(detailsResponse.body);
              final pageDetails = detailsData['query']['pages']['$pageId'];

              if (pageDetails != null && pageDetails.containsKey('coordinates')) {
                 final coord = pageDetails['coordinates'][0];
                 final lat = coord['lat'] as double;
                 final lon = coord['lon'] as double;
                 final extract = pageDetails['extract'] as String? ?? "Интересное место, случайно найденное на планете.";

                 // Clean up extract
                 final cleanDescription = extract.length > 150 ? "${extract.substring(0, 147)}..." : extract;

                 return LocationItem(
                   id: 'random_$pageId',
                   title: title,
                   country: 'Загадочный мир',
                   region: 'Случайная координата',
                   description: cleanDescription,
                   coordinates: GeoPoint(lat, lon),
                   imageAsset: 'assets/scene.jpg', // We still use the fallback image since downloading panoramas is tricky
                   simulatedOpponentOffset: GeoPoint(2.0, 3.0),
                 );
              }
           }
        }
      }

      // Fallback to local catalog if API fails or yields no coordinate
      return LocationsCatalog.items.first;

    } catch (e) {
       // Fallback on error
       return LocationsCatalog.items.first;
    }
  }
}
