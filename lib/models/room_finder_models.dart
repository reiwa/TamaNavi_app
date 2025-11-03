import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/models/active_building_notifier.dart';
import 'package:test_project/models/building_snapshot.dart';
import 'package:test_project/models/element_data_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const String kDraftBuildingId = '__editor_draft__';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class BuildingRoomInfo {
  BuildingRoomInfo({
    required this.buildingId,
    required this.buildingName,
    required this.room,
  });

  final String buildingId;
  final String buildingName;
  final CachedSData room;
}

final buildingRepositoryProvider =
    AsyncNotifierProvider<BuildingRepository, Map<String, BuildingSnapshot>>(
      BuildingRepository.new,
    );

class BuildingRepository extends AsyncNotifier<Map<String, BuildingSnapshot>> {
  @override
  Future<Map<String, BuildingSnapshot>> build() async {
    return _fetchDataFromFirestore();
  }

  Future<Map<String, BuildingSnapshot>> _fetchDataFromFirestore() async {
    state = const AsyncLoading();
    try {
      final querySnapshot = await _firestore.collection('buildings').get();

      final result = <String, BuildingSnapshot>{};
      int fallbackIndex = 0;

      for (final doc in querySnapshot.docs) {
        final Map<String, dynamic> node = doc.data();
        fallbackIndex += 1;

        node.putIfAbsent('id', () => doc.id);

        final elementsQuery = await doc.reference.collection('elements').get();

        final List<Map<String, dynamic>> elementsList = elementsQuery.docs.map((
          elDoc,
        ) {
          final data = elDoc.data();
          data.putIfAbsent('id', () => elDoc.id);
          return data;
        }).toList();

        final snapshot = BuildingSnapshot.fromFirestore(
          parentJson: node,
          elementsList: elementsList,
          fallbackIndex: fallbackIndex,
        );
        result[snapshot.id] = snapshot;
      }
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final result = await _fetchDataFromFirestore();
      state = AsyncData(result);
    } catch (e, s) {
      state = AsyncError(e, s);
    }
  }

  void upsert(BuildingSnapshot snapshot) {
    final current = state.asData?.value ?? <String, BuildingSnapshot>{};
    state = AsyncData({...current, snapshot.id: snapshot});
  }

  void remove(String id) {
    final current = state.asData?.value ?? <String, BuildingSnapshot>{};
    if (!current.containsKey(id)) return;
    final next = Map<String, BuildingSnapshot>.from(current)..remove(id);
    state = AsyncData(next);
  }

  BuildingSnapshot? getById(String id) {
    final current = state.asData?.value;
    if (current == null) return null;
    return current[id];
  }

  bool get hasDraft =>
      (state.asData?.value ?? const {}).containsKey(kDraftBuildingId);

  String? get firstNonDraftBuildingId {
    final current = state.asData?.value ?? const {};
    for (final entry in current.entries) {
      if (entry.key == kDraftBuildingId) continue;
      return entry.key;
    }
    return null;
  }

  List<BuildingRoomInfo> getAllRoomInfos() {
    final current = state.asData?.value ?? const {};
    final result = <BuildingRoomInfo>[];
    for (final snapshot in current.values) {
      if (snapshot.id == kDraftBuildingId) continue;
      for (final room in snapshot.rooms) {
        result.add(
          BuildingRoomInfo(
            buildingId: snapshot.id,
            buildingName: snapshot.name,
            room: room,
          ),
        );
      }
    }
    return result;
  }

