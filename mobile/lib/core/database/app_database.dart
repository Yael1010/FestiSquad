import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'app_database.g.dart';

class CachedSquads extends Table {
  TextColumn get sessionUserId => text()();
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 120)();
  TextColumn get code => text().withLength(min: 6, max: 6)();
  TextColumn get ownerId => text()();
  TextColumn get memberIdsJson => text()();
  TextColumn get currentUserRole => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {sessionUserId, id};
}

class CachedFestivals extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 160)();
  DateTimeColumn get startsAt => dateTime()();
  DateTimeColumn get endsAt => dateTime()();
  TextColumn get boundaryGeoJson => text()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedStages extends Table {
  TextColumn get id => text()();
  TextColumn get festivalId => text()();
  TextColumn get name => text()();
  TextColumn get polygonGeoJson => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class CachedLocations extends Table {
  TextColumn get sessionUserId => text().withDefault(const Constant(''))();
  TextColumn get squadId => text()();
  TextColumn get userId => text()();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  RealColumn get accuracyMeters => real().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {squadId, userId};
}

class CachedMeetingPoints extends Table {
  TextColumn get sessionUserId => text().withDefault(const Constant(''))();
  TextColumn get id => text()();
  TextColumn get squadId => text()();
  TextColumn get title => text().withLength(min: 1, max: 120)();
  RealColumn get latitude => real()();
  RealColumn get longitude => real()();
  TextColumn get createdByUserId => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get cachedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class PendingSyncOperations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get resourceType => text()();
  TextColumn get operation => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

@DriftDatabase(
  tables: [
    CachedSquads,
    CachedFestivals,
    CachedStages,
    CachedLocations,
    CachedMeetingPoints,
    PendingSyncOperations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(
          executor ??
              driftDatabase(
                name: 'festisquad_cache',
                web: DriftWebOptions(
                  sqlite3Wasm: Uri.parse('sqlite3.wasm'),
                  driftWorker: Uri.parse('drift_worker.js'),
                ),
              ),
        );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) => migrator.createAll(),
        onUpgrade: (migrator, from, to) async {
          if (from < 2) {
            await migrator.createTable(cachedStages);
            await migrator.addColumn(
              cachedLocations,
              cachedLocations.sessionUserId,
            );
            await migrator.addColumn(
              cachedMeetingPoints,
              cachedMeetingPoints.sessionUserId,
            );
          }
        },
      );

  Future<List<CachedSquad>> readSquads(String sessionUserId) {
    return (select(cachedSquads)
          ..where((row) => row.sessionUserId.equals(sessionUserId))
          ..orderBy([(row) => OrderingTerm.desc(row.cachedAt)]))
        .get();
  }

  Future<void> replaceSquads(
    String sessionUserId,
    Iterable<CachedSquadsCompanion> values,
  ) {
    return transaction(() async {
      await (delete(cachedSquads)
            ..where((row) => row.sessionUserId.equals(sessionUserId)))
          .go();
      final rows = values.toList(growable: false);
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(cachedSquads, rows));
      }
    });
  }

  Future<void> upsertSquad(CachedSquadsCompanion value) {
    return into(cachedSquads).insertOnConflictUpdate(value);
  }

  Future<void> replaceLatestLocations(
    String sessionUserId,
    String squadId,
    Iterable<CachedLocationsCompanion> values,
  ) {
    return transaction(() async {
      await (delete(cachedLocations)
            ..where((row) =>
                row.sessionUserId.equals(sessionUserId) &
                row.squadId.equals(squadId)))
          .go();
      final rows = values.toList(growable: false);
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(cachedLocations, rows));
      }
    });
  }

  Future<List<CachedLocation>> readLatestLocations(
    String sessionUserId,
    String squadId,
  ) {
    return (select(cachedLocations)
          ..where((row) =>
              row.sessionUserId.equals(sessionUserId) &
              row.squadId.equals(squadId))
          ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)]))
        .get();
  }

  Future<void> replaceMeetingPoints(
    String sessionUserId,
    String squadId,
    Iterable<CachedMeetingPointsCompanion> values,
  ) {
    return transaction(() async {
      await (delete(cachedMeetingPoints)
            ..where((row) =>
                row.sessionUserId.equals(sessionUserId) &
                row.squadId.equals(squadId)))
          .go();
      final rows = values.toList(growable: false);
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(cachedMeetingPoints, rows));
      }
    });
  }

  Future<List<CachedMeetingPoint>> readMeetingPoints(
    String sessionUserId,
    String squadId,
  ) {
    return (select(cachedMeetingPoints)
          ..where((row) =>
              row.sessionUserId.equals(sessionUserId) &
              row.squadId.equals(squadId))
          ..orderBy([(row) => OrderingTerm.desc(row.createdAt)]))
        .get();
  }

  Future<void> upsertFestival(CachedFestivalsCompanion value) {
    return into(cachedFestivals).insertOnConflictUpdate(value);
  }

  Future<CachedFestival?> readFestival(String festivalId) {
    return (select(cachedFestivals)..where((row) => row.id.equals(festivalId)))
        .getSingleOrNull();
  }

  Future<List<CachedStage>> readStages(String festivalId) {
    return (select(cachedStages)
          ..where((row) => row.festivalId.equals(festivalId)))
        .get();
  }

  Future<void> upsertLocation(CachedLocationsCompanion value) {
    return into(cachedLocations).insertOnConflictUpdate(value);
  }

  Future<List<PendingSyncOperation>> readPendingLocations() {
    return (select(pendingSyncOperations)
          ..where((row) => row.resourceType.equals('location'))
          ..orderBy([(row) => OrderingTerm.asc(row.createdAt)]))
        .get();
  }

  Future<void> queueLatestLocation({
    required String userId,
    required String squadId,
    required String payloadJson,
  }) {
    return transaction(() async {
      for (final pending in await readPendingLocations()) {
        final queued = jsonDecode(pending.payloadJson) as Map<String, dynamic>;
        final payload = queued['payload'] as Map<String, dynamic>;
        if (queued['user_id'] == userId && payload['squad_id'] == squadId) {
          await deletePendingOperation(pending.id);
        }
      }
      await into(pendingSyncOperations).insert(
        PendingSyncOperationsCompanion.insert(
          resourceType: 'location',
          operation: 'upsert',
          payloadJson: payloadJson,
          createdAt: DateTime.now().toUtc(),
        ),
      );
    });
  }

  Future<void> deletePendingOperation(int id) async {
    await (delete(pendingSyncOperations)..where((row) => row.id.equals(id)))
        .go();
  }

  Future<void> replaceStages(
    String festivalId,
    Iterable<CachedStagesCompanion> values,
  ) {
    return transaction(() async {
      await (delete(cachedStages)
            ..where((row) => row.festivalId.equals(festivalId)))
          .go();
      final rows = values.toList(growable: false);
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(cachedStages, rows));
      }
    });
  }
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
