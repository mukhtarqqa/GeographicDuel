import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geographic_duel/atlas_map.dart';
import 'package:geographic_duel/features/widgets/primary_button.dart';
import 'package:geographic_duel/main.dart';
import 'package:geographic_duel/domain/models/player_state.dart';
import 'package:geographic_duel/domain/models/round_result.dart';
import 'package:geographic_duel/domain/models/location_item.dart';
import 'package:geographic_duel/domain/models/geo_point.dart' as domain;
import 'package:geographic_duel/data/firebase/firebase_duel_service.dart';
import 'dart:async';

class MockDuelService implements IDuelService {
  PlayerState? _currentUser;
  bool shouldDelayMatchmaking = false;

  @override
  Future<PlayerState> signInAnonymously() async {
    _currentUser = PlayerState(
      id: 'usr_test',
      name: 'Мухтар',
      rating: 1240,
      health: 6000,
    );
    return _currentUser!;
  }

  @override
  Future<PlayerState?> getCurrentUser() async {
    return _currentUser ?? await signInAnonymously();
  }

  @override
  Future<void> startMatchmaking({
    required Function(String matchId, PlayerState opponent) onMatchFound,
  }) async {
    if (shouldDelayMatchmaking) {
      // Test will cancel this before it triggers
      Timer(const Duration(seconds: 1), () {});
    } else {
       // Return async to allow pump to detect it
       Future.delayed(const Duration(milliseconds: 10), () {
           onMatchFound('match_test', PlayerState(id: 'opp_test', name: 'Test', rating: 1200, health: 6000));
       });
    }
  }

  @override
  void cancelMatchmaking() {}

  @override
  Stream<bool> listenToOpponentGuess(String matchId, int roundNumber) {
    return Stream.value(false);
  }

  @override
  Future<DuelRoundResult> submitGuess({
    required String matchId,
    required int roundNumber,
    required domain.GeoPoint? playerGuess,
    required LocationItem location,
    required int playerHealth,
    required int opponentHealth,
    required double multiplier,
  }) async {
    return DuelRoundResult(
      roundNumber: roundNumber,
      location: location,
      playerGuess: playerGuess,
      opponentGuess: domain.GeoPoint(0, 0),
      playerHealthRemaining: playerHealth,
      opponentHealthRemaining: opponentHealth,
      multiplier: multiplier,
    );
  }
}

void main() {
  final mockService = MockDuelService();

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AtlasGeometry.load();
    FirebaseDuelService.instance = mockService;
  });

  testWidgets('home, cancel matchmaking and profile work at mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    mockService.shouldDelayMatchmaking = true;

    await tester.pumpWidget(const GeographicDuelApp(testMode: true));
    await tester.pumpAndSettle();

    expect(find.text('Узнайте мир.\nНа глаз.'), findsOneWidget);

    await tester.tap(find.text('Начать дуэль'));
    await tester.pump();
    expect(find.text('Мир на двоих.'), findsOneWidget);

    await tester.tap(find.text('Отменить поиск'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Начать дуэль'), findsOneWidget);

    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();
    expect(find.text('Мухтар'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile).first);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('game arena floating map requires point and produces round result', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    mockService.shouldDelayMatchmaking = false;

    await tester.pumpWidget(const GeographicDuelApp(testMode: true));
    await tester.pumpAndSettle();

    // Start duel and wait for matchmaking
    await tester.tap(find.text('Начать дуэль'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    // Game screen should be active with FloatingGuessMap
    var confirm = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'ВЫБЕРИТЕ МЕСТО'),
    );
    expect(confirm.onPressed, isNull);

    // Enter manual coordinates to test exact guess
    await tester.tap(find.byTooltip('Ввести координаты'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '45.8');
    await tester.enterText(find.byType(TextField).at(1), '3.4');
    await tester.tap(find.byTooltip('Применить координаты'));
    await tester.pumpAndSettle();

    confirm = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'ОТВЕТИТЬ'),
    );
    expect(confirm.onPressed, isNotNull);

    await tester.tap(find.text('ОТВЕТИТЬ'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify round result screen
    expect(find.text('Вы оказались ближе!'), findsOneWidget);
    // Since we mock it with a tie technically but we can check if it rendered properly
    expect(tester.takeException(), isNull);
  });

  testWidgets('small display does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeographicDuelApp(testMode: true));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
