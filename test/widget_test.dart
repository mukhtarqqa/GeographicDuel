import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geographic_duel/atlas_map.dart';
import 'package:geographic_duel/features/widgets/primary_button.dart';
import 'package:geographic_duel/main.dart';
import 'package:geographic_duel/domain/models/player_state.dart';
import 'package:geographic_duel/domain/models/round_result.dart';
import 'package:geographic_duel/domain/models/location_item.dart';
import 'package:geographic_duel/domain/models/geo_point.dart' as domain;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geographic_duel/data/firebase/firebase_duel_service.dart';
import 'package:geographic_duel/features/auth/auth_screen.dart';
import 'dart:async';

class MockDuelService extends IDuelService {
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
    required Function(String matchId, PlayerState opponent, List<LocationItem> locations) onMatchFound,
  }) async {
    if (shouldDelayMatchmaking) {
      // Test will cancel this before it triggers
      Timer(const Duration(seconds: 1), () {});
    } else {
       // Return async to allow pump to detect it
       Future.delayed(const Duration(milliseconds: 10), () {
           onMatchFound('match_test', PlayerState(id: 'opp_test', name: 'Test', rating: 1200, health: 6000), []);
       });
    }
  }

  @override
  void cancelMatchmaking() {}

  @override
  Stream<DocumentSnapshot>? streamMatch(String matchId) => null;

  @override
  Future<void> signalNextRoundReady({required String matchId, required int roundNumber}) async {}

  @override
  Future<int> recordMatchResult({
    required String matchId,
    required bool won,
    required int myRating,
    required int oppRating,
  }) async => 24;

  @override
  Future<List<LocationItem>> getMatchLocations(String matchId) async => [];

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
      opponentGuess: const domain.GeoPoint(0, 0),
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

    expect(find.text('Әлемді таны.\nКөзбен.'), findsOneWidget);

    await tester.tap(find.text('Жылдам жекпе-жек'));
    await tester.pump();
    expect(find.text('Екі ойыншыға арналған әлем.'), findsOneWidget);

    await tester.tap(find.text('Іздеуді тоқтату'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();
    expect(find.text('Жылдам жекпе-жек'), findsOneWidget);

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
    await tester.tap(find.text('Жылдам жекпе-жек'));
    await tester.pump(const Duration(milliseconds: 10));
    await tester.pumpAndSettle();

    // Game screen should be active with FloatingGuessMap
    var confirm = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Белгі қойыңыз'),
    );
    expect(confirm.onPressed, isNull);

    // Enter manual coordinates to test exact guess
    await tester.tap(find.byTooltip('Координаттарды енгізу'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).at(0), '45.8');
    await tester.enterText(find.byType(TextField).at(1), '3.4');
    await tester.tap(find.byTooltip('Координаттарды қолдану'));
    await tester.pumpAndSettle();

    confirm = tester.widget<PrimaryButton>(
      find.widgetWithText(PrimaryButton, 'Жауап беру'),
    );
    expect(confirm.onPressed, isNotNull);

    await tester.tap(find.text('Жауап беру'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();

    // Verify round result screen rendered without exceptions
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

  testWidgets('AuthScreen validates empty fields and switches between login and registration in Kazakh', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: AuthScreen(),
    ));
    await tester.pumpAndSettle();

    // Verify initial Login screen elements in Kazakh
    expect(find.text('Жүйеге кіру'), findsWidgets);
    expect(find.text('Кіру'), findsOneWidget);
    expect(find.text('Тіркелу'), findsOneWidget);

    // Press Login with empty fields to trigger validation
    await tester.tap(find.widgetWithText(PrimaryButton, 'Жүйеге кіру'));
    await tester.pumpAndSettle();
    expect(find.text('Электрондық поштаны енгізіңіз'), findsOneWidget);
    expect(find.text('Құпиясөзді енгізіңіз'), findsOneWidget);

    // Switch to Registration tab
    await tester.tap(find.text('Тіркелу').first);
    await tester.pumpAndSettle();

    expect(find.text('Жаңа тіркелу'), findsOneWidget);
    expect(find.text('Зерттеушінің аты (Аты-жөні)'), findsOneWidget);
    expect(find.text('Құпиясөзді растау'), findsOneWidget);

    // Trigger validation on Registration
    final registerBtn = find.widgetWithText(PrimaryButton, 'Тіркелуді аяқтау');
    await tester.ensureVisible(registerBtn);
    await tester.tap(registerBtn);
    await tester.pumpAndSettle();
    expect(find.text('Аты-жөніңізді енгізіңіз'), findsOneWidget);
  });

  testWidgets('ProfileScreen logout button displays confirmation dialog in Kazakh', (tester) async {
    await tester.pumpWidget(const GeographicDuelApp(testMode: true));
    await tester.pumpAndSettle();

    // Navigate to Profile tab
    await tester.tap(find.text('Профиль'));
    await tester.pumpAndSettle();

    // Verify profile header and logout action
    expect(find.text('ЗЕРТТЕУШІ ПРОФИЛІ'), findsOneWidget);
    expect(find.text('Жүйеден шығу'), findsOneWidget);

    // Tap Logout button
    await tester.tap(find.text('Жүйеден шығу'));
    await tester.pumpAndSettle();

    // Verify confirmation dialog in pure Kazakh
    expect(find.text('Шынымен аккаунтыңыздан шыққыңыз келе ме? Қайта кіру үшін авторизация қажет болады.'), findsOneWidget);
    expect(find.text('Болдырмау'), findsOneWidget);
    expect(find.text('Иә, шығу'), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Болдырмау'));
    await tester.pumpAndSettle();
    expect(find.text('ЗЕРТТЕУШІ ПРОФИЛІ'), findsOneWidget);
  });
}
