import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geographic_duel/atlas_map.dart';
import 'package:geographic_duel/features/widgets/primary_button.dart';
import 'package:geographic_duel/main.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await AtlasGeometry.load();
  });

  testWidgets('home, cancel matchmaking and profile work at mobile width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeographicDuelApp());
    await tester.pumpAndSettle();
    expect(find.text('Узнайте мир.\nНа глаз.'), findsOneWidget);

    await tester.tap(find.text('Начать дуэль'));
    await tester.pump(const Duration(milliseconds: 300));
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

    await tester.pumpWidget(const GeographicDuelApp());
    await tester.pumpAndSettle();

    // Start duel and wait for matchmaking
    await tester.tap(find.text('Начать дуэль'));
    await tester.pump(const Duration(seconds: 3));
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
    expect(find.text('55 км'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small display does not overflow', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(const GeographicDuelApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
