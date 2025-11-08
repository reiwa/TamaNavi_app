import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';

abstract class InteractionDelegate {
  InteractionDelegate({required this.ref});

  @protected
  final Ref ref;

  InteractiveImageState handleTap({
    required InteractiveImageState state,
    required Offset position,
  }) {
    return state;
  }

  InteractiveImageState handleMarkerTap({
    required InteractiveImageState state,
    required CachedSData element,
    required bool wasSelected,
  }) {
    return state;
  }

  InteractiveImageState handleMarkerDragEnd({
    required InteractiveImageState state,
    required Offset position,
    required bool wasSelected,
  }) {
    return state.copyWith(isDragging: false);
  }

  InteractiveImageState toggleConnectionMode(
    InteractiveImageState state,
  ) {
    return state;
  }

  InteractiveImageState connectToNode(
    InteractiveImageState state,
    CachedSData endNode,
  ) {
    return state;
  }

  InteractiveImageState updateElementName(
    InteractiveImageState state,
    String newName,
  ) {
    return state;
  }

  InteractiveImageState updateElementPosition(
    InteractiveImageState state,
    Offset newPosition,
  ) {
    return state;
  }

  InteractiveImageState addElement({
    required InteractiveImageState state,
    required String name,
    required Offset position,
  }) {
    return state;
  }

  InteractiveImageState deleteSelectedElement(
    InteractiveImageState state,
  ) {
    return state;
  }

  InteractiveImageState activateRoom({
    required InteractiveImageState state,
    required BuildingRoomInfo info,
    required bool switchToDetail,
  }) {
    return state;
  }

  InteractiveImageState returnToSearch(InteractiveImageState state) {
    return state;
  }

  CachedSData? resolveNavigationTarget(InteractiveImageState state) {
    return null;
  }

  Future<bool> calculateRoute({
    required InteractiveImageState state,
    required String startNodeId,
    required String targetElementId,
  }) async {
    return false;
  }
  
  void dispose() {}
}

final interactionDelegateProvider = Provider<InteractionDelegate>((ref) {
  throw StateError('interactionDelegateProvider must be overridden in scope.');
});
