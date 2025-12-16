import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

final activeBuildingProvider =
    NotifierProvider<ActiveBuildingNotifier, BuildingSnapshot>(
      ActiveBuildingNotifier.new,
    );

class ActiveBuildingNotifier extends Notifier<BuildingSnapshot> {
  String? _sourceBuildingId;

  String? get sourceBuildingId => _sourceBuildingId;

  @override
  BuildingSnapshot build() {
    final repoValue = ref.watch(buildingRepositoryProvider).asData?.value ?? {};

    BuildingSnapshot? initial;
    for (final entry in repoValue.entries) {
      if (entry.key == kDraftBuildingId) continue;
      initial = entry.value;
      break;
    }
    initial ??= repoValue[kDraftBuildingId];
    _sourceBuildingId = initial?.id;

    return initial ??
        BuildingSnapshot(
          id: kDraftBuildingId,
          name: '新しい建物',
          floorCount: 1,
          imagePattern: '',
          tags: const ['その他'],
          elements: <CachedSData>[],
          passages: [CachedPData(edges: {})],
        );
  }

  void startNewBuildingDraft() {
    _sourceBuildingId = kDraftBuildingId;
    state = BuildingSnapshot(
      id: kDraftBuildingId,
      name: '新しい建物',
      floorCount: 1,
      imagePattern: '',
      tags: const ['その他'],
      elements: <CachedSData>[],
      passages: [CachedPData(edges: {})],
    );
  }

  void startDraftFromActive() {
    final src = state;
    _sourceBuildingId = src.id;
    final newPassages = [
      for (final p in src.passages)
        CachedPData(edges: p.edges.map(Set<String>.from).toSet()),
    ];
    state = BuildingSnapshot(
      id: kDraftBuildingId,
      name: src.name,
      floorCount: src.floorCount,
      imagePattern: src.imagePattern,
      tags: List<String>.from(src.tags),
      elements: [
        for (final e in src.elements)
          CachedSData(
            id: e.id,
            name: e.name,
            position: e.position,
            floor: e.floor,
            type: e.type,
          ),
      ],
      passages: newPassages.isEmpty ? [CachedPData(edges: {})] : newPassages,
    );
  }

  void updateBuildingSettings({
    String? name,
    int? floors,
    String? pattern,
    List<String>? tags,
  }) {
    state = state.copyWith(
      name: name ?? state.name,
      floorCount: floors ?? state.floorCount,
      imagePattern: pattern ?? state.imagePattern,
      tags: tags ?? state.tags,
    );
  }

  void addSData(CachedSData data) {
    final next = [...state.elements, data];
    state = state.copyWith(elements: next);
  }

  void addData(List<CachedSData> data) {
    final next = [...state.elements, ...data];
    state = state.copyWith(elements: next);
  }

  void updateSData(CachedSData updatedData) {
    final idx = state.elements.indexWhere((e) => e.id == updatedData.id);
    if (idx < 0) return;
    final next = [...state.elements]..[idx] = updatedData;
    state = state.copyWith(elements: next);
  }

  void removeSData(CachedSData data) {
    final nextElements = [...state.elements]
      ..removeWhere((e) => e.id == data.id);
    final nextPassages = _removeEdgesLinkedTo(state.passages, data.id);
    state = state.copyWith(elements: nextElements, passages: nextPassages);
  }

  void addPData(CachedPData data) {
    final next = [...state.passages, data];
    state = state.copyWith(passages: next);
  }

  void addEdge(String startId, String endId) {
    if (startId == endId) return;
    final edgeSet = {startId, endId};

    final passages = state.passages.isEmpty
        ? [CachedPData(edges: {})]
        : state.passages;
    final first = passages.first;
    final alreadyExists = first.edges.any(
      (existing) => existing.containsAll(edgeSet),
    );
    if (alreadyExists) return;

    final newFirst = CachedPData(edges: {...first.edges, edgeSet});
    final nextPassages = [newFirst, ...passages.skip(1)];
    state = state.copyWith(passages: nextPassages);
  }

  bool hasEdgeBetween(String startId, String endId) {
    if (startId == endId || state.passages.isEmpty) {
      return false;
    }

    final first = state.passages.first;
    return first.edges.any(
      (edge) => edge.length == 2 && edge.contains(startId) && edge.contains(endId),
    );
  }

  void removeEdge(String startId, String endId) {
    if (startId == endId || state.passages.isEmpty) {
      return;
    }

    final first = state.passages.first;
    final filtered = first.edges.where(
      (edge) => !(edge.length == 2 && edge.contains(startId) && edge.contains(endId)),
    ).toSet();

    if (filtered.length == first.edges.length) {
      return;
    }

    final nextPassages = [CachedPData(edges: filtered), ...state.passages.skip(1)];
    state = state.copyWith(passages: nextPassages);
  }

  bool hasEdges(String passageId) {
    if (state.passages.isEmpty) return false;
    return state.passages.first.edges.any((set) => set.contains(passageId));
  }

