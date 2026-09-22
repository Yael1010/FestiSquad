// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $CachedSquadsTable extends CachedSquads
    with TableInfo<$CachedSquadsTable, CachedSquad> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedSquadsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionUserIdMeta =
      const VerificationMeta('sessionUserId');
  @override
  late final GeneratedColumn<String> sessionUserId = GeneratedColumn<String>(
      'session_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _codeMeta = const VerificationMeta('code');
  @override
  late final GeneratedColumn<String> code = GeneratedColumn<String>(
      'code', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 6, maxTextLength: 6),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _ownerIdMeta =
      const VerificationMeta('ownerId');
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
      'owner_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _memberIdsJsonMeta =
      const VerificationMeta('memberIdsJson');
  @override
  late final GeneratedColumn<String> memberIdsJson = GeneratedColumn<String>(
      'member_ids_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _currentUserRoleMeta =
      const VerificationMeta('currentUserRole');
  @override
  late final GeneratedColumn<String> currentUserRole = GeneratedColumn<String>(
      'current_user_role', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        sessionUserId,
        id,
        name,
        code,
        ownerId,
        memberIdsJson,
        currentUserRole,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_squads';
  @override
  VerificationContext validateIntegrity(Insertable<CachedSquad> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_user_id')) {
      context.handle(
          _sessionUserIdMeta,
          sessionUserId.isAcceptableOrUnknown(
              data['session_user_id']!, _sessionUserIdMeta));
    } else if (isInserting) {
      context.missing(_sessionUserIdMeta);
    }
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('code')) {
      context.handle(
          _codeMeta, code.isAcceptableOrUnknown(data['code']!, _codeMeta));
    } else if (isInserting) {
      context.missing(_codeMeta);
    }
    if (data.containsKey('owner_id')) {
      context.handle(_ownerIdMeta,
          ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta));
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('member_ids_json')) {
      context.handle(
          _memberIdsJsonMeta,
          memberIdsJson.isAcceptableOrUnknown(
              data['member_ids_json']!, _memberIdsJsonMeta));
    } else if (isInserting) {
      context.missing(_memberIdsJsonMeta);
    }
    if (data.containsKey('current_user_role')) {
      context.handle(
          _currentUserRoleMeta,
          currentUserRole.isAcceptableOrUnknown(
              data['current_user_role']!, _currentUserRoleMeta));
    } else if (isInserting) {
      context.missing(_currentUserRoleMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionUserId, id};
  @override
  CachedSquad map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedSquad(
      sessionUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}session_user_id'])!,
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      code: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}code'])!,
      ownerId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}owner_id'])!,
      memberIdsJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}member_ids_json'])!,
      currentUserRole: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}current_user_role'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedSquadsTable createAlias(String alias) {
    return $CachedSquadsTable(attachedDatabase, alias);
  }
}

