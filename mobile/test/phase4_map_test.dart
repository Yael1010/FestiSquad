import 'package:dio/dio.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:festisquad/core/database/app_database.dart';
import 'package:festisquad/core/location/location_sync_policy.dart';
import 'package:festisquad/core/network/api_client.dart';
import 'package:festisquad/core/security/token_storage.dart';
import 'package:festisquad/features/map/data/offline_map_repository.dart';
import 'package:festisquad/features/map/domain/festival_map.dart';
import 'package:festisquad/features/map/presentation/map_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('foreground sends only after at least 15 meters', () {
    const policy = LocationSyncPolicy();
    final start = DateTime.utc(2026, 9, 22);
    final previous = LocationSnapshot(
      latitude: 19.400000,
      longitude: -99.090000,
      recordedAt: start,
    );
    expect(
      policy.shouldSync(
        lastSynced: previous,
        current: LocationSnapshot(
          latitude: 19.400050,
          longitude: -99.090000,
          recordedAt: start.add(const Duration(minutes: 5)),
        ),
        isInBackground: false,
      ),
      isFalse,
    );
    expect(
      policy.shouldSync(
        lastSynced: previous,
        current: LocationSnapshot(
          latitude: 19.400200,
          longitude: -99.090000,
          recordedAt: start.add(const Duration(seconds: 10)),
        ),
        isInBackground: false,
      ),
      isTrue,
    );
  });

  test('background never sends more often than every three minutes', () {
    const policy = LocationSyncPolicy();
    final start = DateTime.utc(2026, 9, 22);
    final previous = LocationSnapshot(
      latitude: 19.4,
      longitude: -99.09,
      recordedAt: start,
    );
    bool shouldSync(double latitude, Duration elapsed) => policy.shouldSync(
          lastSynced: previous,
          current: LocationSnapshot(
            latitude: latitude,
            longitude: -99.09,
            recordedAt: start.add(elapsed),
          ),
          isInBackground: true,
        );
    expect(shouldSync(19.41, const Duration(minutes: 2)), isFalse);
    expect(shouldSync(19.4, const Duration(minutes: 3)), isTrue);
  });

  test('GeoJSON polygon uses longitude then latitude', () {
    final points = parsePolygon({
      'type': 'Polygon',
      'coordinates': [
        [
          [-99.09, 19.4],
          [-99.08, 19.4],
          [-99.09, 19.4],
        ]
      ],
    });
    expect(points.first.latitude, 19.4);
    expect(points.first.longitude, -99.09);
  });

  test('offline map retains locations and meeting points by session', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_user_id': 'user-1',
      'auth_access_token': 'access',
      'auth_refresh_token': 'refresh',
    });
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMapRepository(
      _OfflineApiClient(),
      database,
      TokenStorage(const FlutterSecureStorage()),
    );
    final now = DateTime.utc(2026, 9, 22);
    await database.upsertLocation(CachedLocationsCompanion.insert(
      sessionUserId: const Value('user-1'),
      squadId: 'squad-1',
      userId: 'friend-1',
      latitude: 19.4,
      longitude: -99.09,
      recordedAt: now,
      cachedAt: now,
    ));
    await database.replaceMeetingPoints('user-1', 'squad-1', [
      CachedMeetingPointsCompanion.insert(
        sessionUserId: const Value('user-1'),
        id: 'point-1',
        squadId: 'squad-1',
        title: 'Entrada norte',
        latitude: 19.401,
        longitude: -99.091,
        createdByUserId: 'user-1',
        createdAt: now,
        cachedAt: now,
      ),
    ]);
    final result = await repository.load('squad-1');
    expect(result.fromCache, isTrue);
    expect(result.festival.isDemo, isTrue);
    expect(result.festival.stages, hasLength(2));
    expect(result.locations.single.userId, 'friend-1');
    expect(result.meetingPoints.single.title, 'Entrada norte');
    expect(
        await database.readLatestLocations('other-user', 'squad-1'), isEmpty);
  });

  test('offline movement keeps only the latest pending location', () async {
    FlutterSecureStorage.setMockInitialValues({
      'auth_user_id': 'user-1',
      'auth_access_token': 'access',
      'auth_refresh_token': 'refresh',
    });
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = OfflineMapRepository(
      _OfflineApiClient(),
      database,
      TokenStorage(const FlutterSecureStorage()),
    );
    final now = DateTime.utc(2026, 9, 22);

    for (final latitude in [19.4001, 19.4002]) {
      await repository.sendLocation(
        squadId: 'squad-1',
        latitude: latitude,
        longitude: -99.09,
        accuracyMeters: 10,
        recordedAt: now,
      );
    }

    expect(await database.readPendingLocations(), hasLength(1));
    expect(
      (await database.readLatestLocations('user-1', 'squad-1')).single.latitude,
      19.4002,
    );
  });

  testWidgets('map layout fits a small phone without network', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(ProviderScope(
      overrides: [
        offlineMapRepositoryProvider.overrideWithValue(_StaticMapRepository()),
      ],
      child: const MaterialApp(home: MapScreen()),
    ));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('PLANO DE DEMOSTRACIÓN'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _StaticMapRepository extends OfflineMapRepository {
  _StaticMapRepository()
      : super(
          _OfflineApiClient(),
          AppDatabase(NativeDatabase.memory()),
          TokenStorage(const FlutterSecureStorage()),
        );

  @override
  Future<FestivalMapSnapshot> load(String? squadId) async {
    return const FestivalMapSnapshot(
      festival: FestivalMap(
        id: 'demo',
        name: 'Festival de prueba',
        boundary: [
          MapPoint(19.4, -99.09),
          MapPoint(19.4, -99.08),
          MapPoint(19.39, -99.08),
        ],
        stages: [],
        isDemo: true,
      ),
      locations: [],
      meetingPoints: [],
      fromCache: true,
    );
  }
}

class _OfflineApiClient extends ApiClient {
  _OfflineApiClient()
      : super(
          baseUrl: 'http://localhost/api/v1',
          tokenStorage: TokenStorage(const FlutterSecureStorage()),
        );

  @override
  Future<Response<dynamic>> get(String path) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
    );
  }

  @override
  Future<Response<dynamic>> post(String path, {Object? data}) async {
    throw DioException(
      requestOptions: RequestOptions(path: path),
      type: DioExceptionType.connectionError,
    );
  }
}
