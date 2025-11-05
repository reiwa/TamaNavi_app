// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interactive_image_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$InteractiveImageState {
  @NullableOffsetConverter()
  Offset? get tapPosition => throw _privateConstructorUsedError;
  CachedSData? get selectedElement => throw _privateConstructorUsedError;
  bool get isDragging => throw _privateConstructorUsedError;
  bool get isConnecting => throw _privateConstructorUsedError;
  CachedSData? get connectingStart => throw _privateConstructorUsedError;
  @NullableOffsetConverter()
  Offset? get previewPosition => throw _privateConstructorUsedError;
  String? get activeBuildingId => throw _privateConstructorUsedError;
  int get currentFloor => throw _privateConstructorUsedError;
  double get currentZoomScale => throw _privateConstructorUsedError;
  PlaceType get currentType => throw _privateConstructorUsedError;
  CachedSData? get pendingFocusElement => throw _privateConstructorUsedError;
  bool get suppressClearOnPageChange => throw _privateConstructorUsedError;
  bool get isSearchMode => throw _privateConstructorUsedError;
  BuildingRoomInfo? get selectedRoomInfo => throw _privateConstructorUsedError;
  String? get currentBuildingRoomId => throw _privateConstructorUsedError;
  bool get needsNavigationOnBuild => throw _privateConstructorUsedError;
  Map<int, Size> get imageDimensionsByFloor =>
      throw _privateConstructorUsedError;

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $InteractiveImageStateCopyWith<InteractiveImageState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InteractiveImageStateCopyWith<$Res> {
  factory $InteractiveImageStateCopyWith(
    InteractiveImageState value,
    $Res Function(InteractiveImageState) then,
  ) = _$InteractiveImageStateCopyWithImpl<$Res, InteractiveImageState>;
  @useResult
  $Res call({
    @NullableOffsetConverter() Offset? tapPosition,
    CachedSData? selectedElement,
    bool isDragging,
    bool isConnecting,
    CachedSData? connectingStart,
    @NullableOffsetConverter() Offset? previewPosition,
    String? activeBuildingId,
    int currentFloor,
    double currentZoomScale,
    PlaceType currentType,
    CachedSData? pendingFocusElement,
    bool suppressClearOnPageChange,
    bool isSearchMode,
    BuildingRoomInfo? selectedRoomInfo,
    String? currentBuildingRoomId,
    bool needsNavigationOnBuild,
    Map<int, Size> imageDimensionsByFloor,
  });

  $CachedSDataCopyWith<$Res>? get selectedElement;
  $CachedSDataCopyWith<$Res>? get connectingStart;
  $CachedSDataCopyWith<$Res>? get pendingFocusElement;
}

/// @nodoc
class _$InteractiveImageStateCopyWithImpl<
  $Res,
  $Val extends InteractiveImageState