  void rebuildRoomPassageEdges(Map<int, Size> imageDimensions) {
    final passages = state.passages.isEmpty
        ? [CachedPData(edges: {})]
        : state.passages;

    final elementsById = {for (final e in state.elements) e.id: e};

    Offset absolutePosition(CachedSData data) {
      final size = imageDimensions[data.floor];
      final width = size?.width ?? 1.0;
      final height = size?.height ?? 1.0;
      return Offset(data.position.dx * width, data.position.dy * height);
    }

    final cleanedPassages = passages
        .map(
          (p) => CachedPData(
            edges: p.edges.where((edge) {
              if (edge.length != 2) return true;
              final ids = edge.toList(growable: false);
              final first = elementsById[ids[0]];
              final second = elementsById[ids[1]];

              final touchesRoom = ids.any(
                (id) => elementsById[id]?.type == PlaceType.room,
              );
              if (touchesRoom) return false;

                final isVerticalPair =
                  first != null &&
                  second != null &&
                  first.type.isVerticalConnector &&
                  first.type == second.type &&
                  second.type.isVerticalConnector &&
                  first.floor != second.floor;

              return !isVerticalPair;
            }).toSet(),
          ),
        )
        .toList();

    final bucket = cleanedPassages.first.edges;
    final existingEdgeKeys = <String>{};
    for (final edge in bucket) {
      if (edge.length != 2) continue;
      final ids = edge.toList()..sort();
      existingEdgeKeys.add('${ids[0]}|${ids[1]}');
    }

    final roomsByFloor = <int, List<CachedSData>>{};
    final passagesByFloor = <int, List<CachedSData>>{};
    for (final e in state.elements) {
      if (e.type == PlaceType.room) {
        roomsByFloor.putIfAbsent(e.floor, () => []).add(e);
      } else if (e.type == PlaceType.passage) {
        passagesByFloor.putIfAbsent(e.floor, () => []).add(e);
      }
    }

    String edgeKey(String a, String b) =>
        (a.compareTo(b) <= 0) ? '$a|$b' : '$b|$a';

    for (final entry in roomsByFloor.entries) {
      final floor = entry.key;
      final floorPassages = passagesByFloor[floor];
      if (floorPassages == null || floorPassages.isEmpty) continue;

      final size = imageDimensions[floor];
      final width = size?.width ?? 1.0;
      final height = size?.height ?? 1.0;

      for (final room in entry.value) {
        CachedSData? closest;
        var bestDist = double.infinity;
        for (final p in floorPassages) {
          final dx = (room.position.dx - p.position.dx) * width;
          final dy = (room.position.dy - p.position.dy) * height;
          final dist = dx * dx + dy * dy;
          if (dist < bestDist) {
            bestDist = dist;
            closest = p;
          }
        }
        if (closest == null) continue;
        final key = edgeKey(room.id, closest.id);
        if (existingEdgeKeys.add(key)) {
          bucket.add({room.id, closest.id});
        }
      }
    }

    const verticalTypes = [PlaceType.elevator, PlaceType.stairs];
    for (final type in verticalTypes) {
      final connectorsByFloor = <int, List<CachedSData>>{};
      for (final element in state.elements) {
        if (element.type != type) continue;
        connectorsByFloor.putIfAbsent(element.floor, () => []).add(element);
      }
      if (connectorsByFloor.isEmpty) continue;

      for (final floorEntry in connectorsByFloor.entries) {
        final floor = floorEntry.key;
        final nodes = floorEntry.value;

        final size = imageDimensions[floor];
        final width = size?.width ?? 1.0;
        final height = size?.height ?? 1.0;

        for (final offset in const [-1, 1]) {
          final adjacentFloor = floor + offset;
          final adjacentNodes = connectorsByFloor[adjacentFloor];
          if (adjacentNodes == null || adjacentNodes.isEmpty) continue;

          for (final node in nodes) {
            final nodePos = Offset(
              node.position.dx * width,
              node.position.dy * height,
            );
            CachedSData? closest;
            var bestDist = double.infinity;

            for (final candidate in adjacentNodes) {
              final candidatePos = Offset(
                candidate.position.dx * width,
                candidate.position.dy * height,
              );
              final dx = nodePos.dx - candidatePos.dx;
              final dy = nodePos.dy - candidatePos.dy;
              final dist = dx * dx + dy * dy;
              if (dist < bestDist) {
                bestDist = dist;
                closest = candidate;
              }
            }

            if (closest == null) continue;
            final key = edgeKey(node.id, closest.id);
            if (existingEdgeKeys.add(key)) {
              bucket.add({node.id, closest.id});
            }
          }
        }
      }
    }

    const connectorTypes = <PlaceType>{
      PlaceType.entrance,
      PlaceType.stairs,
      PlaceType.elevator,
      PlaceType.passage,
    };

    final connectorsByFloor = <int, List<CachedSData>>{};
    for (final element in state.elements) {
      if (!connectorTypes.contains(element.type)) continue;
      connectorsByFloor.putIfAbsent(element.floor, () => []).add(element);
    }

    final connectorLinkCounts = <String, int>{};
    for (final edge in bucket) {
      if (edge.length != 2) continue;
      final ids = edge.toList(growable: false);
      final firstNode = elementsById[ids[0]];
      final secondNode = elementsById[ids[1]];
      if (firstNode == null || secondNode == null) continue;
      if (connectorTypes.contains(firstNode.type) &&
          connectorTypes.contains(secondNode.type)) {
        connectorLinkCounts..update(firstNode.id, (value) => value + 1, ifAbsent: () => 1)
        ..update(secondNode.id, (value) => value + 1, ifAbsent: () => 1);
      }
    }

    for (final entry in connectorsByFloor.entries) {
      final floorNodes = entry.value;
      if (floorNodes.length < 2) continue;

      final absoluteById = <String, Offset>{
        for (final node in floorNodes) node.id: absolutePosition(node),
      };

      for (final node in floorNodes) {
        if ((connectorLinkCounts[node.id] ?? 0) >= 1) continue;

        final nodePos = absoluteById[node.id]!;
        CachedSData? closest;
        var bestDist = double.infinity;

        for (final candidate in floorNodes) {
          if (candidate.id == node.id) continue;
          if ((connectorLinkCounts[candidate.id] ?? 0) >= 1) continue;

          final candidatePos = absoluteById[candidate.id]!;
          final dx = nodePos.dx - candidatePos.dx;
          final dy = nodePos.dy - candidatePos.dy;
          final dist = dx * dx + dy * dy;
          if (dist < bestDist) {
            bestDist = dist;
            closest = candidate;
          }
        }

        if (closest == null) continue;

        final key = edgeKey(node.id, closest.id);
        if (existingEdgeKeys.add(key)) {
          bucket.add({node.id, closest.id});
          connectorLinkCounts[node.id] = (connectorLinkCounts[node.id] ?? 0) + 1;
          connectorLinkCounts[closest.id] =
              (connectorLinkCounts[closest.id] ?? 0) + 1;
        }
      }
    }

    final nextPassages = [
      CachedPData(edges: bucket),
      ...cleanedPassages.skip(1),
    ];
    state = state.copyWith(passages: nextPassages);
  }

