// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $BiblePlansTable extends BiblePlans
    with TableInfo<$BiblePlansTable, BiblePlanRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BiblePlansTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _legacyIdMeta = const VerificationMeta(
    'legacyId',
  );
  @override
  late final GeneratedColumn<String> legacyId = GeneratedColumn<String>(
    'legacy_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _defaultTranslationIdMeta =
      const VerificationMeta('defaultTranslationId');
  @override
  late final GeneratedColumn<String> defaultTranslationId =
      GeneratedColumn<String>(
        'default_translation_id',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _createdAtUtcMicrosMeta =
      const VerificationMeta('createdAtUtcMicros');
  @override
  late final GeneratedColumn<int> createdAtUtcMicros = GeneratedColumn<int>(
    'created_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startDateMeta = const VerificationMeta(
    'startDate',
  );
  @override
  late final GeneratedColumn<String> startDate = GeneratedColumn<String>(
    'start_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _endDateMeta = const VerificationMeta(
    'endDate',
  );
  @override
  late final GeneratedColumn<String> endDate = GeneratedColumn<String>(
    'end_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _readingWeekdaysMaskMeta =
      const VerificationMeta('readingWeekdaysMask');
  @override
  late final GeneratedColumn<int> readingWeekdaysMask = GeneratedColumn<int>(
    'reading_weekdays_mask',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _reminderMinutesLocalMeta =
      const VerificationMeta('reminderMinutesLocal');
  @override
  late final GeneratedColumn<int> reminderMinutesLocal = GeneratedColumn<int>(
    'reminder_minutes_local',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _templateIdMeta = const VerificationMeta(
    'templateId',
  );
  @override
  late final GeneratedColumn<String> templateId = GeneratedColumn<String>(
    'template_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    legacyId,
    position,
    title,
    defaultTranslationId,
    createdAtUtcMicros,
    startDate,
    endDate,
    readingWeekdaysMask,
    reminderMinutesLocal,
    templateId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_plans';
  @override
  VerificationContext validateIntegrity(
    Insertable<BiblePlanRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('legacy_id')) {
      context.handle(
        _legacyIdMeta,
        legacyId.isAcceptableOrUnknown(data['legacy_id']!, _legacyIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('default_translation_id')) {
      context.handle(
        _defaultTranslationIdMeta,
        defaultTranslationId.isAcceptableOrUnknown(
          data['default_translation_id']!,
          _defaultTranslationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_defaultTranslationIdMeta);
    }
    if (data.containsKey('created_at_utc_micros')) {
      context.handle(
        _createdAtUtcMicrosMeta,
        createdAtUtcMicros.isAcceptableOrUnknown(
          data['created_at_utc_micros']!,
          _createdAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMicrosMeta);
    }
    if (data.containsKey('start_date')) {
      context.handle(
        _startDateMeta,
        startDate.isAcceptableOrUnknown(data['start_date']!, _startDateMeta),
      );
    } else if (isInserting) {
      context.missing(_startDateMeta);
    }
    if (data.containsKey('end_date')) {
      context.handle(
        _endDateMeta,
        endDate.isAcceptableOrUnknown(data['end_date']!, _endDateMeta),
      );
    } else if (isInserting) {
      context.missing(_endDateMeta);
    }
    if (data.containsKey('reading_weekdays_mask')) {
      context.handle(
        _readingWeekdaysMaskMeta,
        readingWeekdaysMask.isAcceptableOrUnknown(
          data['reading_weekdays_mask']!,
          _readingWeekdaysMaskMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_readingWeekdaysMaskMeta);
    }
    if (data.containsKey('reminder_minutes_local')) {
      context.handle(
        _reminderMinutesLocalMeta,
        reminderMinutesLocal.isAcceptableOrUnknown(
          data['reminder_minutes_local']!,
          _reminderMinutesLocalMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_reminderMinutesLocalMeta);
    }
    if (data.containsKey('template_id')) {
      context.handle(
        _templateIdMeta,
        templateId.isAcceptableOrUnknown(data['template_id']!, _templateIdMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  BiblePlanRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BiblePlanRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      legacyId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}legacy_id'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      defaultTranslationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}default_translation_id'],
      )!,
      createdAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_micros'],
      )!,
      startDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}start_date'],
      )!,
      endDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}end_date'],
      )!,
      readingWeekdaysMask: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reading_weekdays_mask'],
      )!,
      reminderMinutesLocal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes_local'],
      )!,
      templateId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}template_id'],
      ),
    );
  }

  @override
  $BiblePlansTable createAlias(String alias) {
    return $BiblePlansTable(attachedDatabase, alias);
  }
}

