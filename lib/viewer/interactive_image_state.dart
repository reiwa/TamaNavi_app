import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:test_project/models/active_building_notifier.dart';
import 'package:test_project/models/building_snapshot.dart';
import 'package:test_project/models/element_data_models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/models/room_finder_models.dart';
import 'package:uuid/uuid.dart';
import 'package:test_project/room_editor/editor_connection_handler.dart';
import 'package:test_project/services/path_finder_logic.dart';

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
  }) = _InteractiveImageState;
}

class InteractiveImageNotifier extends StateNotifier<InteractiveImageState> {
  final TransformationController transformationController =
      TransformationController();

  InteractiveImageNotifier() : super(const InteractiveImageState());

  void setImageDimensions(int floor, Size size) {
    if (state.imageDimensionsByFloor[floor] == size) {
      return;
    }
    state = state.copyWith(
      imageDimensionsByFloor: {...state.imageDimensionsByFloor, floor: size},
    );
  }

  void toggleZoom() {
    final isZoomedOut =
        transformationController.value.getMaxScaleOnAxis() <= 1.0;

    if (isZoomedOut) {
      transformationController.value = Matrix4.identity()..scaleByDouble(1.1, 1.1, 1.1, 1.0);
    } else {
      transformationController.value = Matrix4.identity();
    }

    updateCurrentZoomScale();
  }

  void updateCurrentZoomScale() {
    state = state.copyWith(
      currentZoomScale: transformationController.value.getMaxScaleOnAxis(),
    );
  }

  void updatePreviewPosition(Offset? position) {
    state = state.copyWith(previewPosition: position);
  }

  void clearSelectionState(){
    state = state.copyWith(
      selectedElement: null,
      tapPosition: null,
      isDragging: false,
    );
  }

  void setDragging(bool isDragging) {
    state = state.copyWith(isDragging: isDragging);
  }

  void onTapDetected(Offset position){
    state = state.copyWith(
      selectedElement: null,
      tapPosition: position,
    );
  }

  void handlePageChanged(int pageIndex, WidgetRef ref) {
    final active = ref.read(activeBuildingProvider);

    final suppressClear = state.suppressClearOnPageChange;

    state = state.copyWith(
      currentFloor: active.floorCount - pageIndex,
      activeBuildingId: active.id,
      tapPosition: suppressClear ? state.tapPosition : null,
      selectedElement: suppressClear ? state.selectedElement : null,
      isDragging: false,
    );
  }

  void handleBuildingChanged(String activeBuildingId) {
    state = state.copyWith(
      activeBuildingId: activeBuildingId,
    );
  }

  void handleMarkerTap(CachedSData sData, bool isSelected) {
    if (state.isConnecting) {
      onTapDetected(sData.position);
      return;
    }
    final newSelected = isSelected ? null : sData;
    state = state.copyWith(
      selectedElement: newSelected,
      tapPosition: newSelected?.position,
    );
  }

  void handleMarkerDragEnd(Offset position, bool isSelected, WidgetRef ref) {
    final imgState = state;

    if (!isSelected || imgState.selectedElement == null) {
      state = imgState.copyWith(isDragging: false);
      return;
    }

    final clampedPosition = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );

    final updatedData = imgState.selectedElement!.copyWith(
      position: clampedPosition,
    );
    state = imgState.copyWith(
      isDragging: false,
      selectedElement: updatedData,
      tapPosition: clampedPosition,
    );