class CachedSquad extends DataClass implements Insertable<CachedSquad> {
  final String sessionUserId;
  final String id;
  final String name;
  final String code;
  final String ownerId;
  final String memberIdsJson;
  final String currentUserRole;
  final DateTime cachedAt;
  const CachedSquad(
      {required this.sessionUserId,
      required this.id,
      required this.name,
      required this.code,
      required this.ownerId,
      required this.memberIdsJson,
      required this.currentUserRole,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_user_id'] = Variable<String>(sessionUserId);
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['code'] = Variable<String>(code);
    map['owner_id'] = Variable<String>(ownerId);
    map['member_ids_json'] = Variable<String>(memberIdsJson);
    map['current_user_role'] = Variable<String>(currentUserRole);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedSquadsCompanion toCompanion(bool nullToAbsent) {
    return CachedSquadsCompanion(
      sessionUserId: Value(sessionUserId),
      id: Value(id),
      name: Value(name),
      code: Value(code),
      ownerId: Value(ownerId),
      memberIdsJson: Value(memberIdsJson),
      currentUserRole: Value(currentUserRole),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedSquad.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedSquad(
      sessionUserId: serializer.fromJson<String>(json['sessionUserId']),
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      code: serializer.fromJson<String>(json['code']),
      ownerId: serializer.fromJson<String>(json['ownerId']),
      memberIdsJson: serializer.fromJson<String>(json['memberIdsJson']),
      currentUserRole: serializer.fromJson<String>(json['currentUserRole']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionUserId': serializer.toJson<String>(sessionUserId),
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'code': serializer.toJson<String>(code),
      'ownerId': serializer.toJson<String>(ownerId),
      'memberIdsJson': serializer.toJson<String>(memberIdsJson),
      'currentUserRole': serializer.toJson<String>(currentUserRole),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedSquad copyWith(
          {String? sessionUserId,
          String? id,
          String? name,
          String? code,
          String? ownerId,
          String? memberIdsJson,
          String? currentUserRole,
          DateTime? cachedAt}) =>
      CachedSquad(
        sessionUserId: sessionUserId ?? this.sessionUserId,
        id: id ?? this.id,
        name: name ?? this.name,
        code: code ?? this.code,
        ownerId: ownerId ?? this.ownerId,
        memberIdsJson: memberIdsJson ?? this.memberIdsJson,
        currentUserRole: currentUserRole ?? this.currentUserRole,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedSquad copyWithCompanion(CachedSquadsCompanion data) {
    return CachedSquad(
      sessionUserId: data.sessionUserId.present
          ? data.sessionUserId.value
          : this.sessionUserId,
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      code: data.code.present ? data.code.value : this.code,
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      memberIdsJson: data.memberIdsJson.present
          ? data.memberIdsJson.value
          : this.memberIdsJson,
      currentUserRole: data.currentUserRole.present
          ? data.currentUserRole.value
          : this.currentUserRole,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedSquad(')
          ..write('sessionUserId: $sessionUserId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('ownerId: $ownerId, ')
          ..write('memberIdsJson: $memberIdsJson, ')
          ..write('currentUserRole: $currentUserRole, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionUserId, id, name, code, ownerId,
      memberIdsJson, currentUserRole, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedSquad &&
          other.sessionUserId == this.sessionUserId &&
          other.id == this.id &&
          other.name == this.name &&
          other.code == this.code &&
          other.ownerId == this.ownerId &&
          other.memberIdsJson == this.memberIdsJson &&
          other.currentUserRole == this.currentUserRole &&
          other.cachedAt == this.cachedAt);
}

class CachedSquadsCompanion extends UpdateCompanion<CachedSquad> {
  final Value<String> sessionUserId;
  final Value<String> id;
  final Value<String> name;
  final Value<String> code;
  final Value<String> ownerId;
  final Value<String> memberIdsJson;
  final Value<String> currentUserRole;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedSquadsCompanion({
    this.sessionUserId = const Value.absent(),
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.code = const Value.absent(),
    this.ownerId = const Value.absent(),
    this.memberIdsJson = const Value.absent(),
    this.currentUserRole = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedSquadsCompanion.insert({
    required String sessionUserId,
    required String id,
    required String name,
    required String code,
    required String ownerId,
    required String memberIdsJson,
    required String currentUserRole,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : sessionUserId = Value(sessionUserId),
        id = Value(id),
        name = Value(name),
        code = Value(code),
        ownerId = Value(ownerId),
        memberIdsJson = Value(memberIdsJson),
        currentUserRole = Value(currentUserRole),
        cachedAt = Value(cachedAt);
  static Insertable<CachedSquad> custom({
    Expression<String>? sessionUserId,
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? code,
    Expression<String>? ownerId,
    Expression<String>? memberIdsJson,
    Expression<String>? currentUserRole,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionUserId != null) 'session_user_id': sessionUserId,
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (code != null) 'code': code,
      if (ownerId != null) 'owner_id': ownerId,
      if (memberIdsJson != null) 'member_ids_json': memberIdsJson,
      if (currentUserRole != null) 'current_user_role': currentUserRole,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedSquadsCompanion copyWith(
      {Value<String>? sessionUserId,
      Value<String>? id,
      Value<String>? name,
      Value<String>? code,
      Value<String>? ownerId,
      Value<String>? memberIdsJson,
      Value<String>? currentUserRole,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedSquadsCompanion(
      sessionUserId: sessionUserId ?? this.sessionUserId,
      id: id ?? this.id,
      name: name ?? this.name,
      code: code ?? this.code,
      ownerId: ownerId ?? this.ownerId,
      memberIdsJson: memberIdsJson ?? this.memberIdsJson,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionUserId.present) {
      map['session_user_id'] = Variable<String>(sessionUserId.value);
    }
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (code.present) {
      map['code'] = Variable<String>(code.value);
    }
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (memberIdsJson.present) {
      map['member_ids_json'] = Variable<String>(memberIdsJson.value);
    }
    if (currentUserRole.present) {
      map['current_user_role'] = Variable<String>(currentUserRole.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedSquadsCompanion(')
          ..write('sessionUserId: $sessionUserId, ')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('code: $code, ')
          ..write('ownerId: $ownerId, ')
          ..write('memberIdsJson: $memberIdsJson, ')
          ..write('currentUserRole: $currentUserRole, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedFestivalsTable extends CachedFestivals
    with TableInfo<$CachedFestivalsTable, CachedFestival> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedFestivalsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
      'name', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 160),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _startsAtMeta =
      const VerificationMeta('startsAt');
  @override
  late final GeneratedColumn<DateTime> startsAt = GeneratedColumn<DateTime>(
      'starts_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _endsAtMeta = const VerificationMeta('endsAt');
  @override
  late final GeneratedColumn<DateTime> endsAt = GeneratedColumn<DateTime>(
      'ends_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _boundaryGeoJsonMeta =
      const VerificationMeta('boundaryGeoJson');
  @override
  late final GeneratedColumn<String> boundaryGeoJson = GeneratedColumn<String>(
      'boundary_geo_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns =>
      [id, name, startsAt, endsAt, boundaryGeoJson, cachedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_festivals';
  @override
  VerificationContext validateIntegrity(Insertable<CachedFestival> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
          _nameMeta, name.isAcceptableOrUnknown(data['name']!, _nameMeta));
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('starts_at')) {
      context.handle(_startsAtMeta,
          startsAt.isAcceptableOrUnknown(data['starts_at']!, _startsAtMeta));
    } else if (isInserting) {
      context.missing(_startsAtMeta);
    }
    if (data.containsKey('ends_at')) {
      context.handle(_endsAtMeta,
          endsAt.isAcceptableOrUnknown(data['ends_at']!, _endsAtMeta));
    } else if (isInserting) {
      context.missing(_endsAtMeta);
    }
    if (data.containsKey('boundary_geo_json')) {
      context.handle(
          _boundaryGeoJsonMeta,
          boundaryGeoJson.isAcceptableOrUnknown(
              data['boundary_geo_json']!, _boundaryGeoJsonMeta));
    } else if (isInserting) {
      context.missing(_boundaryGeoJsonMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedFestival map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedFestival(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      name: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}name'])!,
      startsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}starts_at'])!,
      endsAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}ends_at'])!,
      boundaryGeoJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}boundary_geo_json'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedFestivalsTable createAlias(String alias) {
    return $CachedFestivalsTable(attachedDatabase, alias);
  }
}

class CachedFestival extends DataClass implements Insertable<CachedFestival> {
  final String id;
  final String name;
  final DateTime startsAt;
  final DateTime endsAt;
  final String boundaryGeoJson;
  final DateTime cachedAt;
  const CachedFestival(
      {required this.id,
      required this.name,
      required this.startsAt,
      required this.endsAt,
      required this.boundaryGeoJson,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    map['starts_at'] = Variable<DateTime>(startsAt);
    map['ends_at'] = Variable<DateTime>(endsAt);
    map['boundary_geo_json'] = Variable<String>(boundaryGeoJson);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedFestivalsCompanion toCompanion(bool nullToAbsent) {
    return CachedFestivalsCompanion(
      id: Value(id),
      name: Value(name),
      startsAt: Value(startsAt),
      endsAt: Value(endsAt),
      boundaryGeoJson: Value(boundaryGeoJson),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedFestival.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedFestival(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      startsAt: serializer.fromJson<DateTime>(json['startsAt']),
      endsAt: serializer.fromJson<DateTime>(json['endsAt']),
      boundaryGeoJson: serializer.fromJson<String>(json['boundaryGeoJson']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'startsAt': serializer.toJson<DateTime>(startsAt),
      'endsAt': serializer.toJson<DateTime>(endsAt),
      'boundaryGeoJson': serializer.toJson<String>(boundaryGeoJson),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedFestival copyWith(
          {String? id,
          String? name,
          DateTime? startsAt,
          DateTime? endsAt,
          String? boundaryGeoJson,
          DateTime? cachedAt}) =>
      CachedFestival(
        id: id ?? this.id,
        name: name ?? this.name,
        startsAt: startsAt ?? this.startsAt,
        endsAt: endsAt ?? this.endsAt,
        boundaryGeoJson: boundaryGeoJson ?? this.boundaryGeoJson,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedFestival copyWithCompanion(CachedFestivalsCompanion data) {
    return CachedFestival(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      startsAt: data.startsAt.present ? data.startsAt.value : this.startsAt,
      endsAt: data.endsAt.present ? data.endsAt.value : this.endsAt,
      boundaryGeoJson: data.boundaryGeoJson.present
          ? data.boundaryGeoJson.value
          : this.boundaryGeoJson,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedFestival(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('boundaryGeoJson: $boundaryGeoJson, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, startsAt, endsAt, boundaryGeoJson, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedFestival &&
          other.id == this.id &&
          other.name == this.name &&
          other.startsAt == this.startsAt &&
          other.endsAt == this.endsAt &&
          other.boundaryGeoJson == this.boundaryGeoJson &&
          other.cachedAt == this.cachedAt);
}

class CachedFestivalsCompanion extends UpdateCompanion<CachedFestival> {
  final Value<String> id;
  final Value<String> name;
  final Value<DateTime> startsAt;
  final Value<DateTime> endsAt;
  final Value<String> boundaryGeoJson;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedFestivalsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.startsAt = const Value.absent(),
    this.endsAt = const Value.absent(),
    this.boundaryGeoJson = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedFestivalsCompanion.insert({
    required String id,
    required String name,
    required DateTime startsAt,
    required DateTime endsAt,
    required String boundaryGeoJson,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        name = Value(name),
        startsAt = Value(startsAt),
        endsAt = Value(endsAt),
        boundaryGeoJson = Value(boundaryGeoJson),
        cachedAt = Value(cachedAt);
  static Insertable<CachedFestival> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<DateTime>? startsAt,
    Expression<DateTime>? endsAt,
    Expression<String>? boundaryGeoJson,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (startsAt != null) 'starts_at': startsAt,
      if (endsAt != null) 'ends_at': endsAt,
      if (boundaryGeoJson != null) 'boundary_geo_json': boundaryGeoJson,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedFestivalsCompanion copyWith(
      {Value<String>? id,
      Value<String>? name,
      Value<DateTime>? startsAt,
      Value<DateTime>? endsAt,
      Value<String>? boundaryGeoJson,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedFestivalsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      startsAt: startsAt ?? this.startsAt,
      endsAt: endsAt ?? this.endsAt,
      boundaryGeoJson: boundaryGeoJson ?? this.boundaryGeoJson,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (startsAt.present) {
      map['starts_at'] = Variable<DateTime>(startsAt.value);
    }
    if (endsAt.present) {
      map['ends_at'] = Variable<DateTime>(endsAt.value);
    }
    if (boundaryGeoJson.present) {
      map['boundary_geo_json'] = Variable<String>(boundaryGeoJson.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedFestivalsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('startsAt: $startsAt, ')
          ..write('endsAt: $endsAt, ')
          ..write('boundaryGeoJson: $boundaryGeoJson, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedLocationsTable extends CachedLocations
    with TableInfo<$CachedLocationsTable, CachedLocation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedLocationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _squadIdMeta =
      const VerificationMeta('squadId');
  @override
  late final GeneratedColumn<String> squadId = GeneratedColumn<String>(
      'squad_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _userIdMeta = const VerificationMeta('userId');
  @override
  late final GeneratedColumn<String> userId = GeneratedColumn<String>(
      'user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _accuracyMetersMeta =
      const VerificationMeta('accuracyMeters');
  @override
  late final GeneratedColumn<double> accuracyMeters = GeneratedColumn<double>(
      'accuracy_meters', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _recordedAtMeta =
      const VerificationMeta('recordedAt');
  @override
  late final GeneratedColumn<DateTime> recordedAt = GeneratedColumn<DateTime>(
      'recorded_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        squadId,
        userId,
        latitude,
        longitude,
        accuracyMeters,
        recordedAt,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_locations';
  @override
  VerificationContext validateIntegrity(Insertable<CachedLocation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('squad_id')) {
      context.handle(_squadIdMeta,
          squadId.isAcceptableOrUnknown(data['squad_id']!, _squadIdMeta));
    } else if (isInserting) {
      context.missing(_squadIdMeta);
    }
    if (data.containsKey('user_id')) {
      context.handle(_userIdMeta,
          userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta));
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('accuracy_meters')) {
      context.handle(
          _accuracyMetersMeta,
          accuracyMeters.isAcceptableOrUnknown(
              data['accuracy_meters']!, _accuracyMetersMeta));
    }
    if (data.containsKey('recorded_at')) {
      context.handle(
          _recordedAtMeta,
          recordedAt.isAcceptableOrUnknown(
              data['recorded_at']!, _recordedAtMeta));
    } else if (isInserting) {
      context.missing(_recordedAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {squadId, userId};
  @override
  CachedLocation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedLocation(
      squadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}squad_id'])!,
      userId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}user_id'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      accuracyMeters: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}accuracy_meters']),
      recordedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}recorded_at'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedLocationsTable createAlias(String alias) {
    return $CachedLocationsTable(attachedDatabase, alias);
  }
}

class CachedLocation extends DataClass implements Insertable<CachedLocation> {
  final String squadId;
  final String userId;
  final double latitude;
  final double longitude;
  final double? accuracyMeters;
  final DateTime recordedAt;
  final DateTime cachedAt;
  const CachedLocation(
      {required this.squadId,
      required this.userId,
      required this.latitude,
      required this.longitude,
      this.accuracyMeters,
      required this.recordedAt,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['squad_id'] = Variable<String>(squadId);
    map['user_id'] = Variable<String>(userId);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    if (!nullToAbsent || accuracyMeters != null) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters);
    }
    map['recorded_at'] = Variable<DateTime>(recordedAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedLocationsCompanion toCompanion(bool nullToAbsent) {
    return CachedLocationsCompanion(
      squadId: Value(squadId),
      userId: Value(userId),
      latitude: Value(latitude),
      longitude: Value(longitude),
      accuracyMeters: accuracyMeters == null && nullToAbsent
          ? const Value.absent()
          : Value(accuracyMeters),
      recordedAt: Value(recordedAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedLocation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedLocation(
      squadId: serializer.fromJson<String>(json['squadId']),
      userId: serializer.fromJson<String>(json['userId']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      accuracyMeters: serializer.fromJson<double?>(json['accuracyMeters']),
      recordedAt: serializer.fromJson<DateTime>(json['recordedAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'squadId': serializer.toJson<String>(squadId),
      'userId': serializer.toJson<String>(userId),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'accuracyMeters': serializer.toJson<double?>(accuracyMeters),
      'recordedAt': serializer.toJson<DateTime>(recordedAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedLocation copyWith(
          {String? squadId,
          String? userId,
          double? latitude,
          double? longitude,
          Value<double?> accuracyMeters = const Value.absent(),
          DateTime? recordedAt,
          DateTime? cachedAt}) =>
      CachedLocation(
        squadId: squadId ?? this.squadId,
        userId: userId ?? this.userId,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        accuracyMeters:
            accuracyMeters.present ? accuracyMeters.value : this.accuracyMeters,
        recordedAt: recordedAt ?? this.recordedAt,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedLocation copyWithCompanion(CachedLocationsCompanion data) {
    return CachedLocation(
      squadId: data.squadId.present ? data.squadId.value : this.squadId,
      userId: data.userId.present ? data.userId.value : this.userId,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      accuracyMeters: data.accuracyMeters.present
          ? data.accuracyMeters.value
          : this.accuracyMeters,
      recordedAt:
          data.recordedAt.present ? data.recordedAt.value : this.recordedAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedLocation(')
          ..write('squadId: $squadId, ')
          ..write('userId: $userId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(squadId, userId, latitude, longitude,
      accuracyMeters, recordedAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedLocation &&
          other.squadId == this.squadId &&
          other.userId == this.userId &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.accuracyMeters == this.accuracyMeters &&
          other.recordedAt == this.recordedAt &&
          other.cachedAt == this.cachedAt);
}

class CachedLocationsCompanion extends UpdateCompanion<CachedLocation> {
  final Value<String> squadId;
  final Value<String> userId;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<double?> accuracyMeters;
  final Value<DateTime> recordedAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedLocationsCompanion({
    this.squadId = const Value.absent(),
    this.userId = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.accuracyMeters = const Value.absent(),
    this.recordedAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedLocationsCompanion.insert({
    required String squadId,
    required String userId,
    required double latitude,
    required double longitude,
    this.accuracyMeters = const Value.absent(),
    required DateTime recordedAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : squadId = Value(squadId),
        userId = Value(userId),
        latitude = Value(latitude),
        longitude = Value(longitude),
        recordedAt = Value(recordedAt),
        cachedAt = Value(cachedAt);
  static Insertable<CachedLocation> custom({
    Expression<String>? squadId,
    Expression<String>? userId,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<double>? accuracyMeters,
    Expression<DateTime>? recordedAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (squadId != null) 'squad_id': squadId,
      if (userId != null) 'user_id': userId,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      if (recordedAt != null) 'recorded_at': recordedAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedLocationsCompanion copyWith(
      {Value<String>? squadId,
      Value<String>? userId,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<double?>? accuracyMeters,
      Value<DateTime>? recordedAt,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedLocationsCompanion(
      squadId: squadId ?? this.squadId,
      userId: userId ?? this.userId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      accuracyMeters: accuracyMeters ?? this.accuracyMeters,
      recordedAt: recordedAt ?? this.recordedAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (squadId.present) {
      map['squad_id'] = Variable<String>(squadId.value);
    }
    if (userId.present) {
      map['user_id'] = Variable<String>(userId.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (accuracyMeters.present) {
      map['accuracy_meters'] = Variable<double>(accuracyMeters.value);
    }
    if (recordedAt.present) {
      map['recorded_at'] = Variable<DateTime>(recordedAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedLocationsCompanion(')
          ..write('squadId: $squadId, ')
          ..write('userId: $userId, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('accuracyMeters: $accuracyMeters, ')
          ..write('recordedAt: $recordedAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CachedMeetingPointsTable extends CachedMeetingPoints
    with TableInfo<$CachedMeetingPointsTable, CachedMeetingPoint> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CachedMeetingPointsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
      'id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _squadIdMeta =
      const VerificationMeta('squadId');
  @override
  late final GeneratedColumn<String> squadId = GeneratedColumn<String>(
      'squad_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
      'title', aliasedName, false,
      additionalChecks:
          GeneratedColumn.checkTextLength(minTextLength: 1, maxTextLength: 120),
      type: DriftSqlType.string,
      requiredDuringInsert: true);
  static const VerificationMeta _latitudeMeta =
      const VerificationMeta('latitude');
  @override
  late final GeneratedColumn<double> latitude = GeneratedColumn<double>(
      'latitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _longitudeMeta =
      const VerificationMeta('longitude');
  @override
  late final GeneratedColumn<double> longitude = GeneratedColumn<double>(
      'longitude', aliasedName, false,
      type: DriftSqlType.double, requiredDuringInsert: true);
  static const VerificationMeta _createdByUserIdMeta =
      const VerificationMeta('createdByUserId');
  @override
  late final GeneratedColumn<String> createdByUserId = GeneratedColumn<String>(
      'created_by_user_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _cachedAtMeta =
      const VerificationMeta('cachedAt');
  @override
  late final GeneratedColumn<DateTime> cachedAt = GeneratedColumn<DateTime>(
      'cached_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        id,
        squadId,
        title,
        latitude,
        longitude,
        createdByUserId,
        createdAt,
        cachedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'cached_meeting_points';
  @override
  VerificationContext validateIntegrity(Insertable<CachedMeetingPoint> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('squad_id')) {
      context.handle(_squadIdMeta,
          squadId.isAcceptableOrUnknown(data['squad_id']!, _squadIdMeta));
    } else if (isInserting) {
      context.missing(_squadIdMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
          _titleMeta, title.isAcceptableOrUnknown(data['title']!, _titleMeta));
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('latitude')) {
      context.handle(_latitudeMeta,
          latitude.isAcceptableOrUnknown(data['latitude']!, _latitudeMeta));
    } else if (isInserting) {
      context.missing(_latitudeMeta);
    }
    if (data.containsKey('longitude')) {
      context.handle(_longitudeMeta,
          longitude.isAcceptableOrUnknown(data['longitude']!, _longitudeMeta));
    } else if (isInserting) {
      context.missing(_longitudeMeta);
    }
    if (data.containsKey('created_by_user_id')) {
      context.handle(
          _createdByUserIdMeta,
          createdByUserId.isAcceptableOrUnknown(
              data['created_by_user_id']!, _createdByUserIdMeta));
    } else if (isInserting) {
      context.missing(_createdByUserIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('cached_at')) {
      context.handle(_cachedAtMeta,
          cachedAt.isAcceptableOrUnknown(data['cached_at']!, _cachedAtMeta));
    } else if (isInserting) {
      context.missing(_cachedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CachedMeetingPoint map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CachedMeetingPoint(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}id'])!,
      squadId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}squad_id'])!,
      title: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}title'])!,
      latitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}latitude'])!,
      longitude: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}longitude'])!,
      createdByUserId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}created_by_user_id'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      cachedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}cached_at'])!,
    );
  }

  @override
  $CachedMeetingPointsTable createAlias(String alias) {
    return $CachedMeetingPointsTable(attachedDatabase, alias);
  }
}

class CachedMeetingPoint extends DataClass
    implements Insertable<CachedMeetingPoint> {
  final String id;
  final String squadId;
  final String title;
  final double latitude;
  final double longitude;
  final String createdByUserId;
  final DateTime createdAt;
  final DateTime cachedAt;
  const CachedMeetingPoint(
      {required this.id,
      required this.squadId,
      required this.title,
      required this.latitude,
      required this.longitude,
      required this.createdByUserId,
      required this.createdAt,
      required this.cachedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['squad_id'] = Variable<String>(squadId);
    map['title'] = Variable<String>(title);
    map['latitude'] = Variable<double>(latitude);
    map['longitude'] = Variable<double>(longitude);
    map['created_by_user_id'] = Variable<String>(createdByUserId);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['cached_at'] = Variable<DateTime>(cachedAt);
    return map;
  }

  CachedMeetingPointsCompanion toCompanion(bool nullToAbsent) {
    return CachedMeetingPointsCompanion(
      id: Value(id),
      squadId: Value(squadId),
      title: Value(title),
      latitude: Value(latitude),
      longitude: Value(longitude),
      createdByUserId: Value(createdByUserId),
      createdAt: Value(createdAt),
      cachedAt: Value(cachedAt),
    );
  }

  factory CachedMeetingPoint.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CachedMeetingPoint(
      id: serializer.fromJson<String>(json['id']),
      squadId: serializer.fromJson<String>(json['squadId']),
      title: serializer.fromJson<String>(json['title']),
      latitude: serializer.fromJson<double>(json['latitude']),
      longitude: serializer.fromJson<double>(json['longitude']),
      createdByUserId: serializer.fromJson<String>(json['createdByUserId']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      cachedAt: serializer.fromJson<DateTime>(json['cachedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'squadId': serializer.toJson<String>(squadId),
      'title': serializer.toJson<String>(title),
      'latitude': serializer.toJson<double>(latitude),
      'longitude': serializer.toJson<double>(longitude),
      'createdByUserId': serializer.toJson<String>(createdByUserId),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'cachedAt': serializer.toJson<DateTime>(cachedAt),
    };
  }

  CachedMeetingPoint copyWith(
          {String? id,
          String? squadId,
          String? title,
          double? latitude,
          double? longitude,
          String? createdByUserId,
          DateTime? createdAt,
          DateTime? cachedAt}) =>
      CachedMeetingPoint(
        id: id ?? this.id,
        squadId: squadId ?? this.squadId,
        title: title ?? this.title,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        createdByUserId: createdByUserId ?? this.createdByUserId,
        createdAt: createdAt ?? this.createdAt,
        cachedAt: cachedAt ?? this.cachedAt,
      );
  CachedMeetingPoint copyWithCompanion(CachedMeetingPointsCompanion data) {
    return CachedMeetingPoint(
      id: data.id.present ? data.id.value : this.id,
      squadId: data.squadId.present ? data.squadId.value : this.squadId,
      title: data.title.present ? data.title.value : this.title,
      latitude: data.latitude.present ? data.latitude.value : this.latitude,
      longitude: data.longitude.present ? data.longitude.value : this.longitude,
      createdByUserId: data.createdByUserId.present
          ? data.createdByUserId.value
          : this.createdByUserId,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      cachedAt: data.cachedAt.present ? data.cachedAt.value : this.cachedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CachedMeetingPoint(')
          ..write('id: $id, ')
          ..write('squadId: $squadId, ')
          ..write('title: $title, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedAt: $cachedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, squadId, title, latitude, longitude,
      createdByUserId, createdAt, cachedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CachedMeetingPoint &&
          other.id == this.id &&
          other.squadId == this.squadId &&
          other.title == this.title &&
          other.latitude == this.latitude &&
          other.longitude == this.longitude &&
          other.createdByUserId == this.createdByUserId &&
          other.createdAt == this.createdAt &&
          other.cachedAt == this.cachedAt);
}

class CachedMeetingPointsCompanion extends UpdateCompanion<CachedMeetingPoint> {
  final Value<String> id;
  final Value<String> squadId;
  final Value<String> title;
  final Value<double> latitude;
  final Value<double> longitude;
  final Value<String> createdByUserId;
  final Value<DateTime> createdAt;
  final Value<DateTime> cachedAt;
  final Value<int> rowid;
  const CachedMeetingPointsCompanion({
    this.id = const Value.absent(),
    this.squadId = const Value.absent(),
    this.title = const Value.absent(),
    this.latitude = const Value.absent(),
    this.longitude = const Value.absent(),
    this.createdByUserId = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.cachedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CachedMeetingPointsCompanion.insert({
    required String id,
    required String squadId,
    required String title,
    required double latitude,
    required double longitude,
    required String createdByUserId,
    required DateTime createdAt,
    required DateTime cachedAt,
    this.rowid = const Value.absent(),
  })  : id = Value(id),
        squadId = Value(squadId),
        title = Value(title),
        latitude = Value(latitude),
        longitude = Value(longitude),
        createdByUserId = Value(createdByUserId),
        createdAt = Value(createdAt),
        cachedAt = Value(cachedAt);
  static Insertable<CachedMeetingPoint> custom({
    Expression<String>? id,
    Expression<String>? squadId,
    Expression<String>? title,
    Expression<double>? latitude,
    Expression<double>? longitude,
    Expression<String>? createdByUserId,
    Expression<DateTime>? createdAt,
    Expression<DateTime>? cachedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (squadId != null) 'squad_id': squadId,
      if (title != null) 'title': title,
      if (latitude != null) 'latitude': latitude,
      if (longitude != null) 'longitude': longitude,
      if (createdByUserId != null) 'created_by_user_id': createdByUserId,
      if (createdAt != null) 'created_at': createdAt,
      if (cachedAt != null) 'cached_at': cachedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CachedMeetingPointsCompanion copyWith(
      {Value<String>? id,
      Value<String>? squadId,
      Value<String>? title,
      Value<double>? latitude,
      Value<double>? longitude,
      Value<String>? createdByUserId,
      Value<DateTime>? createdAt,
      Value<DateTime>? cachedAt,
      Value<int>? rowid}) {
    return CachedMeetingPointsCompanion(
      id: id ?? this.id,
      squadId: squadId ?? this.squadId,
      title: title ?? this.title,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdByUserId: createdByUserId ?? this.createdByUserId,
      createdAt: createdAt ?? this.createdAt,
      cachedAt: cachedAt ?? this.cachedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (squadId.present) {
      map['squad_id'] = Variable<String>(squadId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (latitude.present) {
      map['latitude'] = Variable<double>(latitude.value);
    }
    if (longitude.present) {
      map['longitude'] = Variable<double>(longitude.value);
    }
    if (createdByUserId.present) {
      map['created_by_user_id'] = Variable<String>(createdByUserId.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (cachedAt.present) {
      map['cached_at'] = Variable<DateTime>(cachedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CachedMeetingPointsCompanion(')
          ..write('id: $id, ')
          ..write('squadId: $squadId, ')
          ..write('title: $title, ')
          ..write('latitude: $latitude, ')
          ..write('longitude: $longitude, ')
          ..write('createdByUserId: $createdByUserId, ')
          ..write('createdAt: $createdAt, ')
          ..write('cachedAt: $cachedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $PendingSyncOperationsTable extends PendingSyncOperations
    with TableInfo<$PendingSyncOperationsTable, PendingSyncOperation> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PendingSyncOperationsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
      'id', aliasedName, false,
      hasAutoIncrement: true,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultConstraints:
          GeneratedColumn.constraintIsAlways('PRIMARY KEY AUTOINCREMENT'));
  static const VerificationMeta _resourceTypeMeta =
      const VerificationMeta('resourceType');
  @override
  late final GeneratedColumn<String> resourceType = GeneratedColumn<String>(
      'resource_type', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _operationMeta =
      const VerificationMeta('operation');
  @override
  late final GeneratedColumn<String> operation = GeneratedColumn<String>(
      'operation', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _payloadJsonMeta =
      const VerificationMeta('payloadJson');
  @override
  late final GeneratedColumn<String> payloadJson = GeneratedColumn<String>(
      'payload_json', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _createdAtMeta =
      const VerificationMeta('createdAt');
  @override
  late final GeneratedColumn<DateTime> createdAt = GeneratedColumn<DateTime>(
      'created_at', aliasedName, false,
      type: DriftSqlType.dateTime, requiredDuringInsert: true);
  static const VerificationMeta _attemptsMeta =
      const VerificationMeta('attempts');
  @override
  late final GeneratedColumn<int> attempts = GeneratedColumn<int>(
      'attempts', aliasedName, false,
      type: DriftSqlType.int,
      requiredDuringInsert: false,
      defaultValue: const Constant(0));
  @override
  List<GeneratedColumn> get $columns =>
      [id, resourceType, operation, payloadJson, createdAt, attempts];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'pending_sync_operations';
  @override
  VerificationContext validateIntegrity(
      Insertable<PendingSyncOperation> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('resource_type')) {
      context.handle(
          _resourceTypeMeta,
          resourceType.isAcceptableOrUnknown(
              data['resource_type']!, _resourceTypeMeta));
    } else if (isInserting) {
      context.missing(_resourceTypeMeta);
    }
    if (data.containsKey('operation')) {
      context.handle(_operationMeta,
          operation.isAcceptableOrUnknown(data['operation']!, _operationMeta));
    } else if (isInserting) {
      context.missing(_operationMeta);
    }
    if (data.containsKey('payload_json')) {
      context.handle(
          _payloadJsonMeta,
          payloadJson.isAcceptableOrUnknown(
              data['payload_json']!, _payloadJsonMeta));
    } else if (isInserting) {
      context.missing(_payloadJsonMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(_createdAtMeta,
          createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta));
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('attempts')) {
      context.handle(_attemptsMeta,
          attempts.isAcceptableOrUnknown(data['attempts']!, _attemptsMeta));
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  PendingSyncOperation map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return PendingSyncOperation(
      id: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}id'])!,
      resourceType: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}resource_type'])!,
      operation: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}operation'])!,
      payloadJson: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}payload_json'])!,
      createdAt: attachedDatabase.typeMapping
          .read(DriftSqlType.dateTime, data['${effectivePrefix}created_at'])!,
      attempts: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}attempts'])!,
    );
  }

  @override
  $PendingSyncOperationsTable createAlias(String alias) {
    return $PendingSyncOperationsTable(attachedDatabase, alias);
  }
}

class PendingSyncOperation extends DataClass
    implements Insertable<PendingSyncOperation> {
  final int id;
  final String resourceType;
  final String operation;
  final String payloadJson;
  final DateTime createdAt;
  final int attempts;
  const PendingSyncOperation(
      {required this.id,
      required this.resourceType,
      required this.operation,
      required this.payloadJson,
      required this.createdAt,
      required this.attempts});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['resource_type'] = Variable<String>(resourceType);
    map['operation'] = Variable<String>(operation);
    map['payload_json'] = Variable<String>(payloadJson);
    map['created_at'] = Variable<DateTime>(createdAt);
    map['attempts'] = Variable<int>(attempts);
    return map;
  }

  PendingSyncOperationsCompanion toCompanion(bool nullToAbsent) {
    return PendingSyncOperationsCompanion(
      id: Value(id),
      resourceType: Value(resourceType),
      operation: Value(operation),
      payloadJson: Value(payloadJson),
      createdAt: Value(createdAt),
      attempts: Value(attempts),
    );
  }

  factory PendingSyncOperation.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return PendingSyncOperation(
      id: serializer.fromJson<int>(json['id']),
      resourceType: serializer.fromJson<String>(json['resourceType']),
      operation: serializer.fromJson<String>(json['operation']),
      payloadJson: serializer.fromJson<String>(json['payloadJson']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      attempts: serializer.fromJson<int>(json['attempts']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'resourceType': serializer.toJson<String>(resourceType),
      'operation': serializer.toJson<String>(operation),
      'payloadJson': serializer.toJson<String>(payloadJson),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'attempts': serializer.toJson<int>(attempts),
    };
  }

  PendingSyncOperation copyWith(
          {int? id,
          String? resourceType,
          String? operation,
          String? payloadJson,
          DateTime? createdAt,
          int? attempts}) =>
      PendingSyncOperation(
        id: id ?? this.id,
        resourceType: resourceType ?? this.resourceType,
        operation: operation ?? this.operation,
        payloadJson: payloadJson ?? this.payloadJson,
        createdAt: createdAt ?? this.createdAt,
        attempts: attempts ?? this.attempts,
      );
  PendingSyncOperation copyWithCompanion(PendingSyncOperationsCompanion data) {
    return PendingSyncOperation(
      id: data.id.present ? data.id.value : this.id,
      resourceType: data.resourceType.present
          ? data.resourceType.value
          : this.resourceType,
      operation: data.operation.present ? data.operation.value : this.operation,
      payloadJson:
          data.payloadJson.present ? data.payloadJson.value : this.payloadJson,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      attempts: data.attempts.present ? data.attempts.value : this.attempts,
    );
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOperation(')
          ..write('id: $id, ')
          ..write('resourceType: $resourceType, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      id, resourceType, operation, payloadJson, createdAt, attempts);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is PendingSyncOperation &&
          other.id == this.id &&
          other.resourceType == this.resourceType &&
          other.operation == this.operation &&
          other.payloadJson == this.payloadJson &&
          other.createdAt == this.createdAt &&
          other.attempts == this.attempts);
}

class PendingSyncOperationsCompanion
    extends UpdateCompanion<PendingSyncOperation> {
  final Value<int> id;
  final Value<String> resourceType;
  final Value<String> operation;
  final Value<String> payloadJson;
  final Value<DateTime> createdAt;
  final Value<int> attempts;
  const PendingSyncOperationsCompanion({
    this.id = const Value.absent(),
    this.resourceType = const Value.absent(),
    this.operation = const Value.absent(),
    this.payloadJson = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.attempts = const Value.absent(),
  });
  PendingSyncOperationsCompanion.insert({
    this.id = const Value.absent(),
    required String resourceType,
    required String operation,
    required String payloadJson,
    required DateTime createdAt,
    this.attempts = const Value.absent(),
  })  : resourceType = Value(resourceType),
        operation = Value(operation),
        payloadJson = Value(payloadJson),
        createdAt = Value(createdAt);
  static Insertable<PendingSyncOperation> custom({
    Expression<int>? id,
    Expression<String>? resourceType,
    Expression<String>? operation,
    Expression<String>? payloadJson,
    Expression<DateTime>? createdAt,
    Expression<int>? attempts,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (resourceType != null) 'resource_type': resourceType,
      if (operation != null) 'operation': operation,
      if (payloadJson != null) 'payload_json': payloadJson,
      if (createdAt != null) 'created_at': createdAt,
      if (attempts != null) 'attempts': attempts,
    });
  }

  PendingSyncOperationsCompanion copyWith(
      {Value<int>? id,
      Value<String>? resourceType,
      Value<String>? operation,
      Value<String>? payloadJson,
      Value<DateTime>? createdAt,
      Value<int>? attempts}) {
    return PendingSyncOperationsCompanion(
      id: id ?? this.id,
      resourceType: resourceType ?? this.resourceType,
      operation: operation ?? this.operation,
      payloadJson: payloadJson ?? this.payloadJson,
      createdAt: createdAt ?? this.createdAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (resourceType.present) {
      map['resource_type'] = Variable<String>(resourceType.value);
    }
    if (operation.present) {
      map['operation'] = Variable<String>(operation.value);
    }
    if (payloadJson.present) {
      map['payload_json'] = Variable<String>(payloadJson.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<DateTime>(createdAt.value);
    }
    if (attempts.present) {
      map['attempts'] = Variable<int>(attempts.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PendingSyncOperationsCompanion(')
          ..write('id: $id, ')
          ..write('resourceType: $resourceType, ')
          ..write('operation: $operation, ')
          ..write('payloadJson: $payloadJson, ')
          ..write('createdAt: $createdAt, ')
          ..write('attempts: $attempts')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $CachedSquadsTable cachedSquads = $CachedSquadsTable(this);
  late final $CachedFestivalsTable cachedFestivals =
      $CachedFestivalsTable(this);
  late final $CachedLocationsTable cachedLocations =
      $CachedLocationsTable(this);
  late final $CachedMeetingPointsTable cachedMeetingPoints =
      $CachedMeetingPointsTable(this);
  late final $PendingSyncOperationsTable pendingSyncOperations =
      $PendingSyncOperationsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
        cachedSquads,
        cachedFestivals,
        cachedLocations,
        cachedMeetingPoints,
        pendingSyncOperations
      ];
}

typedef $$CachedSquadsTableCreateCompanionBuilder = CachedSquadsCompanion
    Function({
  required String sessionUserId,
  required String id,
  required String name,
  required String code,
  required String ownerId,
  required String memberIdsJson,
  required String currentUserRole,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$CachedSquadsTableUpdateCompanionBuilder = CachedSquadsCompanion
    Function({
  Value<String> sessionUserId,
  Value<String> id,
  Value<String> name,
  Value<String> code,
  Value<String> ownerId,
  Value<String> memberIdsJson,
  Value<String> currentUserRole,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedSquadsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedSquadsTable> {
  $$CachedSquadsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionUserId => $composableBuilder(
      column: $table.sessionUserId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get currentUserRole => $composableBuilder(
      column: $table.currentUserRole,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedSquadsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedSquadsTable> {
  $$CachedSquadsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionUserId => $composableBuilder(
      column: $table.sessionUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get code => $composableBuilder(
      column: $table.code, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get ownerId => $composableBuilder(
      column: $table.ownerId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get currentUserRole => $composableBuilder(
      column: $table.currentUserRole,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedSquadsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedSquadsTable> {
  $$CachedSquadsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionUserId => $composableBuilder(
      column: $table.sessionUserId, builder: (column) => column);

  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get code =>
      $composableBuilder(column: $table.code, builder: (column) => column);

  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get memberIdsJson => $composableBuilder(
      column: $table.memberIdsJson, builder: (column) => column);

  GeneratedColumn<String> get currentUserRole => $composableBuilder(
      column: $table.currentUserRole, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedSquadsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedSquadsTable,
    CachedSquad,
    $$CachedSquadsTableFilterComposer,
    $$CachedSquadsTableOrderingComposer,
    $$CachedSquadsTableAnnotationComposer,
    $$CachedSquadsTableCreateCompanionBuilder,
    $$CachedSquadsTableUpdateCompanionBuilder,
    (
      CachedSquad,
      BaseReferences<_$AppDatabase, $CachedSquadsTable, CachedSquad>
    ),
    CachedSquad,
    PrefetchHooks Function()> {
  $$CachedSquadsTableTableManager(_$AppDatabase db, $CachedSquadsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedSquadsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedSquadsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedSquadsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionUserId = const Value.absent(),
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<String> code = const Value.absent(),
            Value<String> ownerId = const Value.absent(),
            Value<String> memberIdsJson = const Value.absent(),
            Value<String> currentUserRole = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSquadsCompanion(
            sessionUserId: sessionUserId,
            id: id,
            name: name,
            code: code,
            ownerId: ownerId,
            memberIdsJson: memberIdsJson,
            currentUserRole: currentUserRole,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionUserId,
            required String id,
            required String name,
            required String code,
            required String ownerId,
            required String memberIdsJson,
            required String currentUserRole,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedSquadsCompanion.insert(
            sessionUserId: sessionUserId,
            id: id,
            name: name,
            code: code,
            ownerId: ownerId,
            memberIdsJson: memberIdsJson,
            currentUserRole: currentUserRole,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedSquadsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedSquadsTable,
    CachedSquad,
    $$CachedSquadsTableFilterComposer,
    $$CachedSquadsTableOrderingComposer,
    $$CachedSquadsTableAnnotationComposer,
    $$CachedSquadsTableCreateCompanionBuilder,
    $$CachedSquadsTableUpdateCompanionBuilder,
    (
      CachedSquad,
      BaseReferences<_$AppDatabase, $CachedSquadsTable, CachedSquad>
    ),
    CachedSquad,
    PrefetchHooks Function()>;
typedef $$CachedFestivalsTableCreateCompanionBuilder = CachedFestivalsCompanion
    Function({
  required String id,
  required String name,
  required DateTime startsAt,
  required DateTime endsAt,
  required String boundaryGeoJson,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$CachedFestivalsTableUpdateCompanionBuilder = CachedFestivalsCompanion
    Function({
  Value<String> id,
  Value<String> name,
  Value<DateTime> startsAt,
  Value<DateTime> endsAt,
  Value<String> boundaryGeoJson,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedFestivalsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedFestivalsTable> {
  $$CachedFestivalsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get startsAt => $composableBuilder(
      column: $table.startsAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get boundaryGeoJson => $composableBuilder(
      column: $table.boundaryGeoJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedFestivalsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedFestivalsTable> {
  $$CachedFestivalsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get name => $composableBuilder(
      column: $table.name, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get startsAt => $composableBuilder(
      column: $table.startsAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get endsAt => $composableBuilder(
      column: $table.endsAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get boundaryGeoJson => $composableBuilder(
      column: $table.boundaryGeoJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedFestivalsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedFestivalsTable> {
  $$CachedFestivalsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<DateTime> get startsAt =>
      $composableBuilder(column: $table.startsAt, builder: (column) => column);

  GeneratedColumn<DateTime> get endsAt =>
      $composableBuilder(column: $table.endsAt, builder: (column) => column);

  GeneratedColumn<String> get boundaryGeoJson => $composableBuilder(
      column: $table.boundaryGeoJson, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedFestivalsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedFestivalsTable,
    CachedFestival,
    $$CachedFestivalsTableFilterComposer,
    $$CachedFestivalsTableOrderingComposer,
    $$CachedFestivalsTableAnnotationComposer,
    $$CachedFestivalsTableCreateCompanionBuilder,
    $$CachedFestivalsTableUpdateCompanionBuilder,
    (
      CachedFestival,
      BaseReferences<_$AppDatabase, $CachedFestivalsTable, CachedFestival>
    ),
    CachedFestival,
    PrefetchHooks Function()> {
  $$CachedFestivalsTableTableManager(
      _$AppDatabase db, $CachedFestivalsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedFestivalsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedFestivalsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedFestivalsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> name = const Value.absent(),
            Value<DateTime> startsAt = const Value.absent(),
            Value<DateTime> endsAt = const Value.absent(),
            Value<String> boundaryGeoJson = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedFestivalsCompanion(
            id: id,
            name: name,
            startsAt: startsAt,
            endsAt: endsAt,
            boundaryGeoJson: boundaryGeoJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String name,
            required DateTime startsAt,
            required DateTime endsAt,
            required String boundaryGeoJson,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedFestivalsCompanion.insert(
            id: id,
            name: name,
            startsAt: startsAt,
            endsAt: endsAt,
            boundaryGeoJson: boundaryGeoJson,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedFestivalsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedFestivalsTable,
    CachedFestival,
    $$CachedFestivalsTableFilterComposer,
    $$CachedFestivalsTableOrderingComposer,
    $$CachedFestivalsTableAnnotationComposer,
    $$CachedFestivalsTableCreateCompanionBuilder,
    $$CachedFestivalsTableUpdateCompanionBuilder,
    (
      CachedFestival,
      BaseReferences<_$AppDatabase, $CachedFestivalsTable, CachedFestival>
    ),
    CachedFestival,
    PrefetchHooks Function()>;
typedef $$CachedLocationsTableCreateCompanionBuilder = CachedLocationsCompanion
    Function({
  required String squadId,
  required String userId,
  required double latitude,
  required double longitude,
  Value<double?> accuracyMeters,
  required DateTime recordedAt,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$CachedLocationsTableUpdateCompanionBuilder = CachedLocationsCompanion
    Function({
  Value<String> squadId,
  Value<String> userId,
  Value<double> latitude,
  Value<double> longitude,
  Value<double?> accuracyMeters,
  Value<DateTime> recordedAt,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedLocationsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedLocationsTable> {
  $$CachedLocationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get squadId => $composableBuilder(
      column: $table.squadId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get accuracyMeters => $composableBuilder(
      column: $table.accuracyMeters,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedLocationsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedLocationsTable> {
  $$CachedLocationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get squadId => $composableBuilder(
      column: $table.squadId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get userId => $composableBuilder(
      column: $table.userId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get accuracyMeters => $composableBuilder(
      column: $table.accuracyMeters,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedLocationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedLocationsTable> {
  $$CachedLocationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get squadId =>
      $composableBuilder(column: $table.squadId, builder: (column) => column);

  GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<double> get accuracyMeters => $composableBuilder(
      column: $table.accuracyMeters, builder: (column) => column);

  GeneratedColumn<DateTime> get recordedAt => $composableBuilder(
      column: $table.recordedAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedLocationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedLocationsTable,
    CachedLocation,
    $$CachedLocationsTableFilterComposer,
    $$CachedLocationsTableOrderingComposer,
    $$CachedLocationsTableAnnotationComposer,
    $$CachedLocationsTableCreateCompanionBuilder,
    $$CachedLocationsTableUpdateCompanionBuilder,
    (
      CachedLocation,
      BaseReferences<_$AppDatabase, $CachedLocationsTable, CachedLocation>
    ),
    CachedLocation,
    PrefetchHooks Function()> {
  $$CachedLocationsTableTableManager(
      _$AppDatabase db, $CachedLocationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedLocationsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedLocationsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedLocationsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> squadId = const Value.absent(),
            Value<String> userId = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<double?> accuracyMeters = const Value.absent(),
            Value<DateTime> recordedAt = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedLocationsCompanion(
            squadId: squadId,
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            accuracyMeters: accuracyMeters,
            recordedAt: recordedAt,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String squadId,
            required String userId,
            required double latitude,
            required double longitude,
            Value<double?> accuracyMeters = const Value.absent(),
            required DateTime recordedAt,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedLocationsCompanion.insert(
            squadId: squadId,
            userId: userId,
            latitude: latitude,
            longitude: longitude,
            accuracyMeters: accuracyMeters,
            recordedAt: recordedAt,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedLocationsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedLocationsTable,
    CachedLocation,
    $$CachedLocationsTableFilterComposer,
    $$CachedLocationsTableOrderingComposer,
    $$CachedLocationsTableAnnotationComposer,
    $$CachedLocationsTableCreateCompanionBuilder,
    $$CachedLocationsTableUpdateCompanionBuilder,
    (
      CachedLocation,
      BaseReferences<_$AppDatabase, $CachedLocationsTable, CachedLocation>
    ),
    CachedLocation,
    PrefetchHooks Function()>;
typedef $$CachedMeetingPointsTableCreateCompanionBuilder
    = CachedMeetingPointsCompanion Function({
  required String id,
  required String squadId,
  required String title,
  required double latitude,
  required double longitude,
  required String createdByUserId,
  required DateTime createdAt,
  required DateTime cachedAt,
  Value<int> rowid,
});
typedef $$CachedMeetingPointsTableUpdateCompanionBuilder
    = CachedMeetingPointsCompanion Function({
  Value<String> id,
  Value<String> squadId,
  Value<String> title,
  Value<double> latitude,
  Value<double> longitude,
  Value<String> createdByUserId,
  Value<DateTime> createdAt,
  Value<DateTime> cachedAt,
  Value<int> rowid,
});

class $$CachedMeetingPointsTableFilterComposer
    extends Composer<_$AppDatabase, $CachedMeetingPointsTable> {
  $$CachedMeetingPointsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get squadId => $composableBuilder(
      column: $table.squadId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnFilters(column));
}

class $$CachedMeetingPointsTableOrderingComposer
    extends Composer<_$AppDatabase, $CachedMeetingPointsTable> {
  $$CachedMeetingPointsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get squadId => $composableBuilder(
      column: $table.squadId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get title => $composableBuilder(
      column: $table.title, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get latitude => $composableBuilder(
      column: $table.latitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get longitude => $composableBuilder(
      column: $table.longitude, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get cachedAt => $composableBuilder(
      column: $table.cachedAt, builder: (column) => ColumnOrderings(column));
}

class $$CachedMeetingPointsTableAnnotationComposer
    extends Composer<_$AppDatabase, $CachedMeetingPointsTable> {
  $$CachedMeetingPointsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get squadId =>
      $composableBuilder(column: $table.squadId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<double> get latitude =>
      $composableBuilder(column: $table.latitude, builder: (column) => column);

  GeneratedColumn<double> get longitude =>
      $composableBuilder(column: $table.longitude, builder: (column) => column);

  GeneratedColumn<String> get createdByUserId => $composableBuilder(
      column: $table.createdByUserId, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<DateTime> get cachedAt =>
      $composableBuilder(column: $table.cachedAt, builder: (column) => column);
}

class $$CachedMeetingPointsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $CachedMeetingPointsTable,
    CachedMeetingPoint,
    $$CachedMeetingPointsTableFilterComposer,
    $$CachedMeetingPointsTableOrderingComposer,
    $$CachedMeetingPointsTableAnnotationComposer,
    $$CachedMeetingPointsTableCreateCompanionBuilder,
    $$CachedMeetingPointsTableUpdateCompanionBuilder,
    (
      CachedMeetingPoint,
      BaseReferences<_$AppDatabase, $CachedMeetingPointsTable,
          CachedMeetingPoint>
    ),
    CachedMeetingPoint,
    PrefetchHooks Function()> {
  $$CachedMeetingPointsTableTableManager(
      _$AppDatabase db, $CachedMeetingPointsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CachedMeetingPointsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CachedMeetingPointsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CachedMeetingPointsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> id = const Value.absent(),
            Value<String> squadId = const Value.absent(),
            Value<String> title = const Value.absent(),
            Value<double> latitude = const Value.absent(),
            Value<double> longitude = const Value.absent(),
            Value<String> createdByUserId = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<DateTime> cachedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedMeetingPointsCompanion(
            id: id,
            squadId: squadId,
            title: title,
            latitude: latitude,
            longitude: longitude,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String id,
            required String squadId,
            required String title,
            required double latitude,
            required double longitude,
            required String createdByUserId,
            required DateTime createdAt,
            required DateTime cachedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              CachedMeetingPointsCompanion.insert(
            id: id,
            squadId: squadId,
            title: title,
            latitude: latitude,
            longitude: longitude,
            createdByUserId: createdByUserId,
            createdAt: createdAt,
            cachedAt: cachedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$CachedMeetingPointsTableProcessedTableManager = ProcessedTableManager<
    _$AppDatabase,
    $CachedMeetingPointsTable,
    CachedMeetingPoint,
    $$CachedMeetingPointsTableFilterComposer,
    $$CachedMeetingPointsTableOrderingComposer,
    $$CachedMeetingPointsTableAnnotationComposer,
    $$CachedMeetingPointsTableCreateCompanionBuilder,
    $$CachedMeetingPointsTableUpdateCompanionBuilder,
    (
      CachedMeetingPoint,
      BaseReferences<_$AppDatabase, $CachedMeetingPointsTable,
          CachedMeetingPoint>
    ),
    CachedMeetingPoint,
    PrefetchHooks Function()>;
typedef $$PendingSyncOperationsTableCreateCompanionBuilder
    = PendingSyncOperationsCompanion Function({
  Value<int> id,
  required String resourceType,
  required String operation,
  required String payloadJson,
  required DateTime createdAt,
  Value<int> attempts,
});
typedef $$PendingSyncOperationsTableUpdateCompanionBuilder
    = PendingSyncOperationsCompanion Function({
  Value<int> id,
  Value<String> resourceType,
  Value<String> operation,
  Value<String> payloadJson,
  Value<DateTime> createdAt,
  Value<int> attempts,
});

class $$PendingSyncOperationsTableFilterComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get resourceType => $composableBuilder(
      column: $table.resourceType, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnFilters(column));

  ColumnFilters<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnFilters(column));
}

class $$PendingSyncOperationsTableOrderingComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
      column: $table.id, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get resourceType => $composableBuilder(
      column: $table.resourceType,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get operation => $composableBuilder(
      column: $table.operation, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<DateTime> get createdAt => $composableBuilder(
      column: $table.createdAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get attempts => $composableBuilder(
      column: $table.attempts, builder: (column) => ColumnOrderings(column));
}

class $$PendingSyncOperationsTableAnnotationComposer
    extends Composer<_$AppDatabase, $PendingSyncOperationsTable> {
  $$PendingSyncOperationsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get resourceType => $composableBuilder(
      column: $table.resourceType, builder: (column) => column);

  GeneratedColumn<String> get operation =>
      $composableBuilder(column: $table.operation, builder: (column) => column);

  GeneratedColumn<String> get payloadJson => $composableBuilder(
      column: $table.payloadJson, builder: (column) => column);

  GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get attempts =>
      $composableBuilder(column: $table.attempts, builder: (column) => column);
}

class $$PendingSyncOperationsTableTableManager extends RootTableManager<
    _$AppDatabase,
    $PendingSyncOperationsTable,
    PendingSyncOperation,
    $$PendingSyncOperationsTableFilterComposer,
    $$PendingSyncOperationsTableOrderingComposer,
    $$PendingSyncOperationsTableAnnotationComposer,
    $$PendingSyncOperationsTableCreateCompanionBuilder,
    $$PendingSyncOperationsTableUpdateCompanionBuilder,
    (
      PendingSyncOperation,
      BaseReferences<_$AppDatabase, $PendingSyncOperationsTable,
          PendingSyncOperation>
    ),
    PendingSyncOperation,
    PrefetchHooks Function()> {
  $$PendingSyncOperationsTableTableManager(
      _$AppDatabase db, $PendingSyncOperationsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$PendingSyncOperationsTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$PendingSyncOperationsTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$PendingSyncOperationsTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<int> id = const Value.absent(),
            Value<String> resourceType = const Value.absent(),
            Value<String> operation = const Value.absent(),
            Value<String> payloadJson = const Value.absent(),
            Value<DateTime> createdAt = const Value.absent(),
            Value<int> attempts = const Value.absent(),
          }) =>
              PendingSyncOperationsCompanion(
            id: id,
            resourceType: resourceType,
            operation: operation,
            payloadJson: payloadJson,
            createdAt: createdAt,
            attempts: attempts,
          ),
          createCompanionCallback: ({
            Value<int> id = const Value.absent(),
            required String resourceType,
            required String operation,
            required String payloadJson,
            required DateTime createdAt,
            Value<int> attempts = const Value.absent(),
          }) =>
              PendingSyncOperationsCompanion.insert(
            id: id,
            resourceType: resourceType,
            operation: operation,
            payloadJson: payloadJson,
            createdAt: createdAt,
            attempts: attempts,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$PendingSyncOperationsTableProcessedTableManager
    = ProcessedTableManager<
        _$AppDatabase,
        $PendingSyncOperationsTable,
        PendingSyncOperation,
        $$PendingSyncOperationsTableFilterComposer,
        $$PendingSyncOperationsTableOrderingComposer,
        $$PendingSyncOperationsTableAnnotationComposer,
        $$PendingSyncOperationsTableCreateCompanionBuilder,
        $$PendingSyncOperationsTableUpdateCompanionBuilder,
        (
          PendingSyncOperation,
          BaseReferences<_$AppDatabase, $PendingSyncOperationsTable,
              PendingSyncOperation>
        ),
        PendingSyncOperation,
        PrefetchHooks Function()>;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$CachedSquadsTableTableManager get cachedSquads =>
      $$CachedSquadsTableTableManager(_db, _db.cachedSquads);
  $$CachedFestivalsTableTableManager get cachedFestivals =>
      $$CachedFestivalsTableTableManager(_db, _db.cachedFestivals);
  $$CachedLocationsTableTableManager get cachedLocations =>
      $$CachedLocationsTableTableManager(_db, _db.cachedLocations);
  $$CachedMeetingPointsTableTableManager get cachedMeetingPoints =>
      $$CachedMeetingPointsTableTableManager(_db, _db.cachedMeetingPoints);
  $$PendingSyncOperationsTableTableManager get pendingSyncOperations =>
      $$PendingSyncOperationsTableTableManager(_db, _db.pendingSyncOperations);
}
