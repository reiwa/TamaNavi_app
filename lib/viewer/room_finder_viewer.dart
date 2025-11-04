import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/models/active_building_notifier.dart';
import 'package:test_project/models/building_snapshot.dart';
import 'package:test_project/models/element_data_models.dart';
import 'package:test_project/room_editor/room_finder_app_editor.dart';
import 'package:test_project/models/room_finder_models.dart';
import 'package:test_project/utility/platform_utils.dart';
import 'package:test_project/viewer/interactive_image_state.dart';
import 'package:test_project/viewer/interactive_screen.dart';
import 'passage_painter.dart';
import 'scroll_physics.dart';

part 'interaction_handler.dart';
part 'building_sync.dart';
part 'view_builders.dart';

enum CustomViewMode { editor, finder }

abstract class CustomView extends ConsumerStatefulWidget {
  const CustomView({super.key, required this.mode});

  final CustomViewMode mode;
}

mixin InteractiveImageMixin<T extends CustomView> on ConsumerState<T> {
  late PageController pageController;

  bool isPageScrollable = true;

  bool get enableElementDrag => widget.mode == CustomViewMode.editor;

  bool get showTapDot => widget.mode == CustomViewMode.editor;

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

  PlaceType currentType = PlaceType.room;
  
  final double minScale = 0.8;
  final double maxScale = 8.0;

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  void _handlePageChanged(int pageIndex) {
    ref.read(interactiveImageProvider.notifier).handlePageChanged(pageIndex, ref);
  }

  void _ensureActiveBuildingSynced() =>
      ensureActiveBuildingSyncedLogic(this, ref);

  void syncToBuilding(BuildingSnapshot snapshot, {CachedSData? focusElement}) =>
      syncToBuildingLogic(this, ref, focusElement: focusElement);

  void handleMarkerTap(CachedSData sData, bool isSelected) =>
      handleMarkerTapLogic(this, sData, isSelected, ref);

  void handleMarkerDragEnd(Offset position, bool isSelected) =>
      handleMarkerDragEndLogic(this, position, isSelected, ref);

  bool _pendingContainerSync = false;

  Widget buildInteractiveImage() {
    ref.watch(
      interactiveImageProvider.select((s) => s.currentZoomScale),
    );
    final bool canSwipe = canSwipeFloors;
    final ScrollPhysics pagePhysics = canSwipe
        ? TolerantPageScrollPhysics(
            canScroll: () => true,
            directionTolerance: pi / 6,
          )
        : const NeverScrollableScrollPhysics();
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: Colors.green.withValues(alpha: 0.45),
            width: 2.0,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(0.0),
            topRight: Radius.circular(12.0),
            bottomLeft: Radius.circular(12.0),
            bottomRight: Radius.circular(12.0),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: Listener(
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
                    final int floor = snap.floorCount - pageIndex;

                    return _FloorPageView(self: this, floor: floor);
                  },
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