    ref.read(activeBuildingProvider.notifier).updateSData(updatedData);
  }

  void applyPendingFocusIfAny() {
    if (state.pendingFocusElement != null) {
      final focus = state.pendingFocusElement!;
      state = state.copyWith(
        selectedElement: focus,
        tapPosition: focus.position,
        pendingFocusElement: null,
        suppressClearOnPageChange: false,
      );
    } else {
      state = state.copyWith(
        pendingFocusElement: null,
        suppressClearOnPageChange: false,
      );
    }
  }

  int? syncToBuilding(WidgetRef ref, {CachedSData? focusElement}) {
    final active = ref.read(activeBuildingProvider);
    final imgState = state;

    final targetFloor = focusElement?.floor ?? 1;
    final clampedFloor = targetFloor < 1
        ? 1
        : (targetFloor > active.floorCount ? active.floorCount : targetFloor);
    final pageIndex = active.floorCount - clampedFloor;

    final needsFloorChange = clampedFloor != imgState.currentFloor;

    if (needsFloorChange && focusElement != null) {
      state = imgState.copyWith(
        activeBuildingId: active.id,
        currentFloor: clampedFloor,
        pendingFocusElement: focusElement,
        suppressClearOnPageChange: true,
        tapPosition: null,
        isDragging: false,
        isConnecting: false,
        connectingStart: null,
        previewPosition: null,
      );
      return pageIndex;
    } else {
      state = imgState.copyWith(
        activeBuildingId: active.id,
        currentFloor: clampedFloor,
        tapPosition: focusElement?.position,
        selectedElement: focusElement,
        isDragging: false,
        isConnecting: false,
        connectingStart: null,
        previewPosition: null,
      );
      return null;
    }
  }

  void updateElementName(String newName, WidgetRef ref) {
    final s = state;
    final sel = s.selectedElement;
    if (s.isDragging || sel == null) return;
    final trimmed = newName.trim();
    if (trimmed == sel.name) return;

    final updated = sel.copyWith(name: trimmed);
    ref.read(activeBuildingProvider.notifier).updateSData(updated);
    state = s.copyWith(selectedElement: updated);
  }

  void updateElementPosition(Offset newPosition, WidgetRef ref) {
    final s = state;
    final sel = s.selectedElement;
    if (s.isDragging || sel == null) return;
    if (sel.position == newPosition) return;

    final clampedPosition = Offset(
      newPosition.dx.clamp(0.0, 1.0),
      newPosition.dy.clamp(0.0, 1.0),
    );

    if (sel.position == clampedPosition) return;

    final updated = sel.copyWith(position: clampedPosition);
    ref.read(activeBuildingProvider.notifier).updateSData(updated);
    state = s.copyWith(selectedElement: updated, tapPosition: clampedPosition);
  }

  void setCurrentType(PlaceType type) {
    state = state.copyWith(currentType: type);
  }

  void handleTapEditor(Offset position, WidgetRef ref) {
    final s = state;
    final active = ref.read(activeBuildingProvider);

    if (s.isConnecting) {
      final tapped = findElementAtPosition(
        position,
        active.elements.where((e) => e.floor == s.currentFloor),
      );
      final start = s.connectingStart;
      final canConnect = start != null && tapped != null && canConnectNodes(start, tapped);
      if (canConnect) {
        ref.read(activeBuildingProvider.notifier).addEdge(start.id, tapped.id);
        state = s.copyWith(
          isConnecting: false,
          connectingStart: null,
          previewPosition: null,
          tapPosition: null,
        );
      }
      return;
    }

    final sel = s.selectedElement;
    if (sel != null) {
      final distance = (position - sel.position).distance;
      if (distance > 12.0) {
        state = s.copyWith(
          selectedElement: null,
          tapPosition: position,
        );
        return;
      }
    }

    final same = s.tapPosition == position;
    state = s.copyWith(
      tapPosition: same ? null : position,
    );
  }

  void toggleConnectionMode() {
    final s = state;
    if (s.isConnecting) {
      state = s.copyWith(
        isConnecting: false,
        connectingStart: null,
        previewPosition: null,
      );
    } else if (s.selectedElement != null && s.selectedElement!.type.isGraphNode) {
      state = s.copyWith(
        isConnecting: true,
        connectingStart: s.selectedElement,
        selectedElement: null,
        tapPosition: null,
        previewPosition: Offset.zero,
      );
    }
  }

  void addElement({
    required String name,
    required Offset position,
    required WidgetRef ref,
  }) {
    final s = state;
    final newSData = CachedSData(
      id: const Uuid().v4(),
      name: name.trim(),
      position: position,
      floor: s.currentFloor,
      type: s.currentType,
    );
    ref.read(activeBuildingProvider.notifier).addSData(newSData);
    state = s.copyWith(
      tapPosition: null,
      selectedElement: null,
    );
  }

  void deleteSelectedElement(WidgetRef ref) {
    final sel = state.selectedElement;
    if (sel == null) return;
    ref.read(activeBuildingProvider.notifier).removeSData(sel);
    state = state.copyWith(
      selectedElement: null,
      tapPosition: null,
    );
  }

  void handleTapFinder(Offset position, WidgetRef ref) {
    final route = ref.read(activeRouteProvider);
    if (route.isNotEmpty) return;

    state = state.copyWith(
      tapPosition: position,
      selectedElement: null,
    );
  }

  void activateRoom(WidgetRef ref, BuildingRoomInfo info, {bool switchToDetail = false}) {
    final wasSearchMode = state.isSearchMode;

    ref.read(activeBuildingProvider.notifier).setActiveBuilding(info.buildingId);

    ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();

    final needsNav = switchToDetail && wasSearchMode;

    state = state.copyWith(
      isSearchMode: switchToDetail ? false : state.isSearchMode,
      selectedRoomInfo: info,
      currentBuildingRoomId: info.room.id,
      needsNavigationOnBuild: needsNav,
    );
  }

  void returnToSearch(WidgetRef ref) {
    ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();
    state = state.copyWith(
      isSearchMode: true,
      selectedRoomInfo: null,
      currentBuildingRoomId: null,
      selectedElement: null,
      tapPosition: null,
    );
  }

  CachedSData? resolveNavigationTarget(WidgetRef ref) {
    final active = ref.read(activeBuildingProvider);
    final selected = state.selectedElement;
    if (selected != null) {
      final candidate = _findElementById(active, selected.id);
      if (candidate != null) {
        final activeRoute = ref.read(activeRouteProvider);
        final bool isRouteStart =
            activeRoute.isNotEmpty && activeRoute.first.id == candidate.id;
        if (!isRouteStart || state.selectedRoomInfo == null) {
          return candidate;
        }
      }
    }
    final info = state.selectedRoomInfo;
    if (info == null) return null;
    return _findElementById(active, info.room.id);
  }

  Future<bool> calculateRoute(WidgetRef ref, {
    required String startNodeId,
    required String targetElementId,
  }) async {
    final active = ref.read(activeBuildingProvider);
    final pathfinder = Pathfinder();
    final routeNodes = pathfinder.findPathFromSnapshot(
      active,
      startNodeId,
      targetElementId,
    );

    if (routeNodes.isEmpty) {
      ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();
      return false;
    } else {
      ref.read(activeRouteProvider.notifier).setActiveRouteNodes(routeNodes);
      return true;
    }
  }

  void clearNeedsNavigationOnBuild() {
    if (state.needsNavigationOnBuild) {
      state = state.copyWith(needsNavigationOnBuild: false);
    }
  }

  CachedSData? _findElementById(BuildingSnapshot snapshot, String id) {
    for (final e in snapshot.elements) {
      if (e.id == id) return e;
    }
    return null;
  }

  @override
  void dispose() {
    transformationController.dispose();
    super.dispose();
  }
}

final interactiveImageProvider = StateNotifierProvider<InteractiveImageNotifier, InteractiveImageState>(
  (ref) => InteractiveImageNotifier(),
);
