import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/app_database.dart';
import '../../../core/network/api_client.dart';
import '../../../core/security/token_storage.dart';
import '../domain/festival_map.dart';

const configuredFestivalId = String.fromEnvironment(
  'FESTIVAL_ID',
  defaultValue: 'demo-festival',
);

final offlineMapRepositoryProvider = Provider<OfflineMapRepository>((ref) {
  return OfflineMapRepository(
    ref.watch(apiClientProvider),
    ref.watch(appDatabaseProvider),
    ref.watch(tokenStorageProvider),
  );
});

class OfflineMapRepository {
  OfflineMapRepository(this._api, this._database, this._tokens);

  final ApiClient _api;
  final AppDatabase _database;
  final TokenStorage _tokens;

  Future<FestivalMapSnapshot> load(String? squadId) async {
    final session = await _tokens.readSession();
    final festival = await _loadFestival();
    if (session == null || squadId == null) {
      return FestivalMapSnapshot(
        festival: festival,
        locations: const [],
        meetingPoints: const [],
        fromCache: festival.isDemo,
      );
    }

    await retryPendingLocations();
    try {
      final responses = await Future.wait([
        _api.get('/locations/squad/$squadId/latest'),
        _api.get('/locations/squad/$squadId/meeting-points'),
      ]);
      final locations = (responses[0].data as List)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList(growable: false);
      final meetings = (responses[1].data as List)
          .map((value) => Map<String, dynamic>.from(value as Map))
          .toList(growable: false);
      final now = DateTime.now().toUtc();
      await _database.replaceLatestLocations(
        session.userId,
        squadId,
        locations.map((row) => CachedLocationsCompanion.insert(
              sessionUserId: Value(session.userId),
              squadId: squadId,
              userId: row['user_id'] as String,
              latitude: _decimal(row['latitude']),
              longitude: _decimal(row['longitude']),
              accuracyMeters: Value(
                row['accuracy_meters'] == null
                    ? null
                    : _decimal(row['accuracy_meters']),
              ),
              recordedAt: DateTime.parse(row['recorded_at'] as String),
              cachedAt: now,
            )),
      );
      await _database.replaceMeetingPoints(
        session.userId,
        squadId,
        meetings.map((row) => CachedMeetingPointsCompanion.insert(
              sessionUserId: Value(session.userId),
              id: row['id'] as String,
              squadId: squadId,
              title: row['title'] as String,
              latitude: _decimal(row['latitude']),
              longitude: _decimal(row['longitude']),
              createdByUserId: row['created_by_user_id'] as String,
              createdAt: DateTime.parse(row['created_at'] as String),
              cachedAt: now,
            )),
      );
      return FestivalMapSnapshot(
        festival: festival,
        locations: locations.map(_locationFromJson).toList(growable: false),
        meetingPoints: meetings.map(_meetingFromJson).toList(growable: false),
        fromCache: false,
      );
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      final locations =
          await _database.readLatestLocations(session.userId, squadId);
      final meetings =
          await _database.readMeetingPoints(session.userId, squadId);
      return FestivalMapSnapshot(
        festival: festival,
        locations: locations
            .map((row) => MemberLocation(
                  userId: row.userId,
                  latitude: row.latitude,
                  longitude: row.longitude,
                  recordedAt: row.recordedAt,
                ))
            .toList(growable: false),
        meetingPoints: meetings
            .map((row) => MapMeetingPoint(
                  id: row.id,
                  title: row.title,
                  latitude: row.latitude,
                  longitude: row.longitude,
                ))
            .toList(growable: false),
        fromCache: true,
      );
    }
  }

