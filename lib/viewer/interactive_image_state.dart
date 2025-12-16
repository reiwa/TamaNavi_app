import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';

part 'interactive_image_state.freezed.dart';

class OffsetConverter implements JsonConverter<Offset, Map<String, dynamic>> {
  const OffsetConverter();
  @override
  Offset fromJson(Map<String, dynamic> json) {
    return Offset(json['dx'] as double, json['dy'] as double);
  }

  @override
  Map<String, dynamic> toJson(Offset object) {
    return {'dx': object.dx, 'dy': object.dy};
  }
}

class NullableOffsetConverter
    implements JsonConverter<Offset?, Map<String, dynamic>?> {
  const NullableOffsetConverter();
  @override
  Offset? fromJson(Map<String, dynamic>? json) {
    if (json == null) return null;
    return Offset(json['dx'] as double, json['dy'] as double);
  }

  @override
  Map<String, dynamic>? toJson(Offset? object) {
    if (object == null) return null;
    return {'dx': object.dx, 'dy': object.dy};
  }
}

@freezed
class InteractiveImageState with _$InteractiveImageState {
  const factory InteractiveImageState({
    @NullableOffsetConverter() Offset? tapPosition,
    CachedSData? selectedElement,

    @Default(false) bool isDragging,
    @Default(false) bool isConnecting,

    CachedSData? connectingStart,
    @NullableOffsetConverter() Offset? previewPosition,

    String? activeBuildingId,

    @Default(1) int currentFloor,

    @Default(1.0) double currentZoomScale,

    @Default(PlaceType.room) PlaceType currentType,

    CachedSData? pendingFocusElement,

    @Default(false) bool suppressClearOnPageChange,

    @Default(true) bool isSearchMode,
    BuildingRoomInfo? selectedRoomInfo,
    String? currentBuildingRoomId,
    @Default(false) bool needsNavigationOnBuild,

    @Default({}) Map<int, Size> imageDimensionsByFloor,

    @Default(true) bool allowStairs,
    @Default(true) bool allowElevators,
  }) = _InteractiveImageState;
}
