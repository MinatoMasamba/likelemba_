// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'likelemba_model.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types

extension GetLikelembaModelCollection on Isar {
  IsarCollection<LikelembaModel> get likelembaModels => this.collection();
}

const LikelembaModelSchema = CollectionSchema(
  name: r'LikelembaModel',
  id: 4399356721232441177,
  properties: {
    r'basePenaltyRate': PropertySchema(
      id: 0,
      name: r'basePenaltyRate',
      type: IsarType.double,
    ),
    r'createdAt': PropertySchema(
      id: 1,
      name: r'createdAt',
      type: IsarType.dateTime,
    ),
    r'currentBeneficiaryIndex': PropertySchema(
      id: 2,
      name: r'currentBeneficiaryIndex',
      type: IsarType.long,
    ),
    r'currentReserveFund': PropertySchema(
      id: 3,
      name: r'currentReserveFund',
      type: IsarType.double,
    ),
    r'cycleDurationDays': PropertySchema(
      id: 4,
      name: r'cycleDurationDays',
      type: IsarType.long,
    ),
    r'cycleStartDate': PropertySchema(
      id: 5,
      name: r'cycleStartDate',
      type: IsarType.dateTime,
    ),
    r'dailyContribution': PropertySchema(
      id: 6,
      name: r'dailyContribution',
      type: IsarType.double,
    ),
    r'description': PropertySchema(
      id: 7,
      name: r'description',
      type: IsarType.string,
    ),
    r'elapsedDays': PropertySchema(
      id: 8,
      name: r'elapsedDays',
      type: IsarType.long,
    ),
    r'grossJackpot': PropertySchema(
      id: 9,
      name: r'grossJackpot',
      type: IsarType.double,
    ),
    r'groupName': PropertySchema(
      id: 10,
      name: r'groupName',
      type: IsarType.string,
    ),
    r'isCycleCompleted': PropertySchema(
      id: 11,
      name: r'isCycleCompleted',
      type: IsarType.bool,
    ),
    r'isLocked': PropertySchema(
      id: 12,
      name: r'isLocked',
      type: IsarType.bool,
    ),
    r'lockedAt': PropertySchema(
      id: 13,
      name: r'lockedAt',
      type: IsarType.dateTime,
    ),
    r'netJackpot': PropertySchema(
      id: 14,
      name: r'netJackpot',
      type: IsarType.double,
    ),
    r'regenerationTargetDays': PropertySchema(
      id: 15,
      name: r'regenerationTargetDays',
      type: IsarType.long,
    ),
    r'remoteId': PropertySchema(
      id: 16,
      name: r'remoteId',
      type: IsarType.string,
    ),
    r'securityFeeRate': PropertySchema(
      id: 17,
      name: r'securityFeeRate',
      type: IsarType.double,
    )
  },
  estimateSize: _likelembaModelEstimateSize,
  serialize: _likelembaModelSerialize,
  deserialize: _likelembaModelDeserialize,
  deserializeProp: _likelembaModelDeserializeProp,
  idName: r'id',
  indexes: {},
  links: {
    r'adminLink': LinkSchema(
      id: -1994573226648659972,
      name: r'adminLink',
      target: r'UserModel',
      single: true,
    ),
    r'memberLinks': LinkSchema(
      id: -6382007775373192719,
      name: r'memberLinks',
      target: r'UserModel',
      single: false,
    )
  },
  embeddedSchemas: {},
  getId: _likelembaModelGetId,
  getLinks: _likelembaModelGetLinks,
  attach: _likelembaModelAttach,
  version: '3.1.0+1',
);

