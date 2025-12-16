// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'building_snapshot.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$BuildingSnapshot {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  int get floorCount => throw _privateConstructorUsedError;
  String get imagePattern => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  List<CachedSData> get elements => throw _privateConstructorUsedError;
  List<CachedPData> get passages => throw _privateConstructorUsedError;

  /// Create a copy of BuildingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $BuildingSnapshotCopyWith<BuildingSnapshot> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BuildingSnapshotCopyWith<$Res> {
  factory $BuildingSnapshotCopyWith(
    BuildingSnapshot value,
    $Res Function(BuildingSnapshot) then,
  ) = _$BuildingSnapshotCopyWithImpl<$Res, BuildingSnapshot>;
  @useResult
  $Res call({
    String id,
    String name,
    int floorCount,
    String imagePattern,
    List<String> tags,
    List<CachedSData> elements,
    List<CachedPData> passages,
  });
}

/// @nodoc
class _$BuildingSnapshotCopyWithImpl<$Res, $Val extends BuildingSnapshot>
    implements $BuildingSnapshotCopyWith<$Res> {
  _$BuildingSnapshotCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of BuildingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? floorCount = null,
    Object? imagePattern = null,
    Object? tags = null,
    Object? elements = null,
    Object? passages = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            name: null == name
                ? _value.name
                : name // ignore: cast_nullable_to_non_nullable
                      as String,
            floorCount: null == floorCount
                ? _value.floorCount
                : floorCount // ignore: cast_nullable_to_non_nullable
                      as int,
            imagePattern: null == imagePattern
                ? _value.imagePattern
                : imagePattern // ignore: cast_nullable_to_non_nullable
                      as String,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            elements: null == elements
                ? _value.elements
                : elements // ignore: cast_nullable_to_non_nullable
                      as List<CachedSData>,
            passages: null == passages
                ? _value.passages
                : passages // ignore: cast_nullable_to_non_nullable
                      as List<CachedPData>,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$BuildingSnapshotImplCopyWith<$Res>
    implements $BuildingSnapshotCopyWith<$Res> {
  factory _$$BuildingSnapshotImplCopyWith(
    _$BuildingSnapshotImpl value,
    $Res Function(_$BuildingSnapshotImpl) then,
  ) = __$$BuildingSnapshotImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    int floorCount,
    String imagePattern,
    List<String> tags,
    List<CachedSData> elements,
    List<CachedPData> passages,
  });
}

/// @nodoc
class __$$BuildingSnapshotImplCopyWithImpl<$Res>
    extends _$BuildingSnapshotCopyWithImpl<$Res, _$BuildingSnapshotImpl>
    implements _$$BuildingSnapshotImplCopyWith<$Res> {
  __$$BuildingSnapshotImplCopyWithImpl(
    _$BuildingSnapshotImpl _value,
    $Res Function(_$BuildingSnapshotImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of BuildingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? floorCount = null,
    Object? imagePattern = null,
    Object? tags = null,
    Object? elements = null,
    Object? passages = null,
  }) {
    return _then(
      _$BuildingSnapshotImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _value.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        floorCount: null == floorCount
            ? _value.floorCount
            : floorCount // ignore: cast_nullable_to_non_nullable
                  as int,
        imagePattern: null == imagePattern
            ? _value.imagePattern
            : imagePattern // ignore: cast_nullable_to_non_nullable
                  as String,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        elements: null == elements
            ? _value._elements
            : elements // ignore: cast_nullable_to_non_nullable
                  as List<CachedSData>,
        passages: null == passages
            ? _value._passages
            : passages // ignore: cast_nullable_to_non_nullable
                  as List<CachedPData>,
      ),
    );
  }
}

/// @nodoc

class _$BuildingSnapshotImpl extends _BuildingSnapshot {
  const _$BuildingSnapshotImpl({
    required this.id,
    required this.name,
    required this.floorCount,
    required this.imagePattern,
    required final List<String> tags,
    required final List<CachedSData> elements,
    required final List<CachedPData> passages,
  }) : _tags = tags,
       _elements = elements,
       _passages = passages,
       super._();

  @override
  final String id;
  @override
  final String name;
  @override
  final int floorCount;
  @override
  final String imagePattern;
  final List<String> _tags;
  @override
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  final List<CachedSData> _elements;
  @override
  List<CachedSData> get elements {
    if (_elements is EqualUnmodifiableListView) return _elements;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_elements);
  }

  final List<CachedPData> _passages;
  @override
  List<CachedPData> get passages {
    if (_passages is EqualUnmodifiableListView) return _passages;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_passages);
  }

  @override
  String toString() {
    return 'BuildingSnapshot(id: $id, name: $name, floorCount: $floorCount, imagePattern: $imagePattern, tags: $tags, elements: $elements, passages: $passages)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BuildingSnapshotImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.floorCount, floorCount) ||
                other.floorCount == floorCount) &&
            (identical(other.imagePattern, imagePattern) ||
                other.imagePattern == imagePattern) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            const DeepCollectionEquality().equals(other._elements, _elements) &&
            const DeepCollectionEquality().equals(other._passages, _passages));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    floorCount,
    imagePattern,
    const DeepCollectionEquality().hash(_tags),
    const DeepCollectionEquality().hash(_elements),
    const DeepCollectionEquality().hash(_passages),
  );

  /// Create a copy of BuildingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$BuildingSnapshotImplCopyWith<_$BuildingSnapshotImpl> get copyWith =>
      __$$BuildingSnapshotImplCopyWithImpl<_$BuildingSnapshotImpl>(
        this,
        _$identity,
      );
}

abstract class _BuildingSnapshot extends BuildingSnapshot {
  const factory _BuildingSnapshot({
    required final String id,
    required final String name,
    required final int floorCount,
    required final String imagePattern,
    required final List<String> tags,
    required final List<CachedSData> elements,
    required final List<CachedPData> passages,
  }) = _$BuildingSnapshotImpl;
  const _BuildingSnapshot._() : super._();

  @override
  String get id;
  @override
  String get name;
  @override
  int get floorCount;
  @override
  String get imagePattern;
  @override
  List<String> get tags;
  @override
  List<CachedSData> get elements;
  @override
  List<CachedPData> get passages;

  /// Create a copy of BuildingSnapshot
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$BuildingSnapshotImplCopyWith<_$BuildingSnapshotImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
