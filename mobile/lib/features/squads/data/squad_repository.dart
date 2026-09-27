import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
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

  Future<OfflineData<List<SquadMemberProfile>>> loadMembers(String squadId);

  Future<void> updateRole(String squadId, String userId, String role);

  Future<void> removeMember(String squadId, String userId);

  Future<void> transferOwnership(String squadId, String userId);

  Future<void> deleteSquad(String squadId);
}

abstract interface class SquadRemoteDataSource {
  Future<List<Squad>> listMine();

  Future<Squad> create(String name);

  Future<Squad> join(String code);

  Future<List<SquadMemberProfile>> listMembers(String squadId);

  Future<void> updateRole(String squadId, String userId, String role);

  Future<void> removeMember(String squadId, String userId);

  Future<void> transferOwnership(String squadId, String userId);

  Future<void> deleteSquad(String squadId);
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

  @override
  Future<List<SquadMemberProfile>> listMembers(String squadId) async {
    final response = await _api.get('/squads/$squadId/members');
    return (response.data as List)
        .map((item) => SquadMemberProfile.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(growable: false);
  }

  @override
  Future<void> updateRole(String squadId, String userId, String role) async {
    await _api.patch(
      '/squads/$squadId/members/$userId',
      data: {'role': role},
    );
  }

  @override
  Future<void> removeMember(String squadId, String userId) async {
    await _api.delete('/squads/$squadId/members/$userId');
  }

  @override
  Future<void> transferOwnership(String squadId, String userId) async {
    await _api.post('/squads/$squadId/owner/$userId');
  }

  @override
  Future<void> deleteSquad(String squadId) async {
    await _api.delete('/squads/$squadId');
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
    List<CachedSquad> cachedRows = const [];
    try {
      cachedRows = await _database.readSquads(userId);
    } catch (_) {
      // Un caché local dañado o no disponible no debe bloquear la API.
    }
    if (cachedRows.isNotEmpty) {
      unawaited(_refreshCache(userId));
      return OfflineData(
        cachedRows.map(_fromCache).toList(growable: false),
        fromCache: true,
      );
    }

    final remoteSquads = await _remote.listMine();
    await _tryReplaceCache(userId, remoteSquads);
    return OfflineData(remoteSquads, fromCache: false);
  }

  @override
  Future<Squad> create(String name) async {
    final squad = await _remote.create(name);
    await _tryCacheOne(await _currentUserId(), squad);
    return squad;
  }

  @override
  Future<Squad> join(String code) async {
    final squad = await _remote.join(code);
    await _tryCacheOne(await _currentUserId(), squad);
    return squad;
  }

  @override
  Future<OfflineData<List<SquadMemberProfile>>> loadMembers(
      String squadId) async {
    final userId = await _currentUserId();
    List<CachedSquadMember> cached = const [];
    try {
      cached = await _database.readSquadMembers(userId, squadId);
    } catch (_) {
      // El detalle remoto sigue disponible si el caché local falla.
    }
    if (cached.isNotEmpty) {
      unawaited(_refreshMembersSilently(userId, squadId));
      return OfflineData(
        cached.map(_memberFromCache).toList(growable: false),
        fromCache: true,
      );
    }
    final members = await _remote.listMembers(squadId);
    await _tryCacheMembers(userId, squadId, members);
    return OfflineData(members, fromCache: false);
  }

  @override
  Future<void> updateRole(String squadId, String userId, String role) async {
    await _remote.updateRole(squadId, userId, role);
    await _refreshMembers(await _currentUserId(), squadId);
  }

  @override
  Future<void> removeMember(String squadId, String userId) async {
    await _remote.removeMember(squadId, userId);
    final sessionUserId = await _currentUserId();
    if (sessionUserId == userId) {
      await _database.deleteSquadCache(sessionUserId, squadId);
    } else {
      await _refreshMembers(sessionUserId, squadId);
    }
  }

  @override
  Future<void> transferOwnership(String squadId, String userId) async {
    await _remote.transferOwnership(squadId, userId);
    await _refreshMembers(await _currentUserId(), squadId);
  }

  @override
  Future<void> deleteSquad(String squadId) async {
    await _remote.deleteSquad(squadId);
    final userId = await _currentUserId();
    await _database.deleteSquadCache(userId, squadId);
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
      await _tryReplaceCache(userId, remoteSquads);
    } catch (_) {
      // El caché vigente sigue siendo utilizable; se reintentará al recargar.
    }
  }

  Future<void> _refreshMembers(String userId, String squadId) async {
    final members = await _remote.listMembers(squadId);
    await _tryCacheMembers(userId, squadId, members);
  }

  Future<void> _refreshMembersSilently(String userId, String squadId) async {
    try {
      await _refreshMembers(userId, squadId);
    } catch (_) {
      // El detalle almacenado sigue disponible cuando falla la red.
    }
  }

  Future<void> _tryCacheMembers(
    String userId,
    String squadId,
    List<SquadMemberProfile> members,
  ) async {
    try {
      final cachedAt = DateTime.now().toUtc();
      await _database.replaceSquadMembers(
        userId,
        squadId,
        members.map(
          (member) => CachedSquadMembersCompanion.insert(
            sessionUserId: userId,
            squadId: squadId,
            userId: member.userId,
            name: member.name,
            avatarUrl: Value(member.avatarUrl),
            role: member.role,
            joinedAt: member.joinedAt.toUtc(),
            lastLocationAt: Value(member.lastLocationAt?.toUtc()),
            isOwner: member.isOwner,
            isCurrentUser: member.isCurrentUser,
            cachedAt: cachedAt,
          ),
        ),
      );
    } catch (_) {
      // Los perfiles remotos siguen siendo válidos aunque falle el caché.
    }
  }

  Future<void> _replaceCache(String userId, List<Squad> squads) {
    final cachedAt = DateTime.now().toUtc();
    return _database.replaceSquads(
      userId,
      squads.map((squad) => _toCache(userId, squad, cachedAt)),
    );
  }

  Future<void> _tryReplaceCache(String userId, List<Squad> squads) async {
    try {
      await _replaceCache(userId, squads);
    } catch (_) {
      // La respuesta remota sigue siendo válida aunque falle IndexedDB/SQLite.
    }
  }

  Future<void> _cacheOne(String userId, Squad squad) {
    return _database.upsertSquad(
      _toCache(userId, squad, DateTime.now().toUtc()),
    );
  }

  Future<void> _tryCacheOne(String userId, Squad squad) async {
    try {
      await _cacheOne(userId, squad);
    } catch (_) {
      // Crear o unirse al squad no depende de que el caché local esté disponible.
    }
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

  SquadMemberProfile _memberFromCache(CachedSquadMember row) {
    return SquadMemberProfile(
      userId: row.userId,
      name: row.name,
      avatarUrl: row.avatarUrl,
      role: row.role,
      joinedAt: row.joinedAt.toLocal(),
      lastLocationAt: row.lastLocationAt?.toLocal(),
      isOwner: row.isOwner,
      isCurrentUser: row.isCurrentUser,
    );
  }
}
