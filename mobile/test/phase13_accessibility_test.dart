import 'dart:ui' show Tristate;

import 'package:festisquad/core/theme/app_theme.dart';
import 'package:festisquad/core/theme/festi_widgets.dart';
import 'package:festisquad/features/squads/presentation/squad_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the app no longer starts with fabricated squad data', () {
    expect(activeSquadPreview.value.name, 'Sin squad activo');
    expect(activeSquadPreview.value.members, 0);
    expect(activeSquadPreview.value.id, isNull);
  });

  testWidgets('primary action exposes accessible semantics', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: Scaffold(
          body: BlueButton(label: 'GUARDAR', onPressed: () {}),
        ),
      ),
    );

    final semantics = tester.getSemantics(find.byType(BlueButton));
    expect(semantics.label, 'GUARDAR');
    expect(semantics.flagsCollection.isButton, isTrue);
    expect(semantics.flagsCollection.isEnabled, Tristate.isTrue);
    await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
  });

  testWidgets('empty states remain readable with large text', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: const Scaffold(
            body: SingleChildScrollView(
              child: FestiEmptyState(
                icon: Icons.groups_outlined,
                title: 'Sin squad activo',
                message: 'Crea uno o únete mediante un código privado.',
              ),
            ),
          ),
        ),
      ),
    );

    expect(find.text('Sin squad activo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
