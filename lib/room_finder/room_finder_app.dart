import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/room_finder/detail_screen.dart';
import 'package:tamanavi_app/room_finder/search_screen.dart';
import 'package:tamanavi_app/room_finder/settings_dialog.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';

const List<String> kFinderTagOptions = kBuildingTagOptions;

final selectedTagProvider = StateProvider<String>(
  (ref) => kFinderTagOptions.first,
);

final finderSearchQueryProvider = StateProvider<String>((ref) => '');

final tagSearchResultsProvider = FutureProvider<List<BuildingRoomInfo>>((
  ref,
) async {
  final selectedTag = ref.watch(selectedTagProvider);
  final rawQuery = ref.watch(finderSearchQueryProvider);
  final trimmedQuery = rawQuery.trim();

  final repo = ref.read(buildingRepositoryProvider.notifier);

  if (trimmedQuery.isEmpty) {
    await repo.ensureTagLoaded(selectedTag);
  } else {
    await repo.ensureAllBuildingsLoaded();
  }

  final map =
      ref.read(buildingRepositoryProvider).asData?.value ??
      const <String, BuildingSnapshot>{};

  final results = <BuildingRoomInfo>[];
  final includeAllBuildings = trimmedQuery.isNotEmpty;
  for (final snapshot in map.values) {
    if (snapshot.id == kDraftBuildingId) continue;
    if (!includeAllBuildings && !snapshot.tags.contains(selectedTag)) {
      continue;
    }
    for (final room in snapshot.rooms) {
      results.add(
        BuildingRoomInfo(
          buildingId: snapshot.id,
          buildingName: snapshot.name,
          room: room,
        ),
      );
    }
  }

  results.sort((a, b) {
    final buildingCompare = a.buildingName.compareTo(b.buildingName);
    if (buildingCompare != 0) return buildingCompare;
    final aName = a.room.name.isEmpty ? a.room.id : a.room.name;
    final bName = b.room.name.isEmpty ? b.room.id : b.room.name;
    final roomCompare = aName.compareTo(bName);
    if (roomCompare != 0) return roomCompare;
    return a.room.id.compareTo(b.room.id);
  });

  return results;
});

final roomsInActiveBuildingProvider = Provider<List<BuildingRoomInfo>>((ref) {
  final sortedRoomList = ref.watch(sortedBuildingRoomInfosProvider);
  final activeBuilding = ref.watch(activeBuildingProvider);
  return sortedRoomList
      .where((info) => info.buildingId == activeBuilding.id)
      .toList();
});

@immutable
class FinderLaunchIntent {
  const FinderLaunchIntent({this.navigateTo, this.navigateFrom});

  final String? navigateTo;
  final String? navigateFrom;

  bool get hasNavigateTo => navigateTo != null && navigateTo!.isNotEmpty;
  bool get hasNavigateFrom => navigateFrom != null && navigateFrom!.isNotEmpty;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! FinderLaunchIntent) return false;
    return other.navigateTo == navigateTo && other.navigateFrom == navigateFrom;
  }

  @override
  int get hashCode => Object.hash(navigateTo, navigateFrom);

  static FinderLaunchIntent? maybeFrom({
    String? navigateTo,
    String? navigateFrom,
  }) {
    final sanitizedTo = navigateTo?.trim();
    final sanitizedFrom = navigateFrom?.trim();
    final hasTo = sanitizedTo != null && sanitizedTo.isNotEmpty;
    final hasFrom = sanitizedFrom != null && sanitizedFrom.isNotEmpty;
    if (!hasTo && !hasFrom) {
      return null;
    }
    return FinderLaunchIntent(
      navigateTo: hasTo ? sanitizedTo : null,
      navigateFrom: hasFrom ? sanitizedFrom : null,
    );
  }
}

class FinderView extends CustomView {
  const FinderView({super.key, this.initialIntent})
    : super(mode: CustomViewMode.finder);

  final FinderLaunchIntent? initialIntent;

  @override
  ConsumerState<FinderView> createState() => _FinderViewState();
}

