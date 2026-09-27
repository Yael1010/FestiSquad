import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/offline/offline_state.dart';
import '../domain/festival.dart';

final festivalRepositoryProvider = Provider<FestivalRepository>((ref) {
  return OfflineFirstFestivalRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
  );
});

abstract interface class FestivalRepository {
  Future<OfflineData<List<FestivalSummary>>> loadCatalog({
    bool forceRefresh = false,
  });

  Future<bool> hasAdminAccess();

  Future<FestivalSummary> create(FestivalDraft draft);
}

class OfflineFirstFestivalRepository implements FestivalRepository {
  OfflineFirstFestivalRepository(this._api, this._database);

  final ApiClient _api;
  final AppDatabase _database;

  @override
  Future<OfflineData<List<FestivalSummary>>> loadCatalog({
    bool forceRefresh = false,
  }) async {
    final cached = await _readCacheSafely();
    if (cached.isNotEmpty && !forceRefresh) {
      unawaited(_refreshSilently());
      return OfflineData(cached, fromCache: true);
    }
    try {
      final remote = await _fetchCatalog();
      await _cacheSafely(remote);
      return OfflineData(remote, fromCache: false);
    } catch (_) {
      if (cached.isNotEmpty) return OfflineData(cached, fromCache: true);
      rethrow;
    }
  }

  @override
  Future<bool> hasAdminAccess() async {
    final response = await _api.get('/festivals/admin/access');
    return (response.data as Map)['is_admin'] == true;
  }

  @override
  Future<FestivalSummary> create(FestivalDraft draft) async {
    final response = await _api.post('/festivals', data: draft.toJson());
    final created = FestivalSummary.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
    await _refreshSilently();
    return created;
  }

  Future<List<FestivalSummary>> _fetchCatalog() async {
    final response = await _api.get('/festivals');
    return (response.data as List)
        .map((item) => FestivalSummary.fromJson(
              Map<String, dynamic>.from(item as Map),
            ))
        .toList(growable: false);
  }

  Future<List<FestivalSummary>> _readCacheSafely() async {
    try {
      final rows = await _database.readFestivalCatalog();
      return rows
          .map((row) => FestivalSummary(
                id: row.id,
                name: row.name,
                venueName: row.venueName,
                city: row.city,
                countryCode: row.countryCode,
                timezone: row.timezone,
                startsAt: row.startsAt.toLocal(),
                endsAt: row.endsAt.toLocal(),
                imageUrl: row.imageUrl,
                officialUrl: row.officialUrl,
                status: row.status,
                stageCount: row.stageCount,
              ))
          .toList(growable: false);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _refreshSilently() async {
    try {
      await _cacheSafely(await _fetchCatalog());
    } catch (_) {
      // El catálogo guardado sigue disponible cuando falla la red.
    }
  }

  Future<void> _cacheSafely(List<FestivalSummary> festivals) async {
    try {
      final cachedAt = DateTime.now().toUtc();
      await _database.replaceFestivalCatalog(
        festivals.map(
          (festival) => CachedFestivalSummariesCompanion.insert(
            id: festival.id,
            name: festival.name,
            venueName: festival.venueName,
            city: festival.city,
            countryCode: festival.countryCode,
            timezone: festival.timezone,
            startsAt: festival.startsAt.toUtc(),
            endsAt: festival.endsAt.toUtc(),
            imageUrl: Value(festival.imageUrl),
            officialUrl: Value(festival.officialUrl),
            status: festival.status,
            stageCount: festival.stageCount,
            cachedAt: cachedAt,
          ),
        ),
      );
    } catch (_) {
      // Una falla de SQLite/IndexedDB no invalida la respuesta remota.
    }
  }
}
