import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/services/path_finder_logic.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/viewer/interactions/interaction_delegate.dart';

class FinderInteractionDelegate extends InteractionDelegate {
  FinderInteractionDelegate({required super.ref});

  @override
  InteractiveImageState handleTap({
    required InteractiveImageState state,
    required Offset position,
  }) {
    final route = ref.read(activeRouteProvider);
    if (route.isNotEmpty) {
      return state;
    }
    return state.copyWith(tapPosition: position, selectedElement: null);
  }

  @override
  InteractiveImageState handleMarkerTap({
    required InteractiveImageState state,
    required CachedSData element,
    required bool wasSelected,
  }) {
    final newSelected = wasSelected ? null : element;
    return state.copyWith(
      selectedElement: newSelected,
      tapPosition: newSelected?.position,
    );
  }

  @override
  InteractiveImageState activateRoom({
    required InteractiveImageState state,
    required BuildingRoomInfo info,
    required bool switchToDetail,
    bool autoNavigate = true,
  }) {
    final wasSearchMode = state.isSearchMode;

    ref
        .read(activeBuildingProvider.notifier)
        .setActiveBuilding(info.buildingId);
    ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();

    final needsNavigationOnBuild =
        switchToDetail && wasSearchMode && autoNavigate;

    return state.copyWith(
      isSearchMode: switchToDetail ? false : state.isSearchMode,
      selectedRoomInfo: info,
      currentBuildingRoomId: info.room.id,
      needsNavigationOnBuild: needsNavigationOnBuild,
    );
  }

  @override
  InteractiveImageState returnToSearch(InteractiveImageState state) {
    ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();
    return state.copyWith(
      isSearchMode: true,
      selectedRoomInfo: null,
      currentBuildingRoomId: null,
      selectedElement: null,
      tapPosition: null,
    );
  }

  @override
  CachedSData? resolveNavigationTarget(InteractiveImageState state) {
    final active = ref.read(activeBuildingProvider);
    final selected = state.selectedElement;
    if (selected != null) {
      final candidate = _findElementById(active, selected.id);
      if (candidate != null) {
        final route = ref.read(activeRouteProvider);
        final isRouteStart = route.isNotEmpty && route.first.id == candidate.id;
        if (!isRouteStart || state.selectedRoomInfo == null) {
          return candidate;
        }
      }
    }

    final info = state.selectedRoomInfo;
    if (info == null) {
      return null;
    }
    return _findElementById(active, info.room.id);
  }

  @override
  Future<bool> calculateRoute({
    required InteractiveImageState state,
    required String startNodeId,
    required String targetElementId,
  }) async {
    final active = ref.read(activeBuildingProvider);
    final pathfinder = Pathfinder();
    final nodes = pathfinder.findPathFromSnapshot(
      active,
      startNodeId,
      targetElementId,
    );

    if (nodes.isEmpty) {
      ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();
      return false;
    }

    ref.read(activeRouteProvider.notifier).setActiveRouteNodes(nodes);
    return true;
  }

  CachedSData? _findElementById(BuildingSnapshot snapshot, String id) {
    for (final element in snapshot.elements) {
      if (element.id == id) {
        return element;
      }
    }
    return null;
  }
}
