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

class CachedLocations extends Table {
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
    CachedLocations,
    CachedMeetingPoints,
    PendingSyncOperations,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor])
      : super(executor ?? driftDatabase(name: 'festisquad_cache'));

  @override
  int get schemaVersion => 1;

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
    String squadId,
    Iterable<CachedLocationsCompanion> values,
  ) {
    return transaction(() async {
      await (delete(cachedLocations)
            ..where((row) => row.squadId.equals(squadId)))
          .go();
      final rows = values.toList(growable: false);
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(cachedLocations, rows));
      }
    });
  }

  Future<List<CachedLocation>> readLatestLocations(String squadId) {
    return (select(cachedLocations)
          ..where((row) => row.squadId.equals(squadId))
          ..orderBy([(row) => OrderingTerm.desc(row.recordedAt)]))
        .get();
  }

  Future<void> replaceMeetingPoints(
    String squadId,
    Iterable<CachedMeetingPointsCompanion> values,
  ) {
    return transaction(() async {
      await (delete(cachedMeetingPoints)
            ..where((row) => row.squadId.equals(squadId)))
          .go();
      final rows = values.toList(growable: false);
      if (rows.isNotEmpty) {
        await batch((batch) => batch.insertAll(cachedMeetingPoints, rows));
      }
    });
  }

  Future<List<CachedMeetingPoint>> readMeetingPoints(String squadId) {
    return (select(cachedMeetingPoints)
          ..where((row) => row.squadId.equals(squadId))
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
}

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final database = AppDatabase();
  ref.onDispose(database.close);
  return database;
});
