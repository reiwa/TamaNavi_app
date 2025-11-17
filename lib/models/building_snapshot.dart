import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

part 'building_snapshot.freezed.dart';

const List<String> kBuildingTagOptions = <String>[
  '全学',
  '理学',
  '工学',
  '教育学',
  '経済学',
  'その他',
];

@freezed
class BuildingSnapshot with _$BuildingSnapshot {
  const factory BuildingSnapshot({
    required String id,
    required String name,
    required int floorCount,
    required String imagePattern,
    required List<String> tags,
    required List<CachedSData> elements,
    required List<CachedPData> passages,
  }) = _BuildingSnapshot;

  const BuildingSnapshot._();

  factory BuildingSnapshot.fromFirestore({
    required Map<String, dynamic> parentJson,
    required List<Map<String, dynamic>> elementsList,
    required int fallbackIndex,
  }) {
    final rawName = parentJson['building_name']?.toString() ?? '';
    final rawId = parentJson['id']?.toString();
    final buildingId = (rawId != null && rawId.isNotEmpty)
        ? rawId
        : (rawName.isNotEmpty ? rawName : 'building_$fallbackIndex');
    final name = rawName.isEmpty ? buildingId : rawName;
    final floorCount = (parentJson['floor_count'] as num?)?.toInt() ?? 1;
    final imagePattern = parentJson['image_pattern']?.toString() ?? '';
    final availableTagSet = kBuildingTagOptions.toSet();
    final rawTags = (parentJson['tags'] as List?) ?? const [];
    final sanitizedTagSet = <String>{};
    for (final rawTag in rawTags) {
      if (rawTag is! String) continue;
      final trimmed = rawTag.trim();
      if (trimmed.isEmpty) continue;
      if (availableTagSet.contains(trimmed)) {
        sanitizedTagSet.add(trimmed);
      }
    }

    final normalizedTags = sanitizedTagSet.isEmpty
        ? <String>['その他']
        : sanitizedTagSet.toList()..sort();

    final elements = <CachedSData>[];
    for (final elementNode in elementsList) {
      final id = elementNode['id']?.toString();
      if (id == null) continue;

      final elementName = elementNode['name']?.toString() ?? '';
      final floor = (elementNode['floor'] as num?)?.toInt() ?? 1;
      final typeName = elementNode['type']?.toString();
      final placeType = PlaceType.values.firstWhere(
        (value) => value.name == typeName,
        orElse: () => PlaceType.room,
      );
      Offset position = Offset.zero;
      final positionNode = elementNode['position'];
      if (positionNode is Map<String, dynamic>) {
        final x = (positionNode['x'] as num?)?.toDouble();
        final y = (positionNode['y'] as num?)?.toDouble();
        if (x != null && y != null) {
          position = Offset(x, y);
        }
      }
      elements.add(
        CachedSData(
          id: id,
          name: elementName,
          position: position,
          floor: floor,
          type: placeType,
        ),
      );
    }

    final edges = <Set<String>>{};
    final edgesMap = parentJson['edges_adjacency_list'];

    if (edgesMap is Map) {
      final addedPairs = <String>{};

      edgesMap.forEach((startId, endIds) {
        if (endIds is List) {
          for (final endId in endIds) {
            final String endIdStr = endId.toString();
            final ids = [startId.toString(), endIdStr]..sort();
            final pairKey = "${ids[0]}|${ids[1]}";

            if (addedPairs.add(pairKey)) {
              edges.add({startId.toString(), endIdStr});
            }
          }
        }
      });
    }

    final passages = <CachedPData>[CachedPData(edges: edges)];

    return BuildingSnapshot(
      id: buildingId,
      name: name,
      floorCount: floorCount,
      imagePattern: imagePattern,
      tags: normalizedTags,
      elements: elements,
      passages: passages,
    );
  }

  Map<String, dynamic> toJson() {
    final edgesMap = <String, List<String>>{};
    final allEdges = passages
        .expand((pData) => pData.edges)
        .where((edge) => edge.length == 2)
        .toList();

    for (final edge in allEdges) {
      final ids = edge.toList();
      final id1 = ids[0];
      final id2 = ids[1];
      edgesMap.putIfAbsent(id1, () => []).add(id2);
      edgesMap.putIfAbsent(id2, () => []).add(id1);
    }

    return {
      "building_name": name,
      "floor_count": floorCount,
      "image_pattern": imagePattern,
      "tags": () {
        final availableTagSet = kBuildingTagOptions.toSet();
        final filtered = <String>[
          for (final tag in tags)
            if (availableTagSet.contains(tag)) tag,
        ];
        if (filtered.isEmpty) {
          filtered.add('その他');
        }
        filtered.sort();
        return filtered;
      }(),
      "edges_adjacency_list": edgesMap,
    };
  }
}

extension BuildingSnapshotX on BuildingSnapshot {
  Iterable<CachedSData> get rooms =>
      elements.where((element) => element.type == PlaceType.room);
}
