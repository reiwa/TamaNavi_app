import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod/src/providers/future_provider.dart';
import 'package:riverpod/src/providers/provider.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

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
  bool _allBuildingsLoaded = false;
  @override
  Future<Map<String, BuildingSnapshot>> build() async {
    return <String, BuildingSnapshot>{};
  }

  Map<String, BuildingSnapshot> get _currentSnapshots =>
      state.asData?.value ?? const <String, BuildingSnapshot>{};

  void loadFromCache(
    List<BuildingSnapshot> snapshots, {
    required bool markAllBuildingsLoaded,
  }) {
    if (snapshots.isEmpty) {
      return;
    }
    final next = <String, BuildingSnapshot>{
      for (final snapshot in snapshots) snapshot.id: snapshot,
    };
    final draft = _currentSnapshots[kDraftBuildingId];
    if (draft != null) {
      next[kDraftBuildingId] = draft;
    }
    state = AsyncData(next);
    _allBuildingsLoaded = markAllBuildingsLoaded;
  }

  Future<void> ensureTagLoaded(String tag) async {
    if (_hasSnapshotsForTag(tag)) {
      return;
    }
    await fetchBuildingsByTag(tag);
  }

  Future<void> ensureAllBuildingsLoaded() async {
    if (_allBuildingsLoaded) {
      return;
    }
    await fetchAllBuildings();
  }

  Future<List<BuildingSnapshot>> fetchBuildingsByTag(String tag) async {
    final current = Map<String, BuildingSnapshot>.from(_currentSnapshots);
    try {
      final query = await _firestore
          .collection('buildings')
          .where('tags', arrayContains: tag)
          .get();

      if (query.docs.isEmpty) {
        return const [];
      }

      var fallbackIndex = current.length;
      final pending = <({
        Map<String, dynamic> parentJson,
        DocumentReference<Map<String, dynamic>> docRef,
        int fallbackIndex,
      })>[];
      final orderedIds = <String>[];

      for (final doc in query.docs) {
        final parentJson = Map<String, dynamic>.from(doc.data())
          ..putIfAbsent('id', () => doc.id);
        final buildingId = parentJson['id']?.toString() ?? doc.id;
        orderedIds.add(buildingId);
        if (current.containsKey(buildingId)) {
          continue;
        }
        pending.add((
          parentJson: parentJson,
          docRef: doc.reference,
          fallbackIndex: ++fallbackIndex,
        ));
      }

      if (pending.isNotEmpty) {
        final fetched = await Future.wait(
          pending.map(
            (entry) => _snapshotFromParent(
              parentJson: entry.parentJson,
              docRef: entry.docRef,
              fallbackIndex: entry.fallbackIndex,
            ),
          ),
        );
        for (final snapshot in fetched) {
          current[snapshot.id] = snapshot;
        }
        state = AsyncData(current);
      }

      final result = <BuildingSnapshot>[];
      for (final id in orderedIds) {
        final snapshot = current[id];
        if (snapshot != null) {
          result.add(snapshot);
        }
      }
      return result;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<List<BuildingSnapshot>> fetchAllBuildings() async {
    final current = Map<String, BuildingSnapshot>.from(_currentSnapshots);
    try {
      final query = await _firestore.collection('buildings').get();
      if (query.docs.isEmpty) {
        state = AsyncData(current);
        return const <BuildingSnapshot>[];
      }

      var fallbackIndex = current.length;
      final fetched = await Future.wait(
        query.docs.map((doc) {
          final parentJson = Map<String, dynamic>.from(doc.data())
            ..putIfAbsent('id', () => doc.id);
          return _snapshotFromParent(
            parentJson: parentJson,
            docRef: doc.reference,
            fallbackIndex: ++fallbackIndex,
          );
        }),
      );

      for (final snapshot in fetched) {
        current[snapshot.id] = snapshot;
      }

      state = AsyncData(current);
      _allBuildingsLoaded = true;
      return fetched;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<BuildingSnapshot?> ensureBuildingLoaded(String buildingId) async {
    final current = Map<String, BuildingSnapshot>.from(_currentSnapshots);
    final existing = current[buildingId];
    if (existing != null) {
      return existing;
    }

    try {
      final doc =
          await _firestore.collection('buildings').doc(buildingId).get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }

      final parentJson = Map<String, dynamic>.from(data)
        ..putIfAbsent('id', () => doc.id);

      final snapshot = await _snapshotFromParent(
        parentJson: parentJson,
        docRef: doc.reference,
        fallbackIndex: current.length + 1,
      );
      current[snapshot.id] = snapshot;
      state = AsyncData(current);
      return snapshot;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<BuildingSnapshot?> fetchBuildingContainingRoom(String roomId) async {
    final current = Map<String, BuildingSnapshot>.from(_currentSnapshots);
    for (final snapshot in current.values) {
      final hasRoom =
          snapshot.elements.any((element) => element.id == roomId);
      if (hasRoom) {
        return snapshot;
      }
    }

    try {
      final query = await _firestore
          .collectionGroup('elements')
          .where('id', isEqualTo: roomId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) {
        return null;
      }

      final buildingRef = query.docs.first.reference.parent.parent;
      if (buildingRef == null) {
        return null;
      }

      final doc = await buildingRef.get();
      final data = doc.data();
      if (!doc.exists || data == null) {
        return null;
      }

      final parentJson = Map<String, dynamic>.from(data)
        ..putIfAbsent('id', () => doc.id);

      final snapshot = await _snapshotFromParent(
        parentJson: parentJson,
        docRef: doc.reference,
        fallbackIndex: current.length + 1,
      );
      current[snapshot.id] = snapshot;
      state = AsyncData(current);
      return snapshot;
    } catch (e, s) {
      state = AsyncError(e, s);
      rethrow;
    }
  }

  Future<BuildingSnapshot> _snapshotFromParent({
    required Map<String, dynamic> parentJson,
    required DocumentReference<Map<String, dynamic>> docRef,
    required int fallbackIndex,
  }) async {
    final elementsQuery = await docRef.collection('elements').get();
    final elementsList = elementsQuery.docs.map((elDoc) {
      final data = elDoc.data();
      data.putIfAbsent('id', () => elDoc.id);
      return data;
    }).toList();

    return BuildingSnapshot.fromFirestore(
      parentJson: Map<String, dynamic>.from(parentJson),
      elementsList: elementsList,
      fallbackIndex: fallbackIndex,
    );
  }

  void upsert(BuildingSnapshot snapshot) {
    final current = Map<String, BuildingSnapshot>.from(_currentSnapshots);
    current[snapshot.id] = snapshot;
    state = AsyncData(current);
  }

  void remove(String id) {
    final current = Map<String, BuildingSnapshot>.from(_currentSnapshots);
    if (!current.containsKey(id)) return;
    current.remove(id);
    state = AsyncData(current);
  }

  BuildingSnapshot? getById(String id) {
    return _currentSnapshots[id];
  }

  bool get hasDraft =>
      _currentSnapshots.containsKey(kDraftBuildingId);

  String? get firstNonDraftBuildingId {
    for (final entry in _currentSnapshots.entries) {
      if (entry.key == kDraftBuildingId) continue;
      return entry.key;
    }
    return null;
  }

  List<BuildingRoomInfo> getAllRoomInfos() {
    final current = _currentSnapshots;
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
      rethrow;
    }
  }

  bool _hasSnapshotsForTag(String tag) {
    for (final snapshot in _currentSnapshots.values) {
      if (snapshot.tags.contains(tag)) {
        return true;
      }
    }
    return false;
  }
}

final ProviderFamily<Map<String, Offset>, int> graphNodePositionsProvider = Provider.family<Map<String, Offset>, int>((
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

final ProviderFamily<List<Edge>, int> graphEdgesProvider = Provider.family<List<Edge>, int>((ref, floor) {
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

typedef FloorImageKey = ({String imagePattern, int floor});

const String _floorImageFolder = 'gs://saidai-roomfinder.firebasestorage.app';
const int _maxSvgFetchBytes = 50 * 1024 * 1024;

FloorImageKey _normalizeFloorImageKey(FloorImageKey key) =>
    (imagePattern: key.imagePattern.trim(), floor: key.floor);

class FloorImagePatternMissingException implements Exception {
  const FloorImagePatternMissingException(this.key);

  final FloorImageKey key;

  String get message => '${key.floor}階の画像パスを適切に設定してから再度試してください。';

  @override
  String toString() => message;
}

final FutureProviderFamily<String, FloorImageKey> floorImageUrlProvider = FutureProvider.family<String, FloorImageKey>((
  ref,
  key,
) async {
  final normalizedKey = _normalizeFloorImageKey(key);
  if (normalizedKey.imagePattern.isEmpty) {
    throw FloorImagePatternMissingException(normalizedKey);
  }

  final storageRef = FirebaseStorage.instance.refFromURL(
    '$_floorImageFolder/${normalizedKey.imagePattern}_${normalizedKey.floor}f.svg',
  );
  final url = await storageRef.getDownloadURL();
  return url;
});

final floorImagePrefetchNotifierProvider =
    NotifierProvider<FloorImagePrefetchNotifier, Set<FloorImageKey>>(
      FloorImagePrefetchNotifier.new,
    );

class FloorImagePrefetchNotifier extends Notifier<Set<FloorImageKey>> {
  FloorImagePrefetchNotifier();

  final Set<FloorImageKey> _inFlight = <FloorImageKey>{};
  final Set<FloorImageKey> _failed = <FloorImageKey>{};

  @override
  Set<FloorImageKey> build() => <FloorImageKey>{};

  Future<void> ensurePrefetched(FloorImageKey key) async {
    final normalizedKey = _normalizeFloorImageKey(key);
    if (normalizedKey.imagePattern.isEmpty) {
      return;
    }
    if (state.contains(normalizedKey) ||
        _inFlight.contains(normalizedKey) ||
        _failed.contains(normalizedKey)) {
      return;
    }

    _inFlight.add(normalizedKey);
    try {
      final url = await ref.read(floorImageUrlProvider(normalizedKey).future);
      await ref.read(svgPayloadProvider(url).future);

      final nextState = Set<FloorImageKey>.from(state)..add(normalizedKey);
      state = nextState;
    } catch (_) {
      _failed.add(normalizedKey);
    } finally {
      _inFlight.remove(normalizedKey);
    }
  }
}

class SvgPayload {
  const SvgPayload({required this.bytes, required this.size});

  final Uint8List bytes;
  final Size size;
}

final FutureProviderFamily<SvgPayload, String> svgPayloadProvider = FutureProvider.family<SvgPayload, String>((
  ref,
  url,
) async {
  final storageRef = FirebaseStorage.instance.refFromURL(url);
  final rawBytes = await storageRef
      .getData(_maxSvgFetchBytes)
      .timeout(const Duration(seconds: 15));
  if (rawBytes == null || rawBytes.isEmpty) {
    throw StateError('Empty SVG data for $url');
  }
  final size = _parseSvgSize(rawBytes);
  return SvgPayload(bytes: rawBytes, size: size);
});

Size _parseSvgSize(Uint8List svgBytes) {
  final svgString = utf8.decode(svgBytes);
  final width = _parseSvgLength(_extractSvgAttribute(svgString, 'width'));
  final height = _parseSvgLength(_extractSvgAttribute(svgString, 'height'));

  if (width != null && height != null && width > 0 && height > 0) {
    return Size(width, height);
  }

  final viewBox = _extractSvgAttribute(svgString, 'viewBox');
  if (viewBox != null) {
    final parts = viewBox
        .split(RegExp(r'[\s,]+'))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (parts.length == 4) {
      final vbWidth = double.tryParse(parts[2]);
      final vbHeight = double.tryParse(parts[3]);
      if (vbWidth != null && vbHeight != null && vbWidth > 0 && vbHeight > 0) {
        return Size(vbWidth, vbHeight);
      }
    }
  }

  return const Size.square(1024);
}

String? _extractSvgAttribute(String svgContent, String attribute) {
  final regex = RegExp('$attribute\\s*=\\s*"([^"]+)"', caseSensitive: false);
  final match = regex.firstMatch(svgContent);
  return match?.group(1)?.trim();
}

double? _parseSvgLength(String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  final trimmed = rawValue.trim();
  final valueMatch = RegExp(r'(-?\d*\.?\d+)').firstMatch(trimmed);
  if (valueMatch == null) {
    return null;
  }

  return double.tryParse(valueMatch.group(1)!);
}

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
