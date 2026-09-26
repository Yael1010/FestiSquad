import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:festisquad/core/database/app_database.dart';
import 'package:festisquad/core/security/token_storage.dart';
import 'package:festisquad/features/clash_resolver/data/clash_repository.dart';
import 'package:festisquad/features/clash_resolver/domain/clash_models.dart';
import 'package:festisquad/features/clash_resolver/presentation/clash_resolver_screen.dart';
import 'package:festisquad/features/squads/data/squad_repository.dart';
import 'package:festisquad/features/squads/domain/squad.dart';
import 'package:festisquad/core/offline/offline_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

const userId = '00000000-0000-0000-0000-000000000001';
const squadId = '00000000-0000-0000-0000-000000000010';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late _FakeClashRemote remote;
  late ClashRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_user_id': userId,
      'auth_access_token': 'access',
      'auth_refresh_token': 'refresh',
    });
    database = AppDatabase(NativeDatabase.memory());
    remote = _FakeClashRemote();
    repository = ClashRepository(
      remote,
      database,
      TokenStorage(const FlutterSecureStorage()),
    );
  });

  tearDown(() => database.close());

  test('manual preferences remain queued while offline', () async {
    remote.offline = true;

    final result =
        await repository.saveManual(squadId, ['indie'], ['Las Luces']);

    expect(result.preferences.manualGenres, ['indie']);
    expect(result.syncPending, isTrue);
    expect(await database.readPendingMusicPreferences(), hasLength(1));
  });

  test('offline recommendation uses cached manual fallback', () async {
    await repository.saveManual(squadId, ['indie'], ['Las Luces']);
    remote.offline = true;
    final now = DateTime.utc(2026, 10, 1, 20);
    final conflict = ClashConflict(
      startsAt: now,
      endsAt: now.add(const Duration(hours: 1)),
      options: [
        ConcertOption(
          id: 'a',
          artist: 'DJ Norte',
          stage: 'A',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 1)),
          genres: const ['edm'],
        ),
        ConcertOption(
          id: 'b',
          artist: 'Las Luces',
          stage: 'B',
          startsAt: now,
          endsAt: now.add(const Duration(hours: 1)),
          genres: const ['indie'],
        ),
      ],
    );

    final result = await repository.recommend(squadId, conflict);

    expect(result.recommendation!.selectedArtist, 'Las Luces');
    expect(result.recommendation!.offline, isTrue);
  });

  testWidgets('clash screen fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
        tokenStorageProvider.overrideWithValue(
          TokenStorage(const FlutterSecureStorage()),
        ),
        clashRemoteDataSourceProvider.overrideWithValue(remote),
        squadRepositoryProvider.overrideWithValue(_FakeSquadRepository()),
      ],
      child: const MaterialApp(home: ClashResolverScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Preferencias manuales'.toUpperCase()), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _FakeClashRemote implements ClashRemoteDataSource {
  bool offline = false;
  MusicPreferences stored = const MusicPreferences();

  Never _failure() => throw DioException(
        requestOptions: RequestOptions(path: '/clash-resolver'),
        type: DioExceptionType.connectionError,
      );

  @override
  Future<({List<ClashConflict> conflicts, String? festivalName})>
      conflicts() async {
    if (offline) _failure();
    return (
      festivalName: 'Festival',
      conflicts: const <ClashConflict>[],
    );
  }

  @override
  Future<MusicPreferences> preferences() async {
    if (offline) _failure();
    return stored;
  }

  @override
  Future<ClashRecommendation> recommend(
      String squadId, List<ConcertOption> options) async {
    if (offline) _failure();
    throw UnimplementedError();
  }

  @override
  Future<MusicPreferences> saveManual(
      List<String> genres, List<String> artists) async {
    if (offline) _failure();
    stored = stored.withManual(genres: genres, artists: artists);
    return stored;
  }

  @override
  Future<String> spotifyAuthorizationUrl() async {
    if (offline) _failure();
    return 'https://accounts.spotify.com/authorize';
  }
}

class _FakeSquadRepository implements SquadRepository {
  static const squad = Squad(
    id: squadId,
    name: 'Festival Squad',
    code: 'ABC123',
    ownerId: userId,
    memberIds: [userId],
    currentUserRole: 'admin',
  );

  @override
  Future<Squad> create(String name) async => squad;

  @override
  Future<Squad> join(String code) async => squad;

  @override
  Future<OfflineData<List<Squad>>> loadMine() async =>
      const OfflineData([squad], fromCache: false);
}