  Future<void> sendLocation({
    required String squadId,
    required double latitude,
    required double longitude,
    required double accuracyMeters,
    required DateTime recordedAt,
  }) async {
    final session = await _tokens.readSession();
    if (session == null) return;
    final payload = {
      'squad_id': squadId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy_meters': accuracyMeters,
      'recorded_at': recordedAt.toUtc().toIso8601String(),
    };
    await _database.upsertLocation(CachedLocationsCompanion.insert(
      sessionUserId: Value(session.userId),
      squadId: squadId,
      userId: session.userId,
      latitude: latitude,
      longitude: longitude,
      accuracyMeters: Value(accuracyMeters),
      recordedAt: recordedAt.toUtc(),
      cachedAt: DateTime.now().toUtc(),
    ));
    try {
      await _api.post('/locations', data: payload);
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      await _database.queueLatestLocation(
        userId: session.userId,
        squadId: squadId,
        payloadJson: jsonEncode({
          'user_id': session.userId,
          'payload': payload,
        }),
      );
    }
  }

  Future<void> retryPendingLocations() async {
    final session = await _tokens.readSession();
    if (session == null) return;
    final pending = await _database.readPendingLocations();
    for (final operation in pending) {
      final queued = jsonDecode(operation.payloadJson) as Map<String, dynamic>;
      if (queued['user_id'] != session.userId) continue;
      try {
        await _api.post('/locations', data: queued['payload']);
        await _database.deletePendingOperation(operation.id);
      } on DioException catch (error) {
        if (!_isNetworkFailure(error)) rethrow;
        return;
      }
    }
  }

  Future<void> createMeetingPoint({
    required String squadId,
    required String title,
    required double latitude,
    required double longitude,
  }) async {
    await _api.post('/locations/meeting-points', data: {
      'squad_id': squadId,
      'title': title,
      'latitude': latitude,
      'longitude': longitude,
    });
  }

  Future<FestivalMap> _loadFestival() async {
    if (configuredFestivalId == 'demo-festival') {
      final json = jsonDecode(
        await rootBundle.loadString('assets/map/demo_festival.json'),
      ) as Map<String, dynamic>;
      return FestivalMap.fromJson(json, isDemo: true);
    }
    try {
      final response = await _api.get('/festivals/$configuredFestivalId');
      final json = Map<String, dynamic>.from(response.data as Map);
      final map = FestivalMap.fromJson(json);
      await _database.upsertFestival(CachedFestivalsCompanion.insert(
        id: map.id,
        name: map.name,
        startsAt: DateTime.parse(json['starts_at'] as String),
        endsAt: DateTime.parse(json['ends_at'] as String),
        boundaryGeoJson: jsonEncode(json['boundary']),
        cachedAt: DateTime.now().toUtc(),
      ));
      await _database.replaceStages(
        map.id,
        map.stages.map((stage) => CachedStagesCompanion.insert(
              id: stage.id,
              festivalId: map.id,
              name: stage.name,
              polygonGeoJson: jsonEncode(
                stage.polygon
                    .map((point) => [point.latitude, point.longitude])
                    .toList(),
              ),
            )),
      );
      return map;
    } on DioException catch (error) {
      if (!_isNetworkFailure(error)) rethrow;
      final cached = await _database.readFestival(configuredFestivalId);
      if (cached == null) rethrow;
      final stages = await _database.readStages(configuredFestivalId);
      return FestivalMap(
        id: cached.id,
        name: cached.name,
        boundary: parsePolygon(cached.boundaryGeoJson),
        stages: stages
            .map((row) => FestivalStage(
                  id: row.id,
                  name: row.name,
                  polygon: parsePolygon(row.polygonGeoJson),
                ))
            .toList(growable: false),
        isDemo: false,
      );
    }
  }

  MemberLocation _locationFromJson(Map<String, dynamic> row) {
    return MemberLocation(
      userId: row['user_id'] as String,
      latitude: _decimal(row['latitude']),
      longitude: _decimal(row['longitude']),
      recordedAt: DateTime.parse(row['recorded_at'] as String),
    );
  }

  MapMeetingPoint _meetingFromJson(Map<String, dynamic> row) {
    return MapMeetingPoint(
      id: row['id'] as String,
      title: row['title'] as String,
      latitude: _decimal(row['latitude']),
      longitude: _decimal(row['longitude']),
    );
  }

  double _decimal(Object? value) => double.parse(value.toString());

  bool _isNetworkFailure(DioException error) {
    return error.response == null || (error.response!.statusCode ?? 0) >= 500;
  }
}