class _FinderViewState extends ConsumerState<FinderView>
    with InteractiveImageMixin<FinderView> {
  FinderLaunchIntent? _pendingIntent;
  bool _firstFrameRendered = false;
  bool _isProcessingIntent = false;
  String? _selectedEntranceId;

  @override
  void initState() {
    super.initState();

    _pendingIntent = widget.initialIntent;

    pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      _firstFrameRendered = true;

      final active = ref.read(activeBuildingProvider);
      ref
          .read(interactiveImageProvider.notifier)
          .handleBuildingChanged(active.id);

      await _maybeProcessPendingIntent();
    });
  }

  @override
  void didUpdateWidget(covariant FinderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIntent != oldWidget.initialIntent) {
      _pendingIntent = widget.initialIntent;
      unawaited(_maybeProcessPendingIntent());
    }
  }

  void _handleRepositoryChanged(
    AsyncValue<Map<String, BuildingSnapshot>>? previous,
    AsyncValue<Map<String, BuildingSnapshot>> next,
  ) {
    if (!mounted) return;
    next.whenData((_) => _maybeProcessPendingIntent());
  }

  void _handleSelectedTagChanged(String? previous, String next) {
    if (previous == next) return;
    ref.read(finderSearchQueryProvider.notifier).state = '';
  }

  void _handleNavigationRequests(
    InteractiveImageState? previous,
    InteractiveImageState next,
  ) {
    if (!mounted || !next.needsNavigationOnBuild) {
      return;
    }

    ref.read(interactiveImageProvider.notifier).clearNeedsNavigationOnBuild();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 50));
      if (!mounted) return;
      await _startNavigation();
    });
  }

  Future<void> _handleFloorChange(
    InteractiveImageState? previous,
    InteractiveImageState next,
  ) async {
    if (!mounted) return;
    if (previous?.currentFloor == next.currentFloor) {
      return;
    }

    final activeSnapshot = ref.read(activeBuildingProvider);
    final correctPageIndex = activeSnapshot.floorCount - next.currentFloor;
    if (pageController.hasClients) {
      final current = pageController.page?.round();
      if (current != correctPageIndex) {
        await pageController.animateToPage(
          correctPageIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate,
        );
      }
    }
  }

  void _handleSelectedRoomChanged(
    InteractiveImageState? previous,
    InteractiveImageState next,
  ) {
    if (!mounted) return;
    final prevId = previous?.currentBuildingRoomId;
    final nextId = next.currentBuildingRoomId;
    if (nextId == null || nextId == prevId) {
      return;
    }

    final room = next.selectedRoomInfo?.room;
    if (room == null) {
      return;
    }

    unawaited(_focusOnElement(room));
  }

  void _activateRoom(
    BuildingRoomInfo info, {
    bool switchToDetail = false,
    bool autoNavigate = true,
  }) {
    ref
        .read(interactiveImageProvider.notifier)
        .activateRoom(
          info,
          switchToDetail: switchToDetail,
          autoNavigate: autoNavigate,
        );
  }

  void _returnToSearch() {
    FocusScope.of(context).unfocus();
    ref.read(interactiveImageProvider.notifier).returnToSearch();
  }

  CachedSData? _resolveNavigationTarget() {
    return ref
        .read(interactiveImageProvider.notifier)
        .resolveNavigationTarget();
  }

  Future<void> _focusOnElement(CachedSData element) async {
    final notifier = ref.read(interactiveImageProvider.notifier);
    final pageIndex = notifier.syncToBuilding(focusElement: element);

    if (pageIndex != null) {
      final ready = await _waitForPageView();
      if (!ready) {
        notifier.applyPendingFocusIfAny();
        return;
      }
      if (_isPageViewReady) {
        await pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate,
        );
        await Future<void>.delayed(const Duration(milliseconds: 550));
        if (mounted) {
          notifier.applyPendingFocusIfAny();
        }
      } else {
        notifier.applyPendingFocusIfAny();
      }
    }
  }

  bool get _isPageViewReady {
    if (!pageController.hasClients) return false;
    try {
      final positions = pageController.positions;
      if (positions.isEmpty) {
        return false;
      }
      final position = pageController.position;
      return position.hasPixels && position.hasContentDimensions;
    } on Exception {
      return false;
    }
  }

  Future<bool> _waitForPageView() async {
    if (_isPageViewReady) return true;
    const attempts = 12;
    for (var i = 0; i < attempts; i++) {
      if (!mounted) return false;
      await Future<void>.delayed(const Duration(milliseconds: 25));
      if (_isPageViewReady) {
        return true;
      }
    }
    return _isPageViewReady;
  }

  Future<void> _startNavigation({
    String? startElementId,
  }) async {
    final active = ref.read(activeBuildingProvider);
    final targetElement = _resolveNavigationTarget();
    if (targetElement == null) {
      _showSnackBar('目的地が選択されていません。');
      return;
    }

    if (targetElement.type == PlaceType.room && mounted) {
      ref
          .read(interactiveImageProvider.notifier)
          .activateRoom(
            BuildingRoomInfo(
              buildingId: active.id,
              buildingName: active.name,
              room: targetElement,
            ),
          );
    }

    CachedSData? startNode;
    final desiredStartId = startElementId ?? _selectedEntranceId;
    if (desiredStartId != null) {
      startNode = _findElementById(active, desiredStartId);
    }
    startNode ??= _firstEntrance(active);

    if (startNode == null) {
      _showSnackBar('この建物に入口が見つかりません。');
      return;
    }

    _setSelectedEntranceId(startNode.id);

    await _focusOnElement(startNode);

    ref
        .read(interactiveImageProvider.notifier)
        .selectElementOnly(targetElement);

    final ok = await ref
        .read(interactiveImageProvider.notifier)
        .calculateRoute(
          startNodeId: startNode.id,
          targetElementId: targetElement.id,
        );

    if (!ok) {
      _showSnackBar('ルートが見つかりません。');
    }
  }

  CachedSData? _firstEntrance(BuildingSnapshot snapshot) {
    for (final element in snapshot.elements) {
      if (element.type == PlaceType.entrance) {
        return element;
      }
    }
    return null;
  }

  void _setSelectedEntranceId(String? id) {
    if (!mounted || _selectedEntranceId == id) {
      return;
    }
    setState(() {
      _selectedEntranceId = id;
    });
  }

  Future<void> _maybeProcessPendingIntent() async {
    if (_pendingIntent == null || !_firstFrameRendered || _isProcessingIntent) {
      return;
    }

    final intent = _pendingIntent!;
    if (!intent.hasNavigateTo) {
      _pendingIntent = null;
      return;
    }

    _isProcessingIntent = true;
    try {
      final targetRoomId = intent.navigateTo!;
      var rooms = ref.read(sortedBuildingRoomInfosProvider);
      BuildingRoomInfo? targetInfo;

      for (final info in rooms) {
        if (info.room.id == targetRoomId) {
          targetInfo = info;
          break;
        }
      }

      if (targetInfo == null) {
        final snapshot = await ref
            .read(buildingRepositoryProvider.notifier)
            .fetchBuildingContainingRoom(targetRoomId);
        if (snapshot == null) {
          _pendingIntent = null;
          _showSnackBar('指定された部屋が見つかりません: ${intent.navigateTo}');
          return;
        }
        rooms = ref.read(sortedBuildingRoomInfosProvider);
        for (final info in rooms) {
          if (info.room.id == targetRoomId) {
            targetInfo = info;
            break;
          }
        }
      }

      if (targetInfo == null) {
        _pendingIntent = null;
        _showSnackBar('指定された部屋が見つかりません: ${intent.navigateTo}');
        return;
      }

      final resolvedTarget = targetInfo;
      _pendingIntent = null;

      final buildingSnapshot = ref
          .read(buildingRepositoryProvider)
          .asData
          ?.value[resolvedTarget.buildingId];
      if (buildingSnapshot != null && buildingSnapshot.tags.isNotEmpty) {
        final currentTag = ref.read(selectedTagProvider);
        if (!buildingSnapshot.tags.contains(currentTag)) {
          ref.read(selectedTagProvider.notifier).state =
              buildingSnapshot.tags.first;
        }
      }

      await Future.microtask(() async {
        if (!mounted) return;

        _activateRoom(
          resolvedTarget,
          switchToDetail: true,
          autoNavigate: false,
        );

        await Future<void>.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;

        if (intent.hasNavigateFrom) {
          await _startNavigation(startElementId: intent.navigateFrom);
        }
      });
    } finally {
      _isProcessingIntent = false;
    }
  }

  CachedSData? _findElementById(BuildingSnapshot snapshot, String id) {
    for (final element in snapshot.elements) {
      if (element.id == id) {
        return element;
      }
    }
    return null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void syncToBuilding(BuildingSnapshot snapshot, {CachedSData? focusElement}) {
    ref
        .read(interactiveImageProvider.notifier)
        .syncToBuilding(focusElement: focusElement);
  }

  void _ensureEntranceSelection(List<CachedSData> entrances) {
    final hasCurrent =
        _selectedEntranceId != null &&
        entrances.any((e) => e.id == _selectedEntranceId);
    final desired = entrances.isEmpty
        ? null
        : (hasCurrent ? _selectedEntranceId : entrances.first.id);
    if (desired == _selectedEntranceId) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedEntranceId = desired;
      });
    });
  }

  void _handleEntranceSelection(CachedSData entrance) {
    final shouldUpdate = _selectedEntranceId != entrance.id;
    if (shouldUpdate) {
      setState(() {
        _selectedEntranceId = entrance.id;
      });
    }
    unawaited(_focusOnElement(entrance));
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<AsyncValue<Map<String, BuildingSnapshot>>>(
        buildingRepositoryProvider,
        _handleRepositoryChanged,
      )
      ..listen<String>(
        selectedTagProvider,
        _handleSelectedTagChanged,
      )
      ..listen<InteractiveImageState>(
        interactiveImageProvider,
        _handleNavigationRequests,
      )
      ..listen<InteractiveImageState>(
        interactiveImageProvider,
        _handleFloorChange,
      )
      ..listen<InteractiveImageState>(
        interactiveImageProvider,
        _handleSelectedRoomChanged,
      );

    final isSearchMode = ref.watch(
      interactiveImageProvider.select((s) => s.isSearchMode),
    );
    final selectedRoomInfo = ref.watch(
      interactiveImageProvider.select((s) => s.selectedRoomInfo),
    );

    final shouldShowSearch = isSearchMode || selectedRoomInfo == null;

    final content = shouldShowSearch
        ? FinderSearchContent(
            onTagSelected: (tag) {
              ref.read(selectedTagProvider.notifier).state = tag;
            },
            onRoomTap: (info) {
              _activateRoom(info, switchToDetail: true);
            },
          )
        : () {
            final imageState = ref.watch(interactiveImageProvider);
            final activeBuilding = ref.watch(activeBuildingProvider);
            final inSameBuilding = ref.watch(roomsInActiveBuildingProvider);
            final entrances =
                activeBuilding.elements
                    .where((e) => e.type == PlaceType.entrance)
                    .toList()
                  ..sort((a, b) {
                    final aLabel = a.name.isEmpty ? a.id : a.name;
                    final bLabel = b.name.isEmpty ? b.id : b.name;
                    return aLabel.compareTo(bLabel);
                  });

            _ensureEntranceSelection(entrances);

            final hasValue = inSameBuilding.any(
              (info) => info.room.id == imageState.currentBuildingRoomId,
            );
            final dropdownValue = hasValue
                ? imageState.currentBuildingRoomId
                : null;
            final selectedEntranceId = _selectedEntranceId;

            return FinderDetailContent(
              currentFloor: imageState.currentFloor,
              dropdownValue: dropdownValue,
              roomsInBuilding: inSameBuilding,
              selectedRoomInfo: imageState.selectedRoomInfo,
              entrances: entrances,
              selectedEntranceId: selectedEntranceId,
              onRoomSelected: (value) {
                if (value == null || inSameBuilding.isEmpty) return;
                final match = inSameBuilding.firstWhere(
                  (info) => info.room.id == value,
                  orElse: () => imageState.selectedRoomInfo!,
                );
                _activateRoom(match);
              },
              onEntranceSelected: _handleEntranceSelection,
              onReturnToSearch: _returnToSearch,
              interactiveImage: buildInteractiveImage(),
              selectedElementLabel: _selectedElementLabel(activeBuilding),
              onStartNavigation: _startNavigation,
              canStartNavigation:
                  imageState.selectedRoomInfo != null && entrances.isNotEmpty,
            );
          }();

    return Column(
      children: [
        SafeArea(bottom: false, child: _buildHeader(context)),
        Expanded(child: content),
      ],
    );
  }

  String _selectedElementLabel(BuildingSnapshot snapshot) {
    final target = _resolveNavigationTarget();
    if (target != null) {
      return target.name.isNotEmpty ? target.name : target.id;
    }
    final info = ref.read(interactiveImageProvider).selectedRoomInfo;
    if (info != null) {
      final r = info.room;
      return r.name.isNotEmpty ? r.name : r.id;
    }
    return '-';
  }

  Widget _buildHeader(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colorScheme.outlineVariant,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                color: colorScheme.primary,
              ),
              child: Icon(
                Icons.navigation_rounded,
                color: colorScheme.onPrimary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '玉ナビ',
                    style: textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    '埼玉大学のルート案内アプリ',
                    style: textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              tooltip: '設定',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.surfaceContainerHighest.withValues(
                  alpha: 0.6,
                ),
                foregroundColor: colorScheme.primary,
              ),
              onPressed: () => showFinderSettingsDialog(context),
            ),
          ],
        ),
      ),
    );
  }
}
