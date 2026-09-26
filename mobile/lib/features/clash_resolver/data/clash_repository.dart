import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';
import '../domain/clash_models.dart';

final clashRemoteDataSourceProvider = Provider<ClashRemoteDataSource>((ref) {
  return ApiClashRemoteDataSource(ref.watch(apiClientProvider));
});

final clashRepositoryProvider = Provider<ClashRepository>((ref) {
  return ClashRepository(
    ref.watch(clashRemoteDataSourceProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(tokenStorageProvider),
  );
});

abstract interface class ClashRemoteDataSource {
  Future<MusicPreferences> preferences();
  Future<MusicPreferences> saveManual(
      List<String> genres, List<String> artists);
  Future<({String? festivalName, List<ClashConflict> conflicts})> conflicts();
  Future<ClashRecommendation> recommend(
      String squadId, List<ConcertOption> options);
  Future<String> spotifyAuthorizationUrl();
}

class ApiClashRemoteDataSource implements ClashRemoteDataSource {
  ApiClashRemoteDataSource(this._api);

  final ApiClient _api;

  @override
  Future<MusicPreferences> preferences() async {
    final response = await _api.get('/preferences/music');
    return MusicPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<MusicPreferences> saveManual(
      List<String> genres, List<String> artists) async {
    final response = await _api.post('/preferences/music/manual', data: {
      'genres': genres,
      'artists': artists,
    });
    return MusicPreferences.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<({String? festivalName, List<ClashConflict> conflicts})>
      conflicts() async {
    final response = await _api.get('/clash-resolver/conflicts');
    final data = Map<String, dynamic>.from(response.data as Map);
    return (
      festivalName: data['festival_name'] as String?,
      conflicts: (data['conflicts'] as List)
          .map((value) =>
              ClashConflict.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(growable: false),
    );
  }

  @override
  Future<ClashRecommendation> recommend(
      String squadId, List<ConcertOption> options) async {
    final response = await _api.post('/clash-resolver/recommendation', data: {
      'squad_id': squadId,
      'options': options.map((option) => option.toJson()).toList(),
    });
    return ClashRecommendation.fromJson(
        Map<String, dynamic>.from(response.data as Map));
  }

  @override
  Future<String> spotifyAuthorizationUrl() async {
    final response = await _api.post('/spotify/authorize');
    return (response.data as Map)['authorization_url'] as String;
  }
}

class ClashRepository {
  ClashRepository(this._remote, this._database, this._tokens);

  final ClashRemoteDataSource _remote;
  final AppDatabase _database;
  final TokenStorage _tokens;

  Future<ClashSnapshot> load(String squadId) async {
    final userId = await _userId();
    await _retryPending();
    final cached = await _readCache(userId, squadId);
    try {
      return await _refresh(userId, squadId, cached.recommendation);
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      return cached;
    }
  }

  Future<ClashSnapshot> saveManual(
    String squadId,
    List<String> genres,
    List<String> artists,
  ) async {
    final userId = await _userId();
    final current = await _readCache(userId, squadId);
    final pending = current.copyWith(
      preferences:
          current.preferences.withManual(genres: genres, artists: artists),
      fromCache: true,
      syncPending: true,
    );
    await _writeCache(userId, squadId, pending);
    final payload = jsonEncode({'genres': genres, 'artists': artists});
    await _database.queueMusicPreferences(payload);
    try {
      final preferences = await _remote.saveManual(genres, artists);
      await _clearPending();
      final saved = pending.copyWith(
        preferences: preferences,
        fromCache: false,
        syncPending: false,
      );
      await _writeCache(userId, squadId, saved);
      return saved;
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      return pending;
    }
  }

  Future<ClashSnapshot> recommend(
      String squadId, ClashConflict conflict) async {
    final userId = await _userId();
    final current = await _readCache(userId, squadId);
    try {
      final recommendation = await _remote.recommend(squadId, conflict.options);
      final saved =
          current.copyWith(recommendation: recommendation, fromCache: false);
      await _writeCache(userId, squadId, saved);
      return saved;
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      final recommendation =
          _localRecommendation(conflict.options, current.preferences);
      final saved =
          current.copyWith(recommendation: recommendation, fromCache: true);
      await _writeCache(userId, squadId, saved);
      return saved;
    }
  }

  Future<String> spotifyAuthorizationUrl() => _remote.spotifyAuthorizationUrl();

  Future<ClashSnapshot> _refresh(
    String userId,
    String squadId,
    ClashRecommendation? recommendation,
  ) async {
    final responses = await Future.wait([
      _remote.preferences(),
      _remote.conflicts(),
    ]);
    final conflictData =
        responses[1] as ({String? festivalName, List<ClashConflict> conflicts});
    final snapshot = ClashSnapshot(
      preferences: responses[0] as MusicPreferences,
      conflicts: conflictData.conflicts,
      festivalName: conflictData.festivalName,
      recommendation: recommendation,
      fromCache: false,
    );
    await _writeCache(userId, squadId, snapshot);
    return snapshot;
  }

  Future<ClashSnapshot> _readCache(String userId, String squadId) async {
    final row = await _database.readClashState(userId, squadId);
    if (row == null) return ClashSnapshot.empty;
    final conflictsData = jsonDecode(row.conflictsJson) as Map<String, dynamic>;
    return ClashSnapshot(
      preferences: MusicPreferences.fromJson(
          Map<String, dynamic>.from(jsonDecode(row.preferencesJson) as Map)),
      conflicts: (conflictsData['conflicts'] as List)
          .map((value) =>
              ClashConflict.fromJson(Map<String, dynamic>.from(value as Map)))
          .toList(growable: false),
      festivalName: conflictsData['festival_name'] as String?,
      recommendation: row.recommendationJson == null
          ? null
          : ClashRecommendation.fromJson(Map<String, dynamic>.from(
              jsonDecode(row.recommendationJson!) as Map)),
      fromCache: true,
      syncPending: (await _database.readPendingMusicPreferences()).isNotEmpty,
    );
  }

  Future<void> _writeCache(
      String userId, String squadId, ClashSnapshot snapshot) {
    return _database.upsertClashState(CachedClashStatesCompanion.insert(
      sessionUserId: userId,
      squadId: squadId,
      preferencesJson: jsonEncode(snapshot.preferences.toJson()),
      conflictsJson: jsonEncode({
        'festival_name': snapshot.festivalName,
        'conflicts':
            snapshot.conflicts.map((conflict) => conflict.toJson()).toList(),
      }),
      recommendationJson: Value(snapshot.recommendation == null
          ? null
          : jsonEncode(snapshot.recommendation!.toJson())),
      cachedAt: DateTime.now().toUtc(),
    ));
  }

  ClashRecommendation _localRecommendation(
      List<ConcertOption> options, MusicPreferences preferences) {
    final genres = {
      for (final value in [
        ...preferences.manualGenres,
        ...preferences.spotifyGenres
      ])
        value.toLowerCase()
    };
    final artists = {
      for (final value in [
        ...preferences.manualArtists,
        ...preferences.spotifyArtists
      ])
        value.toLowerCase()
    };
    final ranked = options.map((option) {
      final matched = option.genres
          .where((genre) => genres.contains(genre.toLowerCase()))
          .toList();
      final artistMatch = artists.contains(option.artist.toLowerCase());
      return (
        option: option,
        genres: matched,
        artist: artistMatch,
        score: matched.length * 3 + (artistMatch ? 5 : 0)
      );
    }).toList()
      ..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        final time = a.option.startsAt.compareTo(b.option.startsAt);
        return time != 0 ? time : a.option.artist.compareTo(b.option.artist);
      });
    final best = ranked.first;
    return ClashRecommendation(
      selectedOptionId: best.option.id,
      selectedArtist: best.option.artist,
      selectedStage: best.option.stage,
      score: best.score,
      matchedGenres: best.genres,
      matchedArtist: best.artist,
      reason: best.score == 0
          ? 'Sin coincidencias locales; se eligió la opción más temprana.'
          : 'Recomendación local con tus preferencias guardadas.',
      offline: true,
    );
  }

  Future<void> _retryPending() async {
    for (final operation in await _database.readPendingMusicPreferences()) {
      final data =
          Map<String, dynamic>.from(jsonDecode(operation.payloadJson) as Map);
      try {
        await _remote.saveManual(
          (data['genres'] as List).cast<String>(),
          (data['artists'] as List).cast<String>(),
        );
        await _database.deletePendingOperation(operation.id);
      } on DioException {
        return;
      }
    }
  }

  Future<void> _clearPending() async {
    for (final operation in await _database.readPendingMusicPreferences()) {
      await _database.deletePendingOperation(operation.id);
    }
  }

  Future<String> _userId() async {
    final session = await _tokens.readSession();
    if (session == null) throw StateError('No hay una sesión activa.');
    return session.userId;
  }

  bool _isNetworkFailure(DioException error) =>
      error.response == null || (error.response!.statusCode ?? 0) >= 500;
}
