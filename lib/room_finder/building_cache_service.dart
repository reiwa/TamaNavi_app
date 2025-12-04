import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';

final buildingCacheServiceProvider = Provider<BuildingCacheService>((ref) {
  throw UnimplementedError('buildingCacheServiceProvider must be overridden.');
});

final buildingDataBootstrapperProvider =
    Provider<BuildingDataBootstrapper>((ref) {
  final cacheService = ref.watch(buildingCacheServiceProvider);
  return BuildingDataBootstrapper(ref: ref, cacheService: cacheService);
});

class BuildingCacheService {
  BuildingCacheService._(this._box);

  static const String _boxName = 'building_cache';
  static const String _payloadKey = 'payload';

  final Box<dynamic> _box;

  static Future<BuildingCacheService> initialize() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    return BuildingCacheService._(box);
  }

  BuildingCachePayload? readPayload() {
    final raw = _box.get(_payloadKey);
    if (raw is! Map) {
      return null;
    }
    try {
      return BuildingCachePayload.fromJson(Map<String, dynamic>.from(raw));
    } on Exception catch (_) {
      return null;
    }
  }

  Future<void> writePayload(BuildingCachePayload payload) async {
    await _box.put(_payloadKey, payload.toJson());
  }

  Future<void> clear() async {
    await _box.delete(_payloadKey);
  }
}

class BuildingCachePayload {
  const BuildingCachePayload({
    required this.version,
    required this.snapshots,
    required this.includesAllBuildings,
  });

  factory BuildingCachePayload.fromJson(Map<String, dynamic> json) {
    final versionValue = json['version']?.toString();
    if (versionValue == null || versionValue.isEmpty) {
      throw StateError('Invalid cached version value.');
    }

    final rawSnapshots = json['snapshots'];
    final snapshots = <BuildingSnapshot>[];
    if (rawSnapshots is List) {
      for (final entry in rawSnapshots) {
        if (entry is Map) {
          snapshots.add(
            _snapshotFromCacheJson(Map<String, dynamic>.from(entry)),
          );
        }
      }
    }
    final includesAll = json['includesAllBuildings'];
    return BuildingCachePayload(
      version: versionValue,
      snapshots: snapshots,
      includesAllBuildings: includesAll is bool && includesAll,
    );
  }

  final String version;
  final List<BuildingSnapshot> snapshots;
  final bool includesAllBuildings;

  Map<String, dynamic> toJson() {
    return {
      'version': version,
      'snapshots': snapshots.map(_snapshotToCacheJson).toList(),
      'includesAllBuildings': includesAllBuildings,
    };
  }
}

class BuildingDataBootstrapper {
  BuildingDataBootstrapper({
    required this.ref,
    required this.cacheService,
  });

  final Ref ref;
  final BuildingCacheService cacheService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static const String _metadataCollection = 'metadata';
  static const String _buildingsDocId = 'building_data';
  static const String _versionField = 'version';

  Future<void> ensureLatestDataLoaded() async {
    final repository = ref.read(buildingRepositoryProvider.notifier);
    final cachedPayload = cacheService.readPayload();

    if (cachedPayload != null && cachedPayload.snapshots.isNotEmpty) {
      debugPrint(
        '[BuildingBootstrap] Loaded ${cachedPayload.snapshots.length} cached snapshots (version: ${cachedPayload.version}).',
      );
      repository.loadFromCache(
        cachedPayload.snapshots,
        markAllBuildingsLoaded: cachedPayload.includesAllBuildings,
      );
    } else {
      debugPrint('[BuildingBootstrap] No cached building snapshots found.');
    }

    debugPrint(
      '[BuildingBootstrap] Checking remote metadata (cached version: ${cachedPayload?.version ?? 'none'}).',
    );

    final remoteVersion = await _fetchRemoteVersion();
    if (remoteVersion == null) {
      debugPrint('[BuildingBootstrap] Remote version unavailable. Skipping fetch.');
      return;
    }

    debugPrint('[BuildingBootstrap] Remote version: $remoteVersion');
    final hasCompleteCache = cachedPayload?.includesAllBuildings ?? false;
    if (cachedPayload != null &&
        cachedPayload.version == remoteVersion &&
        hasCompleteCache) {
      debugPrint('[BuildingBootstrap] Cache already up to date.');
      return;
    }

    if (!hasCompleteCache) {
      debugPrint('[BuildingBootstrap] Cache missing buildings. Forcing full refresh.');
    }

    debugPrint('[BuildingBootstrap] Version mismatch detected. Fetching all buildings...');
    try {
      final snapshots = await repository.fetchAllBuildings();
      if (snapshots.isEmpty) {
        debugPrint('[BuildingBootstrap] Fetch returned 0 snapshots. Clearing cache.');
        await cacheService.clear();
        return;
      }

      final payload = BuildingCachePayload(
        version: remoteVersion,
        snapshots: snapshots,
        includesAllBuildings: true,
      );
      await cacheService.writePayload(payload);
      debugPrint(
        '[BuildingBootstrap] Cache updated with ${snapshots.length} snapshots (version: $remoteVersion).',
      );
    } on Exception catch (error, stack) {
      debugPrint('[BuildingBootstrap] Failed to refresh cache: $error\n$stack');
    }
  }

