import 'dart:math' as math;
import '../../domain/models/geo_point.dart';
import '../../domain/models/location_item.dart';
import '../../firebase_options.dart';

class LocationApiService {
  LocationApiService._();
  static final LocationApiService instance = LocationApiService._();

  static const String _streetViewBase = 'https://maps.googleapis.com/maps/api/streetview';

  /// Generates a Google Street View API URL for a given coordinate
  static String getStreetViewUrl({
    required double lat,
    required double lng,
    int width = 1200,
    int height = 800,
    int fov = 100,
    int heading = 0,
    int pitch = 0,
  }) {
    final key = DefaultFirebaseOptions.web.apiKey;
    return '$_streetViewBase?size=${width}x$height&location=$lat,$lng&fov=$fov&heading=$heading&pitch=$pitch&key=$key';
  }

  /// Master list of rich authentic worldwide & Kazakhstan locations with high-res panoramic photography
  static final List<LocationItem> _curatedLocations = [
    // --- Қазақстан (Kazakhstan) ---
    LocationItem(
      id: 'kz_astana_baiterek',
      title: 'Астана · «Бәйтерек» монументі',
      country: 'Қазақстан',
      region: 'Астана қаласы',
      description: 'Қазақстан астанасының орталығындағы ұлттық монумент.',
      coordinates: const GeoPoint(51.1283, 71.4305),
      imageUrl: 'https://images.unsplash.com/photo-1558588942-930faae5a389?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'kz_almaty_medeu',
      title: 'Алматы · «Медеу» шатқалы',
      country: 'Қазақстан',
      region: 'Алматы облысы',
      description: 'Іле Алатауының биік таулы шатқалындағы әлемге әйгілі мұз айдыны.',
      coordinates: const GeoPoint(43.1574, 77.0588),
      imageUrl: 'https://images.unsplash.com/photo-1588668214407-6ea9a6d8c272?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'kz_charyn_canyon',
      title: 'Шарын шатқалы · «Қамалдар аңғары»',
      country: 'Қазақстан',
      region: 'Алматы облысы',
      description: 'Миллиондаған жылдар бойы жел мен су қашаған табиғи каньон.',
      coordinates: const GeoPoint(43.3512, 79.0818),
      imageUrl: 'https://images.unsplash.com/photo-1629814696229-37f2d5924765?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'kz_turkistan_yassawi',
      title: 'Түркістан · Қожа Ахмет Ясауи кесенесі',
      country: 'Қазақстан',
      region: 'Түркістан облысы',
      description: 'XIV ғасырдағы Әмір Темір салған керемет сәулет ескерткіші.',
      coordinates: const GeoPoint(43.2974, 68.2709),
      imageUrl: 'https://images.unsplash.com/photo-1609137144820-221087d19760?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'kz_burabay_borovoe',
      title: 'Бурабай · Оқжетпес шыңы',
      country: 'Қазақстан',
      region: 'Ақмола облысы',
      description: 'Көкшетау қыратындағы қайыңды-қарағайлы ормандар мен таңғажайып көлдер.',
      coordinates: const GeoPoint(53.0833, 70.3000),
      imageUrl: 'https://images.unsplash.com/photo-1596484552834-6a58f850e0a1?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'kz_kolsay_lakes',
      title: 'Көлсай көлдері · Солтүстік Тянь-Шань',
      country: 'Қазақстан',
      region: 'Алматы облысы',
      description: 'Қарағайлы таулар қоршаған зүбәржат түсті биік тау көлдері.',
      coordinates: const GeoPoint(42.9847, 78.3242),
      imageUrl: 'https://images.unsplash.com/photo-1506744038136-46273834b3fb?auto=format&fit=crop&w=1600&q=80',
    ),

    // --- Әлемдік қалалар мен табиғат (World Locations) ---
    LocationItem(
      id: 'world_paris_eiffel',
      title: 'Париж · Эйфель мұнарасы',
      country: 'Франция',
      region: 'Иль-де-Франс',
      description: 'Сена өзенінің жағасында орналасқан әлемдік сәулет туындысы.',
      coordinates: const GeoPoint(48.8584, 2.2945),
      imageUrl: 'https://images.unsplash.com/photo-1511739001486-6bfe10ce785f?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_tokyo_shibuya',
      title: 'Токио · Сибуя қиылысы',
      country: 'Жапония',
      region: 'Канто',
      description: 'Әлемдегі ең қарбалас әрі жарық диодты экрандары бар жаяу жүргіншілер қиылысы.',
      coordinates: const GeoPoint(35.6595, 139.7005),
      imageUrl: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_rome_colosseum',
      title: 'Рим · Колизей амфитеатры',
      country: 'Италия',
      region: 'Лацио',
      description: 'Ежелгі Рим империясының ең ірі амфитеатры.',
      coordinates: const GeoPoint(41.8902, 12.4922),
      imageUrl: 'https://images.unsplash.com/photo-1552832230-c0197dd311b5?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_newyork_manhattan',
      title: 'Нью-Йорк · Манхэттен орталығы',
      country: 'АҚШ',
      region: 'Нью-Йорк штаты',
      description: 'Зәулім ғимараттар мен Таймс-сквер орналасқан алып мегаполис.',
      coordinates: const GeoPoint(40.7580, -73.9855),
      imageUrl: 'https://images.unsplash.com/photo-1496442226666-8d4d0e62e6e9?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_rio_christ',
      title: 'Рио-де-Жанейро · Корковадо шыңы',
      country: 'Бразилия',
      region: 'Оңтүстік-Шығыс',
      description: 'Мұхит жағалауы мен тропикалық джунгли үстіндегі алып монумент.',
      coordinates: const GeoPoint(-22.9519, -43.2105),
      imageUrl: 'https://images.unsplash.com/photo-1483729558449-99ef09a8c325?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_sydney_opera',
      title: 'Сидней · Опера театры мен Гавань',
      country: 'Австралия',
      region: 'Жаңа Оңтүстік Уэльс',
      description: 'Порт-Джексон шығанағының жағасындағы парустар бейнесіндегі ғимарат.',
      coordinates: const GeoPoint(-33.8568, 151.2153),
      imageUrl: 'https://images.unsplash.com/photo-1506973035872-a4ec16b8e8d9?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_cairo_pyramids',
      title: 'Каир · Гиза пирамидалары',
      country: 'Мысыр',
      region: 'Солтүстік Африка',
      description: 'Мыңжылдық тарихы бар ежелгі әлемнің ғажайыбы.',
      coordinates: const GeoPoint(29.9792, 31.1342),
      imageUrl: 'https://images.unsplash.com/photo-1503177119275-0aa32b3a9368?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_london_bigben',
      title: 'Лондон · Вестминстер сарайы',
      country: 'Ұлыбритания',
      region: 'Еуропа',
      description: 'Темза жағалауындағы тарихи парламент ғимараты мен Биг-Бен мұнарасы.',
      coordinates: const GeoPoint(51.5007, -0.1246),
      imageUrl: 'https://images.unsplash.com/photo-1513635269975-59663e0ac1ad?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_dubai_burjkhalifa',
      title: 'Дубай · Бурдж-Халифа',
      country: 'БАӘ',
      region: 'Таяу Шығыс',
      description: 'Шөл далада бой көтерген әлемдегі ең биік зәулім ғимарат.',
      coordinates: const GeoPoint(25.1972, 55.2744),
      imageUrl: 'https://images.unsplash.com/photo-1512453979798-5ea266f8880c?auto=format&fit=crop&w=1600&q=80',
    ),
    LocationItem(
      id: 'world_tromso_fjords',
      title: 'Тромсё · Солтүстік шұғыла фьордтары',
      country: 'Норвегия',
      region: 'Скандинавия',
      description: 'Арктикалық мұхит пен сұлу құз-жартастар көрінісі.',
      coordinates: const GeoPoint(69.6492, 18.9553),
      imageUrl: 'https://images.unsplash.com/photo-1517411032315-54ef2cb783bb?auto=format&fit=crop&w=1600&q=80',
    ),
  ];

  /// Returns deterministically or randomly chosen unique locations for a match (up to 10 rounds)
  List<LocationItem> generateMatchLocations({int count = 10, int? seed}) {
    final list = List<LocationItem>.from(_curatedLocations);
    final rng = seed != null ? math.Random(seed) : math.Random();
    list.shuffle(rng);
    return list.take(count).toList();
  }
}
