import 'package:festisquad/core/theme/app_theme.dart';
import 'package:festisquad/features/squads/domain/squad_signal.dart';
import 'package:festisquad/features/squads/presentation/squad_signal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the same squad code always produces the same signal identity', () {
    final first = SquadSignalIdentity.fromCode('a1b2c3');
    final second = SquadSignalIdentity.fromCode('A1B2C3');
    final different = SquadSignalIdentity.fromCode('Z9Y8X7');

    expect(second.seed, first.seed);
    expect(second.paletteIndex, first.paletteIndex);
    expect(second.symbolIndex, first.symbolIndex);
    expect(different.seed, isNot(first.seed));
  });

  testWidgets('signal fits a compact phone and stops after its time limit',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: const SquadSignalScreen(
          squadName: 'Headliners',
          squadCode: 'A1B2C3',
          signalDuration: Duration(milliseconds: 80),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('HEADLINERS'), findsOneWidget);
    expect(find.text('A1B2C3'), findsOneWidget);
    expect(find.byKey(const ValueKey('squad-signal-canvas')), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 1));
    expect(find.text('EN PAUSA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