int _likelembaModelEstimateSize(
  LikelembaModel object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  {
    final value = object.description;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  bytesCount += 3 + object.groupName.length * 3;
  {
    final value = object.remoteId;
    if (value != null) {
      bytesCount += 3 + value.length * 3;
    }
  }
  return bytesCount;
}

void _likelembaModelSerialize(
  LikelembaModel object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeDouble(offsets[0], object.basePenaltyRate);
  writer.writeDateTime(offsets[1], object.createdAt);
  writer.writeLong(offsets[2], object.currentBeneficiaryIndex);
  writer.writeDouble(offsets[3], object.currentReserveFund);
  writer.writeLong(offsets[4], object.cycleDurationDays);
  writer.writeDateTime(offsets[5], object.cycleStartDate);
  writer.writeDouble(offsets[6], object.dailyContribution);
  writer.writeString(offsets[7], object.description);
  writer.writeLong(offsets[8], object.elapsedDays);
  writer.writeDouble(offsets[9], object.grossJackpot);
  writer.writeString(offsets[10], object.groupName);
  writer.writeBool(offsets[11], object.isCycleCompleted);
  writer.writeBool(offsets[12], object.isLocked);
  writer.writeDateTime(offsets[13], object.lockedAt);
  writer.writeDouble(offsets[14], object.netJackpot);
  writer.writeLong(offsets[15], object.regenerationTargetDays);
  writer.writeString(offsets[16], object.remoteId);
  writer.writeDouble(offsets[17], object.securityFeeRate);
}

LikelembaModel _likelembaModelDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = LikelembaModel();
  object.basePenaltyRate = reader.readDouble(offsets[0]);
  object.createdAt = reader.readDateTime(offsets[1]);
  object.currentBeneficiaryIndex = reader.readLong(offsets[2]);
  object.currentReserveFund = reader.readDouble(offsets[3]);
  object.cycleDurationDays = reader.readLong(offsets[4]);
  object.cycleStartDate = reader.readDateTime(offsets[5]);
  object.dailyContribution = reader.readDouble(offsets[6]);
  object.description = reader.readStringOrNull(offsets[7]);
  object.groupName = reader.readString(offsets[10]);
  object.id = id;
  object.isLocked = reader.readBool(offsets[12]);
  object.lockedAt = reader.readDateTimeOrNull(offsets[13]);
  object.regenerationTargetDays = reader.readLong(offsets[15]);
  object.remoteId = reader.readStringOrNull(offsets[16]);
  object.securityFeeRate = reader.readDouble(offsets[17]);
  return object;
}

