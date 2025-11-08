part of 'room_finder_viewer.dart';

void handlePageChangedLogic<T extends CustomView>(
  InteractiveImageMixin<T> host,
  int pageIndex,
  WidgetRef ref,
) {
  final notifier = ref.read(interactiveImageProvider.notifier);
  final prev = ref.read(interactiveImageProvider);

  notifier.handlePageChanged(pageIndex);

  final next = ref.read(interactiveImageProvider);
  if (!next.suppressClearOnPageChange &&
      next.selectedElement == null &&
      prev.selectedElement != null &&
      host is EditorControllerHost) {
    final editor = host as EditorControllerHost;
    editor.nameController.clear();
    editor.xController.clear();
    editor.yController.clear();
  }
}

void ensureActiveBuildingSyncedLogic<T extends CustomView>(
  InteractiveImageMixin<T> host,
  WidgetRef ref,
) {
  final active = ref.read(activeBuildingProvider);
  final imgState = ref.read(interactiveImageProvider);

  if (host.widget.mode == CustomViewMode.editor &&
      active.id != kDraftBuildingId) {
    if (host._pendingContainerSync) return;
    host._pendingContainerSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted) return;
      ref.read(activeBuildingProvider.notifier).startDraftFromActive();
      host._pendingContainerSync = false;
    });
    return;
  }

  if (host.widget.mode == CustomViewMode.finder &&
      (active.id == kDraftBuildingId)) {
    final fallbackId = ref
        .read(buildingRepositoryProvider.notifier)
        .firstNonDraftBuildingId;
    if (fallbackId != null &&
        fallbackId != active.id &&
        !host._pendingContainerSync) {
      host._pendingContainerSync = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!host.mounted) return;
        ref.read(activeBuildingProvider.notifier).setActiveBuilding(fallbackId);
        host._pendingContainerSync = false;
      });
    }
    return;
  }

  final buildingMismatch = active.id != imgState.activeBuildingId;
  final floorOutOfRange = imgState.currentFloor > active.floorCount;

  if ((buildingMismatch || floorOutOfRange) && !host._pendingContainerSync) {
    host._pendingContainerSync = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!host.mounted) return;
      syncToBuildingLogic(host, ref, focusElement: null);
      host._pendingContainerSync = false;
    });
  }
}

void syncToBuildingLogic<T extends CustomView>(
  InteractiveImageMixin<T> host,
  WidgetRef ref, {
  CachedSData? focusElement,
}) {
  final notifier = ref.read(interactiveImageProvider.notifier);
  final pageIndex = notifier.syncToBuilding(focusElement: focusElement);

  if (pageIndex != null) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (host.pageController.hasClients) {
        host.pageController.jumpToPage(pageIndex);
      } else {
        applyPendingFocusIfAnyLogic(host, ref);
      }
    });
  } else {
    final transformationController = ref
        .read(interactiveImageProvider.notifier)
        .transformationController;
    transformationController.value = Matrix4.identity();
  }
}

void applyPendingFocusIfAnyLogic<T extends CustomView>(
  InteractiveImageMixin<T> host,
  WidgetRef ref,
) {
  final hadPending =
      ref.read(interactiveImageProvider).pendingFocusElement != null;

  ref.read(interactiveImageProvider.notifier).applyPendingFocusIfAny();

  if (hadPending) {
    final transformationController = ref
        .read(interactiveImageProvider.notifier)
        .transformationController;
    transformationController.value = Matrix4.identity();
  }
}
