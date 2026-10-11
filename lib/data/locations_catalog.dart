import '../domain/models/geo_point.dart';
import '../domain/models/location_item.dart';

class LocationsCatalog {
  static const List<LocationItem> items = [
    LocationItem(
      id: 'puy_de_sancy',
      title: 'Пюи-де-Санси',
      country: 'Франция',
      region: 'Овернь — Рона — Альпы',
      description: 'Вулканический массив с зелёными субальпийскими лугами и скалистыми хребтами.',
      coordinates: GeoPoint(45.52824, 2.81401),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(4.1, 4.8), // ~600 km away
    ),
    LocationItem(
      id: 'almaty_medeu',
      title: 'Медеу · Заилийский Алатау',
      country: 'Казахстан',
      region: 'Алматинская область',
      description: 'Высокогорное урочище с реликтовыми тянь-шаньскими елями и заснеженными пиками.',
      coordinates: GeoPoint(43.1574, 77.0588),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(-3.2, 5.5),
    ),
    LocationItem(
      id: 'rome_historic',
      title: 'Рим · Холм Целий',
      country: 'Италия',
      region: 'Лацио',
      description: 'Античные терракотовые крыши, средиземноморские сосны пинии и античные руины.',
      coordinates: GeoPoint(41.8902, 12.4922),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(5.2, -6.1),
    ),
    LocationItem(
      id: 'tokyo_metropolis',
      title: 'Токио · Сибуя',
      country: 'Япония',
      region: 'Канто',
      description: 'Урбанистический пейзаж со стеклянными небоскрёбами и плотной сетью эстакад.',
      coordinates: GeoPoint(35.6762, 139.6503),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(3.8, 4.4),
    ),
    LocationItem(
      id: 'tromso_fjords',
      title: 'Тромсё · Арктический фьорд',
      country: 'Норвегия',
      region: 'Тромс-ог-Финнмарк',
      description: 'Субарктический морской залив с крутыми скалами и северным сиянием.',
      coordinates: GeoPoint(69.6492, 18.9553),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(-4.5, 6.2),
    ),
    LocationItem(
      id: 'rio_guanabara',
      title: 'Рио-де-Жанейро',
      country: 'Бразилия',
      region: 'Юго-Восточный регион',
      description: 'Тропические гранитные холмы над океанической бухтой и атлантические джунгли.',
      coordinates: GeoPoint(-22.9068, -43.1729),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(6.1, 7.8),
    ),
    LocationItem(
      id: 'sydney_harbour',
      title: 'Сидней · Залив Порт-Джексон',
      country: 'Австралия',
      region: 'Новый Южный Уэльс',
      description: 'Знаменитая океанская гавань, эвкалиптовое побережье и южное полушарие.',
      coordinates: GeoPoint(-33.8568, 151.2153),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(-5.4, 6.2),
    ),
    LocationItem(
      id: 'cairo_giza',
      title: 'Каир · Плато Гиза',
      country: 'Египет',
      region: 'Северная Африка',
      description: 'Песчаное пустынное плато у долины Нила с тысячелетней историей.',
      coordinates: GeoPoint(29.9792, 31.1342),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(4.2, -3.9),
    ),
    LocationItem(
      id: 'new_york_manhattan',
      title: 'Нью-Йорк · Манхэттен',
      country: 'США',
      region: 'Северная Америка',
      description: 'Знаменитые улицы с небоскребами, желтыми такси и Центральным парком.',
      coordinates: GeoPoint(40.7829, -73.9654),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(3.1, -4.5),
    ),
    LocationItem(
      id: 'london_westminster',
      title: 'Лондон · Вестминстер',
      country: 'Великобритания',
      region: 'Европа',
      description: 'Историческая набережная Темзы, викторианская архитектура и туманная атмосфера.',
      coordinates: GeoPoint(51.5007, -0.1246),
      imageAsset: 'assets/scene.jpg',
      simulatedOpponentOffset: GeoPoint(-2.5, 3.8),
    ),
  ];

  static LocationItem getById(String id) =>
      items.firstWhere((element) => element.id == id, orElse: () => items.first);

  static LocationItem getForRound(int roundNumber) {
    final index = (roundNumber - 1) % items.length;
    return items[index];
  }

  static List<LocationItem> getMatchLocations({int count = 5, int? seed}) {
    final list = List<LocationItem>.from(items);
    if (seed != null) {
      // Deterministic pseudo-shuffle for multiplayer synchronization
      for (int i = list.length - 1; i > 0; i--) {
        final j = (seed * 37 + i * 19) % (i + 1);
        final temp = list[i];
        list[i] = list[j];
        list[j] = temp;
      }
    }
    return list.take(count).toList();
  }
}
