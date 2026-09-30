import 'package:festisquad/core/theme/app_theme.dart';
import 'package:festisquad/features/auth/data/auth_repository.dart';
import 'package:festisquad/features/auth/domain/auth_session.dart';
import 'package:festisquad/features/auth/presentation/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a user can complete registration from the welcome screen',
      (tester) async {
    final repository = _RecordingAuthRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [authRepositoryProvider.overrideWithValue(repository)],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('CREAR CUENTA').first);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Nombre'),
      'Usuario E2E',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Correo electrónico'),
      'e2e@festisquad.test',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Contraseña'),
      'ClaveSegura123',
    );
    await tester.ensureVisible(find.text('CREAR CUENTA').last);
    await tester.tap(find.text('CREAR CUENTA').last);
    await tester.pumpAndSettle();

    expect(repository.registrationCount, 1);
    expect(
      find.text('Tu próximo festival empieza aquí'),
      findsNothing,
    );
  });
}

class _RecordingAuthRepository implements AuthRepository {
  int registrationCount = 0;

  static const _session = AuthSession(
    userId: '00000000-0000-0000-0000-000000000013',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async {
    registrationCount++;
    return _session;
  }

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async =>
      _session;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession?> restore() async => null;

  @override
  Future<SocialAuthAttempt> startSocial(
    String provider, {
    bool link = false,
  }) =>
      throw UnimplementedError();

  @override
  Future<SocialAuthResult> finishSocial(String flowToken) =>
      throw UnimplementedError();
}
