import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/viewer/interactions/interaction_delegate.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';

class InteractiveImageNotifier extends StateNotifier<InteractiveImageState> {
  InteractiveImageNotifier({
    required this.ref,
    required InteractionDelegate delegate,
  }) : _delegate = delegate,
       transformationController = TransformationController(),
       super(const InteractiveImageState());

  final Ref ref;
  final InteractionDelegate _delegate;
  final TransformationController transformationController;

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
      transformationController.value = Matrix4.identity()
        ..scaleByDouble(1.1, 1.1, 1.1, 1);
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

  void clearSelectionState() {
    state = state.copyWith(
      selectedElement: null,
      tapPosition: null,
      isDragging: false,
    );
  }

  void setDragging({required bool isDragging}) {
    state = state.copyWith(isDragging: isDragging);
  }

  void onTapDetected(Offset position) {
    state = _delegate.handleTap(state: state, position: position);
  }

  void handlePageChanged(int pageIndex) {
    final active = ref.read(activeBuildingProvider);
    final newFloor = active.floorCount - pageIndex;
    final suppressClear = state.suppressClearOnPageChange;

    final prevSelected = state.selectedElement;

    final nextSelected = suppressClear ? state.selectedElement : prevSelected;
    final nextTapPosition = suppressClear
        ? state.tapPosition
        : (prevSelected != null && prevSelected.floor == newFloor
              ? prevSelected.position
              : null);

    state = state.copyWith(
      currentFloor: newFloor,
      activeBuildingId: active.id,
      selectedElement: nextSelected,
      tapPosition: nextTapPosition,
      isDragging: false,
    );
  }

  void handleBuildingChanged(String activeBuildingId) {
    if (state.activeBuildingId != activeBuildingId) {
      transformationController.value = Matrix4.identity();
      state = InteractiveImageState(activeBuildingId: activeBuildingId);
    } else {
      state = state.copyWith(activeBuildingId: activeBuildingId);
    }
  }

  void handleMarkerTap(CachedSData element, {required bool wasSelected}) {
    state = _delegate.handleMarkerTap(
      state: state,
      element: element,
      wasSelected: wasSelected,
    );
  }

  void handleMarkerDragEnd(Offset position, {required bool wasSelected}) {
    state = _delegate.handleMarkerDragEnd(
      state: state,
      position: position,
      wasSelected: wasSelected,
    );
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

  void selectElementOnly(CachedSData element) {
    state = state.copyWith(
      selectedElement: element,
      tapPosition: element.position,
    );
  }

  int? syncToBuilding({CachedSData? focusElement}) {
    final active = ref.read(activeBuildingProvider);
    final imgState = state;

    if (imgState.activeBuildingId != active.id) {
      transformationController.value = Matrix4.identity();

      final targetFloor = focusElement?.floor ?? 1;
      final clampedFloor = targetFloor < 1
          ? 1
          : (targetFloor > active.floorCount ? active.floorCount : targetFloor);
      final pageIndex = active.floorCount - clampedFloor;

      final resetState = InteractiveImageState(
        activeBuildingId: active.id,
        currentFloor: clampedFloor,
        selectedElement: focusElement,
        tapPosition: focusElement?.position,
        pendingFocusElement: focusElement,
        suppressClearOnPageChange: focusElement != null,
      );

      state = resetState.copyWith(
        isSearchMode: imgState.isSearchMode,
        selectedRoomInfo: imgState.selectedRoomInfo,
        currentBuildingRoomId: imgState.currentBuildingRoomId,
        needsNavigationOnBuild: imgState.needsNavigationOnBuild,
      );
      return pageIndex;
    }

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

  void updateElementName(String newName) {
    state = _delegate.updateElementName(state, newName);
  }

  void updateElementPosition(Offset newPosition) {
    state = _delegate.updateElementPosition(state, newPosition);
  }

  void setCurrentType(PlaceType type) {
    state = state.copyWith(currentType: type);
  }

  void setVerticalTraversalPreference({
    bool? allowStairs,
    bool? allowElevators,
  }) {
    final next = state.copyWith(
      allowStairs: allowStairs ?? state.allowStairs,
      allowElevators: allowElevators ?? state.allowElevators,
    );
    if (next == state) return;
    state = next;
  }

  void toggleConnectionMode() {
    state = _delegate.toggleConnectionMode(state);
  }

  void addElement({required String name, required Offset position}) {
    state = _delegate.addElement(state: state, name: name, position: position);
  }

  void deleteSelectedElement() {
    state = _delegate.deleteSelectedElement(state);
  }

  void connectToNode(CachedSData endNode) {
    state = _delegate.connectToNode(state, endNode);
  }

  void activateRoom(
    BuildingRoomInfo info, {
    bool switchToDetail = false,
    bool autoNavigate = true,
  }) {
    state = _delegate.activateRoom(
      state: state,
      info: info,
      switchToDetail: switchToDetail,
      autoNavigate: autoNavigate,
    );
  }

  void returnToSearch() {
    state = _delegate.returnToSearch(state);
  }

  CachedSData? resolveNavigationTarget() {
    return _delegate.resolveNavigationTarget(state);
  }

  Future<bool> calculateRoute({
    required String startNodeId,
    required String targetElementId,
  }) {
    return _delegate.calculateRoute(
      state: state,
      startNodeId: startNodeId,
      targetElementId: targetElementId,
    );
  }

  void clearNeedsNavigationOnBuild() {
    if (state.needsNavigationOnBuild) {
      state = state.copyWith(needsNavigationOnBuild: false);
    }
  }

  @override
  void dispose() {
    _delegate.dispose();
    transformationController.dispose();
    super.dispose();
  }
}

final interactiveImageProvider =
    StateNotifierProvider<InteractiveImageNotifier, InteractiveImageState>((
      ref,
    ) {
      final delegate = ref.watch(interactionDelegateProvider);
      return InteractiveImageNotifier(ref: ref, delegate: delegate);
    });
