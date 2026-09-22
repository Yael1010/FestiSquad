import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:festisquad/core/theme/app_theme.dart';
import 'package:festisquad/core/offline/offline_state.dart';
import 'package:festisquad/features/auth/data/auth_repository.dart';
import 'package:festisquad/features/auth/domain/auth_session.dart';
import 'package:festisquad/features/auth/presentation/login_screen.dart';
import 'package:festisquad/features/squads/presentation/dashboard_screen.dart';
import 'package:festisquad/features/squads/presentation/join_squad_screen.dart';
import 'package:festisquad/features/squads/presentation/squad_preview.dart';
import 'package:festisquad/features/squads/data/squad_repository.dart';
import 'package:festisquad/features/squads/domain/squad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    final loader = FontLoader('FestiSans');
    loader.addFont(rootBundle.load('assets/fonts/roboto-regular.ttf'));
    await loader.load();
    final icons = FontLoader('MaterialIcons');
    icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
    await icons.load();
  });
  final screens = <String, Widget>{
    'welcome': const LoginScreen(),
    'dashboard': const DashboardScreen(),
    'join': const JoinSquadScreen()
  };
  for (final entry in screens.entries) {
    testWidgets('${entry.key} adapts to small, large and accessible layouts',
        (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      tester.view.devicePixelRatio = 1;
      for (final size in [
        const Size(320, 740),
        const Size(430, 932),
        const Size(1280, 900)
      ]) {
        tester.view.physicalSize = size;
        await tester.pumpWidget(ProviderScope(overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository())
        ], child: MaterialApp(theme: buildAppTheme(), home: entry.value)));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: '${entry.key} at $size');
      }
      tester.view.physicalSize = const Size(390, 844);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository())
          ],
          child: MaterialApp(
              theme: buildAppTheme(),
              builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context)
                      .copyWith(textScaler: const TextScaler.linear(1.6)),
                  child: child!),
              home: entry.value)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull,
          reason: '${entry.key} with large text');
    });
    testWidgets('${entry.key} visual reference', (tester) async {
      tester.view.physicalSize = const Size(430, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(_FakeAuthRepository())
          ],
          child: MaterialApp(
              theme: buildAppTheme(),
              home: RepaintBoundary(
                  key: const ValueKey('screen'), child: entry.value))));
      await tester.pumpAndSettle();
      await expectLater(find.byKey(const ValueKey('screen')),
          matchesGoldenFile('goldens/${entry.key}.png'));
    });
  }
  testWidgets('invalid squad code is rejected and valid code updates dashboard',
      (tester) async {
    tester.view.physicalSize = const Size(430, 1100);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(() =>
        activeSquadPreview.value = const SquadPreview("Headliners ’26", 5));
    final router = GoRouter(initialLocation: '/join', routes: [
      GoRoute(path: '/join', builder: (_, __) => const JoinSquadScreen()),
      GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen())
    ]);
    addTearDown(router.dispose);
    await tester.pumpWidget(ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
          squadRepositoryProvider.overrideWithValue(_FakeSquadRepository())
        ],
        child:
            MaterialApp.router(theme: buildAppTheme(), routerConfig: router)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'WRONG');
    await tester.ensureVisible(find.text('UNIRME AL SQUAD'));
    await tester.tap(find.text('UNIRME AL SQUAD'));
    await tester.pumpAndSettle();
    expect(find.textContaining('6 caracteres'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'A1B2C3');
    await tester.ensureVisible(find.text('UNIRME AL SQUAD'));
    await tester.tap(find.text('UNIRME AL SQUAD'));
    await tester.pumpAndSettle();
    expect(find.byType(DashboardScreen), findsOneWidget);
    expect(activeSquadPreview.value.name, 'Los Noctámbulos Stage 1');
    expect(activeSquadPreview.value.members, 6);
    expect(tester.takeException(), isNull);
  });
  testWidgets('registration form rejects empty input', (tester) async {
    await tester.pumpWidget(ProviderScope(overrides: [
      authRepositoryProvider.overrideWithValue(_FakeAuthRepository())
    ], child: MaterialApp(theme: buildAppTheme(), home: const LoginScreen())));
    await tester.tap(find.text('CREAR CUENTA'));
    await tester.pumpAndSettle();
    final submit = find.text('CREAR CUENTA').last;
    await tester.ensureVisible(submit);
    await tester.tap(submit);
    await tester.pumpAndSettle();
    expect(find.text('Escribe tu nombre'), findsOneWidget);
    expect(find.text('Escribe un correo válido'), findsOneWidget);
    expect(find.text('Usa al menos 8 caracteres'), findsOneWidget);
  });
}

class _FakeAuthRepository implements AuthRepository {
  static const session = AuthSession(
    userId: '00000000-0000-0000-0000-000000000002',
    accessToken: 'access-token',
    refreshToken: 'refresh-token',
  );

  @override
  Future<AuthSession> login({
    required String email,
    required String password,
  }) async =>
      session;

  @override
  Future<void> logout() async {}

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      session;

  @override
  Future<AuthSession?> restore() async => null;
}

class _FakeSquadRepository implements SquadRepository {
  @override
  Future<OfflineData<List<Squad>>> loadMine() async =>
      const OfflineData([], fromCache: false);

  @override
  Future<Squad> create(String name) async {
    return Squad(
      id: '00000000-0000-0000-0000-000000000001',
      name: name,
      code: 'A1B2C3',
      ownerId: '00000000-0000-0000-0000-000000000002',
      memberIds: const ['00000000-0000-0000-0000-000000000002'],
      currentUserRole: 'admin',
    );
  }

  @override
  Future<Squad> join(String code) async {
    return const Squad(
      id: '00000000-0000-0000-0000-000000000001',
      name: 'Los Noctámbulos Stage 1',
      code: 'A1B2C3',
      ownerId: '00000000-0000-0000-0000-000000000003',
      memberIds: [
        '00000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000004',
        '00000000-0000-0000-0000-000000000005',
        '00000000-0000-0000-0000-000000000006',
        '00000000-0000-0000-0000-000000000007',
        '00000000-0000-0000-0000-000000000008',
      ],
      currentUserRole: 'member',
    );
  }
}