  List<CachedPData> _removeEdgesLinkedTo(
    List<CachedPData> passages,
    String nodeId,
  ) {
    if (passages.isEmpty) return [CachedPData(edges: {})];
    final first = passages.first;
    final nextFirst = CachedPData(
      edges: first.edges.where((edge) => !edge.contains(nodeId)).toSet(),
    );
    return [nextFirst, ...passages.skip(1)];
  }

  void commitToRepository() {
    ref.read(buildingRepositoryProvider.notifier).upsert(state);
  }

  void setActiveBuilding(String buildingId) {
    final repo = ref.read(buildingRepositoryProvider);

    final snapshotMap = repo.asData?.value;
    if (snapshotMap == null) return;

    final targetSnapshot = snapshotMap[buildingId];
    if (targetSnapshot == null) return;

    _sourceBuildingId = targetSnapshot.id;
    state = targetSnapshot;
  }

  void startDraftForEditing(String buildingId) {
    final repo = ref.read(buildingRepositoryProvider);
    final snapshotMap = repo.asData?.value;
    final sourceSnapshot = snapshotMap?[buildingId];

    if (sourceSnapshot == null || buildingId == kDraftBuildingId) {
      return;
    }

    _sourceBuildingId = sourceSnapshot.id;

    state = BuildingSnapshot(
      id: kDraftBuildingId,
      name: sourceSnapshot.name,
      floorCount: sourceSnapshot.floorCount,
      imagePattern: sourceSnapshot.imagePattern,
      tags: List<String>.from(sourceSnapshot.tags),
      elements: [for (final e in sourceSnapshot.elements) e],
      passages:
          [
            for (final p in sourceSnapshot.passages)
              CachedPData(
                edges: p.edges.map(Set<String>.from).toSet(),
              ),
          ].isEmpty
          ? [CachedPData(edges: {})]
          : [
              for (final p in sourceSnapshot.passages)
                CachedPData(
                  edges: p.edges.map(Set<String>.from).toSet(),
                ),
            ],
    );
  }

  Future<String> uploadDraftToFirestore() async {
    final draftSnapshot = state;
    final repoNotifier = ref.read(buildingRepositoryProvider.notifier);

    if (draftSnapshot.id != kDraftBuildingId) {
      await repoNotifier.uploadSnapshot(draftSnapshot);
      return draftSnapshot.id;
    }

    final uploadId = switch (_sourceBuildingId) {
      null || kDraftBuildingId => _firestore.collection('buildings').doc().id,
      final id => id,
    };

    final snapshotToUpload = draftSnapshot.copyWith(id: uploadId);

    await repoNotifier.uploadSnapshot(snapshotToUpload);

    _sourceBuildingId = uploadId;
    state = snapshotToUpload;

    return uploadId;
  }
}
