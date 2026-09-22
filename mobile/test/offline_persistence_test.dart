import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:festisquad/core/database/app_database.dart';
import 'package:festisquad/core/security/token_storage.dart';
import 'package:festisquad/features/squads/data/squad_repository.dart';
import 'package:festisquad/features/squads/domain/squad.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppDatabase database;
  late _FakeRemote remote;
  late OfflineFirstSquadRepository repository;

  setUp(() {
    FlutterSecureStorage.setMockInitialValues({
      'auth_user_id': 'user-1',
      'auth_access_token': 'access',
      'auth_refresh_token': 'refresh',
    });
    database = AppDatabase(NativeDatabase.memory());
    remote = _FakeRemote();
    repository = OfflineFirstSquadRepository(
      remote,
      database,
      TokenStorage(const FlutterSecureStorage()),
    );
  });

  tearDown(() => database.close());

  test('first squad read comes from API and is persisted', () async {
    remote.squads = const [_squad];

    final result = await repository.loadMine();

    expect(result.fromCache, isFalse);
    expect(result.value.single.name, 'Noctámbulos');
    expect(await database.readSquads('user-1'), hasLength(1));
  });

  test('cached squads remain available when API is offline', () async {
    remote.squads = const [_squad];
    await repository.loadMine();
    remote.failure = StateError('offline');

    final result = await repository.loadMine();

    expect(result.fromCache, isTrue);
    expect(result.value.single.id, _squad.id);
  });

  test('squad cache is isolated by authenticated user', () async {
    remote.squads = const [_squad];
    await repository.loadMine();

    expect(await database.readSquads('user-1'), hasLength(1));
    expect(await database.readSquads('another-user'), isEmpty);
  });

  test('empty server result clears stale squad cache', () async {
    remote.squads = const [_squad];
    await repository.loadMine();
    remote.squads = const [];

    await repository.loadMine();
    await Future<void>.delayed(Duration.zero);

    expect(await database.readSquads('user-1'), isEmpty);
  });
}

const _squad = Squad(
  id: 'squad-1',
  name: 'Noctámbulos',
  code: 'A1B2C3',
  ownerId: 'user-1',
  memberIds: ['user-1'],
  currentUserRole: 'admin',
);

class _FakeRemote implements SquadRemoteDataSource {
  List<Squad> squads = const [];
  Object? failure;

  @override
  Future<List<Squad>> listMine() async {
    if (failure case final error?) throw error;
    return squads;
  }

  @override
  Future<Squad> create(String name) async => _squad;

  @override
  Future<Squad> join(String code) async => _squad;
}