>
    implements $InteractiveImageStateCopyWith<$Res> {
  _$InteractiveImageStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tapPosition = freezed,
    Object? selectedElement = freezed,
    Object? isDragging = null,
    Object? isConnecting = null,
    Object? connectingStart = freezed,
    Object? previewPosition = freezed,
    Object? activeBuildingId = freezed,
    Object? currentFloor = null,
    Object? currentZoomScale = null,
    Object? currentType = null,
    Object? pendingFocusElement = freezed,
    Object? suppressClearOnPageChange = null,
    Object? isSearchMode = null,
    Object? selectedRoomInfo = freezed,
    Object? currentBuildingRoomId = freezed,
    Object? needsNavigationOnBuild = null,
    Object? imageDimensionsByFloor = null,
  }) {
    return _then(
      _value.copyWith(
            tapPosition: freezed == tapPosition
                ? _value.tapPosition
                : tapPosition // ignore: cast_nullable_to_non_nullable
                      as Offset?,
            selectedElement: freezed == selectedElement
                ? _value.selectedElement
                : selectedElement // ignore: cast_nullable_to_non_nullable
                      as CachedSData?,
            isDragging: null == isDragging
                ? _value.isDragging
                : isDragging // ignore: cast_nullable_to_non_nullable
                      as bool,
            isConnecting: null == isConnecting
                ? _value.isConnecting
                : isConnecting // ignore: cast_nullable_to_non_nullable
                      as bool,
            connectingStart: freezed == connectingStart
                ? _value.connectingStart
                : connectingStart // ignore: cast_nullable_to_non_nullable
                      as CachedSData?,
            previewPosition: freezed == previewPosition
                ? _value.previewPosition
                : previewPosition // ignore: cast_nullable_to_non_nullable
                      as Offset?,
            activeBuildingId: freezed == activeBuildingId
                ? _value.activeBuildingId
                : activeBuildingId // ignore: cast_nullable_to_non_nullable
                      as String?,
            currentFloor: null == currentFloor
                ? _value.currentFloor
                : currentFloor // ignore: cast_nullable_to_non_nullable
                      as int,
            currentZoomScale: null == currentZoomScale
                ? _value.currentZoomScale
                : currentZoomScale // ignore: cast_nullable_to_non_nullable
                      as double,
            currentType: null == currentType
                ? _value.currentType
                : currentType // ignore: cast_nullable_to_non_nullable
                      as PlaceType,
            pendingFocusElement: freezed == pendingFocusElement
                ? _value.pendingFocusElement
                : pendingFocusElement // ignore: cast_nullable_to_non_nullable
                      as CachedSData?,
            suppressClearOnPageChange: null == suppressClearOnPageChange
                ? _value.suppressClearOnPageChange
                : suppressClearOnPageChange // ignore: cast_nullable_to_non_nullable
                      as bool,
            isSearchMode: null == isSearchMode
                ? _value.isSearchMode
                : isSearchMode // ignore: cast_nullable_to_non_nullable
                      as bool,
            selectedRoomInfo: freezed == selectedRoomInfo
                ? _value.selectedRoomInfo
                : selectedRoomInfo // ignore: cast_nullable_to_non_nullable
                      as BuildingRoomInfo?,
            currentBuildingRoomId: freezed == currentBuildingRoomId
                ? _value.currentBuildingRoomId
                : currentBuildingRoomId // ignore: cast_nullable_to_non_nullable
                      as String?,
            needsNavigationOnBuild: null == needsNavigationOnBuild
                ? _value.needsNavigationOnBuild
                : needsNavigationOnBuild // ignore: cast_nullable_to_non_nullable
                      as bool,
            imageDimensionsByFloor: null == imageDimensionsByFloor
                ? _value.imageDimensionsByFloor
                : imageDimensionsByFloor // ignore: cast_nullable_to_non_nullable
                      as Map<int, Size>,
          )
          as $Val,
    );
  }

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CachedSDataCopyWith<$Res>? get selectedElement {
    if (_value.selectedElement == null) {
      return null;
    }

    return $CachedSDataCopyWith<$Res>(_value.selectedElement!, (value) {
      return _then(_value.copyWith(selectedElement: value) as $Val);
    });
  }

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CachedSDataCopyWith<$Res>? get connectingStart {
    if (_value.connectingStart == null) {
      return null;
    }

    return $CachedSDataCopyWith<$Res>(_value.connectingStart!, (value) {
      return _then(_value.copyWith(connectingStart: value) as $Val);
    });
  }

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CachedSDataCopyWith<$Res>? get pendingFocusElement {
    if (_value.pendingFocusElement == null) {
      return null;
    }

    return $CachedSDataCopyWith<$Res>(_value.pendingFocusElement!, (value) {
      return _then(_value.copyWith(pendingFocusElement: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$InteractiveImageStateImplCopyWith<$Res>
    implements $InteractiveImageStateCopyWith<$Res> {
  factory _$$InteractiveImageStateImplCopyWith(
    _$InteractiveImageStateImpl value,
    $Res Function(_$InteractiveImageStateImpl) then,
  ) = __$$InteractiveImageStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    @NullableOffsetConverter() Offset? tapPosition,
    CachedSData? selectedElement,
    bool isDragging,
    bool isConnecting,
    CachedSData? connectingStart,
    @NullableOffsetConverter() Offset? previewPosition,
    String? activeBuildingId,
    int currentFloor,
    double currentZoomScale,
    PlaceType currentType,
    CachedSData? pendingFocusElement,
    bool suppressClearOnPageChange,
    bool isSearchMode,
    BuildingRoomInfo? selectedRoomInfo,
    String? currentBuildingRoomId,
    bool needsNavigationOnBuild,
    Map<int, Size> imageDimensionsByFloor,
  });

  @override
  $CachedSDataCopyWith<$Res>? get selectedElement;
  @override
  $CachedSDataCopyWith<$Res>? get connectingStart;
  @override
  $CachedSDataCopyWith<$Res>? get pendingFocusElement;
}

/// @nodoc
class __$$InteractiveImageStateImplCopyWithImpl<$Res>
    extends
        _$InteractiveImageStateCopyWithImpl<$Res, _$InteractiveImageStateImpl>
    implements _$$InteractiveImageStateImplCopyWith<$Res> {
  __$$InteractiveImageStateImplCopyWithImpl(
    _$InteractiveImageStateImpl _value,
    $Res Function(_$InteractiveImageStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tapPosition = freezed,
    Object? selectedElement = freezed,
    Object? isDragging = null,
    Object? isConnecting = null,
    Object? connectingStart = freezed,
    Object? previewPosition = freezed,
    Object? activeBuildingId = freezed,
    Object? currentFloor = null,
    Object? currentZoomScale = null,
    Object? currentType = null,
    Object? pendingFocusElement = freezed,
    Object? suppressClearOnPageChange = null,
    Object? isSearchMode = null,
    Object? selectedRoomInfo = freezed,
    Object? currentBuildingRoomId = freezed,
    Object? needsNavigationOnBuild = null,
    Object? imageDimensionsByFloor = null,
  }) {
    return _then(
      _$InteractiveImageStateImpl(
        tapPosition: freezed == tapPosition
            ? _value.tapPosition
            : tapPosition // ignore: cast_nullable_to_non_nullable
                  as Offset?,
        selectedElement: freezed == selectedElement
            ? _value.selectedElement
            : selectedElement // ignore: cast_nullable_to_non_nullable
                  as CachedSData?,
        isDragging: null == isDragging
            ? _value.isDragging
            : isDragging // ignore: cast_nullable_to_non_nullable
                  as bool,
        isConnecting: null == isConnecting
            ? _value.isConnecting
            : isConnecting // ignore: cast_nullable_to_non_nullable
                  as bool,
        connectingStart: freezed == connectingStart
            ? _value.connectingStart
            : connectingStart // ignore: cast_nullable_to_non_nullable
                  as CachedSData?,
        previewPosition: freezed == previewPosition
            ? _value.previewPosition
            : previewPosition // ignore: cast_nullable_to_non_nullable
                  as Offset?,
        activeBuildingId: freezed == activeBuildingId
            ? _value.activeBuildingId
            : activeBuildingId // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentFloor: null == currentFloor
            ? _value.currentFloor
            : currentFloor // ignore: cast_nullable_to_non_nullable
                  as int,
        currentZoomScale: null == currentZoomScale
            ? _value.currentZoomScale
            : currentZoomScale // ignore: cast_nullable_to_non_nullable
                  as double,
        currentType: null == currentType
            ? _value.currentType
            : currentType // ignore: cast_nullable_to_non_nullable
                  as PlaceType,
        pendingFocusElement: freezed == pendingFocusElement
            ? _value.pendingFocusElement
            : pendingFocusElement // ignore: cast_nullable_to_non_nullable
                  as CachedSData?,
        suppressClearOnPageChange: null == suppressClearOnPageChange
            ? _value.suppressClearOnPageChange
            : suppressClearOnPageChange // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSearchMode: null == isSearchMode
            ? _value.isSearchMode
            : isSearchMode // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedRoomInfo: freezed == selectedRoomInfo
            ? _value.selectedRoomInfo
            : selectedRoomInfo // ignore: cast_nullable_to_non_nullable
                  as BuildingRoomInfo?,
        currentBuildingRoomId: freezed == currentBuildingRoomId
            ? _value.currentBuildingRoomId
            : currentBuildingRoomId // ignore: cast_nullable_to_non_nullable
                  as String?,
        needsNavigationOnBuild: null == needsNavigationOnBuild
            ? _value.needsNavigationOnBuild
            : needsNavigationOnBuild // ignore: cast_nullable_to_non_nullable
                  as bool,
        imageDimensionsByFloor: null == imageDimensionsByFloor
            ? _value._imageDimensionsByFloor
            : imageDimensionsByFloor // ignore: cast_nullable_to_non_nullable
                  as Map<int, Size>,
      ),
    );
  }
}

/// @nodoc

class _$InteractiveImageStateImpl implements _InteractiveImageState {
  const _$InteractiveImageStateImpl({
    @NullableOffsetConverter() this.tapPosition,
    this.selectedElement,
    this.isDragging = false,
    this.isConnecting = false,
    this.connectingStart,
    @NullableOffsetConverter() this.previewPosition,
    this.activeBuildingId,
    this.currentFloor = 1,
    this.currentZoomScale = 1.0,
    this.currentType = PlaceType.room,
    this.pendingFocusElement,
    this.suppressClearOnPageChange = false,
    this.isSearchMode = true,
    this.selectedRoomInfo,
    this.currentBuildingRoomId,
    this.needsNavigationOnBuild = false,
    final Map<int, Size> imageDimensionsByFloor = const {},
  }) : _imageDimensionsByFloor = imageDimensionsByFloor;

  @override
  @NullableOffsetConverter()
  final Offset? tapPosition;
  @override
  final CachedSData? selectedElement;
  @override
  @JsonKey()
  final bool isDragging;
  @override
  @JsonKey()
  final bool isConnecting;
  @override
  final CachedSData? connectingStart;
  @override
  @NullableOffsetConverter()
  final Offset? previewPosition;
  @override
  final String? activeBuildingId;
  @override
  @JsonKey()
  final int currentFloor;
  @override
  @JsonKey()
  final double currentZoomScale;
  @override
  @JsonKey()
  final PlaceType currentType;
  @override
  final CachedSData? pendingFocusElement;
  @override
  @JsonKey()
  final bool suppressClearOnPageChange;
  @override
  @JsonKey()
  final bool isSearchMode;
  @override
  final BuildingRoomInfo? selectedRoomInfo;
  @override
  final String? currentBuildingRoomId;
  @override
  @JsonKey()
  final bool needsNavigationOnBuild;
  final Map<int, Size> _imageDimensionsByFloor;
  @override
  @JsonKey()
  Map<int, Size> get imageDimensionsByFloor {
    if (_imageDimensionsByFloor is EqualUnmodifiableMapView)
      return _imageDimensionsByFloor;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_imageDimensionsByFloor);
  }

  @override
  String toString() {
    return 'InteractiveImageState(tapPosition: $tapPosition, selectedElement: $selectedElement, isDragging: $isDragging, isConnecting: $isConnecting, connectingStart: $connectingStart, previewPosition: $previewPosition, activeBuildingId: $activeBuildingId, currentFloor: $currentFloor, currentZoomScale: $currentZoomScale, currentType: $currentType, pendingFocusElement: $pendingFocusElement, suppressClearOnPageChange: $suppressClearOnPageChange, isSearchMode: $isSearchMode, selectedRoomInfo: $selectedRoomInfo, currentBuildingRoomId: $currentBuildingRoomId, needsNavigationOnBuild: $needsNavigationOnBuild, imageDimensionsByFloor: $imageDimensionsByFloor)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InteractiveImageStateImpl &&
            (identical(other.tapPosition, tapPosition) ||
                other.tapPosition == tapPosition) &&
            (identical(other.selectedElement, selectedElement) ||
                other.selectedElement == selectedElement) &&
            (identical(other.isDragging, isDragging) ||
                other.isDragging == isDragging) &&
            (identical(other.isConnecting, isConnecting) ||
                other.isConnecting == isConnecting) &&
            (identical(other.connectingStart, connectingStart) ||
                other.connectingStart == connectingStart) &&
            (identical(other.previewPosition, previewPosition) ||
                other.previewPosition == previewPosition) &&
            (identical(other.activeBuildingId, activeBuildingId) ||
                other.activeBuildingId == activeBuildingId) &&
            (identical(other.currentFloor, currentFloor) ||
                other.currentFloor == currentFloor) &&
            (identical(other.currentZoomScale, currentZoomScale) ||
                other.currentZoomScale == currentZoomScale) &&
            (identical(other.currentType, currentType) ||
                other.currentType == currentType) &&
            (identical(other.pendingFocusElement, pendingFocusElement) ||
                other.pendingFocusElement == pendingFocusElement) &&
            (identical(
                  other.suppressClearOnPageChange,
                  suppressClearOnPageChange,
                ) ||
                other.suppressClearOnPageChange == suppressClearOnPageChange) &&
            (identical(other.isSearchMode, isSearchMode) ||
                other.isSearchMode == isSearchMode) &&
            (identical(other.selectedRoomInfo, selectedRoomInfo) ||
                other.selectedRoomInfo == selectedRoomInfo) &&
            (identical(other.currentBuildingRoomId, currentBuildingRoomId) ||
                other.currentBuildingRoomId == currentBuildingRoomId) &&
            (identical(other.needsNavigationOnBuild, needsNavigationOnBuild) ||
                other.needsNavigationOnBuild == needsNavigationOnBuild) &&
            const DeepCollectionEquality().equals(
              other._imageDimensionsByFloor,
              _imageDimensionsByFloor,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    tapPosition,
    selectedElement,
    isDragging,
    isConnecting,
    connectingStart,
    previewPosition,
    activeBuildingId,
    currentFloor,
    currentZoomScale,
    currentType,
    pendingFocusElement,
    suppressClearOnPageChange,
    isSearchMode,
    selectedRoomInfo,
    currentBuildingRoomId,
    needsNavigationOnBuild,
    const DeepCollectionEquality().hash(_imageDimensionsByFloor),
  );

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$InteractiveImageStateImplCopyWith<_$InteractiveImageStateImpl>
  get copyWith =>
      __$$InteractiveImageStateImplCopyWithImpl<_$InteractiveImageStateImpl>(
        this,
        _$identity,
      );
}

abstract class _InteractiveImageState implements InteractiveImageState {
  const factory _InteractiveImageState({
    @NullableOffsetConverter() final Offset? tapPosition,
    final CachedSData? selectedElement,
    final bool isDragging,
    final bool isConnecting,
    final CachedSData? connectingStart,
    @NullableOffsetConverter() final Offset? previewPosition,
    final String? activeBuildingId,
    final int currentFloor,
    final double currentZoomScale,
    final PlaceType currentType,
    final CachedSData? pendingFocusElement,
    final bool suppressClearOnPageChange,
    final bool isSearchMode,
    final BuildingRoomInfo? selectedRoomInfo,
    final String? currentBuildingRoomId,
    final bool needsNavigationOnBuild,
    final Map<int, Size> imageDimensionsByFloor,
  }) = _$InteractiveImageStateImpl;

  @override
  @NullableOffsetConverter()
  Offset? get tapPosition;
  @override
  CachedSData? get selectedElement;
  @override
  bool get isDragging;
  @override
  bool get isConnecting;
  @override
  CachedSData? get connectingStart;
  @override
  @NullableOffsetConverter()
  Offset? get previewPosition;
  @override
  String? get activeBuildingId;
  @override
  int get currentFloor;
  @override
  double get currentZoomScale;
  @override
  PlaceType get currentType;
  @override
  CachedSData? get pendingFocusElement;
  @override
  bool get suppressClearOnPageChange;
  @override
  bool get isSearchMode;
  @override
  BuildingRoomInfo? get selectedRoomInfo;
  @override
  String? get currentBuildingRoomId;
  @override
  bool get needsNavigationOnBuild;
  @override
  Map<int, Size> get imageDimensionsByFloor;

  /// Create a copy of InteractiveImageState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$InteractiveImageStateImplCopyWith<_$InteractiveImageStateImpl>
  get copyWith => throw _privateConstructorUsedError;
}
