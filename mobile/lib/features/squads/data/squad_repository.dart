import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_state.dart';
import '../../../core/security/token_storage.dart';
import '../domain/squad.dart';

final squadRemoteDataSourceProvider = Provider<SquadRemoteDataSource>((ref) {
  return ApiSquadRemoteDataSource(ref.watch(apiClientProvider));
});

final squadRepositoryProvider = Provider<SquadRepository>((ref) {
  return OfflineFirstSquadRepository(
    ref.watch(squadRemoteDataSourceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(tokenStorageProvider),
  );
});

abstract interface class SquadRepository {
  Future<OfflineData<List<Squad>>> loadMine();

  Future<Squad> create(String name);

  Future<Squad> join(String code);
}

abstract interface class SquadRemoteDataSource {
  Future<List<Squad>> listMine();

  Future<Squad> create(String name);

  Future<Squad> join(String code);
}

class ApiSquadRemoteDataSource implements SquadRemoteDataSource {
  ApiSquadRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<List<Squad>> listMine() async {
    final response = await _api.get('/squads');
    return (response.data as List)
        .map((item) => _parse(item))
        .toList(growable: false);
  }

  @override
  Future<Squad> create(String name) async {
    final response = await _api.post('/squads', data: {'name': name});
    return _parse(response.data);
  }

  @override
  Future<Squad> join(String code) async {
    final response = await _api.post(
      '/squads/join',
      data: {'code': code.trim().toUpperCase()},
    );
    return _parse(response.data);
  }

  Squad _parse(dynamic data) {
    return Squad.fromJson(Map<String, dynamic>.from(data as Map));
  }
}

class OfflineFirstSquadRepository implements SquadRepository {
  OfflineFirstSquadRepository(this._remote, this._database, this._tokens);

  final SquadRemoteDataSource _remote;
  final AppDatabase _database;
  final TokenStorage _tokens;

  @override
  Future<OfflineData<List<Squad>>> loadMine() async {
    final userId = await _currentUserId();
    final cachedRows = await _database.readSquads(userId);
    if (cachedRows.isNotEmpty) {
      unawaited(_refreshCache(userId));
      return OfflineData(
        cachedRows.map(_fromCache).toList(growable: false),
        fromCache: true,
      );
    }

    final remoteSquads = await _remote.listMine();
    await _replaceCache(userId, remoteSquads);
    return OfflineData(remoteSquads, fromCache: false);
  }

  @override
  Future<Squad> create(String name) async {
    final squad = await _remote.create(name);
    await _cacheOne(await _currentUserId(), squad);
    return squad;
  }

  @override
  Future<Squad> join(String code) async {
    final squad = await _remote.join(code);
    await _cacheOne(await _currentUserId(), squad);
    return squad;
  }

  Future<String> _currentUserId() async {
    final session = await _tokens.readSession();
    if (session == null) {
      throw StateError('No hay una sesión disponible para acceder al caché.');
    }
    return session.userId;
  }

  Future<void> _refreshCache(String userId) async {
    try {
      final remoteSquads = await _remote.listMine();
      await _replaceCache(userId, remoteSquads);
    } catch (_) {
      // El caché vigente sigue siendo utilizable; se reintentará al recargar.
    }
  }

  Future<void> _replaceCache(String userId, List<Squad> squads) {
    final cachedAt = DateTime.now().toUtc();
    return _database.replaceSquads(
      userId,
      squads.map((squad) => _toCache(userId, squad, cachedAt)),
    );
  }

  Future<void> _cacheOne(String userId, Squad squad) {
    return _database.upsertSquad(
      _toCache(userId, squad, DateTime.now().toUtc()),
    );
  }

  CachedSquadsCompanion _toCache(
    String userId,
    Squad squad,
    DateTime cachedAt,
  ) {
    return CachedSquadsCompanion.insert(
      sessionUserId: userId,
      id: squad.id,
      name: squad.name,
      code: squad.code,
      ownerId: squad.ownerId,
      memberIdsJson: jsonEncode(squad.memberIds),
      currentUserRole: squad.currentUserRole,
      cachedAt: cachedAt,
    );
  }

  Squad _fromCache(CachedSquad row) {
    return Squad(
      id: row.id,
      name: row.name,
      code: row.code,
      ownerId: row.ownerId,
      memberIds: (jsonDecode(row.memberIdsJson) as List)
          .cast<String>()
          .toList(growable: false),
      currentUserRole: row.currentUserRole,
    );
  }
}