  Future<String?> _fetchRemoteVersion() async {
    try {
      final doc = await _firestore
          .collection(_metadataCollection)
          .doc(_buildingsDocId)
          .get();
      if (!doc.exists) {
        return null;
      }
      final data = doc.data();
      final version = data?[_versionField];
      if (version == null) {
        return null;
      }
      return version.toString();
    } on Exception catch (error, stack) {
      debugPrint('[BuildingBootstrap] Failed to read remote metadata: $error\n$stack');
      return null;
    }
  }
}

Map<String, dynamic> _snapshotToCacheJson(BuildingSnapshot snapshot) {
  return {
    'id': snapshot.id,
    'name': snapshot.name,
    'floorCount': snapshot.floorCount,
    'imagePattern': snapshot.imagePattern,
    'tags': snapshot.tags,
    'elements': snapshot.elements.map(_cachedSDataToJson).toList(),
    'passages': snapshot.passages.map(_cachedPDataToJson).toList(),
  };
}

BuildingSnapshot _snapshotFromCacheJson(Map<String, dynamic> json) {
  final elements = <CachedSData>[];
  final elementsRaw = json['elements'];
  if (elementsRaw is List) {
    for (final entry in elementsRaw) {
      if (entry is Map) {
        elements.add(
          _cachedSDataFromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }
  }

  final passages = <CachedPData>[];
  final passagesRaw = json['passages'];
  if (passagesRaw is List && passagesRaw.isNotEmpty) {
    for (final entry in passagesRaw) {
      if (entry is Map) {
        passages.add(
          _cachedPDataFromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }
  }

  if (passages.isEmpty) {
    passages.add(CachedPData(edges: <Set<String>>{}));
  }

  final tags = (json['tags'] as List?)
          ?.map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toList() ??
      <String>[];

  return BuildingSnapshot(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    floorCount: (json['floorCount'] as num?)?.toInt() ?? 1,
    imagePattern: json['imagePattern']?.toString() ?? '',
    tags: tags,
    elements: elements,
    passages: passages,
  );
}

Map<String, dynamic> _cachedSDataToJson(CachedSData data) {
  return {
    'id': data.id,
    'name': data.name,
    'floor': data.floor,
    'type': data.type.name,
    'position': {
      'dx': data.position.dx,
      'dy': data.position.dy,
    },
  };
}

CachedSData _cachedSDataFromJson(Map<String, dynamic> json) {
  final positionNode = json['position'];
  var position = Offset.zero;
  if (positionNode is Map) {
    final dx = (positionNode['dx'] as num?)?.toDouble();
    final dy = (positionNode['dy'] as num?)?.toDouble();
    if (dx != null && dy != null) {
      position = Offset(dx, dy);
    }
  }

  final typeName = json['type']?.toString();
  final placeType = PlaceType.values.firstWhere(
    (value) => value.name == typeName,
    orElse: () => PlaceType.room,
  );

  return CachedSData(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    position: position,
    floor: (json['floor'] as num?)?.toInt() ?? 1,
    type: placeType,
  );
}

Map<String, dynamic> _cachedPDataToJson(CachedPData data) {
  return {
    'edges': data.edges
        .map((edge) => edge.map((value) => value).toList(growable: false))
        .toList(growable: false),
  };
}

CachedPData _cachedPDataFromJson(Map<String, dynamic> json) {
  final edges = <Set<String>>{};
  final edgesRaw = json['edges'];
  if (edgesRaw is List) {
    for (final entry in edgesRaw) {
      if (entry is List && entry.length >= 2) {
        edges.add({entry[0].toString(), entry[1].toString()});
      }
    }
  }
  return CachedPData(edges: edges);
}
