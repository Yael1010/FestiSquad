import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:festisquad/core/theme/app_theme.dart';
import 'package:festisquad/core/offline/offline_state.dart';
import 'package:festisquad/core/presentation/phone_preview.dart';
import 'package:festisquad/features/auth/data/auth_repository.dart';
import 'package:festisquad/features/auth/domain/auth_session.dart';
import 'package:festisquad/features/auth/presentation/login_screen.dart';
import 'package:festisquad/features/clash_resolver/data/clash_repository.dart';
import 'package:festisquad/features/clash_resolver/domain/clash_models.dart';
import 'package:festisquad/features/finances/data/finance_repository.dart';
import 'package:festisquad/features/finances/domain/finance_models.dart';
import 'package:festisquad/features/finances/domain/money.dart';
import 'package:festisquad/features/squads/presentation/dashboard_screen.dart';
import 'package:festisquad/features/squads/presentation/join_squad_screen.dart';
import 'package:festisquad/features/squads/presentation/squad_preview.dart';
import 'package:festisquad/features/squads/presentation/squad_signal_screen.dart';
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

  testWidgets('phone preview scales once on a short laptop viewport',
      (tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1536, 720);
    tester.view.devicePixelRatio = 1;

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const PhonePreview(child: LoginScreen()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = find.text('FestiSquad', findRichText: true);
    expect(title, findsOneWidget);
    expect(tester.getSize(title).height, lessThan(70));
    expect(find.text('CREAR CUENTA'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

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

  testWidgets('long pressing the squad bolt reveals Squad Signal',
      (tester) async {
    final router = GoRouter(initialLocation: '/dashboard', routes: [
      GoRoute(
        path: '/dashboard',
        builder: (_, __) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/squad-signal',
        builder: (_, state) => SquadSignalScreen(
          squadName: state.uri.queryParameters['name']!,
          squadCode: state.uri.queryParameters['code']!,
        ),
      ),
    ]);
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(_FakeAuthRepository()),
        ],
        child: MaterialApp.router(
          theme: buildAppTheme(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pump();
    var trigger = find.byKey(const ValueKey('squad-signal-trigger'));
    final shortPress = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(const Duration(seconds: 1));
    await shortPress.up();
    await tester.pump();
    expect(find.byType(SquadSignalScreen), findsNothing);

    trigger = find.byKey(const ValueKey('squad-signal-trigger'));
    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(const Duration(milliseconds: 3100));
    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.byType(SquadSignalScreen), findsOneWidget);
    expect(
      find.text('LA SQUAD SIEMPRE ENCUENTRA EL CAMINO'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('signed-in dashboard shows the real user balance',
      (tester) async {
    addTearDown(() =>
        activeSquadPreview.value = const SquadPreview("Headliners ’26", 5));
    const squad = Squad(
      id: '00000000-0000-0000-0000-000000000010',
      name: 'fest',
      code: '6E12C2',
      ownerId: '00000000-0000-0000-0000-000000000001',
      memberIds: [
        '00000000-0000-0000-0000-000000000001',
        '00000000-0000-0000-0000-000000000002',
      ],
      currentUserRole: 'admin',
    );
    final snapshot = FinanceSnapshot(
      expenses: [
        SquadExpense(
          id: 'expense-1',
          clientRequestId: 'request-1',
          squadId: squad.id,
          paidByUserId: _FakeAuthRepository.session.userId,
          description: 'Bebidas',
          amount: const Money.fromCents(10000),
          participants: const [],
          createdAt: DateTime.utc(2026, 9, 29),
          pendingSync: false,
        ),
      ],
      settlements: const [],
      netBalances: const {
        '00000000-0000-0000-0000-000000000002': Money.fromCents(-5000),
      },
      transfers: const [],
      fromCache: false,
    );
    final members = [
      SquadMemberProfile(
        userId: squad.ownerId,
        name: 'Yael Flores',
        role: 'admin',
        joinedAt: DateTime.utc(2026, 9, 1),
        isOwner: true,
        isCurrentUser: false,
      ),
      SquadMemberProfile(
        userId: _FakeAuthRepository.session.userId,
        name: 'Ángel Yael',
        role: 'member',
        joinedAt: DateTime.utc(2026, 9, 2),
        isOwner: false,
        isCurrentUser: true,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(
              restoredSession: _FakeAuthRepository.session,
            ),
          ),
          squadRepositoryProvider.overrideWithValue(
            _FakeSquadRepository(mine: const [squad], members: members),
          ),
          financeRepositoryProvider.overrideWithValue(
            _FakeFinanceRepository(snapshot),
          ),
          clashRemoteDataSourceProvider.overrideWithValue(
            _FakeClashRemoteDataSource(),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'MXN $50.00'), findsOneWidget);
    expect(find.text('Pendiente por pagar'), findsOneWidget);
    expect(find.textContaining('Bebidas'), findsOneWidget);
    expect(find.text(r'$500', findRichText: true), findsNothing);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();
    expect(find.text('Spotify · Conectado'), findsOneWidget);
    expect(find.text('ÁY'), findsOneWidget);
    expect(find.text('+2'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('dashboard recovers from the first squad load failure',
      (tester) async {
    addTearDown(() =>
        activeSquadPreview.value = const SquadPreview("Headliners ’26", 5));
    const squad = Squad(
      id: '00000000-0000-0000-0000-000000000020',
      name: 'Squad recuperado',
      code: 'RETRY1',
      ownerId: '00000000-0000-0000-0000-000000000002',
      memberIds: ['00000000-0000-0000-0000-000000000002'],
      currentUserRole: 'admin',
    );
    final squadRepository = _FakeSquadRepository(
      mine: const [squad],
      failuresBeforeSuccess: 1,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            _FakeAuthRepository(
              restoredSession: _FakeAuthRepository.session,
            ),
          ),
          squadRepositoryProvider.overrideWithValue(squadRepository),
          financeRepositoryProvider.overrideWithValue(
            _FakeFinanceRepository(
              const FinanceSnapshot(
                expenses: [],
                settlements: [],
                netBalances: {},
                transfers: [],
                fromCache: false,
              ),
            ),
          ),
          clashRemoteDataSourceProvider.overrideWithValue(
            _FakeClashRemoteDataSource(),
          ),
        ],
        child: MaterialApp(
          theme: buildAppTheme(),
          home: const DashboardScreen(),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();

    expect(squadRepository.loadMineCalls, 2);
    expect(find.text('Squad recuperado'), findsOneWidget);
    expect(find.textContaining('Ocurrió un error inesperado'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

class _FakeAuthRepository implements AuthRepository {
  _FakeAuthRepository({this.restoredSession});

  final AuthSession? restoredSession;
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
  Future<SocialAuthAttempt> startSocial(
    String provider, {
    bool link = false,
  }) async =>
      SocialAuthAttempt(
        provider: provider,
        authorizationUrl: 'https://example.com/oauth',
        flowToken: List.filled(48, 'a').join(),
      );

  @override
  Future<SocialAuthResult> finishSocial(String flowToken) async =>
      const SocialAuthResult(
        status: SocialAuthStatus.completed,
        session: session,
      );

  @override
  Future<AuthSession> register({
    required String name,
    required String email,
    required String password,
  }) async =>
      session;

  @override
  Future<AuthSession?> restore() async => restoredSession;
}

class _FakeSquadRepository implements SquadRepository {
  _FakeSquadRepository({
    this.mine = const [],
    this.members = const [],
    this.failuresBeforeSuccess = 0,
  });

  final List<Squad> mine;
  final List<SquadMemberProfile> members;
  int failuresBeforeSuccess;
  int loadMineCalls = 0;
  @override
  Future<void> deleteSquad(String squadId) async {}

  @override
  Future<OfflineData<List<SquadMemberProfile>>> loadMembers(
    String squadId,
  ) async =>
      OfflineData(members, fromCache: false);

  @override
  Future<void> removeMember(String squadId, String userId) async {}

  @override
  Future<void> transferOwnership(String squadId, String userId) async {}

  @override
  Future<void> updateRole(String squadId, String userId, String role) async {}

  @override
  Future<OfflineData<List<Squad>>> loadMine() async {
    loadMineCalls++;
    if (failuresBeforeSuccess > 0) {
      failuresBeforeSuccess--;
      throw StateError('Fallo transitorio de inicio');
    }
    return OfflineData(mine, fromCache: false);
  }

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

class _FakeClashRemoteDataSource implements ClashRemoteDataSource {
  @override
  Future<MusicPreferences> preferences() async => const MusicPreferences(
        spotifyArtists: ['Artista uno'],
        spotifyGenres: ['rock'],
      );

  @override
  Future<({List<ClashConflict> conflicts, String? festivalName})> conflicts(
          String squadId,
          {String? festivalId}) async =>
      (conflicts: const <ClashConflict>[], festivalName: null as String?);

  @override
  Future<({List<ClashConflict> conflicts, String? festivalName})> vote(
    String squadId,
    String conflictId,
    String optionId,
    bool selected,
  ) async =>
      (conflicts: const <ClashConflict>[], festivalName: null as String?);

  @override
  Future<({List<ClashConflict> conflicts, String? festivalName})> decide(
    String squadId,
    String conflictId,
    String optionId,
  ) async =>
      (conflicts: const <ClashConflict>[], festivalName: null as String?);

  @override
  Future<ClashRecommendation> recommend(
    String squadId,
    List<ConcertOption> options,
  ) =>
      throw UnimplementedError();

  @override
  Future<MusicPreferences> saveManual(
    List<String> genres,
    List<String> artists,
  ) =>
      throw UnimplementedError();

  @override
  Future<String> spotifyAuthorizationUrl() => throw UnimplementedError();
}

class _FakeFinanceRepository implements FinanceRepository {
  _FakeFinanceRepository(this.snapshot);

  final FinanceSnapshot snapshot;

  @override
  Future<FinanceSnapshot> load(String squadId) async => snapshot;

  @override
  Future<FinanceSnapshot> create(ExpenseDraft draft) async => snapshot;

  @override
  Future<FinanceSnapshot> createSettlement(SettlementDraft draft) async =>
      snapshot;
}
