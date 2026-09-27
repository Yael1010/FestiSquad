import 'package:dio/dio.dart';
import 'package:drift/native.dart';
import 'package:festisquad/core/database/app_database.dart';
import 'package:festisquad/core/network/api_client.dart';
import 'package:festisquad/core/offline/offline_state.dart';
import 'package:festisquad/core/security/token_storage.dart';
import 'package:festisquad/features/festivals/data/festival_repository.dart';
import 'package:festisquad/features/festivals/domain/festival.dart';
import 'package:festisquad/features/festivals/presentation/festival_admin_screen.dart';
import 'package:festisquad/features/festivals/presentation/festival_catalog_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('festival catalog remains available offline', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final api = _CatalogApiClient();
    final repository = OfflineFirstFestivalRepository(api, database);

    final online = await repository.loadCatalog();
    api.offline = true;
    final offline = await repository.loadCatalog();
    await Future<void>.delayed(Duration.zero);

    expect(online.fromCache, isFalse);
    expect(offline.fromCache, isTrue);
    expect(offline.value.single.name, 'Festival Real');
    expect(await database.readFestivalCatalog(), hasLength(1));
  });

  testWidgets('festival catalog fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          festivalRepositoryProvider.overrideWithValue(_StaticRepository()),
        ],
        child: const MaterialApp(home: FestivalCatalogScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Festival Real'), findsOneWidget);
    expect(find.textContaining('2 escenarios'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('festival admin form fits a compact phone', (tester) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: FestivalAdminScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nuevo festival'), findsOneWidget);
    await tester.fling(
      find.byType(ListView),
      const Offset(0, -700),
      1200,
    );
    await tester.pumpAndSettle();
    expect(find.text('Guardar festival'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

final _festival = FestivalSummary(
  id: '00000000-0000-0000-0000-000000000010',
  name: 'Festival Real',
  venueName: 'Recinto Principal',
  city: 'Ciudad de México',
  countryCode: 'MX',
  timezone: 'America/Mexico_City',
  startsAt: _start,
  endsAt: _end,
  status: 'published',
  stageCount: 2,
);

final _start = DateTime(2030, 11, 16, 14);
final _end = DateTime(2030, 11, 17, 23);

class _StaticRepository implements FestivalRepository {
  @override
  Future<FestivalSummary> create(FestivalDraft draft) async => _festival;

  @override
  Future<bool> hasAdminAccess() async => false;

  @override
  Future<OfflineData<List<FestivalSummary>>> loadCatalog({
    bool forceRefresh = false,
  }) async =>
      OfflineData([_festival], fromCache: false);
}

class _CatalogApiClient extends ApiClient {
  _CatalogApiClient()
      : super(
          baseUrl: 'http://localhost/api/v1',
          tokenStorage: TokenStorage(const FlutterSecureStorage()),
        );

  bool offline = false;

  @override
  Future<Response<dynamic>> get(String path) async {
    if (offline) {
      throw DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.connectionError,
      );
    }
    return Response<dynamic>(
      requestOptions: RequestOptions(path: path),
      statusCode: 200,
      data: [
        {
          'id': _festival.id,
          'name': _festival.name,
          'venue_name': _festival.venueName,
          'city': _festival.city,
          'country_code': _festival.countryCode,
          'timezone': _festival.timezone,
          'starts_at': _start.toIso8601String(),
          'ends_at': _end.toIso8601String(),
          'image_url': null,
          'official_url': null,
          'status': 'published',
          'stage_count': 2,
        }
      ],
    );
  }
}