class BiblePlanRecord extends DataClass implements Insertable<BiblePlanRecord> {
  final String id;
  final String? legacyId;
  final int position;
  final String title;
  final String defaultTranslationId;
  final int createdAtUtcMicros;
  final String startDate;
  final String endDate;
  final int readingWeekdaysMask;
  final int reminderMinutesLocal;
  final String? templateId;
  const BiblePlanRecord({
    required this.id,
    this.legacyId,
    required this.position,
    required this.title,
    required this.defaultTranslationId,
    required this.createdAtUtcMicros,
    required this.startDate,
    required this.endDate,
    required this.readingWeekdaysMask,
    required this.reminderMinutesLocal,
    this.templateId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || legacyId != null) {
      map['legacy_id'] = Variable<String>(legacyId);
    }
    map['position'] = Variable<int>(position);
    map['title'] = Variable<String>(title);
    map['default_translation_id'] = Variable<String>(defaultTranslationId);
    map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros);
    map['start_date'] = Variable<String>(startDate);
    map['end_date'] = Variable<String>(endDate);
    map['reading_weekdays_mask'] = Variable<int>(readingWeekdaysMask);
    map['reminder_minutes_local'] = Variable<int>(reminderMinutesLocal);
    if (!nullToAbsent || templateId != null) {
      map['template_id'] = Variable<String>(templateId);
    }
    return map;
  }

  BiblePlansCompanion toCompanion(bool nullToAbsent) {
    return BiblePlansCompanion(
      id: Value(id),
      legacyId: legacyId == null && nullToAbsent
          ? const Value.absent()
          : Value(legacyId),
      position: Value(position),
      title: Value(title),
      defaultTranslationId: Value(defaultTranslationId),
      createdAtUtcMicros: Value(createdAtUtcMicros),
      startDate: Value(startDate),
      endDate: Value(endDate),
      readingWeekdaysMask: Value(readingWeekdaysMask),
      reminderMinutesLocal: Value(reminderMinutesLocal),
      templateId: templateId == null && nullToAbsent
          ? const Value.absent()
          : Value(templateId),
    );
  }

  factory BiblePlanRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BiblePlanRecord(
      id: serializer.fromJson<String>(json['id']),
      legacyId: serializer.fromJson<String?>(json['legacyId']),
      position: serializer.fromJson<int>(json['position']),
      title: serializer.fromJson<String>(json['title']),
      defaultTranslationId: serializer.fromJson<String>(
        json['defaultTranslationId'],
      ),
      createdAtUtcMicros: serializer.fromJson<int>(json['createdAtUtcMicros']),
      startDate: serializer.fromJson<String>(json['startDate']),
      endDate: serializer.fromJson<String>(json['endDate']),
      readingWeekdaysMask: serializer.fromJson<int>(
        json['readingWeekdaysMask'],
      ),
      reminderMinutesLocal: serializer.fromJson<int>(
        json['reminderMinutesLocal'],
      ),
      templateId: serializer.fromJson<String?>(json['templateId']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'legacyId': serializer.toJson<String?>(legacyId),
      'position': serializer.toJson<int>(position),
      'title': serializer.toJson<String>(title),
      'defaultTranslationId': serializer.toJson<String>(defaultTranslationId),
      'createdAtUtcMicros': serializer.toJson<int>(createdAtUtcMicros),
      'startDate': serializer.toJson<String>(startDate),
      'endDate': serializer.toJson<String>(endDate),
      'readingWeekdaysMask': serializer.toJson<int>(readingWeekdaysMask),
      'reminderMinutesLocal': serializer.toJson<int>(reminderMinutesLocal),
      'templateId': serializer.toJson<String?>(templateId),
    };
  }

  BiblePlanRecord copyWith({
    String? id,
    Value<String?> legacyId = const Value.absent(),
    int? position,
    String? title,
    String? defaultTranslationId,
    int? createdAtUtcMicros,
    String? startDate,
    String? endDate,
    int? readingWeekdaysMask,
    int? reminderMinutesLocal,
    Value<String?> templateId = const Value.absent(),
  }) => BiblePlanRecord(
    id: id ?? this.id,
    legacyId: legacyId.present ? legacyId.value : this.legacyId,
    position: position ?? this.position,
    title: title ?? this.title,
    defaultTranslationId: defaultTranslationId ?? this.defaultTranslationId,
    createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    readingWeekdaysMask: readingWeekdaysMask ?? this.readingWeekdaysMask,
    reminderMinutesLocal: reminderMinutesLocal ?? this.reminderMinutesLocal,
    templateId: templateId.present ? templateId.value : this.templateId,
  );
  BiblePlanRecord copyWithCompanion(BiblePlansCompanion data) {
    return BiblePlanRecord(
      id: data.id.present ? data.id.value : this.id,
      legacyId: data.legacyId.present ? data.legacyId.value : this.legacyId,
      position: data.position.present ? data.position.value : this.position,
      title: data.title.present ? data.title.value : this.title,
      defaultTranslationId: data.defaultTranslationId.present
          ? data.defaultTranslationId.value
          : this.defaultTranslationId,
      createdAtUtcMicros: data.createdAtUtcMicros.present
          ? data.createdAtUtcMicros.value
          : this.createdAtUtcMicros,
      startDate: data.startDate.present ? data.startDate.value : this.startDate,
      endDate: data.endDate.present ? data.endDate.value : this.endDate,
      readingWeekdaysMask: data.readingWeekdaysMask.present
          ? data.readingWeekdaysMask.value
          : this.readingWeekdaysMask,
      reminderMinutesLocal: data.reminderMinutesLocal.present
          ? data.reminderMinutesLocal.value
          : this.reminderMinutesLocal,
      templateId: data.templateId.present
          ? data.templateId.value
          : this.templateId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanRecord(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('defaultTranslationId: $defaultTranslationId, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('readingWeekdaysMask: $readingWeekdaysMask, ')
          ..write('reminderMinutesLocal: $reminderMinutesLocal, ')
          ..write('templateId: $templateId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    legacyId,
    position,
    title,
    defaultTranslationId,
    createdAtUtcMicros,
    startDate,
    endDate,
    readingWeekdaysMask,
    reminderMinutesLocal,
    templateId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiblePlanRecord &&
          other.id == this.id &&
          other.legacyId == this.legacyId &&
          other.position == this.position &&
          other.title == this.title &&
          other.defaultTranslationId == this.defaultTranslationId &&
          other.createdAtUtcMicros == this.createdAtUtcMicros &&
          other.startDate == this.startDate &&
          other.endDate == this.endDate &&
          other.readingWeekdaysMask == this.readingWeekdaysMask &&
          other.reminderMinutesLocal == this.reminderMinutesLocal &&
          other.templateId == this.templateId);
}

class BiblePlansCompanion extends UpdateCompanion<BiblePlanRecord> {
  final Value<String> id;
  final Value<String?> legacyId;
  final Value<int> position;
  final Value<String> title;
  final Value<String> defaultTranslationId;
  final Value<int> createdAtUtcMicros;
  final Value<String> startDate;
  final Value<String> endDate;
  final Value<int> readingWeekdaysMask;
  final Value<int> reminderMinutesLocal;
  final Value<String?> templateId;
  final Value<int> rowid;
  const BiblePlansCompanion({
    this.id = const Value.absent(),
    this.legacyId = const Value.absent(),
    this.position = const Value.absent(),
    this.title = const Value.absent(),
    this.defaultTranslationId = const Value.absent(),
    this.createdAtUtcMicros = const Value.absent(),
    this.startDate = const Value.absent(),
    this.endDate = const Value.absent(),
    this.readingWeekdaysMask = const Value.absent(),
    this.reminderMinutesLocal = const Value.absent(),
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BiblePlansCompanion.insert({
    required String id,
    this.legacyId = const Value.absent(),
    required int position,
    required String title,
    required String defaultTranslationId,
    required int createdAtUtcMicros,
    required String startDate,
    required String endDate,
    required int readingWeekdaysMask,
    required int reminderMinutesLocal,
    this.templateId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       position = Value(position),
       title = Value(title),
       defaultTranslationId = Value(defaultTranslationId),
       createdAtUtcMicros = Value(createdAtUtcMicros),
       startDate = Value(startDate),
       endDate = Value(endDate),
       readingWeekdaysMask = Value(readingWeekdaysMask),
       reminderMinutesLocal = Value(reminderMinutesLocal);
  static Insertable<BiblePlanRecord> custom({
    Expression<String>? id,
    Expression<String>? legacyId,
    Expression<int>? position,
    Expression<String>? title,
    Expression<String>? defaultTranslationId,
    Expression<int>? createdAtUtcMicros,
    Expression<String>? startDate,
    Expression<String>? endDate,
    Expression<int>? readingWeekdaysMask,
    Expression<int>? reminderMinutesLocal,
    Expression<String>? templateId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (legacyId != null) 'legacy_id': legacyId,
      if (position != null) 'position': position,
      if (title != null) 'title': title,
      if (defaultTranslationId != null)
        'default_translation_id': defaultTranslationId,
      if (createdAtUtcMicros != null)
        'created_at_utc_micros': createdAtUtcMicros,
      if (startDate != null) 'start_date': startDate,
      if (endDate != null) 'end_date': endDate,
      if (readingWeekdaysMask != null)
        'reading_weekdays_mask': readingWeekdaysMask,
      if (reminderMinutesLocal != null)
        'reminder_minutes_local': reminderMinutesLocal,
      if (templateId != null) 'template_id': templateId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BiblePlansCompanion copyWith({
    Value<String>? id,
    Value<String?>? legacyId,
    Value<int>? position,
    Value<String>? title,
    Value<String>? defaultTranslationId,
    Value<int>? createdAtUtcMicros,
    Value<String>? startDate,
    Value<String>? endDate,
    Value<int>? readingWeekdaysMask,
    Value<int>? reminderMinutesLocal,
    Value<String?>? templateId,
    Value<int>? rowid,
  }) {
    return BiblePlansCompanion(
      id: id ?? this.id,
      legacyId: legacyId ?? this.legacyId,
      position: position ?? this.position,
      title: title ?? this.title,
      defaultTranslationId: defaultTranslationId ?? this.defaultTranslationId,
      createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      readingWeekdaysMask: readingWeekdaysMask ?? this.readingWeekdaysMask,
      reminderMinutesLocal: reminderMinutesLocal ?? this.reminderMinutesLocal,
      templateId: templateId ?? this.templateId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (legacyId.present) {
      map['legacy_id'] = Variable<String>(legacyId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (defaultTranslationId.present) {
      map['default_translation_id'] = Variable<String>(
        defaultTranslationId.value,
      );
    }
    if (createdAtUtcMicros.present) {
      map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros.value);
    }
    if (startDate.present) {
      map['start_date'] = Variable<String>(startDate.value);
    }
    if (endDate.present) {
      map['end_date'] = Variable<String>(endDate.value);
    }
    if (readingWeekdaysMask.present) {
      map['reading_weekdays_mask'] = Variable<int>(readingWeekdaysMask.value);
    }
    if (reminderMinutesLocal.present) {
      map['reminder_minutes_local'] = Variable<int>(reminderMinutesLocal.value);
    }
    if (templateId.present) {
      map['template_id'] = Variable<String>(templateId.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlansCompanion(')
          ..write('id: $id, ')
          ..write('legacyId: $legacyId, ')
          ..write('position: $position, ')
          ..write('title: $title, ')
          ..write('defaultTranslationId: $defaultTranslationId, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('startDate: $startDate, ')
          ..write('endDate: $endDate, ')
          ..write('readingWeekdaysMask: $readingWeekdaysMask, ')
          ..write('reminderMinutesLocal: $reminderMinutesLocal, ')
          ..write('templateId: $templateId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BiblePlanSourceItemsTable extends BiblePlanSourceItems
    with TableInfo<$BiblePlanSourceItemsTable, BiblePlanSourceItemRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BiblePlanSourceItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bible_plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startChapterMeta = const VerificationMeta(
    'startChapter',
  );
  @override
  late final GeneratedColumn<int> startChapter = GeneratedColumn<int>(
    'start_chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endChapterMeta = const VerificationMeta(
    'endChapter',
  );
  @override
  late final GeneratedColumn<int> endChapter = GeneratedColumn<int>(
    'end_chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    position,
    book,
    startChapter,
    startVerse,
    endChapter,
    endVerse,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_plan_source_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BiblePlanSourceItemRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('start_chapter')) {
      context.handle(
        _startChapterMeta,
        startChapter.isAcceptableOrUnknown(
          data['start_chapter']!,
          _startChapterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startChapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_chapter')) {
      context.handle(
        _endChapterMeta,
        endChapter.isAcceptableOrUnknown(data['end_chapter']!, _endChapterMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {planId, position},
  ];
  @override
  BiblePlanSourceItemRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BiblePlanSourceItemRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      startChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_chapter'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
    );
  }

  @override
  $BiblePlanSourceItemsTable createAlias(String alias) {
    return $BiblePlanSourceItemsTable(attachedDatabase, alias);
  }
}

class BiblePlanSourceItemRecord extends DataClass
    implements Insertable<BiblePlanSourceItemRecord> {
  final String id;
  final String planId;
  final int position;
  final String book;
  final int startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;
  const BiblePlanSourceItemRecord({
    required this.id,
    required this.planId,
    required this.position,
    required this.book,
    required this.startChapter,
    this.startVerse,
    this.endChapter,
    this.endVerse,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['position'] = Variable<int>(position);
    map['book'] = Variable<String>(book);
    map['start_chapter'] = Variable<int>(startChapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endChapter != null) {
      map['end_chapter'] = Variable<int>(endChapter);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    return map;
  }

  BiblePlanSourceItemsCompanion toCompanion(bool nullToAbsent) {
    return BiblePlanSourceItemsCompanion(
      id: Value(id),
      planId: Value(planId),
      position: Value(position),
      book: Value(book),
      startChapter: Value(startChapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endChapter: endChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(endChapter),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
    );
  }

  factory BiblePlanSourceItemRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BiblePlanSourceItemRecord(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      position: serializer.fromJson<int>(json['position']),
      book: serializer.fromJson<String>(json['book']),
      startChapter: serializer.fromJson<int>(json['startChapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endChapter: serializer.fromJson<int?>(json['endChapter']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'position': serializer.toJson<int>(position),
      'book': serializer.toJson<String>(book),
      'startChapter': serializer.toJson<int>(startChapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endChapter': serializer.toJson<int?>(endChapter),
      'endVerse': serializer.toJson<int?>(endVerse),
    };
  }

  BiblePlanSourceItemRecord copyWith({
    String? id,
    String? planId,
    int? position,
    String? book,
    int? startChapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endChapter = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
  }) => BiblePlanSourceItemRecord(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    position: position ?? this.position,
    book: book ?? this.book,
    startChapter: startChapter ?? this.startChapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endChapter: endChapter.present ? endChapter.value : this.endChapter,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
  );
  BiblePlanSourceItemRecord copyWithCompanion(
    BiblePlanSourceItemsCompanion data,
  ) {
    return BiblePlanSourceItemRecord(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      position: data.position.present ? data.position.value : this.position,
      book: data.book.present ? data.book.value : this.book,
      startChapter: data.startChapter.present
          ? data.startChapter.value
          : this.startChapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endChapter: data.endChapter.present
          ? data.endChapter.value
          : this.endChapter,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanSourceItemRecord(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('position: $position, ')
          ..write('book: $book, ')
          ..write('startChapter: $startChapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endChapter: $endChapter, ')
          ..write('endVerse: $endVerse')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    position,
    book,
    startChapter,
    startVerse,
    endChapter,
    endVerse,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiblePlanSourceItemRecord &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.position == this.position &&
          other.book == this.book &&
          other.startChapter == this.startChapter &&
          other.startVerse == this.startVerse &&
          other.endChapter == this.endChapter &&
          other.endVerse == this.endVerse);
}

class BiblePlanSourceItemsCompanion
    extends UpdateCompanion<BiblePlanSourceItemRecord> {
  final Value<String> id;
  final Value<String> planId;
  final Value<int> position;
  final Value<String> book;
  final Value<int> startChapter;
  final Value<int?> startVerse;
  final Value<int?> endChapter;
  final Value<int?> endVerse;
  final Value<int> rowid;
  const BiblePlanSourceItemsCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.position = const Value.absent(),
    this.book = const Value.absent(),
    this.startChapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endChapter = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BiblePlanSourceItemsCompanion.insert({
    required String id,
    required String planId,
    required int position,
    required String book,
    required int startChapter,
    this.startVerse = const Value.absent(),
    this.endChapter = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       position = Value(position),
       book = Value(book),
       startChapter = Value(startChapter);
  static Insertable<BiblePlanSourceItemRecord> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? position,
    Expression<String>? book,
    Expression<int>? startChapter,
    Expression<int>? startVerse,
    Expression<int>? endChapter,
    Expression<int>? endVerse,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (position != null) 'position': position,
      if (book != null) 'book': book,
      if (startChapter != null) 'start_chapter': startChapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endChapter != null) 'end_chapter': endChapter,
      if (endVerse != null) 'end_verse': endVerse,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BiblePlanSourceItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<int>? position,
    Value<String>? book,
    Value<int>? startChapter,
    Value<int?>? startVerse,
    Value<int?>? endChapter,
    Value<int?>? endVerse,
    Value<int>? rowid,
  }) {
    return BiblePlanSourceItemsCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      position: position ?? this.position,
      book: book ?? this.book,
      startChapter: startChapter ?? this.startChapter,
      startVerse: startVerse ?? this.startVerse,
      endChapter: endChapter ?? this.endChapter,
      endVerse: endVerse ?? this.endVerse,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (startChapter.present) {
      map['start_chapter'] = Variable<int>(startChapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endChapter.present) {
      map['end_chapter'] = Variable<int>(endChapter.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanSourceItemsCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('position: $position, ')
          ..write('book: $book, ')
          ..write('startChapter: $startChapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endChapter: $endChapter, ')
          ..write('endVerse: $endVerse, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BiblePlanScheduleEntriesTable extends BiblePlanScheduleEntries
    with
        TableInfo<
          $BiblePlanScheduleEntriesTable,
          BiblePlanScheduleEntryRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BiblePlanScheduleEntriesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
    'plan_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bible_plans (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduledDateMeta = const VerificationMeta(
    'scheduledDate',
  );
  @override
  late final GeneratedColumn<String> scheduledDate = GeneratedColumn<String>(
    'scheduled_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _completedAtUtcMicrosMeta =
      const VerificationMeta('completedAtUtcMicros');
  @override
  late final GeneratedColumn<int> completedAtUtcMicros = GeneratedColumn<int>(
    'completed_at_utc_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _translationOverrideIdMeta =
      const VerificationMeta('translationOverrideId');
  @override
  late final GeneratedColumn<String> translationOverrideId =
      GeneratedColumn<String>(
        'translation_override_id',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    planId,
    position,
    scheduledDate,
    isCompleted,
    completedAtUtcMicros,
    translationOverrideId,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_plan_schedule_entries';
  @override
  VerificationContext validateIntegrity(
    Insertable<BiblePlanScheduleEntryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(
        _planIdMeta,
        planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta),
      );
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('scheduled_date')) {
      context.handle(
        _scheduledDateMeta,
        scheduledDate.isAcceptableOrUnknown(
          data['scheduled_date']!,
          _scheduledDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduledDateMeta);
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCompletedMeta);
    }
    if (data.containsKey('completed_at_utc_micros')) {
      context.handle(
        _completedAtUtcMicrosMeta,
        completedAtUtcMicros.isAcceptableOrUnknown(
          data['completed_at_utc_micros']!,
          _completedAtUtcMicrosMeta,
        ),
      );
    }
    if (data.containsKey('translation_override_id')) {
      context.handle(
        _translationOverrideIdMeta,
        translationOverrideId.isAcceptableOrUnknown(
          data['translation_override_id']!,
          _translationOverrideIdMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {planId, position},
  ];
  @override
  BiblePlanScheduleEntryRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BiblePlanScheduleEntryRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      planId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}plan_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      scheduledDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}scheduled_date'],
      )!,
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_utc_micros'],
      ),
      translationOverrideId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_override_id'],
      ),
    );
  }

  @override
  $BiblePlanScheduleEntriesTable createAlias(String alias) {
    return $BiblePlanScheduleEntriesTable(attachedDatabase, alias);
  }
}

class BiblePlanScheduleEntryRecord extends DataClass
    implements Insertable<BiblePlanScheduleEntryRecord> {
  final String id;
  final String planId;
  final int position;
  final String scheduledDate;
  final bool isCompleted;
  final int? completedAtUtcMicros;
  final String? translationOverrideId;
  const BiblePlanScheduleEntryRecord({
    required this.id,
    required this.planId,
    required this.position,
    required this.scheduledDate,
    required this.isCompleted,
    this.completedAtUtcMicros,
    this.translationOverrideId,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['plan_id'] = Variable<String>(planId);
    map['position'] = Variable<int>(position);
    map['scheduled_date'] = Variable<String>(scheduledDate);
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAtUtcMicros != null) {
      map['completed_at_utc_micros'] = Variable<int>(completedAtUtcMicros);
    }
    if (!nullToAbsent || translationOverrideId != null) {
      map['translation_override_id'] = Variable<String>(translationOverrideId);
    }
    return map;
  }

  BiblePlanScheduleEntriesCompanion toCompanion(bool nullToAbsent) {
    return BiblePlanScheduleEntriesCompanion(
      id: Value(id),
      planId: Value(planId),
      position: Value(position),
      scheduledDate: Value(scheduledDate),
      isCompleted: Value(isCompleted),
      completedAtUtcMicros: completedAtUtcMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtcMicros),
      translationOverrideId: translationOverrideId == null && nullToAbsent
          ? const Value.absent()
          : Value(translationOverrideId),
    );
  }

  factory BiblePlanScheduleEntryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BiblePlanScheduleEntryRecord(
      id: serializer.fromJson<String>(json['id']),
      planId: serializer.fromJson<String>(json['planId']),
      position: serializer.fromJson<int>(json['position']),
      scheduledDate: serializer.fromJson<String>(json['scheduledDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAtUtcMicros: serializer.fromJson<int?>(
        json['completedAtUtcMicros'],
      ),
      translationOverrideId: serializer.fromJson<String?>(
        json['translationOverrideId'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'planId': serializer.toJson<String>(planId),
      'position': serializer.toJson<int>(position),
      'scheduledDate': serializer.toJson<String>(scheduledDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAtUtcMicros': serializer.toJson<int?>(completedAtUtcMicros),
      'translationOverrideId': serializer.toJson<String?>(
        translationOverrideId,
      ),
    };
  }

  BiblePlanScheduleEntryRecord copyWith({
    String? id,
    String? planId,
    int? position,
    String? scheduledDate,
    bool? isCompleted,
    Value<int?> completedAtUtcMicros = const Value.absent(),
    Value<String?> translationOverrideId = const Value.absent(),
  }) => BiblePlanScheduleEntryRecord(
    id: id ?? this.id,
    planId: planId ?? this.planId,
    position: position ?? this.position,
    scheduledDate: scheduledDate ?? this.scheduledDate,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAtUtcMicros: completedAtUtcMicros.present
        ? completedAtUtcMicros.value
        : this.completedAtUtcMicros,
    translationOverrideId: translationOverrideId.present
        ? translationOverrideId.value
        : this.translationOverrideId,
  );
  BiblePlanScheduleEntryRecord copyWithCompanion(
    BiblePlanScheduleEntriesCompanion data,
  ) {
    return BiblePlanScheduleEntryRecord(
      id: data.id.present ? data.id.value : this.id,
      planId: data.planId.present ? data.planId.value : this.planId,
      position: data.position.present ? data.position.value : this.position,
      scheduledDate: data.scheduledDate.present
          ? data.scheduledDate.value
          : this.scheduledDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAtUtcMicros: data.completedAtUtcMicros.present
          ? data.completedAtUtcMicros.value
          : this.completedAtUtcMicros,
      translationOverrideId: data.translationOverrideId.present
          ? data.translationOverrideId.value
          : this.translationOverrideId,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanScheduleEntryRecord(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('position: $position, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAtUtcMicros: $completedAtUtcMicros, ')
          ..write('translationOverrideId: $translationOverrideId')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    planId,
    position,
    scheduledDate,
    isCompleted,
    completedAtUtcMicros,
    translationOverrideId,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiblePlanScheduleEntryRecord &&
          other.id == this.id &&
          other.planId == this.planId &&
          other.position == this.position &&
          other.scheduledDate == this.scheduledDate &&
          other.isCompleted == this.isCompleted &&
          other.completedAtUtcMicros == this.completedAtUtcMicros &&
          other.translationOverrideId == this.translationOverrideId);
}

class BiblePlanScheduleEntriesCompanion
    extends UpdateCompanion<BiblePlanScheduleEntryRecord> {
  final Value<String> id;
  final Value<String> planId;
  final Value<int> position;
  final Value<String> scheduledDate;
  final Value<bool> isCompleted;
  final Value<int?> completedAtUtcMicros;
  final Value<String?> translationOverrideId;
  final Value<int> rowid;
  const BiblePlanScheduleEntriesCompanion({
    this.id = const Value.absent(),
    this.planId = const Value.absent(),
    this.position = const Value.absent(),
    this.scheduledDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAtUtcMicros = const Value.absent(),
    this.translationOverrideId = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BiblePlanScheduleEntriesCompanion.insert({
    required String id,
    required String planId,
    required int position,
    required String scheduledDate,
    required bool isCompleted,
    this.completedAtUtcMicros = const Value.absent(),
    this.translationOverrideId = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       planId = Value(planId),
       position = Value(position),
       scheduledDate = Value(scheduledDate),
       isCompleted = Value(isCompleted);
  static Insertable<BiblePlanScheduleEntryRecord> custom({
    Expression<String>? id,
    Expression<String>? planId,
    Expression<int>? position,
    Expression<String>? scheduledDate,
    Expression<bool>? isCompleted,
    Expression<int>? completedAtUtcMicros,
    Expression<String>? translationOverrideId,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (planId != null) 'plan_id': planId,
      if (position != null) 'position': position,
      if (scheduledDate != null) 'scheduled_date': scheduledDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAtUtcMicros != null)
        'completed_at_utc_micros': completedAtUtcMicros,
      if (translationOverrideId != null)
        'translation_override_id': translationOverrideId,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BiblePlanScheduleEntriesCompanion copyWith({
    Value<String>? id,
    Value<String>? planId,
    Value<int>? position,
    Value<String>? scheduledDate,
    Value<bool>? isCompleted,
    Value<int?>? completedAtUtcMicros,
    Value<String?>? translationOverrideId,
    Value<int>? rowid,
  }) {
    return BiblePlanScheduleEntriesCompanion(
      id: id ?? this.id,
      planId: planId ?? this.planId,
      position: position ?? this.position,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAtUtcMicros: completedAtUtcMicros ?? this.completedAtUtcMicros,
      translationOverrideId:
          translationOverrideId ?? this.translationOverrideId,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (scheduledDate.present) {
      map['scheduled_date'] = Variable<String>(scheduledDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAtUtcMicros.present) {
      map['completed_at_utc_micros'] = Variable<int>(
        completedAtUtcMicros.value,
      );
    }
    if (translationOverrideId.present) {
      map['translation_override_id'] = Variable<String>(
        translationOverrideId.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanScheduleEntriesCompanion(')
          ..write('id: $id, ')
          ..write('planId: $planId, ')
          ..write('position: $position, ')
          ..write('scheduledDate: $scheduledDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAtUtcMicros: $completedAtUtcMicros, ')
          ..write('translationOverrideId: $translationOverrideId, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $BiblePlanScheduleItemsTable extends BiblePlanScheduleItems
    with TableInfo<$BiblePlanScheduleItemsTable, BiblePlanScheduleItemRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $BiblePlanScheduleItemsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _scheduleEntryIdMeta = const VerificationMeta(
    'scheduleEntryId',
  );
  @override
  late final GeneratedColumn<String> scheduleEntryId = GeneratedColumn<String>(
    'schedule_entry_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES bible_plan_schedule_entries (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startChapterMeta = const VerificationMeta(
    'startChapter',
  );
  @override
  late final GeneratedColumn<int> startChapter = GeneratedColumn<int>(
    'start_chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endChapterMeta = const VerificationMeta(
    'endChapter',
  );
  @override
  late final GeneratedColumn<int> endChapter = GeneratedColumn<int>(
    'end_chapter',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    scheduleEntryId,
    position,
    book,
    startChapter,
    startVerse,
    endChapter,
    endVerse,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'bible_plan_schedule_items';
  @override
  VerificationContext validateIntegrity(
    Insertable<BiblePlanScheduleItemRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('schedule_entry_id')) {
      context.handle(
        _scheduleEntryIdMeta,
        scheduleEntryId.isAcceptableOrUnknown(
          data['schedule_entry_id']!,
          _scheduleEntryIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_scheduleEntryIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('start_chapter')) {
      context.handle(
        _startChapterMeta,
        startChapter.isAcceptableOrUnknown(
          data['start_chapter']!,
          _startChapterMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startChapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_chapter')) {
      context.handle(
        _endChapterMeta,
        endChapter.isAcceptableOrUnknown(data['end_chapter']!, _endChapterMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {scheduleEntryId, position},
  ];
  @override
  BiblePlanScheduleItemRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return BiblePlanScheduleItemRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      scheduleEntryId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}schedule_entry_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      startChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endChapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_chapter'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
    );
  }

  @override
  $BiblePlanScheduleItemsTable createAlias(String alias) {
    return $BiblePlanScheduleItemsTable(attachedDatabase, alias);
  }
}

class BiblePlanScheduleItemRecord extends DataClass
    implements Insertable<BiblePlanScheduleItemRecord> {
  final String id;
  final String scheduleEntryId;
  final int position;
  final String book;
  final int startChapter;
  final int? startVerse;
  final int? endChapter;
  final int? endVerse;
  const BiblePlanScheduleItemRecord({
    required this.id,
    required this.scheduleEntryId,
    required this.position,
    required this.book,
    required this.startChapter,
    this.startVerse,
    this.endChapter,
    this.endVerse,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['schedule_entry_id'] = Variable<String>(scheduleEntryId);
    map['position'] = Variable<int>(position);
    map['book'] = Variable<String>(book);
    map['start_chapter'] = Variable<int>(startChapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endChapter != null) {
      map['end_chapter'] = Variable<int>(endChapter);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    return map;
  }

  BiblePlanScheduleItemsCompanion toCompanion(bool nullToAbsent) {
    return BiblePlanScheduleItemsCompanion(
      id: Value(id),
      scheduleEntryId: Value(scheduleEntryId),
      position: Value(position),
      book: Value(book),
      startChapter: Value(startChapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endChapter: endChapter == null && nullToAbsent
          ? const Value.absent()
          : Value(endChapter),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
    );
  }

  factory BiblePlanScheduleItemRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return BiblePlanScheduleItemRecord(
      id: serializer.fromJson<String>(json['id']),
      scheduleEntryId: serializer.fromJson<String>(json['scheduleEntryId']),
      position: serializer.fromJson<int>(json['position']),
      book: serializer.fromJson<String>(json['book']),
      startChapter: serializer.fromJson<int>(json['startChapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endChapter: serializer.fromJson<int?>(json['endChapter']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'scheduleEntryId': serializer.toJson<String>(scheduleEntryId),
      'position': serializer.toJson<int>(position),
      'book': serializer.toJson<String>(book),
      'startChapter': serializer.toJson<int>(startChapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endChapter': serializer.toJson<int?>(endChapter),
      'endVerse': serializer.toJson<int?>(endVerse),
    };
  }

  BiblePlanScheduleItemRecord copyWith({
    String? id,
    String? scheduleEntryId,
    int? position,
    String? book,
    int? startChapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endChapter = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
  }) => BiblePlanScheduleItemRecord(
    id: id ?? this.id,
    scheduleEntryId: scheduleEntryId ?? this.scheduleEntryId,
    position: position ?? this.position,
    book: book ?? this.book,
    startChapter: startChapter ?? this.startChapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endChapter: endChapter.present ? endChapter.value : this.endChapter,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
  );
  BiblePlanScheduleItemRecord copyWithCompanion(
    BiblePlanScheduleItemsCompanion data,
  ) {
    return BiblePlanScheduleItemRecord(
      id: data.id.present ? data.id.value : this.id,
      scheduleEntryId: data.scheduleEntryId.present
          ? data.scheduleEntryId.value
          : this.scheduleEntryId,
      position: data.position.present ? data.position.value : this.position,
      book: data.book.present ? data.book.value : this.book,
      startChapter: data.startChapter.present
          ? data.startChapter.value
          : this.startChapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endChapter: data.endChapter.present
          ? data.endChapter.value
          : this.endChapter,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
    );
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanScheduleItemRecord(')
          ..write('id: $id, ')
          ..write('scheduleEntryId: $scheduleEntryId, ')
          ..write('position: $position, ')
          ..write('book: $book, ')
          ..write('startChapter: $startChapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endChapter: $endChapter, ')
          ..write('endVerse: $endVerse')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    scheduleEntryId,
    position,
    book,
    startChapter,
    startVerse,
    endChapter,
    endVerse,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is BiblePlanScheduleItemRecord &&
          other.id == this.id &&
          other.scheduleEntryId == this.scheduleEntryId &&
          other.position == this.position &&
          other.book == this.book &&
          other.startChapter == this.startChapter &&
          other.startVerse == this.startVerse &&
          other.endChapter == this.endChapter &&
          other.endVerse == this.endVerse);
}

class BiblePlanScheduleItemsCompanion
    extends UpdateCompanion<BiblePlanScheduleItemRecord> {
  final Value<String> id;
  final Value<String> scheduleEntryId;
  final Value<int> position;
  final Value<String> book;
  final Value<int> startChapter;
  final Value<int?> startVerse;
  final Value<int?> endChapter;
  final Value<int?> endVerse;
  final Value<int> rowid;
  const BiblePlanScheduleItemsCompanion({
    this.id = const Value.absent(),
    this.scheduleEntryId = const Value.absent(),
    this.position = const Value.absent(),
    this.book = const Value.absent(),
    this.startChapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endChapter = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  BiblePlanScheduleItemsCompanion.insert({
    required String id,
    required String scheduleEntryId,
    required int position,
    required String book,
    required int startChapter,
    this.startVerse = const Value.absent(),
    this.endChapter = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       scheduleEntryId = Value(scheduleEntryId),
       position = Value(position),
       book = Value(book),
       startChapter = Value(startChapter);
  static Insertable<BiblePlanScheduleItemRecord> custom({
    Expression<String>? id,
    Expression<String>? scheduleEntryId,
    Expression<int>? position,
    Expression<String>? book,
    Expression<int>? startChapter,
    Expression<int>? startVerse,
    Expression<int>? endChapter,
    Expression<int>? endVerse,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (scheduleEntryId != null) 'schedule_entry_id': scheduleEntryId,
      if (position != null) 'position': position,
      if (book != null) 'book': book,
      if (startChapter != null) 'start_chapter': startChapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endChapter != null) 'end_chapter': endChapter,
      if (endVerse != null) 'end_verse': endVerse,
      if (rowid != null) 'rowid': rowid,
    });
  }

  BiblePlanScheduleItemsCompanion copyWith({
    Value<String>? id,
    Value<String>? scheduleEntryId,
    Value<int>? position,
    Value<String>? book,
    Value<int>? startChapter,
    Value<int?>? startVerse,
    Value<int?>? endChapter,
    Value<int?>? endVerse,
    Value<int>? rowid,
  }) {
    return BiblePlanScheduleItemsCompanion(
      id: id ?? this.id,
      scheduleEntryId: scheduleEntryId ?? this.scheduleEntryId,
      position: position ?? this.position,
      book: book ?? this.book,
      startChapter: startChapter ?? this.startChapter,
      startVerse: startVerse ?? this.startVerse,
      endChapter: endChapter ?? this.endChapter,
      endVerse: endVerse ?? this.endVerse,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (scheduleEntryId.present) {
      map['schedule_entry_id'] = Variable<String>(scheduleEntryId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (startChapter.present) {
      map['start_chapter'] = Variable<int>(startChapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endChapter.present) {
      map['end_chapter'] = Variable<int>(endChapter.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('BiblePlanScheduleItemsCompanion(')
          ..write('id: $id, ')
          ..write('scheduleEntryId: $scheduleEntryId, ')
          ..write('position: $position, ')
          ..write('book: $book, ')
          ..write('startChapter: $startChapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endChapter: $endChapter, ')
          ..write('endVerse: $endVerse, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordTranslationStatesTable extends WordTranslationStates
    with TableInfo<$WordTranslationStatesTable, WordTranslationStateRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordTranslationStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _translationIdMeta = const VerificationMeta(
    'translationId',
  );
  @override
  late final GeneratedColumn<String> translationId = GeneratedColumn<String>(
    'translation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _accessModeMeta = const VerificationMeta(
    'accessMode',
  );
  @override
  late final GeneratedColumn<String> accessMode = GeneratedColumn<String>(
    'access_mode',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _installedVersionMeta = const VerificationMeta(
    'installedVersion',
  );
  @override
  late final GeneratedColumn<String> installedVersion = GeneratedColumn<String>(
    'installed_version',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _managedRelativePathMeta =
      const VerificationMeta('managedRelativePath');
  @override
  late final GeneratedColumn<String> managedRelativePath =
      GeneratedColumn<String>(
        'managed_relative_path',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _updatedAtUtcMicrosMeta =
      const VerificationMeta('updatedAtUtcMicros');
  @override
  late final GeneratedColumn<int> updatedAtUtcMicros = GeneratedColumn<int>(
    'updated_at_utc_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _downloadProgressPermilleMeta =
      const VerificationMeta('downloadProgressPermille');
  @override
  late final GeneratedColumn<int> downloadProgressPermille =
      GeneratedColumn<int>(
        'download_progress_permille',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      );
  @override
  List<GeneratedColumn> get $columns => [
    translationId,
    accessMode,
    state,
    installedVersion,
    managedRelativePath,
    updatedAtUtcMicros,
    failureCode,
    downloadProgressPermille,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_translation_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordTranslationStateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('translation_id')) {
      context.handle(
        _translationIdMeta,
        translationId.isAcceptableOrUnknown(
          data['translation_id']!,
          _translationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationIdMeta);
    }
    if (data.containsKey('access_mode')) {
      context.handle(
        _accessModeMeta,
        accessMode.isAcceptableOrUnknown(data['access_mode']!, _accessModeMeta),
      );
    } else if (isInserting) {
      context.missing(_accessModeMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('installed_version')) {
      context.handle(
        _installedVersionMeta,
        installedVersion.isAcceptableOrUnknown(
          data['installed_version']!,
          _installedVersionMeta,
        ),
      );
    }
    if (data.containsKey('managed_relative_path')) {
      context.handle(
        _managedRelativePathMeta,
        managedRelativePath.isAcceptableOrUnknown(
          data['managed_relative_path']!,
          _managedRelativePathMeta,
        ),
      );
    }
    if (data.containsKey('updated_at_utc_micros')) {
      context.handle(
        _updatedAtUtcMicrosMeta,
        updatedAtUtcMicros.isAcceptableOrUnknown(
          data['updated_at_utc_micros']!,
          _updatedAtUtcMicrosMeta,
        ),
      );
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('download_progress_permille')) {
      context.handle(
        _downloadProgressPermilleMeta,
        downloadProgressPermille.isAcceptableOrUnknown(
          data['download_progress_permille']!,
          _downloadProgressPermilleMeta,
        ),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {translationId};
  @override
  WordTranslationStateRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordTranslationStateRecord(
      translationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_id'],
      )!,
      accessMode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}access_mode'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      installedVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}installed_version'],
      ),
      managedRelativePath: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}managed_relative_path'],
      ),
      updatedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_micros'],
      ),
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      downloadProgressPermille: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}download_progress_permille'],
      ),
    );
  }

  @override
  $WordTranslationStatesTable createAlias(String alias) {
    return $WordTranslationStatesTable(attachedDatabase, alias);
  }
}

class WordTranslationStateRecord extends DataClass
    implements Insertable<WordTranslationStateRecord> {
  final String translationId;
  final String accessMode;
  final String state;
  final String? installedVersion;
  final String? managedRelativePath;
  final int? updatedAtUtcMicros;
  final String? failureCode;
  final int? downloadProgressPermille;
  const WordTranslationStateRecord({
    required this.translationId,
    required this.accessMode,
    required this.state,
    this.installedVersion,
    this.managedRelativePath,
    this.updatedAtUtcMicros,
    this.failureCode,
    this.downloadProgressPermille,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['translation_id'] = Variable<String>(translationId);
    map['access_mode'] = Variable<String>(accessMode);
    map['state'] = Variable<String>(state);
    if (!nullToAbsent || installedVersion != null) {
      map['installed_version'] = Variable<String>(installedVersion);
    }
    if (!nullToAbsent || managedRelativePath != null) {
      map['managed_relative_path'] = Variable<String>(managedRelativePath);
    }
    if (!nullToAbsent || updatedAtUtcMicros != null) {
      map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros);
    }
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    if (!nullToAbsent || downloadProgressPermille != null) {
      map['download_progress_permille'] = Variable<int>(
        downloadProgressPermille,
      );
    }
    return map;
  }

  WordTranslationStatesCompanion toCompanion(bool nullToAbsent) {
    return WordTranslationStatesCompanion(
      translationId: Value(translationId),
      accessMode: Value(accessMode),
      state: Value(state),
      installedVersion: installedVersion == null && nullToAbsent
          ? const Value.absent()
          : Value(installedVersion),
      managedRelativePath: managedRelativePath == null && nullToAbsent
          ? const Value.absent()
          : Value(managedRelativePath),
      updatedAtUtcMicros: updatedAtUtcMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(updatedAtUtcMicros),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      downloadProgressPermille: downloadProgressPermille == null && nullToAbsent
          ? const Value.absent()
          : Value(downloadProgressPermille),
    );
  }

  factory WordTranslationStateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordTranslationStateRecord(
      translationId: serializer.fromJson<String>(json['translationId']),
      accessMode: serializer.fromJson<String>(json['accessMode']),
      state: serializer.fromJson<String>(json['state']),
      installedVersion: serializer.fromJson<String?>(json['installedVersion']),
      managedRelativePath: serializer.fromJson<String?>(
        json['managedRelativePath'],
      ),
      updatedAtUtcMicros: serializer.fromJson<int?>(json['updatedAtUtcMicros']),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      downloadProgressPermille: serializer.fromJson<int?>(
        json['downloadProgressPermille'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'translationId': serializer.toJson<String>(translationId),
      'accessMode': serializer.toJson<String>(accessMode),
      'state': serializer.toJson<String>(state),
      'installedVersion': serializer.toJson<String?>(installedVersion),
      'managedRelativePath': serializer.toJson<String?>(managedRelativePath),
      'updatedAtUtcMicros': serializer.toJson<int?>(updatedAtUtcMicros),
      'failureCode': serializer.toJson<String?>(failureCode),
      'downloadProgressPermille': serializer.toJson<int?>(
        downloadProgressPermille,
      ),
    };
  }

  WordTranslationStateRecord copyWith({
    String? translationId,
    String? accessMode,
    String? state,
    Value<String?> installedVersion = const Value.absent(),
    Value<String?> managedRelativePath = const Value.absent(),
    Value<int?> updatedAtUtcMicros = const Value.absent(),
    Value<String?> failureCode = const Value.absent(),
    Value<int?> downloadProgressPermille = const Value.absent(),
  }) => WordTranslationStateRecord(
    translationId: translationId ?? this.translationId,
    accessMode: accessMode ?? this.accessMode,
    state: state ?? this.state,
    installedVersion: installedVersion.present
        ? installedVersion.value
        : this.installedVersion,
    managedRelativePath: managedRelativePath.present
        ? managedRelativePath.value
        : this.managedRelativePath,
    updatedAtUtcMicros: updatedAtUtcMicros.present
        ? updatedAtUtcMicros.value
        : this.updatedAtUtcMicros,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    downloadProgressPermille: downloadProgressPermille.present
        ? downloadProgressPermille.value
        : this.downloadProgressPermille,
  );
  WordTranslationStateRecord copyWithCompanion(
    WordTranslationStatesCompanion data,
  ) {
    return WordTranslationStateRecord(
      translationId: data.translationId.present
          ? data.translationId.value
          : this.translationId,
      accessMode: data.accessMode.present
          ? data.accessMode.value
          : this.accessMode,
      state: data.state.present ? data.state.value : this.state,
      installedVersion: data.installedVersion.present
          ? data.installedVersion.value
          : this.installedVersion,
      managedRelativePath: data.managedRelativePath.present
          ? data.managedRelativePath.value
          : this.managedRelativePath,
      updatedAtUtcMicros: data.updatedAtUtcMicros.present
          ? data.updatedAtUtcMicros.value
          : this.updatedAtUtcMicros,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      downloadProgressPermille: data.downloadProgressPermille.present
          ? data.downloadProgressPermille.value
          : this.downloadProgressPermille,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordTranslationStateRecord(')
          ..write('translationId: $translationId, ')
          ..write('accessMode: $accessMode, ')
          ..write('state: $state, ')
          ..write('installedVersion: $installedVersion, ')
          ..write('managedRelativePath: $managedRelativePath, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros, ')
          ..write('failureCode: $failureCode, ')
          ..write('downloadProgressPermille: $downloadProgressPermille')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    translationId,
    accessMode,
    state,
    installedVersion,
    managedRelativePath,
    updatedAtUtcMicros,
    failureCode,
    downloadProgressPermille,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordTranslationStateRecord &&
          other.translationId == this.translationId &&
          other.accessMode == this.accessMode &&
          other.state == this.state &&
          other.installedVersion == this.installedVersion &&
          other.managedRelativePath == this.managedRelativePath &&
          other.updatedAtUtcMicros == this.updatedAtUtcMicros &&
          other.failureCode == this.failureCode &&
          other.downloadProgressPermille == this.downloadProgressPermille);
}

class WordTranslationStatesCompanion
    extends UpdateCompanion<WordTranslationStateRecord> {
  final Value<String> translationId;
  final Value<String> accessMode;
  final Value<String> state;
  final Value<String?> installedVersion;
  final Value<String?> managedRelativePath;
  final Value<int?> updatedAtUtcMicros;
  final Value<String?> failureCode;
  final Value<int?> downloadProgressPermille;
  final Value<int> rowid;
  const WordTranslationStatesCompanion({
    this.translationId = const Value.absent(),
    this.accessMode = const Value.absent(),
    this.state = const Value.absent(),
    this.installedVersion = const Value.absent(),
    this.managedRelativePath = const Value.absent(),
    this.updatedAtUtcMicros = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.downloadProgressPermille = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordTranslationStatesCompanion.insert({
    required String translationId,
    required String accessMode,
    required String state,
    this.installedVersion = const Value.absent(),
    this.managedRelativePath = const Value.absent(),
    this.updatedAtUtcMicros = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.downloadProgressPermille = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : translationId = Value(translationId),
       accessMode = Value(accessMode),
       state = Value(state);
  static Insertable<WordTranslationStateRecord> custom({
    Expression<String>? translationId,
    Expression<String>? accessMode,
    Expression<String>? state,
    Expression<String>? installedVersion,
    Expression<String>? managedRelativePath,
    Expression<int>? updatedAtUtcMicros,
    Expression<String>? failureCode,
    Expression<int>? downloadProgressPermille,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (translationId != null) 'translation_id': translationId,
      if (accessMode != null) 'access_mode': accessMode,
      if (state != null) 'state': state,
      if (installedVersion != null) 'installed_version': installedVersion,
      if (managedRelativePath != null)
        'managed_relative_path': managedRelativePath,
      if (updatedAtUtcMicros != null)
        'updated_at_utc_micros': updatedAtUtcMicros,
      if (failureCode != null) 'failure_code': failureCode,
      if (downloadProgressPermille != null)
        'download_progress_permille': downloadProgressPermille,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordTranslationStatesCompanion copyWith({
    Value<String>? translationId,
    Value<String>? accessMode,
    Value<String>? state,
    Value<String?>? installedVersion,
    Value<String?>? managedRelativePath,
    Value<int?>? updatedAtUtcMicros,
    Value<String?>? failureCode,
    Value<int?>? downloadProgressPermille,
    Value<int>? rowid,
  }) {
    return WordTranslationStatesCompanion(
      translationId: translationId ?? this.translationId,
      accessMode: accessMode ?? this.accessMode,
      state: state ?? this.state,
      installedVersion: installedVersion ?? this.installedVersion,
      managedRelativePath: managedRelativePath ?? this.managedRelativePath,
      updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
      failureCode: failureCode ?? this.failureCode,
      downloadProgressPermille:
          downloadProgressPermille ?? this.downloadProgressPermille,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (translationId.present) {
      map['translation_id'] = Variable<String>(translationId.value);
    }
    if (accessMode.present) {
      map['access_mode'] = Variable<String>(accessMode.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (installedVersion.present) {
      map['installed_version'] = Variable<String>(installedVersion.value);
    }
    if (managedRelativePath.present) {
      map['managed_relative_path'] = Variable<String>(
        managedRelativePath.value,
      );
    }
    if (updatedAtUtcMicros.present) {
      map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros.value);
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (downloadProgressPermille.present) {
      map['download_progress_permille'] = Variable<int>(
        downloadProgressPermille.value,
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordTranslationStatesCompanion(')
          ..write('translationId: $translationId, ')
          ..write('accessMode: $accessMode, ')
          ..write('state: $state, ')
          ..write('installedVersion: $installedVersion, ')
          ..write('managedRelativePath: $managedRelativePath, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros, ')
          ..write('failureCode: $failureCode, ')
          ..write('downloadProgressPermille: $downloadProgressPermille, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $LocalMigrationMetadataTable extends LocalMigrationMetadata
    with TableInfo<$LocalMigrationMetadataTable, LocalMigrationMetadataRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $LocalMigrationMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _migrationIdMeta = const VerificationMeta(
    'migrationId',
  );
  @override
  late final GeneratedColumn<String> migrationId = GeneratedColumn<String>(
    'migration_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _stateMeta = const VerificationMeta('state');
  @override
  late final GeneratedColumn<String> state = GeneratedColumn<String>(
    'state',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sourceFingerprintMeta = const VerificationMeta(
    'sourceFingerprint',
  );
  @override
  late final GeneratedColumn<String> sourceFingerprint =
      GeneratedColumn<String>(
        'source_fingerprint',
        aliasedName,
        false,
        type: DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const VerificationMeta _startedAtUtcMicrosMeta =
      const VerificationMeta('startedAtUtcMicros');
  @override
  late final GeneratedColumn<int> startedAtUtcMicros = GeneratedColumn<int>(
    'started_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _completedAtUtcMicrosMeta =
      const VerificationMeta('completedAtUtcMicros');
  @override
  late final GeneratedColumn<int> completedAtUtcMicros = GeneratedColumn<int>(
    'completed_at_utc_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _failureCodeMeta = const VerificationMeta(
    'failureCode',
  );
  @override
  late final GeneratedColumn<String> failureCode = GeneratedColumn<String>(
    'failure_code',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _targetSchemaVersionMeta =
      const VerificationMeta('targetSchemaVersion');
  @override
  late final GeneratedColumn<int> targetSchemaVersion = GeneratedColumn<int>(
    'target_schema_version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    migrationId,
    state,
    sourceFingerprint,
    startedAtUtcMicros,
    completedAtUtcMicros,
    failureCode,
    targetSchemaVersion,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'local_migration_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<LocalMigrationMetadataRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('migration_id')) {
      context.handle(
        _migrationIdMeta,
        migrationId.isAcceptableOrUnknown(
          data['migration_id']!,
          _migrationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_migrationIdMeta);
    }
    if (data.containsKey('state')) {
      context.handle(
        _stateMeta,
        state.isAcceptableOrUnknown(data['state']!, _stateMeta),
      );
    } else if (isInserting) {
      context.missing(_stateMeta);
    }
    if (data.containsKey('source_fingerprint')) {
      context.handle(
        _sourceFingerprintMeta,
        sourceFingerprint.isAcceptableOrUnknown(
          data['source_fingerprint']!,
          _sourceFingerprintMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_sourceFingerprintMeta);
    }
    if (data.containsKey('started_at_utc_micros')) {
      context.handle(
        _startedAtUtcMicrosMeta,
        startedAtUtcMicros.isAcceptableOrUnknown(
          data['started_at_utc_micros']!,
          _startedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_startedAtUtcMicrosMeta);
    }
    if (data.containsKey('completed_at_utc_micros')) {
      context.handle(
        _completedAtUtcMicrosMeta,
        completedAtUtcMicros.isAcceptableOrUnknown(
          data['completed_at_utc_micros']!,
          _completedAtUtcMicrosMeta,
        ),
      );
    }
    if (data.containsKey('failure_code')) {
      context.handle(
        _failureCodeMeta,
        failureCode.isAcceptableOrUnknown(
          data['failure_code']!,
          _failureCodeMeta,
        ),
      );
    }
    if (data.containsKey('target_schema_version')) {
      context.handle(
        _targetSchemaVersionMeta,
        targetSchemaVersion.isAcceptableOrUnknown(
          data['target_schema_version']!,
          _targetSchemaVersionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_targetSchemaVersionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {migrationId};
  @override
  LocalMigrationMetadataRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return LocalMigrationMetadataRecord(
      migrationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}migration_id'],
      )!,
      state: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}state'],
      )!,
      sourceFingerprint: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}source_fingerprint'],
      )!,
      startedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}started_at_utc_micros'],
      )!,
      completedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_utc_micros'],
      ),
      failureCode: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}failure_code'],
      ),
      targetSchemaVersion: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}target_schema_version'],
      )!,
    );
  }

  @override
  $LocalMigrationMetadataTable createAlias(String alias) {
    return $LocalMigrationMetadataTable(attachedDatabase, alias);
  }
}

class LocalMigrationMetadataRecord extends DataClass
    implements Insertable<LocalMigrationMetadataRecord> {
  final String migrationId;
  final String state;
  final String sourceFingerprint;
  final int startedAtUtcMicros;
  final int? completedAtUtcMicros;
  final String? failureCode;
  final int targetSchemaVersion;
  const LocalMigrationMetadataRecord({
    required this.migrationId,
    required this.state,
    required this.sourceFingerprint,
    required this.startedAtUtcMicros,
    this.completedAtUtcMicros,
    this.failureCode,
    required this.targetSchemaVersion,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['migration_id'] = Variable<String>(migrationId);
    map['state'] = Variable<String>(state);
    map['source_fingerprint'] = Variable<String>(sourceFingerprint);
    map['started_at_utc_micros'] = Variable<int>(startedAtUtcMicros);
    if (!nullToAbsent || completedAtUtcMicros != null) {
      map['completed_at_utc_micros'] = Variable<int>(completedAtUtcMicros);
    }
    if (!nullToAbsent || failureCode != null) {
      map['failure_code'] = Variable<String>(failureCode);
    }
    map['target_schema_version'] = Variable<int>(targetSchemaVersion);
    return map;
  }

  LocalMigrationMetadataCompanion toCompanion(bool nullToAbsent) {
    return LocalMigrationMetadataCompanion(
      migrationId: Value(migrationId),
      state: Value(state),
      sourceFingerprint: Value(sourceFingerprint),
      startedAtUtcMicros: Value(startedAtUtcMicros),
      completedAtUtcMicros: completedAtUtcMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtcMicros),
      failureCode: failureCode == null && nullToAbsent
          ? const Value.absent()
          : Value(failureCode),
      targetSchemaVersion: Value(targetSchemaVersion),
    );
  }

  factory LocalMigrationMetadataRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return LocalMigrationMetadataRecord(
      migrationId: serializer.fromJson<String>(json['migrationId']),
      state: serializer.fromJson<String>(json['state']),
      sourceFingerprint: serializer.fromJson<String>(json['sourceFingerprint']),
      startedAtUtcMicros: serializer.fromJson<int>(json['startedAtUtcMicros']),
      completedAtUtcMicros: serializer.fromJson<int?>(
        json['completedAtUtcMicros'],
      ),
      failureCode: serializer.fromJson<String?>(json['failureCode']),
      targetSchemaVersion: serializer.fromJson<int>(
        json['targetSchemaVersion'],
      ),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'migrationId': serializer.toJson<String>(migrationId),
      'state': serializer.toJson<String>(state),
      'sourceFingerprint': serializer.toJson<String>(sourceFingerprint),
      'startedAtUtcMicros': serializer.toJson<int>(startedAtUtcMicros),
      'completedAtUtcMicros': serializer.toJson<int?>(completedAtUtcMicros),
      'failureCode': serializer.toJson<String?>(failureCode),
      'targetSchemaVersion': serializer.toJson<int>(targetSchemaVersion),
    };
  }

  LocalMigrationMetadataRecord copyWith({
    String? migrationId,
    String? state,
    String? sourceFingerprint,
    int? startedAtUtcMicros,
    Value<int?> completedAtUtcMicros = const Value.absent(),
    Value<String?> failureCode = const Value.absent(),
    int? targetSchemaVersion,
  }) => LocalMigrationMetadataRecord(
    migrationId: migrationId ?? this.migrationId,
    state: state ?? this.state,
    sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
    startedAtUtcMicros: startedAtUtcMicros ?? this.startedAtUtcMicros,
    completedAtUtcMicros: completedAtUtcMicros.present
        ? completedAtUtcMicros.value
        : this.completedAtUtcMicros,
    failureCode: failureCode.present ? failureCode.value : this.failureCode,
    targetSchemaVersion: targetSchemaVersion ?? this.targetSchemaVersion,
  );
  LocalMigrationMetadataRecord copyWithCompanion(
    LocalMigrationMetadataCompanion data,
  ) {
    return LocalMigrationMetadataRecord(
      migrationId: data.migrationId.present
          ? data.migrationId.value
          : this.migrationId,
      state: data.state.present ? data.state.value : this.state,
      sourceFingerprint: data.sourceFingerprint.present
          ? data.sourceFingerprint.value
          : this.sourceFingerprint,
      startedAtUtcMicros: data.startedAtUtcMicros.present
          ? data.startedAtUtcMicros.value
          : this.startedAtUtcMicros,
      completedAtUtcMicros: data.completedAtUtcMicros.present
          ? data.completedAtUtcMicros.value
          : this.completedAtUtcMicros,
      failureCode: data.failureCode.present
          ? data.failureCode.value
          : this.failureCode,
      targetSchemaVersion: data.targetSchemaVersion.present
          ? data.targetSchemaVersion.value
          : this.targetSchemaVersion,
    );
  }

  @override
  String toString() {
    return (StringBuffer('LocalMigrationMetadataRecord(')
          ..write('migrationId: $migrationId, ')
          ..write('state: $state, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('startedAtUtcMicros: $startedAtUtcMicros, ')
          ..write('completedAtUtcMicros: $completedAtUtcMicros, ')
          ..write('failureCode: $failureCode, ')
          ..write('targetSchemaVersion: $targetSchemaVersion')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    migrationId,
    state,
    sourceFingerprint,
    startedAtUtcMicros,
    completedAtUtcMicros,
    failureCode,
    targetSchemaVersion,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is LocalMigrationMetadataRecord &&
          other.migrationId == this.migrationId &&
          other.state == this.state &&
          other.sourceFingerprint == this.sourceFingerprint &&
          other.startedAtUtcMicros == this.startedAtUtcMicros &&
          other.completedAtUtcMicros == this.completedAtUtcMicros &&
          other.failureCode == this.failureCode &&
          other.targetSchemaVersion == this.targetSchemaVersion);
}

class LocalMigrationMetadataCompanion
    extends UpdateCompanion<LocalMigrationMetadataRecord> {
  final Value<String> migrationId;
  final Value<String> state;
  final Value<String> sourceFingerprint;
  final Value<int> startedAtUtcMicros;
  final Value<int?> completedAtUtcMicros;
  final Value<String?> failureCode;
  final Value<int> targetSchemaVersion;
  final Value<int> rowid;
  const LocalMigrationMetadataCompanion({
    this.migrationId = const Value.absent(),
    this.state = const Value.absent(),
    this.sourceFingerprint = const Value.absent(),
    this.startedAtUtcMicros = const Value.absent(),
    this.completedAtUtcMicros = const Value.absent(),
    this.failureCode = const Value.absent(),
    this.targetSchemaVersion = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  LocalMigrationMetadataCompanion.insert({
    required String migrationId,
    required String state,
    required String sourceFingerprint,
    required int startedAtUtcMicros,
    this.completedAtUtcMicros = const Value.absent(),
    this.failureCode = const Value.absent(),
    required int targetSchemaVersion,
    this.rowid = const Value.absent(),
  }) : migrationId = Value(migrationId),
       state = Value(state),
       sourceFingerprint = Value(sourceFingerprint),
       startedAtUtcMicros = Value(startedAtUtcMicros),
       targetSchemaVersion = Value(targetSchemaVersion);
  static Insertable<LocalMigrationMetadataRecord> custom({
    Expression<String>? migrationId,
    Expression<String>? state,
    Expression<String>? sourceFingerprint,
    Expression<int>? startedAtUtcMicros,
    Expression<int>? completedAtUtcMicros,
    Expression<String>? failureCode,
    Expression<int>? targetSchemaVersion,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (migrationId != null) 'migration_id': migrationId,
      if (state != null) 'state': state,
      if (sourceFingerprint != null) 'source_fingerprint': sourceFingerprint,
      if (startedAtUtcMicros != null)
        'started_at_utc_micros': startedAtUtcMicros,
      if (completedAtUtcMicros != null)
        'completed_at_utc_micros': completedAtUtcMicros,
      if (failureCode != null) 'failure_code': failureCode,
      if (targetSchemaVersion != null)
        'target_schema_version': targetSchemaVersion,
      if (rowid != null) 'rowid': rowid,
    });
  }

  LocalMigrationMetadataCompanion copyWith({
    Value<String>? migrationId,
    Value<String>? state,
    Value<String>? sourceFingerprint,
    Value<int>? startedAtUtcMicros,
    Value<int?>? completedAtUtcMicros,
    Value<String?>? failureCode,
    Value<int>? targetSchemaVersion,
    Value<int>? rowid,
  }) {
    return LocalMigrationMetadataCompanion(
      migrationId: migrationId ?? this.migrationId,
      state: state ?? this.state,
      sourceFingerprint: sourceFingerprint ?? this.sourceFingerprint,
      startedAtUtcMicros: startedAtUtcMicros ?? this.startedAtUtcMicros,
      completedAtUtcMicros: completedAtUtcMicros ?? this.completedAtUtcMicros,
      failureCode: failureCode ?? this.failureCode,
      targetSchemaVersion: targetSchemaVersion ?? this.targetSchemaVersion,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (migrationId.present) {
      map['migration_id'] = Variable<String>(migrationId.value);
    }
    if (state.present) {
      map['state'] = Variable<String>(state.value);
    }
    if (sourceFingerprint.present) {
      map['source_fingerprint'] = Variable<String>(sourceFingerprint.value);
    }
    if (startedAtUtcMicros.present) {
      map['started_at_utc_micros'] = Variable<int>(startedAtUtcMicros.value);
    }
    if (completedAtUtcMicros.present) {
      map['completed_at_utc_micros'] = Variable<int>(
        completedAtUtcMicros.value,
      );
    }
    if (failureCode.present) {
      map['failure_code'] = Variable<String>(failureCode.value);
    }
    if (targetSchemaVersion.present) {
      map['target_schema_version'] = Variable<int>(targetSchemaVersion.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('LocalMigrationMetadataCompanion(')
          ..write('migrationId: $migrationId, ')
          ..write('state: $state, ')
          ..write('sourceFingerprint: $sourceFingerprint, ')
          ..write('startedAtUtcMicros: $startedAtUtcMicros, ')
          ..write('completedAtUtcMicros: $completedAtUtcMicros, ')
          ..write('failureCode: $failureCode, ')
          ..write('targetSchemaVersion: $targetSchemaVersion, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordReaderStatesTable extends WordReaderStates
    with TableInfo<$WordReaderStatesTable, WordReaderStateRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordReaderStatesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _translationIdMeta = const VerificationMeta(
    'translationId',
  );
  @override
  late final GeneratedColumn<String> translationId = GeneratedColumn<String>(
    'translation_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMicrosMeta =
      const VerificationMeta('updatedAtUtcMicros');
  @override
  late final GeneratedColumn<int> updatedAtUtcMicros = GeneratedColumn<int>(
    'updated_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    book,
    chapter,
    translationId,
    updatedAtUtcMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_reader_states';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordReaderStateRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('translation_id')) {
      context.handle(
        _translationIdMeta,
        translationId.isAcceptableOrUnknown(
          data['translation_id']!,
          _translationIdMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_translationIdMeta);
    }
    if (data.containsKey('updated_at_utc_micros')) {
      context.handle(
        _updatedAtUtcMicrosMeta,
        updatedAtUtcMicros.isAcceptableOrUnknown(
          data['updated_at_utc_micros']!,
          _updatedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordReaderStateRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordReaderStateRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      translationId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}translation_id'],
      )!,
      updatedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_micros'],
      )!,
    );
  }

  @override
  $WordReaderStatesTable createAlias(String alias) {
    return $WordReaderStatesTable(attachedDatabase, alias);
  }
}

class WordReaderStateRecord extends DataClass
    implements Insertable<WordReaderStateRecord> {
  final String id;
  final String book;
  final int chapter;
  final String translationId;
  final int updatedAtUtcMicros;
  const WordReaderStateRecord({
    required this.id,
    required this.book,
    required this.chapter,
    required this.translationId,
    required this.updatedAtUtcMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    map['translation_id'] = Variable<String>(translationId);
    map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros);
    return map;
  }

  WordReaderStatesCompanion toCompanion(bool nullToAbsent) {
    return WordReaderStatesCompanion(
      id: Value(id),
      book: Value(book),
      chapter: Value(chapter),
      translationId: Value(translationId),
      updatedAtUtcMicros: Value(updatedAtUtcMicros),
    );
  }

  factory WordReaderStateRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordReaderStateRecord(
      id: serializer.fromJson<String>(json['id']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      translationId: serializer.fromJson<String>(json['translationId']),
      updatedAtUtcMicros: serializer.fromJson<int>(json['updatedAtUtcMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'translationId': serializer.toJson<String>(translationId),
      'updatedAtUtcMicros': serializer.toJson<int>(updatedAtUtcMicros),
    };
  }

  WordReaderStateRecord copyWith({
    String? id,
    String? book,
    int? chapter,
    String? translationId,
    int? updatedAtUtcMicros,
  }) => WordReaderStateRecord(
    id: id ?? this.id,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    translationId: translationId ?? this.translationId,
    updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
  );
  WordReaderStateRecord copyWithCompanion(WordReaderStatesCompanion data) {
    return WordReaderStateRecord(
      id: data.id.present ? data.id.value : this.id,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      translationId: data.translationId.present
          ? data.translationId.value
          : this.translationId,
      updatedAtUtcMicros: data.updatedAtUtcMicros.present
          ? data.updatedAtUtcMicros.value
          : this.updatedAtUtcMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordReaderStateRecord(')
          ..write('id: $id, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('translationId: $translationId, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, book, chapter, translationId, updatedAtUtcMicros);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordReaderStateRecord &&
          other.id == this.id &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.translationId == this.translationId &&
          other.updatedAtUtcMicros == this.updatedAtUtcMicros);
}

class WordReaderStatesCompanion extends UpdateCompanion<WordReaderStateRecord> {
  final Value<String> id;
  final Value<String> book;
  final Value<int> chapter;
  final Value<String> translationId;
  final Value<int> updatedAtUtcMicros;
  final Value<int> rowid;
  const WordReaderStatesCompanion({
    this.id = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.translationId = const Value.absent(),
    this.updatedAtUtcMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordReaderStatesCompanion.insert({
    required String id,
    required String book,
    required int chapter,
    required String translationId,
    required int updatedAtUtcMicros,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       book = Value(book),
       chapter = Value(chapter),
       translationId = Value(translationId),
       updatedAtUtcMicros = Value(updatedAtUtcMicros);
  static Insertable<WordReaderStateRecord> custom({
    Expression<String>? id,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<String>? translationId,
    Expression<int>? updatedAtUtcMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (translationId != null) 'translation_id': translationId,
      if (updatedAtUtcMicros != null)
        'updated_at_utc_micros': updatedAtUtcMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordReaderStatesCompanion copyWith({
    Value<String>? id,
    Value<String>? book,
    Value<int>? chapter,
    Value<String>? translationId,
    Value<int>? updatedAtUtcMicros,
    Value<int>? rowid,
  }) {
    return WordReaderStatesCompanion(
      id: id ?? this.id,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      translationId: translationId ?? this.translationId,
      updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (translationId.present) {
      map['translation_id'] = Variable<String>(translationId.value);
    }
    if (updatedAtUtcMicros.present) {
      map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordReaderStatesCompanion(')
          ..write('id: $id, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('translationId: $translationId, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordAudioPreferencesTable extends WordAudioPreferences
    with TableInfo<$WordAudioPreferencesTable, WordAudioPreferenceRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordAudioPreferencesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _voiceKeyMeta = const VerificationMeta(
    'voiceKey',
  );
  @override
  late final GeneratedColumn<String> voiceKey = GeneratedColumn<String>(
    'voice_key',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _playbackRateMeta = const VerificationMeta(
    'playbackRate',
  );
  @override
  late final GeneratedColumn<double> playbackRate = GeneratedColumn<double>(
    'playback_rate',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [id, voiceKey, playbackRate];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_audio_preferences';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordAudioPreferenceRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('voice_key')) {
      context.handle(
        _voiceKeyMeta,
        voiceKey.isAcceptableOrUnknown(data['voice_key']!, _voiceKeyMeta),
      );
    }
    if (data.containsKey('playback_rate')) {
      context.handle(
        _playbackRateMeta,
        playbackRate.isAcceptableOrUnknown(
          data['playback_rate']!,
          _playbackRateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_playbackRateMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordAudioPreferenceRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordAudioPreferenceRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      voiceKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}voice_key'],
      ),
      playbackRate: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}playback_rate'],
      )!,
    );
  }

  @override
  $WordAudioPreferencesTable createAlias(String alias) {
    return $WordAudioPreferencesTable(attachedDatabase, alias);
  }
}

class WordAudioPreferenceRecord extends DataClass
    implements Insertable<WordAudioPreferenceRecord> {
  final String id;
  final String? voiceKey;
  final double playbackRate;
  const WordAudioPreferenceRecord({
    required this.id,
    this.voiceKey,
    required this.playbackRate,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || voiceKey != null) {
      map['voice_key'] = Variable<String>(voiceKey);
    }
    map['playback_rate'] = Variable<double>(playbackRate);
    return map;
  }

  WordAudioPreferencesCompanion toCompanion(bool nullToAbsent) {
    return WordAudioPreferencesCompanion(
      id: Value(id),
      voiceKey: voiceKey == null && nullToAbsent
          ? const Value.absent()
          : Value(voiceKey),
      playbackRate: Value(playbackRate),
    );
  }

  factory WordAudioPreferenceRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordAudioPreferenceRecord(
      id: serializer.fromJson<String>(json['id']),
      voiceKey: serializer.fromJson<String?>(json['voiceKey']),
      playbackRate: serializer.fromJson<double>(json['playbackRate']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'voiceKey': serializer.toJson<String?>(voiceKey),
      'playbackRate': serializer.toJson<double>(playbackRate),
    };
  }

  WordAudioPreferenceRecord copyWith({
    String? id,
    Value<String?> voiceKey = const Value.absent(),
    double? playbackRate,
  }) => WordAudioPreferenceRecord(
    id: id ?? this.id,
    voiceKey: voiceKey.present ? voiceKey.value : this.voiceKey,
    playbackRate: playbackRate ?? this.playbackRate,
  );
  WordAudioPreferenceRecord copyWithCompanion(
    WordAudioPreferencesCompanion data,
  ) {
    return WordAudioPreferenceRecord(
      id: data.id.present ? data.id.value : this.id,
      voiceKey: data.voiceKey.present ? data.voiceKey.value : this.voiceKey,
      playbackRate: data.playbackRate.present
          ? data.playbackRate.value
          : this.playbackRate,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordAudioPreferenceRecord(')
          ..write('id: $id, ')
          ..write('voiceKey: $voiceKey, ')
          ..write('playbackRate: $playbackRate')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, voiceKey, playbackRate);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordAudioPreferenceRecord &&
          other.id == this.id &&
          other.voiceKey == this.voiceKey &&
          other.playbackRate == this.playbackRate);
}

class WordAudioPreferencesCompanion
    extends UpdateCompanion<WordAudioPreferenceRecord> {
  final Value<String> id;
  final Value<String?> voiceKey;
  final Value<double> playbackRate;
  final Value<int> rowid;
  const WordAudioPreferencesCompanion({
    this.id = const Value.absent(),
    this.voiceKey = const Value.absent(),
    this.playbackRate = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordAudioPreferencesCompanion.insert({
    required String id,
    this.voiceKey = const Value.absent(),
    required double playbackRate,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       playbackRate = Value(playbackRate);
  static Insertable<WordAudioPreferenceRecord> custom({
    Expression<String>? id,
    Expression<String>? voiceKey,
    Expression<double>? playbackRate,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (voiceKey != null) 'voice_key': voiceKey,
      if (playbackRate != null) 'playback_rate': playbackRate,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordAudioPreferencesCompanion copyWith({
    Value<String>? id,
    Value<String?>? voiceKey,
    Value<double>? playbackRate,
    Value<int>? rowid,
  }) {
    return WordAudioPreferencesCompanion(
      id: id ?? this.id,
      voiceKey: voiceKey ?? this.voiceKey,
      playbackRate: playbackRate ?? this.playbackRate,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (voiceKey.present) {
      map['voice_key'] = Variable<String>(voiceKey.value);
    }
    if (playbackRate.present) {
      map['playback_rate'] = Variable<double>(playbackRate.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordAudioPreferencesCompanion(')
          ..write('id: $id, ')
          ..write('voiceKey: $voiceKey, ')
          ..write('playbackRate: $playbackRate, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordScriptureBookmarksTable extends WordScriptureBookmarks
    with TableInfo<$WordScriptureBookmarksTable, WordScriptureBookmarkRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordScriptureBookmarksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _anchorKeyMeta = const VerificationMeta(
    'anchorKey',
  );
  @override
  late final GeneratedColumn<String> anchorKey = GeneratedColumn<String>(
    'anchor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMicrosMeta =
      const VerificationMeta('createdAtUtcMicros');
  @override
  late final GeneratedColumn<int> createdAtUtcMicros = GeneratedColumn<int>(
    'created_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    createdAtUtcMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_scripture_bookmarks';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordScriptureBookmarkRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anchor_key')) {
      context.handle(
        _anchorKeyMeta,
        anchorKey.isAcceptableOrUnknown(data['anchor_key']!, _anchorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorKeyMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    if (data.containsKey('created_at_utc_micros')) {
      context.handle(
        _createdAtUtcMicrosMeta,
        createdAtUtcMicros.isAcceptableOrUnknown(
          data['created_at_utc_micros']!,
          _createdAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {anchorKey};
  @override
  WordScriptureBookmarkRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordScriptureBookmarkRecord(
      anchorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_key'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
      createdAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_micros'],
      )!,
    );
  }

  @override
  $WordScriptureBookmarksTable createAlias(String alias) {
    return $WordScriptureBookmarksTable(attachedDatabase, alias);
  }
}

class WordScriptureBookmarkRecord extends DataClass
    implements Insertable<WordScriptureBookmarkRecord> {
  final String anchorKey;
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;
  final int createdAtUtcMicros;
  const WordScriptureBookmarkRecord({
    required this.anchorKey,
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
    required this.createdAtUtcMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anchor_key'] = Variable<String>(anchorKey);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros);
    return map;
  }

  WordScriptureBookmarksCompanion toCompanion(bool nullToAbsent) {
    return WordScriptureBookmarksCompanion(
      anchorKey: Value(anchorKey),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
      createdAtUtcMicros: Value(createdAtUtcMicros),
    );
  }

  factory WordScriptureBookmarkRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordScriptureBookmarkRecord(
      anchorKey: serializer.fromJson<String>(json['anchorKey']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
      createdAtUtcMicros: serializer.fromJson<int>(json['createdAtUtcMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'anchorKey': serializer.toJson<String>(anchorKey),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endVerse': serializer.toJson<int?>(endVerse),
      'createdAtUtcMicros': serializer.toJson<int>(createdAtUtcMicros),
    };
  }

  WordScriptureBookmarkRecord copyWith({
    String? anchorKey,
    String? book,
    int? chapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
    int? createdAtUtcMicros,
  }) => WordScriptureBookmarkRecord(
    anchorKey: anchorKey ?? this.anchorKey,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
    createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
  );
  WordScriptureBookmarkRecord copyWithCompanion(
    WordScriptureBookmarksCompanion data,
  ) {
    return WordScriptureBookmarkRecord(
      anchorKey: data.anchorKey.present ? data.anchorKey.value : this.anchorKey,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      createdAtUtcMicros: data.createdAtUtcMicros.present
          ? data.createdAtUtcMicros.value
          : this.createdAtUtcMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureBookmarkRecord(')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    createdAtUtcMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordScriptureBookmarkRecord &&
          other.anchorKey == this.anchorKey &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.createdAtUtcMicros == this.createdAtUtcMicros);
}

class WordScriptureBookmarksCompanion
    extends UpdateCompanion<WordScriptureBookmarkRecord> {
  final Value<String> anchorKey;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int?> startVerse;
  final Value<int?> endVerse;
  final Value<int> createdAtUtcMicros;
  final Value<int> rowid;
  const WordScriptureBookmarksCompanion({
    this.anchorKey = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.createdAtUtcMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordScriptureBookmarksCompanion.insert({
    required String anchorKey,
    required String book,
    required int chapter,
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    required int createdAtUtcMicros,
    this.rowid = const Value.absent(),
  }) : anchorKey = Value(anchorKey),
       book = Value(book),
       chapter = Value(chapter),
       createdAtUtcMicros = Value(createdAtUtcMicros);
  static Insertable<WordScriptureBookmarkRecord> custom({
    Expression<String>? anchorKey,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<int>? createdAtUtcMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (anchorKey != null) 'anchor_key': anchorKey,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (createdAtUtcMicros != null)
        'created_at_utc_micros': createdAtUtcMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordScriptureBookmarksCompanion copyWith({
    Value<String>? anchorKey,
    Value<String>? book,
    Value<int>? chapter,
    Value<int?>? startVerse,
    Value<int?>? endVerse,
    Value<int>? createdAtUtcMicros,
    Value<int>? rowid,
  }) {
    return WordScriptureBookmarksCompanion(
      anchorKey: anchorKey ?? this.anchorKey,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (anchorKey.present) {
      map['anchor_key'] = Variable<String>(anchorKey.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (createdAtUtcMicros.present) {
      map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureBookmarksCompanion(')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordScriptureHighlightsTable extends WordScriptureHighlights
    with
        TableInfo<$WordScriptureHighlightsTable, WordScriptureHighlightRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordScriptureHighlightsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _anchorKeyMeta = const VerificationMeta(
    'anchorKey',
  );
  @override
  late final GeneratedColumn<String> anchorKey = GeneratedColumn<String>(
    'anchor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _styleMeta = const VerificationMeta('style');
  @override
  late final GeneratedColumn<String> style = GeneratedColumn<String>(
    'style',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMicrosMeta =
      const VerificationMeta('updatedAtUtcMicros');
  @override
  late final GeneratedColumn<int> updatedAtUtcMicros = GeneratedColumn<int>(
    'updated_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    style,
    updatedAtUtcMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_scripture_highlights';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordScriptureHighlightRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anchor_key')) {
      context.handle(
        _anchorKeyMeta,
        anchorKey.isAcceptableOrUnknown(data['anchor_key']!, _anchorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorKeyMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    if (data.containsKey('style')) {
      context.handle(
        _styleMeta,
        style.isAcceptableOrUnknown(data['style']!, _styleMeta),
      );
    } else if (isInserting) {
      context.missing(_styleMeta);
    }
    if (data.containsKey('updated_at_utc_micros')) {
      context.handle(
        _updatedAtUtcMicrosMeta,
        updatedAtUtcMicros.isAcceptableOrUnknown(
          data['updated_at_utc_micros']!,
          _updatedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {anchorKey};
  @override
  WordScriptureHighlightRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordScriptureHighlightRecord(
      anchorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_key'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
      style: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}style'],
      )!,
      updatedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_micros'],
      )!,
    );
  }

  @override
  $WordScriptureHighlightsTable createAlias(String alias) {
    return $WordScriptureHighlightsTable(attachedDatabase, alias);
  }
}

class WordScriptureHighlightRecord extends DataClass
    implements Insertable<WordScriptureHighlightRecord> {
  final String anchorKey;
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;
  final String style;
  final int updatedAtUtcMicros;
  const WordScriptureHighlightRecord({
    required this.anchorKey,
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
    required this.style,
    required this.updatedAtUtcMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anchor_key'] = Variable<String>(anchorKey);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    map['style'] = Variable<String>(style);
    map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros);
    return map;
  }

  WordScriptureHighlightsCompanion toCompanion(bool nullToAbsent) {
    return WordScriptureHighlightsCompanion(
      anchorKey: Value(anchorKey),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
      style: Value(style),
      updatedAtUtcMicros: Value(updatedAtUtcMicros),
    );
  }

  factory WordScriptureHighlightRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordScriptureHighlightRecord(
      anchorKey: serializer.fromJson<String>(json['anchorKey']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
      style: serializer.fromJson<String>(json['style']),
      updatedAtUtcMicros: serializer.fromJson<int>(json['updatedAtUtcMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'anchorKey': serializer.toJson<String>(anchorKey),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endVerse': serializer.toJson<int?>(endVerse),
      'style': serializer.toJson<String>(style),
      'updatedAtUtcMicros': serializer.toJson<int>(updatedAtUtcMicros),
    };
  }

  WordScriptureHighlightRecord copyWith({
    String? anchorKey,
    String? book,
    int? chapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
    String? style,
    int? updatedAtUtcMicros,
  }) => WordScriptureHighlightRecord(
    anchorKey: anchorKey ?? this.anchorKey,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
    style: style ?? this.style,
    updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
  );
  WordScriptureHighlightRecord copyWithCompanion(
    WordScriptureHighlightsCompanion data,
  ) {
    return WordScriptureHighlightRecord(
      anchorKey: data.anchorKey.present ? data.anchorKey.value : this.anchorKey,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      style: data.style.present ? data.style.value : this.style,
      updatedAtUtcMicros: data.updatedAtUtcMicros.present
          ? data.updatedAtUtcMicros.value
          : this.updatedAtUtcMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureHighlightRecord(')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('style: $style, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    style,
    updatedAtUtcMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordScriptureHighlightRecord &&
          other.anchorKey == this.anchorKey &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.style == this.style &&
          other.updatedAtUtcMicros == this.updatedAtUtcMicros);
}

class WordScriptureHighlightsCompanion
    extends UpdateCompanion<WordScriptureHighlightRecord> {
  final Value<String> anchorKey;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int?> startVerse;
  final Value<int?> endVerse;
  final Value<String> style;
  final Value<int> updatedAtUtcMicros;
  final Value<int> rowid;
  const WordScriptureHighlightsCompanion({
    this.anchorKey = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.style = const Value.absent(),
    this.updatedAtUtcMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordScriptureHighlightsCompanion.insert({
    required String anchorKey,
    required String book,
    required int chapter,
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    required String style,
    required int updatedAtUtcMicros,
    this.rowid = const Value.absent(),
  }) : anchorKey = Value(anchorKey),
       book = Value(book),
       chapter = Value(chapter),
       style = Value(style),
       updatedAtUtcMicros = Value(updatedAtUtcMicros);
  static Insertable<WordScriptureHighlightRecord> custom({
    Expression<String>? anchorKey,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<String>? style,
    Expression<int>? updatedAtUtcMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (anchorKey != null) 'anchor_key': anchorKey,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (style != null) 'style': style,
      if (updatedAtUtcMicros != null)
        'updated_at_utc_micros': updatedAtUtcMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordScriptureHighlightsCompanion copyWith({
    Value<String>? anchorKey,
    Value<String>? book,
    Value<int>? chapter,
    Value<int?>? startVerse,
    Value<int?>? endVerse,
    Value<String>? style,
    Value<int>? updatedAtUtcMicros,
    Value<int>? rowid,
  }) {
    return WordScriptureHighlightsCompanion(
      anchorKey: anchorKey ?? this.anchorKey,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      style: style ?? this.style,
      updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (anchorKey.present) {
      map['anchor_key'] = Variable<String>(anchorKey.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (style.present) {
      map['style'] = Variable<String>(style.value);
    }
    if (updatedAtUtcMicros.present) {
      map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureHighlightsCompanion(')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('style: $style, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordScriptureNotesTable extends WordScriptureNotes
    with TableInfo<$WordScriptureNotesTable, WordScriptureNoteRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordScriptureNotesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorKeyMeta = const VerificationMeta(
    'anchorKey',
  );
  @override
  late final GeneratedColumn<String> anchorKey = GeneratedColumn<String>(
    'anchor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'body',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _createdAtUtcMicrosMeta =
      const VerificationMeta('createdAtUtcMicros');
  @override
  late final GeneratedColumn<int> createdAtUtcMicros = GeneratedColumn<int>(
    'created_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMicrosMeta =
      const VerificationMeta('updatedAtUtcMicros');
  @override
  late final GeneratedColumn<int> updatedAtUtcMicros = GeneratedColumn<int>(
    'updated_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    body,
    createdAtUtcMicros,
    updatedAtUtcMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_scripture_notes';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordScriptureNoteRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('anchor_key')) {
      context.handle(
        _anchorKeyMeta,
        anchorKey.isAcceptableOrUnknown(data['anchor_key']!, _anchorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorKeyMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('created_at_utc_micros')) {
      context.handle(
        _createdAtUtcMicrosMeta,
        createdAtUtcMicros.isAcceptableOrUnknown(
          data['created_at_utc_micros']!,
          _createdAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMicrosMeta);
    }
    if (data.containsKey('updated_at_utc_micros')) {
      context.handle(
        _updatedAtUtcMicrosMeta,
        updatedAtUtcMicros.isAcceptableOrUnknown(
          data['updated_at_utc_micros']!,
          _updatedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  WordScriptureNoteRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordScriptureNoteRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      anchorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_key'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}body'],
      )!,
      createdAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_micros'],
      )!,
      updatedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_micros'],
      )!,
    );
  }

  @override
  $WordScriptureNotesTable createAlias(String alias) {
    return $WordScriptureNotesTable(attachedDatabase, alias);
  }
}

class WordScriptureNoteRecord extends DataClass
    implements Insertable<WordScriptureNoteRecord> {
  final String id;
  final String anchorKey;
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;
  final String body;
  final int createdAtUtcMicros;
  final int updatedAtUtcMicros;
  const WordScriptureNoteRecord({
    required this.id,
    required this.anchorKey,
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
    required this.body,
    required this.createdAtUtcMicros,
    required this.updatedAtUtcMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['anchor_key'] = Variable<String>(anchorKey);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    map['body'] = Variable<String>(body);
    map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros);
    map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros);
    return map;
  }

  WordScriptureNotesCompanion toCompanion(bool nullToAbsent) {
    return WordScriptureNotesCompanion(
      id: Value(id),
      anchorKey: Value(anchorKey),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
      body: Value(body),
      createdAtUtcMicros: Value(createdAtUtcMicros),
      updatedAtUtcMicros: Value(updatedAtUtcMicros),
    );
  }

  factory WordScriptureNoteRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordScriptureNoteRecord(
      id: serializer.fromJson<String>(json['id']),
      anchorKey: serializer.fromJson<String>(json['anchorKey']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
      body: serializer.fromJson<String>(json['body']),
      createdAtUtcMicros: serializer.fromJson<int>(json['createdAtUtcMicros']),
      updatedAtUtcMicros: serializer.fromJson<int>(json['updatedAtUtcMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'anchorKey': serializer.toJson<String>(anchorKey),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endVerse': serializer.toJson<int?>(endVerse),
      'body': serializer.toJson<String>(body),
      'createdAtUtcMicros': serializer.toJson<int>(createdAtUtcMicros),
      'updatedAtUtcMicros': serializer.toJson<int>(updatedAtUtcMicros),
    };
  }

  WordScriptureNoteRecord copyWith({
    String? id,
    String? anchorKey,
    String? book,
    int? chapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
    String? body,
    int? createdAtUtcMicros,
    int? updatedAtUtcMicros,
  }) => WordScriptureNoteRecord(
    id: id ?? this.id,
    anchorKey: anchorKey ?? this.anchorKey,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
    body: body ?? this.body,
    createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
    updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
  );
  WordScriptureNoteRecord copyWithCompanion(WordScriptureNotesCompanion data) {
    return WordScriptureNoteRecord(
      id: data.id.present ? data.id.value : this.id,
      anchorKey: data.anchorKey.present ? data.anchorKey.value : this.anchorKey,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      body: data.body.present ? data.body.value : this.body,
      createdAtUtcMicros: data.createdAtUtcMicros.present
          ? data.createdAtUtcMicros.value
          : this.createdAtUtcMicros,
      updatedAtUtcMicros: data.updatedAtUtcMicros.present
          ? data.updatedAtUtcMicros.value
          : this.updatedAtUtcMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureNoteRecord(')
          ..write('id: $id, ')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('body: $body, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    body,
    createdAtUtcMicros,
    updatedAtUtcMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordScriptureNoteRecord &&
          other.id == this.id &&
          other.anchorKey == this.anchorKey &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.body == this.body &&
          other.createdAtUtcMicros == this.createdAtUtcMicros &&
          other.updatedAtUtcMicros == this.updatedAtUtcMicros);
}

class WordScriptureNotesCompanion
    extends UpdateCompanion<WordScriptureNoteRecord> {
  final Value<String> id;
  final Value<String> anchorKey;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int?> startVerse;
  final Value<int?> endVerse;
  final Value<String> body;
  final Value<int> createdAtUtcMicros;
  final Value<int> updatedAtUtcMicros;
  final Value<int> rowid;
  const WordScriptureNotesCompanion({
    this.id = const Value.absent(),
    this.anchorKey = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.body = const Value.absent(),
    this.createdAtUtcMicros = const Value.absent(),
    this.updatedAtUtcMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordScriptureNotesCompanion.insert({
    required String id,
    required String anchorKey,
    required String book,
    required int chapter,
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    required String body,
    required int createdAtUtcMicros,
    required int updatedAtUtcMicros,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       anchorKey = Value(anchorKey),
       book = Value(book),
       chapter = Value(chapter),
       body = Value(body),
       createdAtUtcMicros = Value(createdAtUtcMicros),
       updatedAtUtcMicros = Value(updatedAtUtcMicros);
  static Insertable<WordScriptureNoteRecord> custom({
    Expression<String>? id,
    Expression<String>? anchorKey,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<String>? body,
    Expression<int>? createdAtUtcMicros,
    Expression<int>? updatedAtUtcMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (anchorKey != null) 'anchor_key': anchorKey,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (body != null) 'body': body,
      if (createdAtUtcMicros != null)
        'created_at_utc_micros': createdAtUtcMicros,
      if (updatedAtUtcMicros != null)
        'updated_at_utc_micros': updatedAtUtcMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordScriptureNotesCompanion copyWith({
    Value<String>? id,
    Value<String>? anchorKey,
    Value<String>? book,
    Value<int>? chapter,
    Value<int?>? startVerse,
    Value<int?>? endVerse,
    Value<String>? body,
    Value<int>? createdAtUtcMicros,
    Value<int>? updatedAtUtcMicros,
    Value<int>? rowid,
  }) {
    return WordScriptureNotesCompanion(
      id: id ?? this.id,
      anchorKey: anchorKey ?? this.anchorKey,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      body: body ?? this.body,
      createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
      updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (anchorKey.present) {
      map['anchor_key'] = Variable<String>(anchorKey.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (body.present) {
      map['body'] = Variable<String>(body.value);
    }
    if (createdAtUtcMicros.present) {
      map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros.value);
    }
    if (updatedAtUtcMicros.present) {
      map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureNotesCompanion(')
          ..write('id: $id, ')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('body: $body, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordScriptureNoteAnchorsTable extends WordScriptureNoteAnchors
    with
        TableInfo<
          $WordScriptureNoteAnchorsTable,
          WordScriptureNoteAnchorRecord
        > {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordScriptureNoteAnchorsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _noteIdMeta = const VerificationMeta('noteId');
  @override
  late final GeneratedColumn<String> noteId = GeneratedColumn<String>(
    'note_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES word_scripture_notes (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _ordinalMeta = const VerificationMeta(
    'ordinal',
  );
  @override
  late final GeneratedColumn<int> ordinal = GeneratedColumn<int>(
    'ordinal',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _anchorKeyMeta = const VerificationMeta(
    'anchorKey',
  );
  @override
  late final GeneratedColumn<String> anchorKey = GeneratedColumn<String>(
    'anchor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    noteId,
    ordinal,
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_scripture_note_anchors';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordScriptureNoteAnchorRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('note_id')) {
      context.handle(
        _noteIdMeta,
        noteId.isAcceptableOrUnknown(data['note_id']!, _noteIdMeta),
      );
    } else if (isInserting) {
      context.missing(_noteIdMeta);
    }
    if (data.containsKey('ordinal')) {
      context.handle(
        _ordinalMeta,
        ordinal.isAcceptableOrUnknown(data['ordinal']!, _ordinalMeta),
      );
    } else if (isInserting) {
      context.missing(_ordinalMeta);
    }
    if (data.containsKey('anchor_key')) {
      context.handle(
        _anchorKeyMeta,
        anchorKey.isAcceptableOrUnknown(data['anchor_key']!, _anchorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorKeyMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {noteId, ordinal};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {noteId, anchorKey},
  ];
  @override
  WordScriptureNoteAnchorRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordScriptureNoteAnchorRecord(
      noteId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}note_id'],
      )!,
      ordinal: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}ordinal'],
      )!,
      anchorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_key'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
    );
  }

  @override
  $WordScriptureNoteAnchorsTable createAlias(String alias) {
    return $WordScriptureNoteAnchorsTable(attachedDatabase, alias);
  }
}

class WordScriptureNoteAnchorRecord extends DataClass
    implements Insertable<WordScriptureNoteAnchorRecord> {
  final String noteId;
  final int ordinal;
  final String anchorKey;
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;
  const WordScriptureNoteAnchorRecord({
    required this.noteId,
    required this.ordinal,
    required this.anchorKey,
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['note_id'] = Variable<String>(noteId);
    map['ordinal'] = Variable<int>(ordinal);
    map['anchor_key'] = Variable<String>(anchorKey);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    return map;
  }

  WordScriptureNoteAnchorsCompanion toCompanion(bool nullToAbsent) {
    return WordScriptureNoteAnchorsCompanion(
      noteId: Value(noteId),
      ordinal: Value(ordinal),
      anchorKey: Value(anchorKey),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
    );
  }

  factory WordScriptureNoteAnchorRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordScriptureNoteAnchorRecord(
      noteId: serializer.fromJson<String>(json['noteId']),
      ordinal: serializer.fromJson<int>(json['ordinal']),
      anchorKey: serializer.fromJson<String>(json['anchorKey']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'noteId': serializer.toJson<String>(noteId),
      'ordinal': serializer.toJson<int>(ordinal),
      'anchorKey': serializer.toJson<String>(anchorKey),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endVerse': serializer.toJson<int?>(endVerse),
    };
  }

  WordScriptureNoteAnchorRecord copyWith({
    String? noteId,
    int? ordinal,
    String? anchorKey,
    String? book,
    int? chapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
  }) => WordScriptureNoteAnchorRecord(
    noteId: noteId ?? this.noteId,
    ordinal: ordinal ?? this.ordinal,
    anchorKey: anchorKey ?? this.anchorKey,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
  );
  WordScriptureNoteAnchorRecord copyWithCompanion(
    WordScriptureNoteAnchorsCompanion data,
  ) {
    return WordScriptureNoteAnchorRecord(
      noteId: data.noteId.present ? data.noteId.value : this.noteId,
      ordinal: data.ordinal.present ? data.ordinal.value : this.ordinal,
      anchorKey: data.anchorKey.present ? data.anchorKey.value : this.anchorKey,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureNoteAnchorRecord(')
          ..write('noteId: $noteId, ')
          ..write('ordinal: $ordinal, ')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    noteId,
    ordinal,
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordScriptureNoteAnchorRecord &&
          other.noteId == this.noteId &&
          other.ordinal == this.ordinal &&
          other.anchorKey == this.anchorKey &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse);
}

class WordScriptureNoteAnchorsCompanion
    extends UpdateCompanion<WordScriptureNoteAnchorRecord> {
  final Value<String> noteId;
  final Value<int> ordinal;
  final Value<String> anchorKey;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int?> startVerse;
  final Value<int?> endVerse;
  final Value<int> rowid;
  const WordScriptureNoteAnchorsCompanion({
    this.noteId = const Value.absent(),
    this.ordinal = const Value.absent(),
    this.anchorKey = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordScriptureNoteAnchorsCompanion.insert({
    required String noteId,
    required int ordinal,
    required String anchorKey,
    required String book,
    required int chapter,
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : noteId = Value(noteId),
       ordinal = Value(ordinal),
       anchorKey = Value(anchorKey),
       book = Value(book),
       chapter = Value(chapter);
  static Insertable<WordScriptureNoteAnchorRecord> custom({
    Expression<String>? noteId,
    Expression<int>? ordinal,
    Expression<String>? anchorKey,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (noteId != null) 'note_id': noteId,
      if (ordinal != null) 'ordinal': ordinal,
      if (anchorKey != null) 'anchor_key': anchorKey,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordScriptureNoteAnchorsCompanion copyWith({
    Value<String>? noteId,
    Value<int>? ordinal,
    Value<String>? anchorKey,
    Value<String>? book,
    Value<int>? chapter,
    Value<int?>? startVerse,
    Value<int?>? endVerse,
    Value<int>? rowid,
  }) {
    return WordScriptureNoteAnchorsCompanion(
      noteId: noteId ?? this.noteId,
      ordinal: ordinal ?? this.ordinal,
      anchorKey: anchorKey ?? this.anchorKey,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (noteId.present) {
      map['note_id'] = Variable<String>(noteId.value);
    }
    if (ordinal.present) {
      map['ordinal'] = Variable<int>(ordinal.value);
    }
    if (anchorKey.present) {
      map['anchor_key'] = Variable<String>(anchorKey.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordScriptureNoteAnchorsCompanion(')
          ..write('noteId: $noteId, ')
          ..write('ordinal: $ordinal, ')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WordReadingHistoryTable extends WordReadingHistory
    with TableInfo<$WordReadingHistoryTable, WordReadingHistoryRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WordReadingHistoryTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _anchorKeyMeta = const VerificationMeta(
    'anchorKey',
  );
  @override
  late final GeneratedColumn<String> anchorKey = GeneratedColumn<String>(
    'anchor_key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bookMeta = const VerificationMeta('book');
  @override
  late final GeneratedColumn<String> book = GeneratedColumn<String>(
    'book',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _chapterMeta = const VerificationMeta(
    'chapter',
  );
  @override
  late final GeneratedColumn<int> chapter = GeneratedColumn<int>(
    'chapter',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _startVerseMeta = const VerificationMeta(
    'startVerse',
  );
  @override
  late final GeneratedColumn<int> startVerse = GeneratedColumn<int>(
    'start_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _endVerseMeta = const VerificationMeta(
    'endVerse',
  );
  @override
  late final GeneratedColumn<int> endVerse = GeneratedColumn<int>(
    'end_verse',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _openedAtUtcMicrosMeta = const VerificationMeta(
    'openedAtUtcMicros',
  );
  @override
  late final GeneratedColumn<int> openedAtUtcMicros = GeneratedColumn<int>(
    'opened_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    openedAtUtcMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'word_reading_history';
  @override
  VerificationContext validateIntegrity(
    Insertable<WordReadingHistoryRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('anchor_key')) {
      context.handle(
        _anchorKeyMeta,
        anchorKey.isAcceptableOrUnknown(data['anchor_key']!, _anchorKeyMeta),
      );
    } else if (isInserting) {
      context.missing(_anchorKeyMeta);
    }
    if (data.containsKey('book')) {
      context.handle(
        _bookMeta,
        book.isAcceptableOrUnknown(data['book']!, _bookMeta),
      );
    } else if (isInserting) {
      context.missing(_bookMeta);
    }
    if (data.containsKey('chapter')) {
      context.handle(
        _chapterMeta,
        chapter.isAcceptableOrUnknown(data['chapter']!, _chapterMeta),
      );
    } else if (isInserting) {
      context.missing(_chapterMeta);
    }
    if (data.containsKey('start_verse')) {
      context.handle(
        _startVerseMeta,
        startVerse.isAcceptableOrUnknown(data['start_verse']!, _startVerseMeta),
      );
    }
    if (data.containsKey('end_verse')) {
      context.handle(
        _endVerseMeta,
        endVerse.isAcceptableOrUnknown(data['end_verse']!, _endVerseMeta),
      );
    }
    if (data.containsKey('opened_at_utc_micros')) {
      context.handle(
        _openedAtUtcMicrosMeta,
        openedAtUtcMicros.isAcceptableOrUnknown(
          data['opened_at_utc_micros']!,
          _openedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_openedAtUtcMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {anchorKey};
  @override
  WordReadingHistoryRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WordReadingHistoryRecord(
      anchorKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}anchor_key'],
      )!,
      book: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}book'],
      )!,
      chapter: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}chapter'],
      )!,
      startVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}start_verse'],
      ),
      endVerse: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}end_verse'],
      ),
      openedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}opened_at_utc_micros'],
      )!,
    );
  }

  @override
  $WordReadingHistoryTable createAlias(String alias) {
    return $WordReadingHistoryTable(attachedDatabase, alias);
  }
}

class WordReadingHistoryRecord extends DataClass
    implements Insertable<WordReadingHistoryRecord> {
  final String anchorKey;
  final String book;
  final int chapter;
  final int? startVerse;
  final int? endVerse;
  final int openedAtUtcMicros;
  const WordReadingHistoryRecord({
    required this.anchorKey,
    required this.book,
    required this.chapter,
    this.startVerse,
    this.endVerse,
    required this.openedAtUtcMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['anchor_key'] = Variable<String>(anchorKey);
    map['book'] = Variable<String>(book);
    map['chapter'] = Variable<int>(chapter);
    if (!nullToAbsent || startVerse != null) {
      map['start_verse'] = Variable<int>(startVerse);
    }
    if (!nullToAbsent || endVerse != null) {
      map['end_verse'] = Variable<int>(endVerse);
    }
    map['opened_at_utc_micros'] = Variable<int>(openedAtUtcMicros);
    return map;
  }

  WordReadingHistoryCompanion toCompanion(bool nullToAbsent) {
    return WordReadingHistoryCompanion(
      anchorKey: Value(anchorKey),
      book: Value(book),
      chapter: Value(chapter),
      startVerse: startVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(startVerse),
      endVerse: endVerse == null && nullToAbsent
          ? const Value.absent()
          : Value(endVerse),
      openedAtUtcMicros: Value(openedAtUtcMicros),
    );
  }

  factory WordReadingHistoryRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WordReadingHistoryRecord(
      anchorKey: serializer.fromJson<String>(json['anchorKey']),
      book: serializer.fromJson<String>(json['book']),
      chapter: serializer.fromJson<int>(json['chapter']),
      startVerse: serializer.fromJson<int?>(json['startVerse']),
      endVerse: serializer.fromJson<int?>(json['endVerse']),
      openedAtUtcMicros: serializer.fromJson<int>(json['openedAtUtcMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'anchorKey': serializer.toJson<String>(anchorKey),
      'book': serializer.toJson<String>(book),
      'chapter': serializer.toJson<int>(chapter),
      'startVerse': serializer.toJson<int?>(startVerse),
      'endVerse': serializer.toJson<int?>(endVerse),
      'openedAtUtcMicros': serializer.toJson<int>(openedAtUtcMicros),
    };
  }

  WordReadingHistoryRecord copyWith({
    String? anchorKey,
    String? book,
    int? chapter,
    Value<int?> startVerse = const Value.absent(),
    Value<int?> endVerse = const Value.absent(),
    int? openedAtUtcMicros,
  }) => WordReadingHistoryRecord(
    anchorKey: anchorKey ?? this.anchorKey,
    book: book ?? this.book,
    chapter: chapter ?? this.chapter,
    startVerse: startVerse.present ? startVerse.value : this.startVerse,
    endVerse: endVerse.present ? endVerse.value : this.endVerse,
    openedAtUtcMicros: openedAtUtcMicros ?? this.openedAtUtcMicros,
  );
  WordReadingHistoryRecord copyWithCompanion(WordReadingHistoryCompanion data) {
    return WordReadingHistoryRecord(
      anchorKey: data.anchorKey.present ? data.anchorKey.value : this.anchorKey,
      book: data.book.present ? data.book.value : this.book,
      chapter: data.chapter.present ? data.chapter.value : this.chapter,
      startVerse: data.startVerse.present
          ? data.startVerse.value
          : this.startVerse,
      endVerse: data.endVerse.present ? data.endVerse.value : this.endVerse,
      openedAtUtcMicros: data.openedAtUtcMicros.present
          ? data.openedAtUtcMicros.value
          : this.openedAtUtcMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WordReadingHistoryRecord(')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('openedAtUtcMicros: $openedAtUtcMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    anchorKey,
    book,
    chapter,
    startVerse,
    endVerse,
    openedAtUtcMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WordReadingHistoryRecord &&
          other.anchorKey == this.anchorKey &&
          other.book == this.book &&
          other.chapter == this.chapter &&
          other.startVerse == this.startVerse &&
          other.endVerse == this.endVerse &&
          other.openedAtUtcMicros == this.openedAtUtcMicros);
}

class WordReadingHistoryCompanion
    extends UpdateCompanion<WordReadingHistoryRecord> {
  final Value<String> anchorKey;
  final Value<String> book;
  final Value<int> chapter;
  final Value<int?> startVerse;
  final Value<int?> endVerse;
  final Value<int> openedAtUtcMicros;
  final Value<int> rowid;
  const WordReadingHistoryCompanion({
    this.anchorKey = const Value.absent(),
    this.book = const Value.absent(),
    this.chapter = const Value.absent(),
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    this.openedAtUtcMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WordReadingHistoryCompanion.insert({
    required String anchorKey,
    required String book,
    required int chapter,
    this.startVerse = const Value.absent(),
    this.endVerse = const Value.absent(),
    required int openedAtUtcMicros,
    this.rowid = const Value.absent(),
  }) : anchorKey = Value(anchorKey),
       book = Value(book),
       chapter = Value(chapter),
       openedAtUtcMicros = Value(openedAtUtcMicros);
  static Insertable<WordReadingHistoryRecord> custom({
    Expression<String>? anchorKey,
    Expression<String>? book,
    Expression<int>? chapter,
    Expression<int>? startVerse,
    Expression<int>? endVerse,
    Expression<int>? openedAtUtcMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (anchorKey != null) 'anchor_key': anchorKey,
      if (book != null) 'book': book,
      if (chapter != null) 'chapter': chapter,
      if (startVerse != null) 'start_verse': startVerse,
      if (endVerse != null) 'end_verse': endVerse,
      if (openedAtUtcMicros != null) 'opened_at_utc_micros': openedAtUtcMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WordReadingHistoryCompanion copyWith({
    Value<String>? anchorKey,
    Value<String>? book,
    Value<int>? chapter,
    Value<int?>? startVerse,
    Value<int?>? endVerse,
    Value<int>? openedAtUtcMicros,
    Value<int>? rowid,
  }) {
    return WordReadingHistoryCompanion(
      anchorKey: anchorKey ?? this.anchorKey,
      book: book ?? this.book,
      chapter: chapter ?? this.chapter,
      startVerse: startVerse ?? this.startVerse,
      endVerse: endVerse ?? this.endVerse,
      openedAtUtcMicros: openedAtUtcMicros ?? this.openedAtUtcMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (anchorKey.present) {
      map['anchor_key'] = Variable<String>(anchorKey.value);
    }
    if (book.present) {
      map['book'] = Variable<String>(book.value);
    }
    if (chapter.present) {
      map['chapter'] = Variable<int>(chapter.value);
    }
    if (startVerse.present) {
      map['start_verse'] = Variable<int>(startVerse.value);
    }
    if (endVerse.present) {
      map['end_verse'] = Variable<int>(endVerse.value);
    }
    if (openedAtUtcMicros.present) {
      map['opened_at_utc_micros'] = Variable<int>(openedAtUtcMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WordReadingHistoryCompanion(')
          ..write('anchorKey: $anchorKey, ')
          ..write('book: $book, ')
          ..write('chapter: $chapter, ')
          ..write('startVerse: $startVerse, ')
          ..write('endVerse: $endVerse, ')
          ..write('openedAtUtcMicros: $openedAtUtcMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $TasksTable extends Tasks with TableInfo<$TasksTable, StoredTaskRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _dueDateMeta = const VerificationMeta(
    'dueDate',
  );
  @override
  late final GeneratedColumn<String> dueDate = GeneratedColumn<String>(
    'due_date',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isCompletedMeta = const VerificationMeta(
    'isCompleted',
  );
  @override
  late final GeneratedColumn<bool> isCompleted = GeneratedColumn<bool>(
    'is_completed',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_completed" IN (0, 1))',
    ),
  );
  static const VerificationMeta _completedAtUtcMicrosMeta =
      const VerificationMeta('completedAtUtcMicros');
  @override
  late final GeneratedColumn<int> completedAtUtcMicros = GeneratedColumn<int>(
    'completed_at_utc_micros',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _createdAtUtcMicrosMeta =
      const VerificationMeta('createdAtUtcMicros');
  @override
  late final GeneratedColumn<int> createdAtUtcMicros = GeneratedColumn<int>(
    'created_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtUtcMicrosMeta =
      const VerificationMeta('updatedAtUtcMicros');
  @override
  late final GeneratedColumn<int> updatedAtUtcMicros = GeneratedColumn<int>(
    'updated_at_utc_micros',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    title,
    dueDate,
    isCompleted,
    completedAtUtcMicros,
    createdAtUtcMicros,
    updatedAtUtcMicros,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<StoredTaskRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('due_date')) {
      context.handle(
        _dueDateMeta,
        dueDate.isAcceptableOrUnknown(data['due_date']!, _dueDateMeta),
      );
    }
    if (data.containsKey('is_completed')) {
      context.handle(
        _isCompletedMeta,
        isCompleted.isAcceptableOrUnknown(
          data['is_completed']!,
          _isCompletedMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_isCompletedMeta);
    }
    if (data.containsKey('completed_at_utc_micros')) {
      context.handle(
        _completedAtUtcMicrosMeta,
        completedAtUtcMicros.isAcceptableOrUnknown(
          data['completed_at_utc_micros']!,
          _completedAtUtcMicrosMeta,
        ),
      );
    }
    if (data.containsKey('created_at_utc_micros')) {
      context.handle(
        _createdAtUtcMicrosMeta,
        createdAtUtcMicros.isAcceptableOrUnknown(
          data['created_at_utc_micros']!,
          _createdAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_createdAtUtcMicrosMeta);
    }
    if (data.containsKey('updated_at_utc_micros')) {
      context.handle(
        _updatedAtUtcMicrosMeta,
        updatedAtUtcMicros.isAcceptableOrUnknown(
          data['updated_at_utc_micros']!,
          _updatedAtUtcMicrosMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_updatedAtUtcMicrosMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  StoredTaskRecord map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return StoredTaskRecord(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      dueDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_date'],
      ),
      isCompleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_completed'],
      )!,
      completedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at_utc_micros'],
      ),
      createdAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at_utc_micros'],
      )!,
      updatedAtUtcMicros: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at_utc_micros'],
      )!,
    );
  }

  @override
  $TasksTable createAlias(String alias) {
    return $TasksTable(attachedDatabase, alias);
  }
}

class StoredTaskRecord extends DataClass
    implements Insertable<StoredTaskRecord> {
  final String id;
  final String title;
  final String? dueDate;
  final bool isCompleted;
  final int? completedAtUtcMicros;
  final int createdAtUtcMicros;
  final int updatedAtUtcMicros;
  const StoredTaskRecord({
    required this.id,
    required this.title,
    this.dueDate,
    required this.isCompleted,
    this.completedAtUtcMicros,
    required this.createdAtUtcMicros,
    required this.updatedAtUtcMicros,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || dueDate != null) {
      map['due_date'] = Variable<String>(dueDate);
    }
    map['is_completed'] = Variable<bool>(isCompleted);
    if (!nullToAbsent || completedAtUtcMicros != null) {
      map['completed_at_utc_micros'] = Variable<int>(completedAtUtcMicros);
    }
    map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros);
    map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros);
    return map;
  }

  TasksCompanion toCompanion(bool nullToAbsent) {
    return TasksCompanion(
      id: Value(id),
      title: Value(title),
      dueDate: dueDate == null && nullToAbsent
          ? const Value.absent()
          : Value(dueDate),
      isCompleted: Value(isCompleted),
      completedAtUtcMicros: completedAtUtcMicros == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAtUtcMicros),
      createdAtUtcMicros: Value(createdAtUtcMicros),
      updatedAtUtcMicros: Value(updatedAtUtcMicros),
    );
  }

  factory StoredTaskRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return StoredTaskRecord(
      id: serializer.fromJson<String>(json['id']),
      title: serializer.fromJson<String>(json['title']),
      dueDate: serializer.fromJson<String?>(json['dueDate']),
      isCompleted: serializer.fromJson<bool>(json['isCompleted']),
      completedAtUtcMicros: serializer.fromJson<int?>(
        json['completedAtUtcMicros'],
      ),
      createdAtUtcMicros: serializer.fromJson<int>(json['createdAtUtcMicros']),
      updatedAtUtcMicros: serializer.fromJson<int>(json['updatedAtUtcMicros']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'title': serializer.toJson<String>(title),
      'dueDate': serializer.toJson<String?>(dueDate),
      'isCompleted': serializer.toJson<bool>(isCompleted),
      'completedAtUtcMicros': serializer.toJson<int?>(completedAtUtcMicros),
      'createdAtUtcMicros': serializer.toJson<int>(createdAtUtcMicros),
      'updatedAtUtcMicros': serializer.toJson<int>(updatedAtUtcMicros),
    };
  }

  StoredTaskRecord copyWith({
    String? id,
    String? title,
    Value<String?> dueDate = const Value.absent(),
    bool? isCompleted,
    Value<int?> completedAtUtcMicros = const Value.absent(),
    int? createdAtUtcMicros,
    int? updatedAtUtcMicros,
  }) => StoredTaskRecord(
    id: id ?? this.id,
    title: title ?? this.title,
    dueDate: dueDate.present ? dueDate.value : this.dueDate,
    isCompleted: isCompleted ?? this.isCompleted,
    completedAtUtcMicros: completedAtUtcMicros.present
        ? completedAtUtcMicros.value
        : this.completedAtUtcMicros,
    createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
    updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
  );
  StoredTaskRecord copyWithCompanion(TasksCompanion data) {
    return StoredTaskRecord(
      id: data.id.present ? data.id.value : this.id,
      title: data.title.present ? data.title.value : this.title,
      dueDate: data.dueDate.present ? data.dueDate.value : this.dueDate,
      isCompleted: data.isCompleted.present
          ? data.isCompleted.value
          : this.isCompleted,
      completedAtUtcMicros: data.completedAtUtcMicros.present
          ? data.completedAtUtcMicros.value
          : this.completedAtUtcMicros,
      createdAtUtcMicros: data.createdAtUtcMicros.present
          ? data.createdAtUtcMicros.value
          : this.createdAtUtcMicros,
      updatedAtUtcMicros: data.updatedAtUtcMicros.present
          ? data.updatedAtUtcMicros.value
          : this.updatedAtUtcMicros,
    );
  }

  @override
  String toString() {
    return (StringBuffer('StoredTaskRecord(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAtUtcMicros: $completedAtUtcMicros, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    dueDate,
    isCompleted,
    completedAtUtcMicros,
    createdAtUtcMicros,
    updatedAtUtcMicros,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is StoredTaskRecord &&
          other.id == this.id &&
          other.title == this.title &&
          other.dueDate == this.dueDate &&
          other.isCompleted == this.isCompleted &&
          other.completedAtUtcMicros == this.completedAtUtcMicros &&
          other.createdAtUtcMicros == this.createdAtUtcMicros &&
          other.updatedAtUtcMicros == this.updatedAtUtcMicros);
}

class TasksCompanion extends UpdateCompanion<StoredTaskRecord> {
  final Value<String> id;
  final Value<String> title;
  final Value<String?> dueDate;
  final Value<bool> isCompleted;
  final Value<int?> completedAtUtcMicros;
  final Value<int> createdAtUtcMicros;
  final Value<int> updatedAtUtcMicros;
  final Value<int> rowid;
  const TasksCompanion({
    this.id = const Value.absent(),
    this.title = const Value.absent(),
    this.dueDate = const Value.absent(),
    this.isCompleted = const Value.absent(),
    this.completedAtUtcMicros = const Value.absent(),
    this.createdAtUtcMicros = const Value.absent(),
    this.updatedAtUtcMicros = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  TasksCompanion.insert({
    required String id,
    required String title,
    this.dueDate = const Value.absent(),
    required bool isCompleted,
    this.completedAtUtcMicros = const Value.absent(),
    required int createdAtUtcMicros,
    required int updatedAtUtcMicros,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       title = Value(title),
       isCompleted = Value(isCompleted),
       createdAtUtcMicros = Value(createdAtUtcMicros),
       updatedAtUtcMicros = Value(updatedAtUtcMicros);
  static Insertable<StoredTaskRecord> custom({
    Expression<String>? id,
    Expression<String>? title,
    Expression<String>? dueDate,
    Expression<bool>? isCompleted,
    Expression<int>? completedAtUtcMicros,
    Expression<int>? createdAtUtcMicros,
    Expression<int>? updatedAtUtcMicros,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (dueDate != null) 'due_date': dueDate,
      if (isCompleted != null) 'is_completed': isCompleted,
      if (completedAtUtcMicros != null)
        'completed_at_utc_micros': completedAtUtcMicros,
      if (createdAtUtcMicros != null)
        'created_at_utc_micros': createdAtUtcMicros,
      if (updatedAtUtcMicros != null)
        'updated_at_utc_micros': updatedAtUtcMicros,
      if (rowid != null) 'rowid': rowid,
    });
  }

  TasksCompanion copyWith({
    Value<String>? id,
    Value<String>? title,
    Value<String?>? dueDate,
    Value<bool>? isCompleted,
    Value<int?>? completedAtUtcMicros,
    Value<int>? createdAtUtcMicros,
    Value<int>? updatedAtUtcMicros,
    Value<int>? rowid,
  }) {
    return TasksCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAtUtcMicros: completedAtUtcMicros ?? this.completedAtUtcMicros,
      createdAtUtcMicros: createdAtUtcMicros ?? this.createdAtUtcMicros,
      updatedAtUtcMicros: updatedAtUtcMicros ?? this.updatedAtUtcMicros,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (dueDate.present) {
      map['due_date'] = Variable<String>(dueDate.value);
    }
    if (isCompleted.present) {
      map['is_completed'] = Variable<bool>(isCompleted.value);
    }
    if (completedAtUtcMicros.present) {
      map['completed_at_utc_micros'] = Variable<int>(
        completedAtUtcMicros.value,
      );
    }
    if (createdAtUtcMicros.present) {
      map['created_at_utc_micros'] = Variable<int>(createdAtUtcMicros.value);
    }
    if (updatedAtUtcMicros.present) {
      map['updated_at_utc_micros'] = Variable<int>(updatedAtUtcMicros.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TasksCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('dueDate: $dueDate, ')
          ..write('isCompleted: $isCompleted, ')
          ..write('completedAtUtcMicros: $completedAtUtcMicros, ')
          ..write('createdAtUtcMicros: $createdAtUtcMicros, ')
          ..write('updatedAtUtcMicros: $updatedAtUtcMicros, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyPriorityTasksTable extends DailyPriorityTasks
    with TableInfo<$DailyPriorityTasksTable, DailyPriorityTaskRecord> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyPriorityTasksTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _priorityDateMeta = const VerificationMeta(
    'priorityDate',
  );
  @override
  late final GeneratedColumn<String> priorityDate = GeneratedColumn<String>(
    'priority_date',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _taskIdMeta = const VerificationMeta('taskId');
  @override
  late final GeneratedColumn<String> taskId = GeneratedColumn<String>(
    'task_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES tasks (id) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [priorityDate, taskId, position];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_priority_tasks';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyPriorityTaskRecord> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('priority_date')) {
      context.handle(
        _priorityDateMeta,
        priorityDate.isAcceptableOrUnknown(
          data['priority_date']!,
          _priorityDateMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_priorityDateMeta);
    }
    if (data.containsKey('task_id')) {
      context.handle(
        _taskIdMeta,
        taskId.isAcceptableOrUnknown(data['task_id']!, _taskIdMeta),
      );
    } else if (isInserting) {
      context.missing(_taskIdMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {priorityDate, taskId};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {priorityDate, position},
  ];
  @override
  DailyPriorityTaskRecord map(
    Map<String, dynamic> data, {
    String? tablePrefix,
  }) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyPriorityTaskRecord(
      priorityDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}priority_date'],
      )!,
      taskId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}task_id'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
    );
  }

  @override
  $DailyPriorityTasksTable createAlias(String alias) {
    return $DailyPriorityTasksTable(attachedDatabase, alias);
  }
}

class DailyPriorityTaskRecord extends DataClass
    implements Insertable<DailyPriorityTaskRecord> {
  final String priorityDate;
  final String taskId;
  final int position;
  const DailyPriorityTaskRecord({
    required this.priorityDate,
    required this.taskId,
    required this.position,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['priority_date'] = Variable<String>(priorityDate);
    map['task_id'] = Variable<String>(taskId);
    map['position'] = Variable<int>(position);
    return map;
  }

  DailyPriorityTasksCompanion toCompanion(bool nullToAbsent) {
    return DailyPriorityTasksCompanion(
      priorityDate: Value(priorityDate),
      taskId: Value(taskId),
      position: Value(position),
    );
  }

  factory DailyPriorityTaskRecord.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyPriorityTaskRecord(
      priorityDate: serializer.fromJson<String>(json['priorityDate']),
      taskId: serializer.fromJson<String>(json['taskId']),
      position: serializer.fromJson<int>(json['position']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'priorityDate': serializer.toJson<String>(priorityDate),
      'taskId': serializer.toJson<String>(taskId),
      'position': serializer.toJson<int>(position),
    };
  }

  DailyPriorityTaskRecord copyWith({
    String? priorityDate,
    String? taskId,
    int? position,
  }) => DailyPriorityTaskRecord(
    priorityDate: priorityDate ?? this.priorityDate,
    taskId: taskId ?? this.taskId,
    position: position ?? this.position,
  );
  DailyPriorityTaskRecord copyWithCompanion(DailyPriorityTasksCompanion data) {
    return DailyPriorityTaskRecord(
      priorityDate: data.priorityDate.present
          ? data.priorityDate.value
          : this.priorityDate,
      taskId: data.taskId.present ? data.taskId.value : this.taskId,
      position: data.position.present ? data.position.value : this.position,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyPriorityTaskRecord(')
          ..write('priorityDate: $priorityDate, ')
          ..write('taskId: $taskId, ')
          ..write('position: $position')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(priorityDate, taskId, position);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyPriorityTaskRecord &&
          other.priorityDate == this.priorityDate &&
          other.taskId == this.taskId &&
          other.position == this.position);
}

class DailyPriorityTasksCompanion
    extends UpdateCompanion<DailyPriorityTaskRecord> {
  final Value<String> priorityDate;
  final Value<String> taskId;
  final Value<int> position;
  final Value<int> rowid;
  const DailyPriorityTasksCompanion({
    this.priorityDate = const Value.absent(),
    this.taskId = const Value.absent(),
    this.position = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyPriorityTasksCompanion.insert({
    required String priorityDate,
    required String taskId,
    required int position,
    this.rowid = const Value.absent(),
  }) : priorityDate = Value(priorityDate),
       taskId = Value(taskId),
       position = Value(position);
  static Insertable<DailyPriorityTaskRecord> custom({
    Expression<String>? priorityDate,
    Expression<String>? taskId,
    Expression<int>? position,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (priorityDate != null) 'priority_date': priorityDate,
      if (taskId != null) 'task_id': taskId,
      if (position != null) 'position': position,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyPriorityTasksCompanion copyWith({
    Value<String>? priorityDate,
    Value<String>? taskId,
    Value<int>? position,
    Value<int>? rowid,
  }) {
    return DailyPriorityTasksCompanion(
      priorityDate: priorityDate ?? this.priorityDate,
      taskId: taskId ?? this.taskId,
      position: position ?? this.position,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (priorityDate.present) {
      map['priority_date'] = Variable<String>(priorityDate.value);
    }
    if (taskId.present) {
      map['task_id'] = Variable<String>(taskId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyPriorityTasksCompanion(')
          ..write('priorityDate: $priorityDate, ')
          ..write('taskId: $taskId, ')
          ..write('position: $position, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $BiblePlansTable biblePlans = $BiblePlansTable(this);
  late final $BiblePlanSourceItemsTable biblePlanSourceItems =
      $BiblePlanSourceItemsTable(this);
  late final $BiblePlanScheduleEntriesTable biblePlanScheduleEntries =
      $BiblePlanScheduleEntriesTable(this);
  late final $BiblePlanScheduleItemsTable biblePlanScheduleItems =
      $BiblePlanScheduleItemsTable(this);
  late final $WordTranslationStatesTable wordTranslationStates =
      $WordTranslationStatesTable(this);
  late final $LocalMigrationMetadataTable localMigrationMetadata =
      $LocalMigrationMetadataTable(this);
  late final $WordReaderStatesTable wordReaderStates = $WordReaderStatesTable(
    this,
  );
  late final $WordAudioPreferencesTable wordAudioPreferences =
      $WordAudioPreferencesTable(this);
  late final $WordScriptureBookmarksTable wordScriptureBookmarks =
      $WordScriptureBookmarksTable(this);
  late final $WordScriptureHighlightsTable wordScriptureHighlights =
      $WordScriptureHighlightsTable(this);
  late final $WordScriptureNotesTable wordScriptureNotes =
      $WordScriptureNotesTable(this);
  late final $WordScriptureNoteAnchorsTable wordScriptureNoteAnchors =
      $WordScriptureNoteAnchorsTable(this);
  late final $WordReadingHistoryTable wordReadingHistory =
      $WordReadingHistoryTable(this);
  late final $TasksTable tasks = $TasksTable(this);
  late final $DailyPriorityTasksTable dailyPriorityTasks =
      $DailyPriorityTasksTable(this);
  late final Index idxBiblePlanScheduleEntriesPlanDate = Index(
    'idx_bible_plan_schedule_entries_plan_date',
    'CREATE INDEX idx_bible_plan_schedule_entries_plan_date ON bible_plan_schedule_entries (plan_id, scheduled_date)',
  );
  late final Index idxTasksOpenDueDate = Index(
    'idx_tasks_open_due_date',
    'CREATE INDEX idx_tasks_open_due_date ON tasks (is_completed, due_date)',
  );
  late final Index idxDailyPriorityTasksDatePosition = Index(
    'idx_daily_priority_tasks_date_position',
    'CREATE INDEX idx_daily_priority_tasks_date_position ON daily_priority_tasks (priority_date, position)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    biblePlans,
    biblePlanSourceItems,
    biblePlanScheduleEntries,
    biblePlanScheduleItems,
    wordTranslationStates,
    localMigrationMetadata,
    wordReaderStates,
    wordAudioPreferences,
    wordScriptureBookmarks,
    wordScriptureHighlights,
    wordScriptureNotes,
    wordScriptureNoteAnchors,
    wordReadingHistory,
    tasks,
    dailyPriorityTasks,
    idxBiblePlanScheduleEntriesPlanDate,
    idxTasksOpenDueDate,
    idxDailyPriorityTasksDatePosition,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bible_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('bible_plan_source_items', kind: UpdateKind.delete)],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bible_plans',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('bible_plan_schedule_entries', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'bible_plan_schedule_entries',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('bible_plan_schedule_items', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'word_scripture_notes',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [
        TableUpdate('word_scripture_note_anchors', kind: UpdateKind.delete),
      ],
    ),
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'tasks',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('daily_priority_tasks', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$BiblePlansTableCreateCompanionBuilder =
    BiblePlansCompanion Function({
      required String id,
      Value<String?> legacyId,
      required int position,
      required String title,
      required String defaultTranslationId,
      required int createdAtUtcMicros,
      required String startDate,
      required String endDate,
      required int readingWeekdaysMask,
      required int reminderMinutesLocal,
      Value<String?> templateId,
      Value<int> rowid,
    });
typedef $$BiblePlansTableUpdateCompanionBuilder =
    BiblePlansCompanion Function({
      Value<String> id,
      Value<String?> legacyId,
      Value<int> position,
      Value<String> title,
      Value<String> defaultTranslationId,
      Value<int> createdAtUtcMicros,
      Value<String> startDate,
      Value<String> endDate,
      Value<int> readingWeekdaysMask,
      Value<int> reminderMinutesLocal,
      Value<String?> templateId,
      Value<int> rowid,
    });

final class $$BiblePlansTableReferences
    extends BaseReferences<_$AppDatabase, $BiblePlansTable, BiblePlanRecord> {
  $$BiblePlansTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $BiblePlanSourceItemsTable,
    List<BiblePlanSourceItemRecord>
  >
  _biblePlanSourceItemsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.biblePlanSourceItems,
        aliasName: 'bible_plans__id__bible_plan_source_items__plan_id',
      );

  $$BiblePlanSourceItemsTableProcessedTableManager
  get biblePlanSourceItemsRefs {
    final manager = $$BiblePlanSourceItemsTableTableManager(
      $_db,
      $_db.biblePlanSourceItems,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _biblePlanSourceItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static MultiTypedResultKey<
    $BiblePlanScheduleEntriesTable,
    List<BiblePlanScheduleEntryRecord>
  >
  _biblePlanScheduleEntriesRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.biblePlanScheduleEntries,
        aliasName: 'bible_plans__id__bible_plan_schedule_entries__plan_id',
      );

  $$BiblePlanScheduleEntriesTableProcessedTableManager
  get biblePlanScheduleEntriesRefs {
    final manager = $$BiblePlanScheduleEntriesTableTableManager(
      $_db,
      $_db.biblePlanScheduleEntries,
    ).filter((f) => f.planId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _biblePlanScheduleEntriesRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BiblePlansTableFilterComposer
    extends Composer<_$AppDatabase, $BiblePlansTable> {
  $$BiblePlansTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get defaultTranslationId => $composableBuilder(
    column: $table.defaultTranslationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get readingWeekdaysMask => $composableBuilder(
    column: $table.readingWeekdaysMask,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutesLocal => $composableBuilder(
    column: $table.reminderMinutesLocal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> biblePlanSourceItemsRefs(
    Expression<bool> Function($$BiblePlanSourceItemsTableFilterComposer f) f,
  ) {
    final $$BiblePlanSourceItemsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.biblePlanSourceItems,
      getReferencedColumn: (t) => t.planId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlanSourceItemsTableFilterComposer(
            $db: $db,
            $table: $db.biblePlanSourceItems,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  Expression<bool> biblePlanScheduleEntriesRefs(
    Expression<bool> Function($$BiblePlanScheduleEntriesTableFilterComposer f)
    f,
  ) {
    final $$BiblePlanScheduleEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.biblePlanScheduleEntries,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleEntriesTableFilterComposer(
                $db: $db,
                $table: $db.biblePlanScheduleEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BiblePlansTableOrderingComposer
    extends Composer<_$AppDatabase, $BiblePlansTable> {
  $$BiblePlansTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get legacyId => $composableBuilder(
    column: $table.legacyId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get defaultTranslationId => $composableBuilder(
    column: $table.defaultTranslationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get startDate => $composableBuilder(
    column: $table.startDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get endDate => $composableBuilder(
    column: $table.endDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get readingWeekdaysMask => $composableBuilder(
    column: $table.readingWeekdaysMask,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutesLocal => $composableBuilder(
    column: $table.reminderMinutesLocal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$BiblePlansTableAnnotationComposer
    extends Composer<_$AppDatabase, $BiblePlansTable> {
  $$BiblePlansTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get legacyId =>
      $composableBuilder(column: $table.legacyId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get defaultTranslationId => $composableBuilder(
    column: $table.defaultTranslationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get startDate =>
      $composableBuilder(column: $table.startDate, builder: (column) => column);

  GeneratedColumn<String> get endDate =>
      $composableBuilder(column: $table.endDate, builder: (column) => column);

  GeneratedColumn<int> get readingWeekdaysMask => $composableBuilder(
    column: $table.readingWeekdaysMask,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutesLocal => $composableBuilder(
    column: $table.reminderMinutesLocal,
    builder: (column) => column,
  );

  GeneratedColumn<String> get templateId => $composableBuilder(
    column: $table.templateId,
    builder: (column) => column,
  );

  Expression<T> biblePlanSourceItemsRefs<T extends Object>(
    Expression<T> Function($$BiblePlanSourceItemsTableAnnotationComposer a) f,
  ) {
    final $$BiblePlanSourceItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.biblePlanSourceItems,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanSourceItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.biblePlanSourceItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }

  Expression<T> biblePlanScheduleEntriesRefs<T extends Object>(
    Expression<T> Function($$BiblePlanScheduleEntriesTableAnnotationComposer a)
    f,
  ) {
    final $$BiblePlanScheduleEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.biblePlanScheduleEntries,
          getReferencedColumn: (t) => t.planId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.biblePlanScheduleEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BiblePlansTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BiblePlansTable,
          BiblePlanRecord,
          $$BiblePlansTableFilterComposer,
          $$BiblePlansTableOrderingComposer,
          $$BiblePlansTableAnnotationComposer,
          $$BiblePlansTableCreateCompanionBuilder,
          $$BiblePlansTableUpdateCompanionBuilder,
          (BiblePlanRecord, $$BiblePlansTableReferences),
          BiblePlanRecord,
          PrefetchHooks Function({
            bool biblePlanSourceItemsRefs,
            bool biblePlanScheduleEntriesRefs,
          })
        > {
  $$BiblePlansTableTableManager(_$AppDatabase db, $BiblePlansTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BiblePlansTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BiblePlansTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$BiblePlansTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> legacyId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> defaultTranslationId = const Value.absent(),
                Value<int> createdAtUtcMicros = const Value.absent(),
                Value<String> startDate = const Value.absent(),
                Value<String> endDate = const Value.absent(),
                Value<int> readingWeekdaysMask = const Value.absent(),
                Value<int> reminderMinutesLocal = const Value.absent(),
                Value<String?> templateId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlansCompanion(
                id: id,
                legacyId: legacyId,
                position: position,
                title: title,
                defaultTranslationId: defaultTranslationId,
                createdAtUtcMicros: createdAtUtcMicros,
                startDate: startDate,
                endDate: endDate,
                readingWeekdaysMask: readingWeekdaysMask,
                reminderMinutesLocal: reminderMinutesLocal,
                templateId: templateId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> legacyId = const Value.absent(),
                required int position,
                required String title,
                required String defaultTranslationId,
                required int createdAtUtcMicros,
                required String startDate,
                required String endDate,
                required int readingWeekdaysMask,
                required int reminderMinutesLocal,
                Value<String?> templateId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlansCompanion.insert(
                id: id,
                legacyId: legacyId,
                position: position,
                title: title,
                defaultTranslationId: defaultTranslationId,
                createdAtUtcMicros: createdAtUtcMicros,
                startDate: startDate,
                endDate: endDate,
                readingWeekdaysMask: readingWeekdaysMask,
                reminderMinutesLocal: reminderMinutesLocal,
                templateId: templateId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BiblePlansTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                biblePlanSourceItemsRefs = false,
                biblePlanScheduleEntriesRefs = false,
              }) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (biblePlanSourceItemsRefs) db.biblePlanSourceItems,
                    if (biblePlanScheduleEntriesRefs)
                      db.biblePlanScheduleEntries,
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (biblePlanSourceItemsRefs)
                        await $_getPrefetchedData<
                          BiblePlanRecord,
                          $BiblePlansTable,
                          BiblePlanSourceItemRecord
                        >(
                          currentTable: table,
                          referencedTable: $$BiblePlansTableReferences
                              ._biblePlanSourceItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BiblePlansTableReferences(
                                db,
                                table,
                                p0,
                              ).biblePlanSourceItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (biblePlanScheduleEntriesRefs)
                        await $_getPrefetchedData<
                          BiblePlanRecord,
                          $BiblePlansTable,
                          BiblePlanScheduleEntryRecord
                        >(
                          currentTable: table,
                          referencedTable: $$BiblePlansTableReferences
                              ._biblePlanScheduleEntriesRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BiblePlansTableReferences(
                                db,
                                table,
                                p0,
                              ).biblePlanScheduleEntriesRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.planId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BiblePlansTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BiblePlansTable,
      BiblePlanRecord,
      $$BiblePlansTableFilterComposer,
      $$BiblePlansTableOrderingComposer,
      $$BiblePlansTableAnnotationComposer,
      $$BiblePlansTableCreateCompanionBuilder,
      $$BiblePlansTableUpdateCompanionBuilder,
      (BiblePlanRecord, $$BiblePlansTableReferences),
      BiblePlanRecord,
      PrefetchHooks Function({
        bool biblePlanSourceItemsRefs,
        bool biblePlanScheduleEntriesRefs,
      })
    >;
typedef $$BiblePlanSourceItemsTableCreateCompanionBuilder =
    BiblePlanSourceItemsCompanion Function({
      required String id,
      required String planId,
      required int position,
      required String book,
      required int startChapter,
      Value<int?> startVerse,
      Value<int?> endChapter,
      Value<int?> endVerse,
      Value<int> rowid,
    });
typedef $$BiblePlanSourceItemsTableUpdateCompanionBuilder =
    BiblePlanSourceItemsCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<int> position,
      Value<String> book,
      Value<int> startChapter,
      Value<int?> startVerse,
      Value<int?> endChapter,
      Value<int?> endVerse,
      Value<int> rowid,
    });

final class $$BiblePlanSourceItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BiblePlanSourceItemsTable,
          BiblePlanSourceItemRecord
        > {
  $$BiblePlanSourceItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BiblePlansTable _planIdTable(_$AppDatabase db) => db.biblePlans
      .createAlias('bible_plan_source_items__plan_id__bible_plans__id');

  $$BiblePlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$BiblePlansTableTableManager(
      $_db,
      $_db.biblePlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BiblePlanSourceItemsTableFilterComposer
    extends Composer<_$AppDatabase, $BiblePlanSourceItemsTable> {
  $$BiblePlanSourceItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  $$BiblePlansTableFilterComposer get planId {
    final $$BiblePlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.biblePlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlansTableFilterComposer(
            $db: $db,
            $table: $db.biblePlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiblePlanSourceItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $BiblePlanSourceItemsTable> {
  $$BiblePlanSourceItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  $$BiblePlansTableOrderingComposer get planId {
    final $$BiblePlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.biblePlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlansTableOrderingComposer(
            $db: $db,
            $table: $db.biblePlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiblePlanSourceItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BiblePlanSourceItemsTable> {
  $$BiblePlanSourceItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  $$BiblePlansTableAnnotationComposer get planId {
    final $$BiblePlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.biblePlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlansTableAnnotationComposer(
            $db: $db,
            $table: $db.biblePlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiblePlanSourceItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BiblePlanSourceItemsTable,
          BiblePlanSourceItemRecord,
          $$BiblePlanSourceItemsTableFilterComposer,
          $$BiblePlanSourceItemsTableOrderingComposer,
          $$BiblePlanSourceItemsTableAnnotationComposer,
          $$BiblePlanSourceItemsTableCreateCompanionBuilder,
          $$BiblePlanSourceItemsTableUpdateCompanionBuilder,
          (BiblePlanSourceItemRecord, $$BiblePlanSourceItemsTableReferences),
          BiblePlanSourceItemRecord,
          PrefetchHooks Function({bool planId})
        > {
  $$BiblePlanSourceItemsTableTableManager(
    _$AppDatabase db,
    $BiblePlanSourceItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BiblePlanSourceItemsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$BiblePlanSourceItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BiblePlanSourceItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> startChapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endChapter = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlanSourceItemsCompanion(
                id: id,
                planId: planId,
                position: position,
                book: book,
                startChapter: startChapter,
                startVerse: startVerse,
                endChapter: endChapter,
                endVerse: endVerse,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required int position,
                required String book,
                required int startChapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endChapter = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlanSourceItemsCompanion.insert(
                id: id,
                planId: planId,
                position: position,
                book: book,
                startChapter: startChapter,
                startVerse: startVerse,
                endChapter: endChapter,
                endVerse: endVerse,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BiblePlanSourceItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({planId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (planId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.planId,
                                referencedTable:
                                    $$BiblePlanSourceItemsTableReferences
                                        ._planIdTable(db),
                                referencedColumn:
                                    $$BiblePlanSourceItemsTableReferences
                                        ._planIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BiblePlanSourceItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BiblePlanSourceItemsTable,
      BiblePlanSourceItemRecord,
      $$BiblePlanSourceItemsTableFilterComposer,
      $$BiblePlanSourceItemsTableOrderingComposer,
      $$BiblePlanSourceItemsTableAnnotationComposer,
      $$BiblePlanSourceItemsTableCreateCompanionBuilder,
      $$BiblePlanSourceItemsTableUpdateCompanionBuilder,
      (BiblePlanSourceItemRecord, $$BiblePlanSourceItemsTableReferences),
      BiblePlanSourceItemRecord,
      PrefetchHooks Function({bool planId})
    >;
typedef $$BiblePlanScheduleEntriesTableCreateCompanionBuilder =
    BiblePlanScheduleEntriesCompanion Function({
      required String id,
      required String planId,
      required int position,
      required String scheduledDate,
      required bool isCompleted,
      Value<int?> completedAtUtcMicros,
      Value<String?> translationOverrideId,
      Value<int> rowid,
    });
typedef $$BiblePlanScheduleEntriesTableUpdateCompanionBuilder =
    BiblePlanScheduleEntriesCompanion Function({
      Value<String> id,
      Value<String> planId,
      Value<int> position,
      Value<String> scheduledDate,
      Value<bool> isCompleted,
      Value<int?> completedAtUtcMicros,
      Value<String?> translationOverrideId,
      Value<int> rowid,
    });

final class $$BiblePlanScheduleEntriesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BiblePlanScheduleEntriesTable,
          BiblePlanScheduleEntryRecord
        > {
  $$BiblePlanScheduleEntriesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BiblePlansTable _planIdTable(_$AppDatabase db) => db.biblePlans
      .createAlias('bible_plan_schedule_entries__plan_id__bible_plans__id');

  $$BiblePlansTableProcessedTableManager get planId {
    final $_column = $_itemColumn<String>('plan_id')!;

    final manager = $$BiblePlansTableTableManager(
      $_db,
      $_db.biblePlans,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_planIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static MultiTypedResultKey<
    $BiblePlanScheduleItemsTable,
    List<BiblePlanScheduleItemRecord>
  >
  _biblePlanScheduleItemsRefsTable(
    _$AppDatabase db,
  ) => MultiTypedResultKey.fromTable(
    db.biblePlanScheduleItems,
    aliasName:
        'bible_plan_schedule_entries__id__bible_plan_schedule_items__schedule_entry_id',
  );

  $$BiblePlanScheduleItemsTableProcessedTableManager
  get biblePlanScheduleItemsRefs {
    final manager =
        $$BiblePlanScheduleItemsTableTableManager(
          $_db,
          $_db.biblePlanScheduleItems,
        ).filter(
          (f) => f.scheduleEntryId.id.sqlEquals($_itemColumn<String>('id')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _biblePlanScheduleItemsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$BiblePlanScheduleEntriesTableFilterComposer
    extends Composer<_$AppDatabase, $BiblePlanScheduleEntriesTable> {
  $$BiblePlanScheduleEntriesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationOverrideId => $composableBuilder(
    column: $table.translationOverrideId,
    builder: (column) => ColumnFilters(column),
  );

  $$BiblePlansTableFilterComposer get planId {
    final $$BiblePlansTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.biblePlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlansTableFilterComposer(
            $db: $db,
            $table: $db.biblePlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<bool> biblePlanScheduleItemsRefs(
    Expression<bool> Function($$BiblePlanScheduleItemsTableFilterComposer f) f,
  ) {
    final $$BiblePlanScheduleItemsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.biblePlanScheduleItems,
          getReferencedColumn: (t) => t.scheduleEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleItemsTableFilterComposer(
                $db: $db,
                $table: $db.biblePlanScheduleItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BiblePlanScheduleEntriesTableOrderingComposer
    extends Composer<_$AppDatabase, $BiblePlanScheduleEntriesTable> {
  $$BiblePlanScheduleEntriesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationOverrideId => $composableBuilder(
    column: $table.translationOverrideId,
    builder: (column) => ColumnOrderings(column),
  );

  $$BiblePlansTableOrderingComposer get planId {
    final $$BiblePlansTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.biblePlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlansTableOrderingComposer(
            $db: $db,
            $table: $db.biblePlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$BiblePlanScheduleEntriesTableAnnotationComposer
    extends Composer<_$AppDatabase, $BiblePlanScheduleEntriesTable> {
  $$BiblePlanScheduleEntriesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get scheduledDate => $composableBuilder(
    column: $table.scheduledDate,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get translationOverrideId => $composableBuilder(
    column: $table.translationOverrideId,
    builder: (column) => column,
  );

  $$BiblePlansTableAnnotationComposer get planId {
    final $$BiblePlansTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.planId,
      referencedTable: $db.biblePlans,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$BiblePlansTableAnnotationComposer(
            $db: $db,
            $table: $db.biblePlans,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  Expression<T> biblePlanScheduleItemsRefs<T extends Object>(
    Expression<T> Function($$BiblePlanScheduleItemsTableAnnotationComposer a) f,
  ) {
    final $$BiblePlanScheduleItemsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.biblePlanScheduleItems,
          getReferencedColumn: (t) => t.scheduleEntryId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleItemsTableAnnotationComposer(
                $db: $db,
                $table: $db.biblePlanScheduleItems,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$BiblePlanScheduleEntriesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BiblePlanScheduleEntriesTable,
          BiblePlanScheduleEntryRecord,
          $$BiblePlanScheduleEntriesTableFilterComposer,
          $$BiblePlanScheduleEntriesTableOrderingComposer,
          $$BiblePlanScheduleEntriesTableAnnotationComposer,
          $$BiblePlanScheduleEntriesTableCreateCompanionBuilder,
          $$BiblePlanScheduleEntriesTableUpdateCompanionBuilder,
          (
            BiblePlanScheduleEntryRecord,
            $$BiblePlanScheduleEntriesTableReferences,
          ),
          BiblePlanScheduleEntryRecord,
          PrefetchHooks Function({bool planId, bool biblePlanScheduleItemsRefs})
        > {
  $$BiblePlanScheduleEntriesTableTableManager(
    _$AppDatabase db,
    $BiblePlanScheduleEntriesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BiblePlanScheduleEntriesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BiblePlanScheduleEntriesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BiblePlanScheduleEntriesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> planId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> scheduledDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int?> completedAtUtcMicros = const Value.absent(),
                Value<String?> translationOverrideId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlanScheduleEntriesCompanion(
                id: id,
                planId: planId,
                position: position,
                scheduledDate: scheduledDate,
                isCompleted: isCompleted,
                completedAtUtcMicros: completedAtUtcMicros,
                translationOverrideId: translationOverrideId,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String planId,
                required int position,
                required String scheduledDate,
                required bool isCompleted,
                Value<int?> completedAtUtcMicros = const Value.absent(),
                Value<String?> translationOverrideId = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlanScheduleEntriesCompanion.insert(
                id: id,
                planId: planId,
                position: position,
                scheduledDate: scheduledDate,
                isCompleted: isCompleted,
                completedAtUtcMicros: completedAtUtcMicros,
                translationOverrideId: translationOverrideId,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BiblePlanScheduleEntriesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({planId = false, biblePlanScheduleItemsRefs = false}) {
                return PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (biblePlanScheduleItemsRefs) db.biblePlanScheduleItems,
                  ],
                  addJoins:
                      <
                        T extends TableManagerState<
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic,
                          dynamic
                        >
                      >(state) {
                        if (planId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.planId,
                                    referencedTable:
                                        $$BiblePlanScheduleEntriesTableReferences
                                            ._planIdTable(db),
                                    referencedColumn:
                                        $$BiblePlanScheduleEntriesTableReferences
                                            ._planIdTable(db)
                                            .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (biblePlanScheduleItemsRefs)
                        await $_getPrefetchedData<
                          BiblePlanScheduleEntryRecord,
                          $BiblePlanScheduleEntriesTable,
                          BiblePlanScheduleItemRecord
                        >(
                          currentTable: table,
                          referencedTable:
                              $$BiblePlanScheduleEntriesTableReferences
                                  ._biblePlanScheduleItemsRefsTable(db),
                          managerFromTypedResult: (p0) =>
                              $$BiblePlanScheduleEntriesTableReferences(
                                db,
                                table,
                                p0,
                              ).biblePlanScheduleItemsRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.scheduleEntryId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$BiblePlanScheduleEntriesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BiblePlanScheduleEntriesTable,
      BiblePlanScheduleEntryRecord,
      $$BiblePlanScheduleEntriesTableFilterComposer,
      $$BiblePlanScheduleEntriesTableOrderingComposer,
      $$BiblePlanScheduleEntriesTableAnnotationComposer,
      $$BiblePlanScheduleEntriesTableCreateCompanionBuilder,
      $$BiblePlanScheduleEntriesTableUpdateCompanionBuilder,
      (BiblePlanScheduleEntryRecord, $$BiblePlanScheduleEntriesTableReferences),
      BiblePlanScheduleEntryRecord,
      PrefetchHooks Function({bool planId, bool biblePlanScheduleItemsRefs})
    >;
typedef $$BiblePlanScheduleItemsTableCreateCompanionBuilder =
    BiblePlanScheduleItemsCompanion Function({
      required String id,
      required String scheduleEntryId,
      required int position,
      required String book,
      required int startChapter,
      Value<int?> startVerse,
      Value<int?> endChapter,
      Value<int?> endVerse,
      Value<int> rowid,
    });
typedef $$BiblePlanScheduleItemsTableUpdateCompanionBuilder =
    BiblePlanScheduleItemsCompanion Function({
      Value<String> id,
      Value<String> scheduleEntryId,
      Value<int> position,
      Value<String> book,
      Value<int> startChapter,
      Value<int?> startVerse,
      Value<int?> endChapter,
      Value<int?> endVerse,
      Value<int> rowid,
    });

final class $$BiblePlanScheduleItemsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $BiblePlanScheduleItemsTable,
          BiblePlanScheduleItemRecord
        > {
  $$BiblePlanScheduleItemsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $BiblePlanScheduleEntriesTable _scheduleEntryIdTable(
    _$AppDatabase db,
  ) => db.biblePlanScheduleEntries.createAlias(
    'bible_plan_schedule_items__schedule_entry_id__bible_plan_schedule_entries__id',
  );

  $$BiblePlanScheduleEntriesTableProcessedTableManager get scheduleEntryId {
    final $_column = $_itemColumn<String>('schedule_entry_id')!;

    final manager = $$BiblePlanScheduleEntriesTableTableManager(
      $_db,
      $_db.biblePlanScheduleEntries,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_scheduleEntryIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$BiblePlanScheduleItemsTableFilterComposer
    extends Composer<_$AppDatabase, $BiblePlanScheduleItemsTable> {
  $$BiblePlanScheduleItemsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  $$BiblePlanScheduleEntriesTableFilterComposer get scheduleEntryId {
    final $$BiblePlanScheduleEntriesTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleEntryId,
          referencedTable: $db.biblePlanScheduleEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleEntriesTableFilterComposer(
                $db: $db,
                $table: $db.biblePlanScheduleEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BiblePlanScheduleItemsTableOrderingComposer
    extends Composer<_$AppDatabase, $BiblePlanScheduleItemsTable> {
  $$BiblePlanScheduleItemsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  $$BiblePlanScheduleEntriesTableOrderingComposer get scheduleEntryId {
    final $$BiblePlanScheduleEntriesTableOrderingComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleEntryId,
          referencedTable: $db.biblePlanScheduleEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleEntriesTableOrderingComposer(
                $db: $db,
                $table: $db.biblePlanScheduleEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BiblePlanScheduleItemsTableAnnotationComposer
    extends Composer<_$AppDatabase, $BiblePlanScheduleItemsTable> {
  $$BiblePlanScheduleItemsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get startChapter => $composableBuilder(
    column: $table.startChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endChapter => $composableBuilder(
    column: $table.endChapter,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  $$BiblePlanScheduleEntriesTableAnnotationComposer get scheduleEntryId {
    final $$BiblePlanScheduleEntriesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.scheduleEntryId,
          referencedTable: $db.biblePlanScheduleEntries,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$BiblePlanScheduleEntriesTableAnnotationComposer(
                $db: $db,
                $table: $db.biblePlanScheduleEntries,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$BiblePlanScheduleItemsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $BiblePlanScheduleItemsTable,
          BiblePlanScheduleItemRecord,
          $$BiblePlanScheduleItemsTableFilterComposer,
          $$BiblePlanScheduleItemsTableOrderingComposer,
          $$BiblePlanScheduleItemsTableAnnotationComposer,
          $$BiblePlanScheduleItemsTableCreateCompanionBuilder,
          $$BiblePlanScheduleItemsTableUpdateCompanionBuilder,
          (
            BiblePlanScheduleItemRecord,
            $$BiblePlanScheduleItemsTableReferences,
          ),
          BiblePlanScheduleItemRecord,
          PrefetchHooks Function({bool scheduleEntryId})
        > {
  $$BiblePlanScheduleItemsTableTableManager(
    _$AppDatabase db,
    $BiblePlanScheduleItemsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$BiblePlanScheduleItemsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$BiblePlanScheduleItemsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$BiblePlanScheduleItemsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> scheduleEntryId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> startChapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endChapter = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlanScheduleItemsCompanion(
                id: id,
                scheduleEntryId: scheduleEntryId,
                position: position,
                book: book,
                startChapter: startChapter,
                startVerse: startVerse,
                endChapter: endChapter,
                endVerse: endVerse,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String scheduleEntryId,
                required int position,
                required String book,
                required int startChapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endChapter = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => BiblePlanScheduleItemsCompanion.insert(
                id: id,
                scheduleEntryId: scheduleEntryId,
                position: position,
                book: book,
                startChapter: startChapter,
                startVerse: startVerse,
                endChapter: endChapter,
                endVerse: endVerse,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$BiblePlanScheduleItemsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({scheduleEntryId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (scheduleEntryId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.scheduleEntryId,
                                referencedTable:
                                    $$BiblePlanScheduleItemsTableReferences
                                        ._scheduleEntryIdTable(db),
                                referencedColumn:
                                    $$BiblePlanScheduleItemsTableReferences
                                        ._scheduleEntryIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$BiblePlanScheduleItemsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $BiblePlanScheduleItemsTable,
      BiblePlanScheduleItemRecord,
      $$BiblePlanScheduleItemsTableFilterComposer,
      $$BiblePlanScheduleItemsTableOrderingComposer,
      $$BiblePlanScheduleItemsTableAnnotationComposer,
      $$BiblePlanScheduleItemsTableCreateCompanionBuilder,
      $$BiblePlanScheduleItemsTableUpdateCompanionBuilder,
      (BiblePlanScheduleItemRecord, $$BiblePlanScheduleItemsTableReferences),
      BiblePlanScheduleItemRecord,
      PrefetchHooks Function({bool scheduleEntryId})
    >;
typedef $$WordTranslationStatesTableCreateCompanionBuilder =
    WordTranslationStatesCompanion Function({
      required String translationId,
      required String accessMode,
      required String state,
      Value<String?> installedVersion,
      Value<String?> managedRelativePath,
      Value<int?> updatedAtUtcMicros,
      Value<String?> failureCode,
      Value<int?> downloadProgressPermille,
      Value<int> rowid,
    });
typedef $$WordTranslationStatesTableUpdateCompanionBuilder =
    WordTranslationStatesCompanion Function({
      Value<String> translationId,
      Value<String> accessMode,
      Value<String> state,
      Value<String?> installedVersion,
      Value<String?> managedRelativePath,
      Value<int?> updatedAtUtcMicros,
      Value<String?> failureCode,
      Value<int?> downloadProgressPermille,
      Value<int> rowid,
    });

class $$WordTranslationStatesTableFilterComposer
    extends Composer<_$AppDatabase, $WordTranslationStatesTable> {
  $$WordTranslationStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get accessMode => $composableBuilder(
    column: $table.accessMode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get installedVersion => $composableBuilder(
    column: $table.installedVersion,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get managedRelativePath => $composableBuilder(
    column: $table.managedRelativePath,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get downloadProgressPermille => $composableBuilder(
    column: $table.downloadProgressPermille,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordTranslationStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordTranslationStatesTable> {
  $$WordTranslationStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get accessMode => $composableBuilder(
    column: $table.accessMode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get installedVersion => $composableBuilder(
    column: $table.installedVersion,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get managedRelativePath => $composableBuilder(
    column: $table.managedRelativePath,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get downloadProgressPermille => $composableBuilder(
    column: $table.downloadProgressPermille,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordTranslationStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordTranslationStatesTable> {
  $$WordTranslationStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get accessMode => $composableBuilder(
    column: $table.accessMode,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get installedVersion => $composableBuilder(
    column: $table.installedVersion,
    builder: (column) => column,
  );

  GeneratedColumn<String> get managedRelativePath => $composableBuilder(
    column: $table.managedRelativePath,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get downloadProgressPermille => $composableBuilder(
    column: $table.downloadProgressPermille,
    builder: (column) => column,
  );
}

class $$WordTranslationStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordTranslationStatesTable,
          WordTranslationStateRecord,
          $$WordTranslationStatesTableFilterComposer,
          $$WordTranslationStatesTableOrderingComposer,
          $$WordTranslationStatesTableAnnotationComposer,
          $$WordTranslationStatesTableCreateCompanionBuilder,
          $$WordTranslationStatesTableUpdateCompanionBuilder,
          (
            WordTranslationStateRecord,
            BaseReferences<
              _$AppDatabase,
              $WordTranslationStatesTable,
              WordTranslationStateRecord
            >,
          ),
          WordTranslationStateRecord,
          PrefetchHooks Function()
        > {
  $$WordTranslationStatesTableTableManager(
    _$AppDatabase db,
    $WordTranslationStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordTranslationStatesTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WordTranslationStatesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WordTranslationStatesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> translationId = const Value.absent(),
                Value<String> accessMode = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String?> installedVersion = const Value.absent(),
                Value<String?> managedRelativePath = const Value.absent(),
                Value<int?> updatedAtUtcMicros = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int?> downloadProgressPermille = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordTranslationStatesCompanion(
                translationId: translationId,
                accessMode: accessMode,
                state: state,
                installedVersion: installedVersion,
                managedRelativePath: managedRelativePath,
                updatedAtUtcMicros: updatedAtUtcMicros,
                failureCode: failureCode,
                downloadProgressPermille: downloadProgressPermille,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String translationId,
                required String accessMode,
                required String state,
                Value<String?> installedVersion = const Value.absent(),
                Value<String?> managedRelativePath = const Value.absent(),
                Value<int?> updatedAtUtcMicros = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int?> downloadProgressPermille = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordTranslationStatesCompanion.insert(
                translationId: translationId,
                accessMode: accessMode,
                state: state,
                installedVersion: installedVersion,
                managedRelativePath: managedRelativePath,
                updatedAtUtcMicros: updatedAtUtcMicros,
                failureCode: failureCode,
                downloadProgressPermille: downloadProgressPermille,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordTranslationStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordTranslationStatesTable,
      WordTranslationStateRecord,
      $$WordTranslationStatesTableFilterComposer,
      $$WordTranslationStatesTableOrderingComposer,
      $$WordTranslationStatesTableAnnotationComposer,
      $$WordTranslationStatesTableCreateCompanionBuilder,
      $$WordTranslationStatesTableUpdateCompanionBuilder,
      (
        WordTranslationStateRecord,
        BaseReferences<
          _$AppDatabase,
          $WordTranslationStatesTable,
          WordTranslationStateRecord
        >,
      ),
      WordTranslationStateRecord,
      PrefetchHooks Function()
    >;
typedef $$LocalMigrationMetadataTableCreateCompanionBuilder =
    LocalMigrationMetadataCompanion Function({
      required String migrationId,
      required String state,
      required String sourceFingerprint,
      required int startedAtUtcMicros,
      Value<int?> completedAtUtcMicros,
      Value<String?> failureCode,
      required int targetSchemaVersion,
      Value<int> rowid,
    });
typedef $$LocalMigrationMetadataTableUpdateCompanionBuilder =
    LocalMigrationMetadataCompanion Function({
      Value<String> migrationId,
      Value<String> state,
      Value<String> sourceFingerprint,
      Value<int> startedAtUtcMicros,
      Value<int?> completedAtUtcMicros,
      Value<String?> failureCode,
      Value<int> targetSchemaVersion,
      Value<int> rowid,
    });

class $$LocalMigrationMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $LocalMigrationMetadataTable> {
  $$LocalMigrationMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get migrationId => $composableBuilder(
    column: $table.migrationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startedAtUtcMicros => $composableBuilder(
    column: $table.startedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get targetSchemaVersion => $composableBuilder(
    column: $table.targetSchemaVersion,
    builder: (column) => ColumnFilters(column),
  );
}

class $$LocalMigrationMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $LocalMigrationMetadataTable> {
  $$LocalMigrationMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get migrationId => $composableBuilder(
    column: $table.migrationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get state => $composableBuilder(
    column: $table.state,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startedAtUtcMicros => $composableBuilder(
    column: $table.startedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get targetSchemaVersion => $composableBuilder(
    column: $table.targetSchemaVersion,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$LocalMigrationMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $LocalMigrationMetadataTable> {
  $$LocalMigrationMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get migrationId => $composableBuilder(
    column: $table.migrationId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get state =>
      $composableBuilder(column: $table.state, builder: (column) => column);

  GeneratedColumn<String> get sourceFingerprint => $composableBuilder(
    column: $table.sourceFingerprint,
    builder: (column) => column,
  );

  GeneratedColumn<int> get startedAtUtcMicros => $composableBuilder(
    column: $table.startedAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<String> get failureCode => $composableBuilder(
    column: $table.failureCode,
    builder: (column) => column,
  );

  GeneratedColumn<int> get targetSchemaVersion => $composableBuilder(
    column: $table.targetSchemaVersion,
    builder: (column) => column,
  );
}

class $$LocalMigrationMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $LocalMigrationMetadataTable,
          LocalMigrationMetadataRecord,
          $$LocalMigrationMetadataTableFilterComposer,
          $$LocalMigrationMetadataTableOrderingComposer,
          $$LocalMigrationMetadataTableAnnotationComposer,
          $$LocalMigrationMetadataTableCreateCompanionBuilder,
          $$LocalMigrationMetadataTableUpdateCompanionBuilder,
          (
            LocalMigrationMetadataRecord,
            BaseReferences<
              _$AppDatabase,
              $LocalMigrationMetadataTable,
              LocalMigrationMetadataRecord
            >,
          ),
          LocalMigrationMetadataRecord,
          PrefetchHooks Function()
        > {
  $$LocalMigrationMetadataTableTableManager(
    _$AppDatabase db,
    $LocalMigrationMetadataTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$LocalMigrationMetadataTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$LocalMigrationMetadataTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$LocalMigrationMetadataTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> migrationId = const Value.absent(),
                Value<String> state = const Value.absent(),
                Value<String> sourceFingerprint = const Value.absent(),
                Value<int> startedAtUtcMicros = const Value.absent(),
                Value<int?> completedAtUtcMicros = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                Value<int> targetSchemaVersion = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => LocalMigrationMetadataCompanion(
                migrationId: migrationId,
                state: state,
                sourceFingerprint: sourceFingerprint,
                startedAtUtcMicros: startedAtUtcMicros,
                completedAtUtcMicros: completedAtUtcMicros,
                failureCode: failureCode,
                targetSchemaVersion: targetSchemaVersion,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String migrationId,
                required String state,
                required String sourceFingerprint,
                required int startedAtUtcMicros,
                Value<int?> completedAtUtcMicros = const Value.absent(),
                Value<String?> failureCode = const Value.absent(),
                required int targetSchemaVersion,
                Value<int> rowid = const Value.absent(),
              }) => LocalMigrationMetadataCompanion.insert(
                migrationId: migrationId,
                state: state,
                sourceFingerprint: sourceFingerprint,
                startedAtUtcMicros: startedAtUtcMicros,
                completedAtUtcMicros: completedAtUtcMicros,
                failureCode: failureCode,
                targetSchemaVersion: targetSchemaVersion,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$LocalMigrationMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $LocalMigrationMetadataTable,
      LocalMigrationMetadataRecord,
      $$LocalMigrationMetadataTableFilterComposer,
      $$LocalMigrationMetadataTableOrderingComposer,
      $$LocalMigrationMetadataTableAnnotationComposer,
      $$LocalMigrationMetadataTableCreateCompanionBuilder,
      $$LocalMigrationMetadataTableUpdateCompanionBuilder,
      (
        LocalMigrationMetadataRecord,
        BaseReferences<
          _$AppDatabase,
          $LocalMigrationMetadataTable,
          LocalMigrationMetadataRecord
        >,
      ),
      LocalMigrationMetadataRecord,
      PrefetchHooks Function()
    >;
typedef $$WordReaderStatesTableCreateCompanionBuilder =
    WordReaderStatesCompanion Function({
      required String id,
      required String book,
      required int chapter,
      required String translationId,
      required int updatedAtUtcMicros,
      Value<int> rowid,
    });
typedef $$WordReaderStatesTableUpdateCompanionBuilder =
    WordReaderStatesCompanion Function({
      Value<String> id,
      Value<String> book,
      Value<int> chapter,
      Value<String> translationId,
      Value<int> updatedAtUtcMicros,
      Value<int> rowid,
    });

class $$WordReaderStatesTableFilterComposer
    extends Composer<_$AppDatabase, $WordReaderStatesTable> {
  $$WordReaderStatesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordReaderStatesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordReaderStatesTable> {
  $$WordReaderStatesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordReaderStatesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordReaderStatesTable> {
  $$WordReaderStatesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<String> get translationId => $composableBuilder(
    column: $table.translationId,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => column,
  );
}

class $$WordReaderStatesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordReaderStatesTable,
          WordReaderStateRecord,
          $$WordReaderStatesTableFilterComposer,
          $$WordReaderStatesTableOrderingComposer,
          $$WordReaderStatesTableAnnotationComposer,
          $$WordReaderStatesTableCreateCompanionBuilder,
          $$WordReaderStatesTableUpdateCompanionBuilder,
          (
            WordReaderStateRecord,
            BaseReferences<
              _$AppDatabase,
              $WordReaderStatesTable,
              WordReaderStateRecord
            >,
          ),
          WordReaderStateRecord,
          PrefetchHooks Function()
        > {
  $$WordReaderStatesTableTableManager(
    _$AppDatabase db,
    $WordReaderStatesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordReaderStatesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordReaderStatesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordReaderStatesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<String> translationId = const Value.absent(),
                Value<int> updatedAtUtcMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordReaderStatesCompanion(
                id: id,
                book: book,
                chapter: chapter,
                translationId: translationId,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String book,
                required int chapter,
                required String translationId,
                required int updatedAtUtcMicros,
                Value<int> rowid = const Value.absent(),
              }) => WordReaderStatesCompanion.insert(
                id: id,
                book: book,
                chapter: chapter,
                translationId: translationId,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordReaderStatesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordReaderStatesTable,
      WordReaderStateRecord,
      $$WordReaderStatesTableFilterComposer,
      $$WordReaderStatesTableOrderingComposer,
      $$WordReaderStatesTableAnnotationComposer,
      $$WordReaderStatesTableCreateCompanionBuilder,
      $$WordReaderStatesTableUpdateCompanionBuilder,
      (
        WordReaderStateRecord,
        BaseReferences<
          _$AppDatabase,
          $WordReaderStatesTable,
          WordReaderStateRecord
        >,
      ),
      WordReaderStateRecord,
      PrefetchHooks Function()
    >;
typedef $$WordAudioPreferencesTableCreateCompanionBuilder =
    WordAudioPreferencesCompanion Function({
      required String id,
      Value<String?> voiceKey,
      required double playbackRate,
      Value<int> rowid,
    });
typedef $$WordAudioPreferencesTableUpdateCompanionBuilder =
    WordAudioPreferencesCompanion Function({
      Value<String> id,
      Value<String?> voiceKey,
      Value<double> playbackRate,
      Value<int> rowid,
    });

class $$WordAudioPreferencesTableFilterComposer
    extends Composer<_$AppDatabase, $WordAudioPreferencesTable> {
  $$WordAudioPreferencesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get voiceKey => $composableBuilder(
    column: $table.voiceKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get playbackRate => $composableBuilder(
    column: $table.playbackRate,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordAudioPreferencesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordAudioPreferencesTable> {
  $$WordAudioPreferencesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get voiceKey => $composableBuilder(
    column: $table.voiceKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get playbackRate => $composableBuilder(
    column: $table.playbackRate,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordAudioPreferencesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordAudioPreferencesTable> {
  $$WordAudioPreferencesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get voiceKey =>
      $composableBuilder(column: $table.voiceKey, builder: (column) => column);

  GeneratedColumn<double> get playbackRate => $composableBuilder(
    column: $table.playbackRate,
    builder: (column) => column,
  );
}

class $$WordAudioPreferencesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordAudioPreferencesTable,
          WordAudioPreferenceRecord,
          $$WordAudioPreferencesTableFilterComposer,
          $$WordAudioPreferencesTableOrderingComposer,
          $$WordAudioPreferencesTableAnnotationComposer,
          $$WordAudioPreferencesTableCreateCompanionBuilder,
          $$WordAudioPreferencesTableUpdateCompanionBuilder,
          (
            WordAudioPreferenceRecord,
            BaseReferences<
              _$AppDatabase,
              $WordAudioPreferencesTable,
              WordAudioPreferenceRecord
            >,
          ),
          WordAudioPreferenceRecord,
          PrefetchHooks Function()
        > {
  $$WordAudioPreferencesTableTableManager(
    _$AppDatabase db,
    $WordAudioPreferencesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordAudioPreferencesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordAudioPreferencesTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WordAudioPreferencesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> voiceKey = const Value.absent(),
                Value<double> playbackRate = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordAudioPreferencesCompanion(
                id: id,
                voiceKey: voiceKey,
                playbackRate: playbackRate,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> voiceKey = const Value.absent(),
                required double playbackRate,
                Value<int> rowid = const Value.absent(),
              }) => WordAudioPreferencesCompanion.insert(
                id: id,
                voiceKey: voiceKey,
                playbackRate: playbackRate,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordAudioPreferencesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordAudioPreferencesTable,
      WordAudioPreferenceRecord,
      $$WordAudioPreferencesTableFilterComposer,
      $$WordAudioPreferencesTableOrderingComposer,
      $$WordAudioPreferencesTableAnnotationComposer,
      $$WordAudioPreferencesTableCreateCompanionBuilder,
      $$WordAudioPreferencesTableUpdateCompanionBuilder,
      (
        WordAudioPreferenceRecord,
        BaseReferences<
          _$AppDatabase,
          $WordAudioPreferencesTable,
          WordAudioPreferenceRecord
        >,
      ),
      WordAudioPreferenceRecord,
      PrefetchHooks Function()
    >;
typedef $$WordScriptureBookmarksTableCreateCompanionBuilder =
    WordScriptureBookmarksCompanion Function({
      required String anchorKey,
      required String book,
      required int chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      required int createdAtUtcMicros,
      Value<int> rowid,
    });
typedef $$WordScriptureBookmarksTableUpdateCompanionBuilder =
    WordScriptureBookmarksCompanion Function({
      Value<String> anchorKey,
      Value<String> book,
      Value<int> chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<int> createdAtUtcMicros,
      Value<int> rowid,
    });

class $$WordScriptureBookmarksTableFilterComposer
    extends Composer<_$AppDatabase, $WordScriptureBookmarksTable> {
  $$WordScriptureBookmarksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordScriptureBookmarksTableOrderingComposer
    extends Composer<_$AppDatabase, $WordScriptureBookmarksTable> {
  $$WordScriptureBookmarksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordScriptureBookmarksTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordScriptureBookmarksTable> {
  $$WordScriptureBookmarksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get anchorKey =>
      $composableBuilder(column: $table.anchorKey, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => column,
  );
}

class $$WordScriptureBookmarksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordScriptureBookmarksTable,
          WordScriptureBookmarkRecord,
          $$WordScriptureBookmarksTableFilterComposer,
          $$WordScriptureBookmarksTableOrderingComposer,
          $$WordScriptureBookmarksTableAnnotationComposer,
          $$WordScriptureBookmarksTableCreateCompanionBuilder,
          $$WordScriptureBookmarksTableUpdateCompanionBuilder,
          (
            WordScriptureBookmarkRecord,
            BaseReferences<
              _$AppDatabase,
              $WordScriptureBookmarksTable,
              WordScriptureBookmarkRecord
            >,
          ),
          WordScriptureBookmarkRecord,
          PrefetchHooks Function()
        > {
  $$WordScriptureBookmarksTableTableManager(
    _$AppDatabase db,
    $WordScriptureBookmarksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordScriptureBookmarksTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WordScriptureBookmarksTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WordScriptureBookmarksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> anchorKey = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> createdAtUtcMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureBookmarksCompanion(
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                createdAtUtcMicros: createdAtUtcMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String anchorKey,
                required String book,
                required int chapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                required int createdAtUtcMicros,
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureBookmarksCompanion.insert(
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                createdAtUtcMicros: createdAtUtcMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordScriptureBookmarksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordScriptureBookmarksTable,
      WordScriptureBookmarkRecord,
      $$WordScriptureBookmarksTableFilterComposer,
      $$WordScriptureBookmarksTableOrderingComposer,
      $$WordScriptureBookmarksTableAnnotationComposer,
      $$WordScriptureBookmarksTableCreateCompanionBuilder,
      $$WordScriptureBookmarksTableUpdateCompanionBuilder,
      (
        WordScriptureBookmarkRecord,
        BaseReferences<
          _$AppDatabase,
          $WordScriptureBookmarksTable,
          WordScriptureBookmarkRecord
        >,
      ),
      WordScriptureBookmarkRecord,
      PrefetchHooks Function()
    >;
typedef $$WordScriptureHighlightsTableCreateCompanionBuilder =
    WordScriptureHighlightsCompanion Function({
      required String anchorKey,
      required String book,
      required int chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      required String style,
      required int updatedAtUtcMicros,
      Value<int> rowid,
    });
typedef $$WordScriptureHighlightsTableUpdateCompanionBuilder =
    WordScriptureHighlightsCompanion Function({
      Value<String> anchorKey,
      Value<String> book,
      Value<int> chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<String> style,
      Value<int> updatedAtUtcMicros,
      Value<int> rowid,
    });

class $$WordScriptureHighlightsTableFilterComposer
    extends Composer<_$AppDatabase, $WordScriptureHighlightsTable> {
  $$WordScriptureHighlightsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordScriptureHighlightsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordScriptureHighlightsTable> {
  $$WordScriptureHighlightsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get style => $composableBuilder(
    column: $table.style,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordScriptureHighlightsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordScriptureHighlightsTable> {
  $$WordScriptureHighlightsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get anchorKey =>
      $composableBuilder(column: $table.anchorKey, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<String> get style =>
      $composableBuilder(column: $table.style, builder: (column) => column);

  GeneratedColumn<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => column,
  );
}

class $$WordScriptureHighlightsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordScriptureHighlightsTable,
          WordScriptureHighlightRecord,
          $$WordScriptureHighlightsTableFilterComposer,
          $$WordScriptureHighlightsTableOrderingComposer,
          $$WordScriptureHighlightsTableAnnotationComposer,
          $$WordScriptureHighlightsTableCreateCompanionBuilder,
          $$WordScriptureHighlightsTableUpdateCompanionBuilder,
          (
            WordScriptureHighlightRecord,
            BaseReferences<
              _$AppDatabase,
              $WordScriptureHighlightsTable,
              WordScriptureHighlightRecord
            >,
          ),
          WordScriptureHighlightRecord,
          PrefetchHooks Function()
        > {
  $$WordScriptureHighlightsTableTableManager(
    _$AppDatabase db,
    $WordScriptureHighlightsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordScriptureHighlightsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WordScriptureHighlightsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WordScriptureHighlightsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> anchorKey = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<String> style = const Value.absent(),
                Value<int> updatedAtUtcMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureHighlightsCompanion(
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                style: style,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String anchorKey,
                required String book,
                required int chapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                required String style,
                required int updatedAtUtcMicros,
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureHighlightsCompanion.insert(
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                style: style,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordScriptureHighlightsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordScriptureHighlightsTable,
      WordScriptureHighlightRecord,
      $$WordScriptureHighlightsTableFilterComposer,
      $$WordScriptureHighlightsTableOrderingComposer,
      $$WordScriptureHighlightsTableAnnotationComposer,
      $$WordScriptureHighlightsTableCreateCompanionBuilder,
      $$WordScriptureHighlightsTableUpdateCompanionBuilder,
      (
        WordScriptureHighlightRecord,
        BaseReferences<
          _$AppDatabase,
          $WordScriptureHighlightsTable,
          WordScriptureHighlightRecord
        >,
      ),
      WordScriptureHighlightRecord,
      PrefetchHooks Function()
    >;
typedef $$WordScriptureNotesTableCreateCompanionBuilder =
    WordScriptureNotesCompanion Function({
      required String id,
      required String anchorKey,
      required String book,
      required int chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      required String body,
      required int createdAtUtcMicros,
      required int updatedAtUtcMicros,
      Value<int> rowid,
    });
typedef $$WordScriptureNotesTableUpdateCompanionBuilder =
    WordScriptureNotesCompanion Function({
      Value<String> id,
      Value<String> anchorKey,
      Value<String> book,
      Value<int> chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<String> body,
      Value<int> createdAtUtcMicros,
      Value<int> updatedAtUtcMicros,
      Value<int> rowid,
    });

final class $$WordScriptureNotesTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WordScriptureNotesTable,
          WordScriptureNoteRecord
        > {
  $$WordScriptureNotesTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static MultiTypedResultKey<
    $WordScriptureNoteAnchorsTable,
    List<WordScriptureNoteAnchorRecord>
  >
  _wordScriptureNoteAnchorsRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.wordScriptureNoteAnchors,
        aliasName:
            'word_scripture_notes__id__word_scripture_note_anchors__note_id',
      );

  $$WordScriptureNoteAnchorsTableProcessedTableManager
  get wordScriptureNoteAnchorsRefs {
    final manager = $$WordScriptureNoteAnchorsTableTableManager(
      $_db,
      $_db.wordScriptureNoteAnchors,
    ).filter((f) => f.noteId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _wordScriptureNoteAnchorsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$WordScriptureNotesTableFilterComposer
    extends Composer<_$AppDatabase, $WordScriptureNotesTable> {
  $$WordScriptureNotesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> wordScriptureNoteAnchorsRefs(
    Expression<bool> Function($$WordScriptureNoteAnchorsTableFilterComposer f)
    f,
  ) {
    final $$WordScriptureNoteAnchorsTableFilterComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.wordScriptureNoteAnchors,
          getReferencedColumn: (t) => t.noteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WordScriptureNoteAnchorsTableFilterComposer(
                $db: $db,
                $table: $db.wordScriptureNoteAnchors,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WordScriptureNotesTableOrderingComposer
    extends Composer<_$AppDatabase, $WordScriptureNotesTable> {
  $$WordScriptureNotesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordScriptureNotesTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordScriptureNotesTable> {
  $$WordScriptureNotesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get anchorKey =>
      $composableBuilder(column: $table.anchorKey, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => column,
  );

  Expression<T> wordScriptureNoteAnchorsRefs<T extends Object>(
    Expression<T> Function($$WordScriptureNoteAnchorsTableAnnotationComposer a)
    f,
  ) {
    final $$WordScriptureNoteAnchorsTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.wordScriptureNoteAnchors,
          getReferencedColumn: (t) => t.noteId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WordScriptureNoteAnchorsTableAnnotationComposer(
                $db: $db,
                $table: $db.wordScriptureNoteAnchors,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$WordScriptureNotesTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordScriptureNotesTable,
          WordScriptureNoteRecord,
          $$WordScriptureNotesTableFilterComposer,
          $$WordScriptureNotesTableOrderingComposer,
          $$WordScriptureNotesTableAnnotationComposer,
          $$WordScriptureNotesTableCreateCompanionBuilder,
          $$WordScriptureNotesTableUpdateCompanionBuilder,
          (WordScriptureNoteRecord, $$WordScriptureNotesTableReferences),
          WordScriptureNoteRecord,
          PrefetchHooks Function({bool wordScriptureNoteAnchorsRefs})
        > {
  $$WordScriptureNotesTableTableManager(
    _$AppDatabase db,
    $WordScriptureNotesTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordScriptureNotesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordScriptureNotesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordScriptureNotesTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> anchorKey = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<int> createdAtUtcMicros = const Value.absent(),
                Value<int> updatedAtUtcMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureNotesCompanion(
                id: id,
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                body: body,
                createdAtUtcMicros: createdAtUtcMicros,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String anchorKey,
                required String book,
                required int chapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                required String body,
                required int createdAtUtcMicros,
                required int updatedAtUtcMicros,
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureNotesCompanion.insert(
                id: id,
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                body: body,
                createdAtUtcMicros: createdAtUtcMicros,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordScriptureNotesTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({wordScriptureNoteAnchorsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (wordScriptureNoteAnchorsRefs) db.wordScriptureNoteAnchors,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (wordScriptureNoteAnchorsRefs)
                    await $_getPrefetchedData<
                      WordScriptureNoteRecord,
                      $WordScriptureNotesTable,
                      WordScriptureNoteAnchorRecord
                    >(
                      currentTable: table,
                      referencedTable: $$WordScriptureNotesTableReferences
                          ._wordScriptureNoteAnchorsRefsTable(db),
                      managerFromTypedResult: (p0) =>
                          $$WordScriptureNotesTableReferences(
                            db,
                            table,
                            p0,
                          ).wordScriptureNoteAnchorsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.noteId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$WordScriptureNotesTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordScriptureNotesTable,
      WordScriptureNoteRecord,
      $$WordScriptureNotesTableFilterComposer,
      $$WordScriptureNotesTableOrderingComposer,
      $$WordScriptureNotesTableAnnotationComposer,
      $$WordScriptureNotesTableCreateCompanionBuilder,
      $$WordScriptureNotesTableUpdateCompanionBuilder,
      (WordScriptureNoteRecord, $$WordScriptureNotesTableReferences),
      WordScriptureNoteRecord,
      PrefetchHooks Function({bool wordScriptureNoteAnchorsRefs})
    >;
typedef $$WordScriptureNoteAnchorsTableCreateCompanionBuilder =
    WordScriptureNoteAnchorsCompanion Function({
      required String noteId,
      required int ordinal,
      required String anchorKey,
      required String book,
      required int chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<int> rowid,
    });
typedef $$WordScriptureNoteAnchorsTableUpdateCompanionBuilder =
    WordScriptureNoteAnchorsCompanion Function({
      Value<String> noteId,
      Value<int> ordinal,
      Value<String> anchorKey,
      Value<String> book,
      Value<int> chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<int> rowid,
    });

final class $$WordScriptureNoteAnchorsTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $WordScriptureNoteAnchorsTable,
          WordScriptureNoteAnchorRecord
        > {
  $$WordScriptureNoteAnchorsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $WordScriptureNotesTable _noteIdTable(_$AppDatabase db) =>
      db.wordScriptureNotes.createAlias(
        'word_scripture_note_anchors__note_id__word_scripture_notes__id',
      );

  $$WordScriptureNotesTableProcessedTableManager get noteId {
    final $_column = $_itemColumn<String>('note_id')!;

    final manager = $$WordScriptureNotesTableTableManager(
      $_db,
      $_db.wordScriptureNotes,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_noteIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$WordScriptureNoteAnchorsTableFilterComposer
    extends Composer<_$AppDatabase, $WordScriptureNoteAnchorsTable> {
  $$WordScriptureNoteAnchorsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  $$WordScriptureNotesTableFilterComposer get noteId {
    final $$WordScriptureNotesTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.wordScriptureNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordScriptureNotesTableFilterComposer(
            $db: $db,
            $table: $db.wordScriptureNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordScriptureNoteAnchorsTableOrderingComposer
    extends Composer<_$AppDatabase, $WordScriptureNoteAnchorsTable> {
  $$WordScriptureNoteAnchorsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get ordinal => $composableBuilder(
    column: $table.ordinal,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  $$WordScriptureNotesTableOrderingComposer get noteId {
    final $$WordScriptureNotesTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.noteId,
      referencedTable: $db.wordScriptureNotes,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$WordScriptureNotesTableOrderingComposer(
            $db: $db,
            $table: $db.wordScriptureNotes,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$WordScriptureNoteAnchorsTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordScriptureNoteAnchorsTable> {
  $$WordScriptureNoteAnchorsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get ordinal =>
      $composableBuilder(column: $table.ordinal, builder: (column) => column);

  GeneratedColumn<String> get anchorKey =>
      $composableBuilder(column: $table.anchorKey, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  $$WordScriptureNotesTableAnnotationComposer get noteId {
    final $$WordScriptureNotesTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.noteId,
          referencedTable: $db.wordScriptureNotes,
          getReferencedColumn: (t) => t.id,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$WordScriptureNotesTableAnnotationComposer(
                $db: $db,
                $table: $db.wordScriptureNotes,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return composer;
  }
}

class $$WordScriptureNoteAnchorsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordScriptureNoteAnchorsTable,
          WordScriptureNoteAnchorRecord,
          $$WordScriptureNoteAnchorsTableFilterComposer,
          $$WordScriptureNoteAnchorsTableOrderingComposer,
          $$WordScriptureNoteAnchorsTableAnnotationComposer,
          $$WordScriptureNoteAnchorsTableCreateCompanionBuilder,
          $$WordScriptureNoteAnchorsTableUpdateCompanionBuilder,
          (
            WordScriptureNoteAnchorRecord,
            $$WordScriptureNoteAnchorsTableReferences,
          ),
          WordScriptureNoteAnchorRecord,
          PrefetchHooks Function({bool noteId})
        > {
  $$WordScriptureNoteAnchorsTableTableManager(
    _$AppDatabase db,
    $WordScriptureNoteAnchorsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordScriptureNoteAnchorsTableFilterComposer(
                $db: db,
                $table: table,
              ),
          createOrderingComposer: () =>
              $$WordScriptureNoteAnchorsTableOrderingComposer(
                $db: db,
                $table: table,
              ),
          createComputedFieldComposer: () =>
              $$WordScriptureNoteAnchorsTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> noteId = const Value.absent(),
                Value<int> ordinal = const Value.absent(),
                Value<String> anchorKey = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureNoteAnchorsCompanion(
                noteId: noteId,
                ordinal: ordinal,
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String noteId,
                required int ordinal,
                required String anchorKey,
                required String book,
                required int chapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordScriptureNoteAnchorsCompanion.insert(
                noteId: noteId,
                ordinal: ordinal,
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$WordScriptureNoteAnchorsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({noteId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (noteId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.noteId,
                                referencedTable:
                                    $$WordScriptureNoteAnchorsTableReferences
                                        ._noteIdTable(db),
                                referencedColumn:
                                    $$WordScriptureNoteAnchorsTableReferences
                                        ._noteIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$WordScriptureNoteAnchorsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordScriptureNoteAnchorsTable,
      WordScriptureNoteAnchorRecord,
      $$WordScriptureNoteAnchorsTableFilterComposer,
      $$WordScriptureNoteAnchorsTableOrderingComposer,
      $$WordScriptureNoteAnchorsTableAnnotationComposer,
      $$WordScriptureNoteAnchorsTableCreateCompanionBuilder,
      $$WordScriptureNoteAnchorsTableUpdateCompanionBuilder,
      (
        WordScriptureNoteAnchorRecord,
        $$WordScriptureNoteAnchorsTableReferences,
      ),
      WordScriptureNoteAnchorRecord,
      PrefetchHooks Function({bool noteId})
    >;
typedef $$WordReadingHistoryTableCreateCompanionBuilder =
    WordReadingHistoryCompanion Function({
      required String anchorKey,
      required String book,
      required int chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      required int openedAtUtcMicros,
      Value<int> rowid,
    });
typedef $$WordReadingHistoryTableUpdateCompanionBuilder =
    WordReadingHistoryCompanion Function({
      Value<String> anchorKey,
      Value<String> book,
      Value<int> chapter,
      Value<int?> startVerse,
      Value<int?> endVerse,
      Value<int> openedAtUtcMicros,
      Value<int> rowid,
    });

class $$WordReadingHistoryTableFilterComposer
    extends Composer<_$AppDatabase, $WordReadingHistoryTable> {
  $$WordReadingHistoryTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get openedAtUtcMicros => $composableBuilder(
    column: $table.openedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );
}

class $$WordReadingHistoryTableOrderingComposer
    extends Composer<_$AppDatabase, $WordReadingHistoryTable> {
  $$WordReadingHistoryTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get anchorKey => $composableBuilder(
    column: $table.anchorKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get book => $composableBuilder(
    column: $table.book,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get chapter => $composableBuilder(
    column: $table.chapter,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get endVerse => $composableBuilder(
    column: $table.endVerse,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get openedAtUtcMicros => $composableBuilder(
    column: $table.openedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$WordReadingHistoryTableAnnotationComposer
    extends Composer<_$AppDatabase, $WordReadingHistoryTable> {
  $$WordReadingHistoryTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get anchorKey =>
      $composableBuilder(column: $table.anchorKey, builder: (column) => column);

  GeneratedColumn<String> get book =>
      $composableBuilder(column: $table.book, builder: (column) => column);

  GeneratedColumn<int> get chapter =>
      $composableBuilder(column: $table.chapter, builder: (column) => column);

  GeneratedColumn<int> get startVerse => $composableBuilder(
    column: $table.startVerse,
    builder: (column) => column,
  );

  GeneratedColumn<int> get endVerse =>
      $composableBuilder(column: $table.endVerse, builder: (column) => column);

  GeneratedColumn<int> get openedAtUtcMicros => $composableBuilder(
    column: $table.openedAtUtcMicros,
    builder: (column) => column,
  );
}

class $$WordReadingHistoryTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $WordReadingHistoryTable,
          WordReadingHistoryRecord,
          $$WordReadingHistoryTableFilterComposer,
          $$WordReadingHistoryTableOrderingComposer,
          $$WordReadingHistoryTableAnnotationComposer,
          $$WordReadingHistoryTableCreateCompanionBuilder,
          $$WordReadingHistoryTableUpdateCompanionBuilder,
          (
            WordReadingHistoryRecord,
            BaseReferences<
              _$AppDatabase,
              $WordReadingHistoryTable,
              WordReadingHistoryRecord
            >,
          ),
          WordReadingHistoryRecord,
          PrefetchHooks Function()
        > {
  $$WordReadingHistoryTableTableManager(
    _$AppDatabase db,
    $WordReadingHistoryTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WordReadingHistoryTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WordReadingHistoryTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WordReadingHistoryTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> anchorKey = const Value.absent(),
                Value<String> book = const Value.absent(),
                Value<int> chapter = const Value.absent(),
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                Value<int> openedAtUtcMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => WordReadingHistoryCompanion(
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                openedAtUtcMicros: openedAtUtcMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String anchorKey,
                required String book,
                required int chapter,
                Value<int?> startVerse = const Value.absent(),
                Value<int?> endVerse = const Value.absent(),
                required int openedAtUtcMicros,
                Value<int> rowid = const Value.absent(),
              }) => WordReadingHistoryCompanion.insert(
                anchorKey: anchorKey,
                book: book,
                chapter: chapter,
                startVerse: startVerse,
                endVerse: endVerse,
                openedAtUtcMicros: openedAtUtcMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$WordReadingHistoryTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $WordReadingHistoryTable,
      WordReadingHistoryRecord,
      $$WordReadingHistoryTableFilterComposer,
      $$WordReadingHistoryTableOrderingComposer,
      $$WordReadingHistoryTableAnnotationComposer,
      $$WordReadingHistoryTableCreateCompanionBuilder,
      $$WordReadingHistoryTableUpdateCompanionBuilder,
      (
        WordReadingHistoryRecord,
        BaseReferences<
          _$AppDatabase,
          $WordReadingHistoryTable,
          WordReadingHistoryRecord
        >,
      ),
      WordReadingHistoryRecord,
      PrefetchHooks Function()
    >;
typedef $$TasksTableCreateCompanionBuilder =
    TasksCompanion Function({
      required String id,
      required String title,
      Value<String?> dueDate,
      required bool isCompleted,
      Value<int?> completedAtUtcMicros,
      required int createdAtUtcMicros,
      required int updatedAtUtcMicros,
      Value<int> rowid,
    });
typedef $$TasksTableUpdateCompanionBuilder =
    TasksCompanion Function({
      Value<String> id,
      Value<String> title,
      Value<String?> dueDate,
      Value<bool> isCompleted,
      Value<int?> completedAtUtcMicros,
      Value<int> createdAtUtcMicros,
      Value<int> updatedAtUtcMicros,
      Value<int> rowid,
    });

final class $$TasksTableReferences
    extends BaseReferences<_$AppDatabase, $TasksTable, StoredTaskRecord> {
  $$TasksTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<
    $DailyPriorityTasksTable,
    List<DailyPriorityTaskRecord>
  >
  _dailyPriorityTasksRefsTable(_$AppDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.dailyPriorityTasks,
        aliasName: 'tasks__id__daily_priority_tasks__task_id',
      );

  $$DailyPriorityTasksTableProcessedTableManager get dailyPriorityTasksRefs {
    final manager = $$DailyPriorityTasksTableTableManager(
      $_db,
      $_db.dailyPriorityTasks,
    ).filter((f) => f.taskId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(
      _dailyPriorityTasksRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$TasksTableFilterComposer extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> dailyPriorityTasksRefs(
    Expression<bool> Function($$DailyPriorityTasksTableFilterComposer f) f,
  ) {
    final $$DailyPriorityTasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: $db.dailyPriorityTasks,
      getReferencedColumn: (t) => t.taskId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$DailyPriorityTasksTableFilterComposer(
            $db: $db,
            $table: $db.dailyPriorityTasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$TasksTableOrderingComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueDate => $composableBuilder(
    column: $table.dueDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$TasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $TasksTable> {
  $$TasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get dueDate =>
      $composableBuilder(column: $table.dueDate, builder: (column) => column);

  GeneratedColumn<bool> get isCompleted => $composableBuilder(
    column: $table.isCompleted,
    builder: (column) => column,
  );

  GeneratedColumn<int> get completedAtUtcMicros => $composableBuilder(
    column: $table.completedAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAtUtcMicros => $composableBuilder(
    column: $table.createdAtUtcMicros,
    builder: (column) => column,
  );

  GeneratedColumn<int> get updatedAtUtcMicros => $composableBuilder(
    column: $table.updatedAtUtcMicros,
    builder: (column) => column,
  );

  Expression<T> dailyPriorityTasksRefs<T extends Object>(
    Expression<T> Function($$DailyPriorityTasksTableAnnotationComposer a) f,
  ) {
    final $$DailyPriorityTasksTableAnnotationComposer composer =
        $composerBuilder(
          composer: this,
          getCurrentColumn: (t) => t.id,
          referencedTable: $db.dailyPriorityTasks,
          getReferencedColumn: (t) => t.taskId,
          builder:
              (
                joinBuilder, {
                $addJoinBuilderToRootComposer,
                $removeJoinBuilderFromRootComposer,
              }) => $$DailyPriorityTasksTableAnnotationComposer(
                $db: $db,
                $table: $db.dailyPriorityTasks,
                $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
                joinBuilder: joinBuilder,
                $removeJoinBuilderFromRootComposer:
                    $removeJoinBuilderFromRootComposer,
              ),
        );
    return f(composer);
  }
}

class $$TasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $TasksTable,
          StoredTaskRecord,
          $$TasksTableFilterComposer,
          $$TasksTableOrderingComposer,
          $$TasksTableAnnotationComposer,
          $$TasksTableCreateCompanionBuilder,
          $$TasksTableUpdateCompanionBuilder,
          (StoredTaskRecord, $$TasksTableReferences),
          StoredTaskRecord,
          PrefetchHooks Function({bool dailyPriorityTasksRefs})
        > {
  $$TasksTableTableManager(_$AppDatabase db, $TasksTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$TasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$TasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$TasksTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> dueDate = const Value.absent(),
                Value<bool> isCompleted = const Value.absent(),
                Value<int?> completedAtUtcMicros = const Value.absent(),
                Value<int> createdAtUtcMicros = const Value.absent(),
                Value<int> updatedAtUtcMicros = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion(
                id: id,
                title: title,
                dueDate: dueDate,
                isCompleted: isCompleted,
                completedAtUtcMicros: completedAtUtcMicros,
                createdAtUtcMicros: createdAtUtcMicros,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String title,
                Value<String?> dueDate = const Value.absent(),
                required bool isCompleted,
                Value<int?> completedAtUtcMicros = const Value.absent(),
                required int createdAtUtcMicros,
                required int updatedAtUtcMicros,
                Value<int> rowid = const Value.absent(),
              }) => TasksCompanion.insert(
                id: id,
                title: title,
                dueDate: dueDate,
                isCompleted: isCompleted,
                completedAtUtcMicros: completedAtUtcMicros,
                createdAtUtcMicros: createdAtUtcMicros,
                updatedAtUtcMicros: updatedAtUtcMicros,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) =>
                    (e.readTable(table), $$TasksTableReferences(db, table, e)),
              )
              .toList(),
          prefetchHooksCallback: ({dailyPriorityTasksRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (dailyPriorityTasksRefs) db.dailyPriorityTasks,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (dailyPriorityTasksRefs)
                    await $_getPrefetchedData<
                      StoredTaskRecord,
                      $TasksTable,
                      DailyPriorityTaskRecord
                    >(
                      currentTable: table,
                      referencedTable: $$TasksTableReferences
                          ._dailyPriorityTasksRefsTable(db),
                      managerFromTypedResult: (p0) => $$TasksTableReferences(
                        db,
                        table,
                        p0,
                      ).dailyPriorityTasksRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where((e) => e.taskId == item.id),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
        ),
      );
}

typedef $$TasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $TasksTable,
      StoredTaskRecord,
      $$TasksTableFilterComposer,
      $$TasksTableOrderingComposer,
      $$TasksTableAnnotationComposer,
      $$TasksTableCreateCompanionBuilder,
      $$TasksTableUpdateCompanionBuilder,
      (StoredTaskRecord, $$TasksTableReferences),
      StoredTaskRecord,
      PrefetchHooks Function({bool dailyPriorityTasksRefs})
    >;
typedef $$DailyPriorityTasksTableCreateCompanionBuilder =
    DailyPriorityTasksCompanion Function({
      required String priorityDate,
      required String taskId,
      required int position,
      Value<int> rowid,
    });
typedef $$DailyPriorityTasksTableUpdateCompanionBuilder =
    DailyPriorityTasksCompanion Function({
      Value<String> priorityDate,
      Value<String> taskId,
      Value<int> position,
      Value<int> rowid,
    });

final class $$DailyPriorityTasksTableReferences
    extends
        BaseReferences<
          _$AppDatabase,
          $DailyPriorityTasksTable,
          DailyPriorityTaskRecord
        > {
  $$DailyPriorityTasksTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $TasksTable _taskIdTable(_$AppDatabase db) =>
      db.tasks.createAlias('daily_priority_tasks__task_id__tasks__id');

  $$TasksTableProcessedTableManager get taskId {
    final $_column = $_itemColumn<String>('task_id')!;

    final manager = $$TasksTableTableManager(
      $_db,
      $_db.tasks,
    ).filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_taskIdTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$DailyPriorityTasksTableFilterComposer
    extends Composer<_$AppDatabase, $DailyPriorityTasksTable> {
  $$DailyPriorityTasksTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get priorityDate => $composableBuilder(
    column: $table.priorityDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  $$TasksTableFilterComposer get taskId {
    final $$TasksTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableFilterComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPriorityTasksTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyPriorityTasksTable> {
  $$DailyPriorityTasksTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get priorityDate => $composableBuilder(
    column: $table.priorityDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  $$TasksTableOrderingComposer get taskId {
    final $$TasksTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableOrderingComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPriorityTasksTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyPriorityTasksTable> {
  $$DailyPriorityTasksTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get priorityDate => $composableBuilder(
    column: $table.priorityDate,
    builder: (column) => column,
  );

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  $$TasksTableAnnotationComposer get taskId {
    final $$TasksTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.taskId,
      referencedTable: $db.tasks,
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$TasksTableAnnotationComposer(
            $db: $db,
            $table: $db.tasks,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$DailyPriorityTasksTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyPriorityTasksTable,
          DailyPriorityTaskRecord,
          $$DailyPriorityTasksTableFilterComposer,
          $$DailyPriorityTasksTableOrderingComposer,
          $$DailyPriorityTasksTableAnnotationComposer,
          $$DailyPriorityTasksTableCreateCompanionBuilder,
          $$DailyPriorityTasksTableUpdateCompanionBuilder,
          (DailyPriorityTaskRecord, $$DailyPriorityTasksTableReferences),
          DailyPriorityTaskRecord,
          PrefetchHooks Function({bool taskId})
        > {
  $$DailyPriorityTasksTableTableManager(
    _$AppDatabase db,
    $DailyPriorityTasksTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyPriorityTasksTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyPriorityTasksTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyPriorityTasksTableAnnotationComposer(
                $db: db,
                $table: table,
              ),
          updateCompanionCallback:
              ({
                Value<String> priorityDate = const Value.absent(),
                Value<String> taskId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyPriorityTasksCompanion(
                priorityDate: priorityDate,
                taskId: taskId,
                position: position,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String priorityDate,
                required String taskId,
                required int position,
                Value<int> rowid = const Value.absent(),
              }) => DailyPriorityTasksCompanion.insert(
                priorityDate: priorityDate,
                taskId: taskId,
                position: position,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$DailyPriorityTasksTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({taskId = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (taskId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.taskId,
                                referencedTable:
                                    $$DailyPriorityTasksTableReferences
                                        ._taskIdTable(db),
                                referencedColumn:
                                    $$DailyPriorityTasksTableReferences
                                        ._taskIdTable(db)
                                        .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$DailyPriorityTasksTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyPriorityTasksTable,
      DailyPriorityTaskRecord,
      $$DailyPriorityTasksTableFilterComposer,
      $$DailyPriorityTasksTableOrderingComposer,
      $$DailyPriorityTasksTableAnnotationComposer,
      $$DailyPriorityTasksTableCreateCompanionBuilder,
      $$DailyPriorityTasksTableUpdateCompanionBuilder,
      (DailyPriorityTaskRecord, $$DailyPriorityTasksTableReferences),
      DailyPriorityTaskRecord,
      PrefetchHooks Function({bool taskId})
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$BiblePlansTableTableManager get biblePlans =>
      $$BiblePlansTableTableManager(_db, _db.biblePlans);
  $$BiblePlanSourceItemsTableTableManager get biblePlanSourceItems =>
      $$BiblePlanSourceItemsTableTableManager(_db, _db.biblePlanSourceItems);
  $$BiblePlanScheduleEntriesTableTableManager get biblePlanScheduleEntries =>
      $$BiblePlanScheduleEntriesTableTableManager(
        _db,
        _db.biblePlanScheduleEntries,
      );
  $$BiblePlanScheduleItemsTableTableManager get biblePlanScheduleItems =>
      $$BiblePlanScheduleItemsTableTableManager(
        _db,
        _db.biblePlanScheduleItems,
      );
  $$WordTranslationStatesTableTableManager get wordTranslationStates =>
      $$WordTranslationStatesTableTableManager(_db, _db.wordTranslationStates);
  $$LocalMigrationMetadataTableTableManager get localMigrationMetadata =>
      $$LocalMigrationMetadataTableTableManager(
        _db,
        _db.localMigrationMetadata,
      );
  $$WordReaderStatesTableTableManager get wordReaderStates =>
      $$WordReaderStatesTableTableManager(_db, _db.wordReaderStates);
  $$WordAudioPreferencesTableTableManager get wordAudioPreferences =>
      $$WordAudioPreferencesTableTableManager(_db, _db.wordAudioPreferences);
  $$WordScriptureBookmarksTableTableManager get wordScriptureBookmarks =>
      $$WordScriptureBookmarksTableTableManager(
        _db,
        _db.wordScriptureBookmarks,
      );
  $$WordScriptureHighlightsTableTableManager get wordScriptureHighlights =>
      $$WordScriptureHighlightsTableTableManager(
        _db,
        _db.wordScriptureHighlights,
      );
  $$WordScriptureNotesTableTableManager get wordScriptureNotes =>
      $$WordScriptureNotesTableTableManager(_db, _db.wordScriptureNotes);
  $$WordScriptureNoteAnchorsTableTableManager get wordScriptureNoteAnchors =>
      $$WordScriptureNoteAnchorsTableTableManager(
        _db,
        _db.wordScriptureNoteAnchors,
      );
  $$WordReadingHistoryTableTableManager get wordReadingHistory =>
      $$WordReadingHistoryTableTableManager(_db, _db.wordReadingHistory);
  $$TasksTableTableManager get tasks =>
      $$TasksTableTableManager(_db, _db.tasks);
  $$DailyPriorityTasksTableTableManager get dailyPriorityTasks =>
      $$DailyPriorityTasksTableTableManager(_db, _db.dailyPriorityTasks);
}
