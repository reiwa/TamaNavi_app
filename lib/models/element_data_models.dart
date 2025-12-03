import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tamanavi_app/theme/app_theme.dart';

part 'element_data_models.freezed.dart';

abstract class PlaceDescriptor {
  Color get color;
  bool get isGraphNode;
  String get label;
}

class _PlaceDescriptor implements PlaceDescriptor {
  const _PlaceDescriptor({
    required this.color,
    required this.isGraphNode,
    required this.label,
  });

  @override
  final Color color;
  @override
  final bool isGraphNode;
  @override
  final String label;
}

enum PlaceType implements PlaceDescriptor {
  room(_PlaceDescriptor(color: Colors.blue, isGraphNode: true, label: '部屋')),
  passage(
    _PlaceDescriptor(color: AppPalette.primary, isGraphNode: true, label: '廊下'),
  ),
  elevator(
    _PlaceDescriptor(color: Colors.purple, isGraphNode: true, label: '階段'),
  ),
  entrance(
    _PlaceDescriptor(
      color: AppPalette.secondary,
      isGraphNode: true,
      label: '入口',
    ),
  );

  const PlaceType(this._descriptor);

  final _PlaceDescriptor _descriptor;

  @override
  Color get color => _descriptor.color;

  @override
  bool get isGraphNode => _descriptor.isGraphNode;

  @override
  String get label => _descriptor.label;
}

@freezed
class CachedSData with _$CachedSData {
  const factory CachedSData({
    required String id,
    required String name,
    required Offset position,
    required int floor,
    required PlaceType type,
  }) = _CachedSData;
}

class CachedPData {
  CachedPData({required this.edges});
  Set<Set<String>> edges;
}

class Edge {
  Edge({required this.start, required this.end});
  final Offset start;
  final Offset end;
}

class RouteSegment {
  RouteSegment({required this.from, required this.to});

  final CachedSData from;
  final CachedSData to;

  bool get isSameFloor => from.floor == to.floor;

  bool matches(String startId, String endId) =>
      from.id == startId && to.id == endId;
}

class RouteVisualSegment {
  RouteVisualSegment({
    required this.start,
    required this.end,
    required this.fromType,
    required this.toType,
  });

  final Offset start;
  final Offset end;
  final PlaceType fromType;
  final PlaceType toType;

  bool get touchesEntrance =>
      fromType == PlaceType.entrance || toType == PlaceType.entrance;

  bool get touchesElevator =>
      fromType == PlaceType.elevator || toType == PlaceType.elevator;
}

extension CachedSDataFirestore on CachedSData {
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'position': {'x': position.dx, 'y': position.dy},
      'floor': floor,
      'type': type.name,
    };
  }
}