P _likelembaModelDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readDouble(offset)) as P;
    case 1:
      return (reader.readDateTime(offset)) as P;
    case 2:
      return (reader.readLong(offset)) as P;
    case 3:
      return (reader.readDouble(offset)) as P;
    case 4:
      return (reader.readLong(offset)) as P;
    case 5:
      return (reader.readDateTime(offset)) as P;
    case 6:
      return (reader.readDouble(offset)) as P;
    case 7:
      return (reader.readStringOrNull(offset)) as P;
    case 8:
      return (reader.readLong(offset)) as P;
    case 9:
      return (reader.readDouble(offset)) as P;
    case 10:
      return (reader.readString(offset)) as P;
    case 11:
      return (reader.readBool(offset)) as P;
    case 12:
      return (reader.readBool(offset)) as P;
    case 13:
      return (reader.readDateTimeOrNull(offset)) as P;
    case 14:
      return (reader.readDouble(offset)) as P;
    case 15:
      return (reader.readLong(offset)) as P;
    case 16:
      return (reader.readStringOrNull(offset)) as P;
    case 17:
      return (reader.readDouble(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _likelembaModelGetId(LikelembaModel object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _likelembaModelGetLinks(LikelembaModel object) {
  return [object.adminLink, object.memberLinks];
}

void _likelembaModelAttach(
    IsarCollection<dynamic> col, Id id, LikelembaModel object) {
  object.id = id;
  object.adminLink
      .attach(col, col.isar.collection<UserModel>(), r'adminLink', id);
  object.memberLinks
      .attach(col, col.isar.collection<UserModel>(), r'memberLinks', id);
}

extension LikelembaModelQueryWhereSort
    on QueryBuilder<LikelembaModel, LikelembaModel, QWhere> {
  QueryBuilder<LikelembaModel, LikelembaModel, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension LikelembaModelQueryWhere
    on QueryBuilder<LikelembaModel, LikelembaModel, QWhereClause> {
  QueryBuilder<LikelembaModel, LikelembaModel, QAfterWhereClause> idEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: id,
        upper: id,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterWhereClause> idNotEqualTo(
      Id id) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterWhereClause> idGreaterThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterWhereClause> idLessThan(
      Id id,
      {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(
        lower: lowerId,
        includeLower: includeLower,
        upper: upperId,
        includeUpper: includeUpper,
      ));
    });
  }
}

extension LikelembaModelQueryFilter
    on QueryBuilder<LikelembaModel, LikelembaModel, QFilterCondition> {
  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      basePenaltyRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'basePenaltyRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      basePenaltyRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'basePenaltyRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      basePenaltyRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'basePenaltyRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      basePenaltyRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'basePenaltyRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      createdAtEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      createdAtGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      createdAtLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'createdAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      createdAtBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'createdAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentBeneficiaryIndexEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentBeneficiaryIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentBeneficiaryIndexGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentBeneficiaryIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentBeneficiaryIndexLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentBeneficiaryIndex',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentBeneficiaryIndexBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentBeneficiaryIndex',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentReserveFundEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'currentReserveFund',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentReserveFundGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'currentReserveFund',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentReserveFundLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'currentReserveFund',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      currentReserveFundBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'currentReserveFund',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleDurationDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleDurationDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleDurationDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleDurationDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleDurationDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleDurationDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleDurationDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleDurationDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleStartDateEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'cycleStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleStartDateGreaterThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'cycleStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleStartDateLessThan(
    DateTime value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'cycleStartDate',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      cycleStartDateBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'cycleStartDate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      dailyContributionEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'dailyContribution',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      dailyContributionGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'dailyContribution',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      dailyContributionLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'dailyContribution',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      dailyContributionBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'dailyContribution',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'description',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'description',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'description',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'description',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      descriptionIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'description',
        value: '',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      elapsedDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'elapsedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      elapsedDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'elapsedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      elapsedDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'elapsedDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      elapsedDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'elapsedDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      grossJackpotEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'grossJackpot',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      grossJackpotGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'grossJackpot',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      grossJackpotLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'grossJackpot',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      grossJackpotBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'grossJackpot',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'groupName',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'groupName',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'groupName',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      groupNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'groupName',
        value: '',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition> idEqualTo(
      Id value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'id',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'id',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      isCycleCompletedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isCycleCompleted',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      isLockedEqualTo(bool value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'isLocked',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      lockedAtIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'lockedAt',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      lockedAtIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'lockedAt',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      lockedAtEqualTo(DateTime? value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'lockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      lockedAtGreaterThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'lockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      lockedAtLessThan(
    DateTime? value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'lockedAt',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      lockedAtBetween(
    DateTime? lower,
    DateTime? upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'lockedAt',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      netJackpotEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'netJackpot',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      netJackpotGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'netJackpot',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      netJackpotLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'netJackpot',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      netJackpotBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'netJackpot',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      regenerationTargetDaysEqualTo(int value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'regenerationTargetDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      regenerationTargetDaysGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'regenerationTargetDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      regenerationTargetDaysLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'regenerationTargetDays',
        value: value,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      regenerationTargetDaysBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'regenerationTargetDays',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdIsNotNull() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(const FilterCondition.isNotNull(
        property: r'remoteId',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdEqualTo(
    String? value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdGreaterThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdLessThan(
    String? value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdBetween(
    String? lower,
    String? upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'remoteId',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.startsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.endsWith(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdContains(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.contains(
        property: r'remoteId',
        value: value,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdMatches(String pattern, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.matches(
        property: r'remoteId',
        wildcard: pattern,
        caseSensitive: caseSensitive,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      remoteIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        property: r'remoteId',
        value: '',
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      securityFeeRateEqualTo(
    double value, {
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.equalTo(
        property: r'securityFeeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      securityFeeRateGreaterThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.greaterThan(
        include: include,
        property: r'securityFeeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      securityFeeRateLessThan(
    double value, {
    bool include = false,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.lessThan(
        include: include,
        property: r'securityFeeRate',
        value: value,
        epsilon: epsilon,
      ));
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      securityFeeRateBetween(
    double lower,
    double upper, {
    bool includeLower = true,
    bool includeUpper = true,
    double epsilon = Query.epsilon,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(FilterCondition.between(
        property: r'securityFeeRate',
        lower: lower,
        includeLower: includeLower,
        upper: upper,
        includeUpper: includeUpper,
        epsilon: epsilon,
      ));
    });
  }
}

extension LikelembaModelQueryObject
    on QueryBuilder<LikelembaModel, LikelembaModel, QFilterCondition> {}

extension LikelembaModelQueryLinks
    on QueryBuilder<LikelembaModel, LikelembaModel, QFilterCondition> {
  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition> adminLink(
      FilterQuery<UserModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'adminLink');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      adminLinkIsNull() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'adminLink', 0, true, 0, true);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinks(FilterQuery<UserModel> q) {
    return QueryBuilder.apply(this, (query) {
      return query.link(q, r'memberLinks');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinksLengthEqualTo(int length) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'memberLinks', length, true, length, true);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinksIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'memberLinks', 0, true, 0, true);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinksIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'memberLinks', 0, false, 999999, true);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinksLengthLessThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'memberLinks', 0, true, length, include);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinksLengthGreaterThan(
    int length, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(r'memberLinks', length, include, 999999, true);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterFilterCondition>
      memberLinksLengthBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.linkLength(
          r'memberLinks', lower, includeLower, upper, includeUpper);
    });
  }
}

extension LikelembaModelQuerySortBy
    on QueryBuilder<LikelembaModel, LikelembaModel, QSortBy> {
  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByBasePenaltyRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePenaltyRate', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByBasePenaltyRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePenaltyRate', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> sortByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCurrentBeneficiaryIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBeneficiaryIndex', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCurrentBeneficiaryIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBeneficiaryIndex', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCurrentReserveFund() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentReserveFund', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCurrentReserveFundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentReserveFund', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCycleDurationDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDurationDays', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCycleDurationDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDurationDays', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCycleStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleStartDate', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByCycleStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleStartDate', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByDailyContribution() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyContribution', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByDailyContributionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyContribution', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByElapsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedDays', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByElapsedDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedDays', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByGrossJackpot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossJackpot', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByGrossJackpotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossJackpot', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> sortByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByIsCycleCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCycleCompleted', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByIsCycleCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCycleCompleted', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> sortByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> sortByLockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedAt', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByLockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedAt', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByNetJackpot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netJackpot', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByNetJackpotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netJackpot', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByRegenerationTargetDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regenerationTargetDays', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByRegenerationTargetDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regenerationTargetDays', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> sortByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortBySecurityFeeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityFeeRate', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      sortBySecurityFeeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityFeeRate', Sort.desc);
    });
  }
}

extension LikelembaModelQuerySortThenBy
    on QueryBuilder<LikelembaModel, LikelembaModel, QSortThenBy> {
  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByBasePenaltyRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePenaltyRate', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByBasePenaltyRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'basePenaltyRate', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCreatedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createdAt', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCurrentBeneficiaryIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBeneficiaryIndex', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCurrentBeneficiaryIndexDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentBeneficiaryIndex', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCurrentReserveFund() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentReserveFund', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCurrentReserveFundDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'currentReserveFund', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCycleDurationDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDurationDays', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCycleDurationDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleDurationDays', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCycleStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleStartDate', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByCycleStartDateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cycleStartDate', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByDailyContribution() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyContribution', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByDailyContributionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'dailyContribution', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByDescription() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByDescriptionDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'description', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByElapsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedDays', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByElapsedDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'elapsedDays', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByGrossJackpot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossJackpot', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByGrossJackpotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'grossJackpot', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenByGroupName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByGroupNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'groupName', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByIsCycleCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCycleCompleted', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByIsCycleCompletedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isCycleCompleted', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByIsLockedDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'isLocked', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenByLockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedAt', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByLockedAtDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'lockedAt', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByNetJackpot() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netJackpot', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByNetJackpotDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'netJackpot', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByRegenerationTargetDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regenerationTargetDays', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByRegenerationTargetDaysDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'regenerationTargetDays', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy> thenByRemoteId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenByRemoteIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'remoteId', Sort.desc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenBySecurityFeeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityFeeRate', Sort.asc);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QAfterSortBy>
      thenBySecurityFeeRateDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'securityFeeRate', Sort.desc);
    });
  }
}

extension LikelembaModelQueryWhereDistinct
    on QueryBuilder<LikelembaModel, LikelembaModel, QDistinct> {
  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByBasePenaltyRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'basePenaltyRate');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByCreatedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createdAt');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByCurrentBeneficiaryIndex() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentBeneficiaryIndex');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByCurrentReserveFund() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'currentReserveFund');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByCycleDurationDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cycleDurationDays');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByCycleStartDate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cycleStartDate');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByDailyContribution() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'dailyContribution');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct> distinctByDescription(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'description', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByElapsedDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'elapsedDays');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByGrossJackpot() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'grossJackpot');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct> distinctByGroupName(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'groupName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByIsCycleCompleted() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isCycleCompleted');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct> distinctByIsLocked() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'isLocked');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct> distinctByLockedAt() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'lockedAt');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByNetJackpot() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'netJackpot');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctByRegenerationTargetDays() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'regenerationTargetDays');
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct> distinctByRemoteId(
      {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'remoteId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<LikelembaModel, LikelembaModel, QDistinct>
      distinctBySecurityFeeRate() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'securityFeeRate');
    });
  }
}