  Future<void> uploadSnapshot(BuildingSnapshot snapshot) async {
    if (snapshot.id == kDraftBuildingId) {
      throw Exception('ドラフトIDのままアップロードすることはできません。');
    }

    final buildingDocRef = _firestore.collection('buildings').doc(snapshot.id);
    final elementsCollectionRef = buildingDocRef.collection('elements');

    final batch = _firestore.batch();

    batch.set(buildingDocRef, snapshot.toJson());

    final oldElementsQuery = await elementsCollectionRef.get();
    final oldElementIds = oldElementsQuery.docs.map((doc) => doc.id).toSet();

    final newElementIds = snapshot.elements.map((el) => el.id).toSet();

    for (final element in snapshot.elements) {
      final elementDocRef = elementsCollectionRef.doc(element.id);
      batch.set(elementDocRef, element.toJson());
    }

    final idsToDelete = oldElementIds.difference(newElementIds);
    for (final idToDelete in idsToDelete) {
      final elementDocRef = elementsCollectionRef.doc(idToDelete);
      batch.delete(elementDocRef);
    }

    try {
      await batch.commit();

      upsert(snapshot);
    } catch (e) {
      print('Firestore へのアップロード中にエラーが発生しました: $e');
      rethrow;
    }
  }
}

final graphNodePositionsProvider = Provider.family<Map<String, Offset>, int>((
  ref,
  floor,
) {
  final snap = ref.watch(activeBuildingProvider);
  return {
    for (final s in snap.elements.where(
      (e) => e.type.isGraphNode && e.floor == floor,
    ))
      s.id: s.position,
  };
});

final graphEdgesProvider = Provider.family<List<Edge>, int>((ref, floor) {
  final positions = ref.watch(graphNodePositionsProvider(floor));
  final snap = ref.watch(activeBuildingProvider);
  final edges = <Edge>[];
  for (final p in snap.passages) {
    for (final set in p.edges) {
      if (set.length != 2) continue;
      final ids = set.toList();
      final a = positions[ids[0]];
      final b = positions[ids[1]];
      if (a != null && b != null) {
        edges.add(Edge(start: a, end: b));
      }
    }
  }
  return edges;
});

final activeRouteProvider =
    NotifierProvider<ActiveRouteNotifier, List<CachedSData>>(
      ActiveRouteNotifier.new,
    );

class ActiveRouteNotifier extends Notifier<List<CachedSData>> {
  @override
  List<CachedSData> build() => <CachedSData>[];

  void setActiveRouteNodes(List<CachedSData> nodes) {
    state = List<CachedSData>.from(nodes);
  }

  void clearActiveRouteNodes() {
    if (state.isEmpty) return;
    state = <CachedSData>[];
  }
}

final activeRouteSegmentsProvider = Provider<List<RouteSegment>>((ref) {
  final nodes = ref.watch(activeRouteProvider);
  final segments = <RouteSegment>[];
  for (var i = 0; i < nodes.length - 1; i++) {
    segments.add(RouteSegment(from: nodes[i], to: nodes[i + 1]));
  }
  return segments;
});

final buildingRoomInfosProvider = Provider<List<BuildingRoomInfo>>((ref) {
  final repo = ref.watch(buildingRepositoryProvider);
  return repo.maybeWhen(
    data: (map) {
      final list = <BuildingRoomInfo>[];
      for (final snapshot in map.values) {
        if (snapshot.id == kDraftBuildingId) continue;
        for (final room in snapshot.rooms) {
          list.add(
            BuildingRoomInfo(
              buildingId: snapshot.id,
              buildingName: snapshot.name,
              room: room,
            ),
          );
        }
      }
      return list;
    },
    orElse: () => <BuildingRoomInfo>[],
  );
});

final sortedBuildingRoomInfosProvider = Provider<List<BuildingRoomInfo>>((ref) {
  final rooms = ref.watch(buildingRoomInfosProvider);

  final listToSort = List<BuildingRoomInfo>.from(rooms);
  listToSort.sort((a, b) {
    final buildingCompare = a.buildingName.compareTo(b.buildingName);
    if (buildingCompare != 0) return buildingCompare;
    final aName = a.room.name.isEmpty ? a.room.id : a.room.name;
    final bName = b.room.name.isEmpty ? b.room.id : b.room.name;
    final roomCompare = aName.compareTo(bName);
    if (roomCompare != 0) return roomCompare;
    return a.room.id.compareTo(b.room.id);
  });

  return listToSort;
});
