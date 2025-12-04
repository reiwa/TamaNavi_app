import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/utility/platform_utils.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/viewer/interactive_screen.dart';
import 'package:tamanavi_app/viewer/passage_painter.dart';
import 'package:tamanavi_app/viewer/scroll_physics.dart';

part 'interaction_handler.dart';
part 'building_sync.dart';
part 'view_builders.dart';

enum CustomViewMode { editor, finder }

abstract class CustomView extends ConsumerStatefulWidget {
  const CustomView({required this.mode, super.key});

  final CustomViewMode mode;
}

mixin InteractiveImageMixin<T extends CustomView> on ConsumerState<T> {
  late PageController pageController;

  bool isPageScrollable = true;

  bool get enableElementDrag => widget.mode == CustomViewMode.editor;

  bool get showTapDot => widget.mode == CustomViewMode.editor;

  bool get showSelectedPin => widget.mode == CustomViewMode.finder;

  bool canSwipeFloorsFor(InteractiveImageState s) {
    final transformationController = ref
        .read(interactiveImageProvider.notifier)
        .transformationController;
    final scale = transformationController.value.getMaxScaleOnAxis();
    final canSwipeWhileConnectingElevator =
        s.isConnecting && (s.connectingStart?.type == PlaceType.elevator);
    return isDesktopOrElse &&
        !s.isDragging &&
        (!s.isConnecting || canSwipeWhileConnectingElevator) &&
        scale <= 1.05;
  }

  bool get canSwipeFloors {
    final s = ref.read(interactiveImageProvider);
    return canSwipeFloorsFor(s);
  }

  final double minScale = 0.8;
  final double maxScale = 8;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int pageIndex) {
    ref.read(interactiveImageProvider.notifier).handlePageChanged(pageIndex);
  }

  void _ensureActiveBuildingSynced() =>
      ensureActiveBuildingSyncedLogic(this, ref);

  void syncToBuilding(BuildingSnapshot snapshot, {CachedSData? focusElement}) =>
      syncToBuildingLogic(this, ref, focusElement: focusElement);

  void handleMarkerTap(CachedSData sData, {required bool wasSelected}) =>
      handleMarkerTapLogic(
        this,
        sData,
        wasSelected: wasSelected,
        ref: ref,
      );

  void handleMarkerDragEnd(Offset position, {required bool wasSelected}) =>
      handleMarkerDragEndLogic(
        this,
        position,
        wasSelected: wasSelected,
        ref: ref,
      );

  bool _pendingContainerSync = false;

  Widget buildInteractiveImage() {
    ref.watch(interactiveImageProvider.select((s) => s.currentZoomScale));
    final canSwipe = canSwipeFloors;
    final pagePhysics = canSwipe
        ? TolerantPageScrollPhysics(
            canScroll: () => true,
          )
        : const NeverScrollableScrollPhysics();
    return Listener(
      child: Builder(
        builder: (context) {
          final snap = ref.watch(activeBuildingProvider);
          _ensureActiveBuildingSynced();

          return Listener(
            child: PageView.builder(
              controller: pageController,
              scrollBehavior: CustomScrollBehavior(),
              scrollDirection: Axis.vertical,
              physics: pagePhysics,
              itemCount: snap.floorCount,
              onPageChanged: _handlePageChanged,
              itemBuilder: (context, pageIndex) {
                final floor = snap.floorCount - pageIndex;

                return _FloorPageView(self: this, floor: floor);
              },
            ),
          );
        },
      ),
    );
  }
}