extension LikelembaModelQueryProperty
    on QueryBuilder<LikelembaModel, LikelembaModel, QQueryProperty> {
  QueryBuilder<LikelembaModel, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<LikelembaModel, double, QQueryOperations>
      basePenaltyRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'basePenaltyRate');
    });
  }

  QueryBuilder<LikelembaModel, DateTime, QQueryOperations> createdAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createdAt');
    });
  }

  QueryBuilder<LikelembaModel, int, QQueryOperations>
      currentBeneficiaryIndexProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentBeneficiaryIndex');
    });
  }

  QueryBuilder<LikelembaModel, double, QQueryOperations>
      currentReserveFundProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'currentReserveFund');
    });
  }

  QueryBuilder<LikelembaModel, int, QQueryOperations>
      cycleDurationDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cycleDurationDays');
    });
  }

  QueryBuilder<LikelembaModel, DateTime, QQueryOperations>
      cycleStartDateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cycleStartDate');
    });
  }

  QueryBuilder<LikelembaModel, double, QQueryOperations>
      dailyContributionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'dailyContribution');
    });
  }

  QueryBuilder<LikelembaModel, String?, QQueryOperations>
      descriptionProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'description');
    });
  }

  QueryBuilder<LikelembaModel, int, QQueryOperations> elapsedDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'elapsedDays');
    });
  }

  QueryBuilder<LikelembaModel, double, QQueryOperations>
      grossJackpotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'grossJackpot');
    });
  }

  QueryBuilder<LikelembaModel, String, QQueryOperations> groupNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'groupName');
    });
  }

  QueryBuilder<LikelembaModel, bool, QQueryOperations>
      isCycleCompletedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isCycleCompleted');
    });
  }

  QueryBuilder<LikelembaModel, bool, QQueryOperations> isLockedProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'isLocked');
    });
  }

  QueryBuilder<LikelembaModel, DateTime?, QQueryOperations> lockedAtProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'lockedAt');
    });
  }

  QueryBuilder<LikelembaModel, double, QQueryOperations> netJackpotProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'netJackpot');
    });
  }

  QueryBuilder<LikelembaModel, int, QQueryOperations>
      regenerationTargetDaysProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'regenerationTargetDays');
    });
  }

  QueryBuilder<LikelembaModel, String?, QQueryOperations> remoteIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'remoteId');
    });
  }

  QueryBuilder<LikelembaModel, double, QQueryOperations>
      securityFeeRateProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'securityFeeRate');
    });
  }
}
