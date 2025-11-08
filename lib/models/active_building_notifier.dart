import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
      elements: <CachedSData>[],
      passages: [CachedPData(edges: {})],
    );
  }

  void startDraftFromActive() {
    final src = state;
    _sourceBuildingId = src.id;
    final newPassages = [
      for (final p in src.passages)
        CachedPData(edges: p.edges.map((s) => Set<String>.from(s)).toSet()),
    ];
    state = BuildingSnapshot(
      id: kDraftBuildingId,
      name: src.name,
      floorCount: src.floorCount,
      imagePattern: src.imagePattern,
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

  void updateBuildingSettings({String? name, int? floors, String? pattern}) {
    state = state.copyWith(
      name: name ?? state.name,
      floorCount: floors ?? state.floorCount,
      imagePattern: pattern ?? state.imagePattern,
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

  bool hasEdges(String passageId) {
    if (state.passages.isEmpty) return false;
    return state.passages.first.edges.any((set) => set.contains(passageId));
  }

  void rebuildRoomPassageEdges() {
    final passages = state.passages.isEmpty
        ? [CachedPData(edges: {})]
        : state.passages;

    final elementsById = {for (final e in state.elements) e.id: e};

    final cleanedPassages = passages
        .map(
          (p) => CachedPData(
            edges: p.edges.where((edge) {
              if (edge.length != 2) return true;
              final hasRoom = edge.any(
                (id) => elementsById[id]?.type == PlaceType.room,
              );
              return !hasRoom;
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
      final floorPassages = passagesByFloor[entry.key];
      if (floorPassages == null || floorPassages.isEmpty) continue;

      for (final room in entry.value) {
        CachedSData? closest;
        double bestDist = double.infinity;
        for (final p in floorPassages) {
          final dx = room.position.dx - p.position.dx;
          final dy = room.position.dy - p.position.dy;
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
      elements: [for (final e in sourceSnapshot.elements) e],
      passages:
          [
            for (final p in sourceSnapshot.passages)
              CachedPData(
                edges: p.edges.map((s) => Set<String>.from(s)).toSet(),
              ),
          ].isEmpty
          ? [CachedPData(edges: {})]
          : [
              for (final p in sourceSnapshot.passages)
                CachedPData(
                  edges: p.edges.map((s) => Set<String>.from(s)).toSet(),
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

    final String uploadId = switch (_sourceBuildingId) {
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
