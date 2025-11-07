import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/models/active_building_notifier.dart';
import 'package:test_project/models/element_data_models.dart';
import 'package:test_project/room_editor/editor_connection_handler.dart';
import 'package:test_project/viewer/interactive_image_state.dart';
import 'package:test_project/viewer/interactions/interaction_delegate.dart';
import 'package:uuid/uuid.dart';

class EditorInteractionDelegate extends InteractionDelegate {
  EditorInteractionDelegate({required Ref ref}) : super(ref: ref);

  @override
  InteractiveImageState handleTap({
    required InteractiveImageState state,
    required Offset position,
  }) {
    final active = ref.read(activeBuildingProvider);

    if (state.isConnecting) {
      final tapped = findElementAtPosition(
        position,
        active.elements.where((e) => e.floor == state.currentFloor),
      );
      final start = state.connectingStart;
      final canConnect =
          start != null && tapped != null && canConnectNodes(start, tapped);
      if (canConnect) {
        ref.read(activeBuildingProvider.notifier).addEdge(
              start.id,
              tapped.id,
            );
        return state.copyWith(
          isConnecting: false,
          connectingStart: null,
          previewPosition: null,
          tapPosition: null,
        );
      }
      return state.copyWith(
        tapPosition: position,
        selectedElement: null,
      );
    }

    final selected = state.selectedElement;
    if (selected != null) {
      final distance = (position - selected.position).distance;
      if (distance > 12.0) {
        return state.copyWith(
          selectedElement: null,
          tapPosition: position,
        );
      }
    }

    final sameLocation = state.tapPosition == position;
    return state.copyWith(tapPosition: sameLocation ? null : position);
  }

  @override
  InteractiveImageState handleMarkerTap({
    required InteractiveImageState state,
    required CachedSData element,
    required bool wasSelected,
  }) {
    if (state.isConnecting && state.connectingStart != null) {
      if (canConnectNodes(state.connectingStart!, element)) {
        ref.read(activeBuildingProvider.notifier).addEdge(
              state.connectingStart!.id,
              element.id,
            );
        return state.copyWith(
          isConnecting: false,
          connectingStart: null,
          previewPosition: null,
          selectedElement: null,
          tapPosition: null,
        );
      }
      return state.copyWith(
        tapPosition: element.position,
        selectedElement: null,
      );
    }

    final newSelected = wasSelected ? null : element;
    return state.copyWith(
      selectedElement: newSelected,
      tapPosition: newSelected?.position,
    );
  }

  @override
  InteractiveImageState handleMarkerDragEnd({
    required InteractiveImageState state,
    required Offset position,
    required bool wasSelected,
  }) {
    if (!wasSelected || state.selectedElement == null) {
      return state.copyWith(isDragging: false);
    }

    final clamped = Offset(
      position.dx.clamp(0.0, 1.0),
      position.dy.clamp(0.0, 1.0),
    );

    final updated = state.selectedElement!.copyWith(position: clamped);
    ref.read(activeBuildingProvider.notifier).updateSData(updated);

    return state.copyWith(
      isDragging: false,
      selectedElement: updated,
      tapPosition: clamped,
    );
  }

  @override
  InteractiveImageState toggleConnectionMode(
    InteractiveImageState state,
  ) {
    if (state.isConnecting) {
      return state.copyWith(
        isConnecting: false,
        connectingStart: null,
        previewPosition: null,
      );
    }
    final selected = state.selectedElement;
    if (selected != null && selected.type.isGraphNode) {
      return state.copyWith(
        isConnecting: true,
        connectingStart: selected,
        selectedElement: null,
        tapPosition: null,
        previewPosition: Offset.zero,
      );
    }
    return state;
  }

  @override
  InteractiveImageState connectToNode(
    InteractiveImageState state,
    CachedSData endNode,
  ) {
    final start = state.connectingStart;
    if (start == null || start.id == endNode.id) {
      return state;
    }

    ref.read(activeBuildingProvider.notifier).addEdge(start.id, endNode.id);

    return state.copyWith(
      isConnecting: false,
      connectingStart: null,
      previewPosition: null,
      selectedElement: null,
      tapPosition: null,
    );
  }

  @override
  InteractiveImageState updateElementName(
    InteractiveImageState state,
    String newName,
  ) {
    final selected = state.selectedElement;
    if (state.isDragging || selected == null) {
      return state;
    }

    final trimmed = newName.trim();
    if (trimmed == selected.name) {
      return state;
    }

    final updated = selected.copyWith(name: trimmed);
    ref.read(activeBuildingProvider.notifier).updateSData(updated);
    return state.copyWith(selectedElement: updated);
  }

  @override
  InteractiveImageState updateElementPosition(
    InteractiveImageState state,
    Offset newPosition,
  ) {
    final selected = state.selectedElement;
    if (state.isDragging || selected == null) {
      return state;
    }

    final clamped = Offset(
      newPosition.dx.clamp(0.0, 1.0),
      newPosition.dy.clamp(0.0, 1.0),
    );

    if (selected.position == clamped) {
      return state;
    }

    final updated = selected.copyWith(position: clamped);
    ref.read(activeBuildingProvider.notifier).updateSData(updated);
    return state.copyWith(
      selectedElement: updated,
      tapPosition: clamped,
    );
  }

  @override
  InteractiveImageState addElement({
    required InteractiveImageState state,
    required String name,
    required Offset position,
  }) {
    final newElement = CachedSData(
      id: const Uuid().v4(),
      name: name.trim(),
      position: position,
      floor: state.currentFloor,
      type: state.currentType,
    );

    ref.read(activeBuildingProvider.notifier).addSData(newElement);

    return state.copyWith(
      tapPosition: null,
      selectedElement: null,
    );
  }

  @override
  InteractiveImageState deleteSelectedElement(
    InteractiveImageState state,
  ) {
    final selected = state.selectedElement;
    if (selected == null) {
      return state;
    }

    ref.read(activeBuildingProvider.notifier).removeSData(selected);
    return state.copyWith(
      selectedElement: null,
      tapPosition: null,
    );
  }
}
