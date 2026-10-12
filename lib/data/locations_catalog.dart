import '../domain/models/location_item.dart';
import 'services/location_api_service.dart';

class LocationsCatalog {
  static List<LocationItem> get items =>
      LocationApiService.instance.generateMatchLocations(count: 50);

  static LocationItem getById(String id) =>
      items.firstWhere((element) => element.id == id, orElse: () => items.first);

  static LocationItem getForRound(int roundNumber, {List<LocationItem>? matchLocations}) {
    if (matchLocations != null && matchLocations.isNotEmpty) {
      final index = (roundNumber - 1) % matchLocations.length;
      return matchLocations[index];
    }
    final list = items;
    final index = (roundNumber - 1) % list.length;
    return list[index];
  }

  static List<LocationItem> getMatchLocations({int count = 10, int? seed}) {
    return LocationApiService.instance.generateMatchLocations(count: count, seed: seed);
  }
}
