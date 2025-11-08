import 'package:flutter_riverpod/legacy.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';
import 'detail_screen.dart';
import 'entrance_selector.dart';
import 'search_screen.dart';

final searchQueryProvider = StateProvider<String>((ref) => '');
final displayLimitProvider = StateProvider<int>((ref) => 30);
const int _limitIncrement = 30;

final debouncedQueryProvider = FutureProvider<String>((ref) async {
  final query = ref.watch(searchQueryProvider);

  await Future.delayed(const Duration(milliseconds: 300));

  return query.trim().toLowerCase();
});

final filteredRoomsProvider = Provider<List<BuildingRoomInfo>>((ref) {
  final query = ref.watch(debouncedQueryProvider);
  final sortedRooms = ref.watch(sortedBuildingRoomInfosProvider);
  final limit = ref.watch(displayLimitProvider);

  return query.when(
    data: (query) {
      if (query.isEmpty) {
        return sortedRooms.take(limit).toList();
      }

      return sortedRooms
          .where((info) {
            final roomName = info.room.name.toLowerCase();
            final buildingName = info.buildingName.toLowerCase();
            return roomName.contains(query) ||
                buildingName.contains(query);
          })
          .take(limit)
          .toList();
    },
    loading: () =>
        sortedRooms.take(limit).toList(),
    error: (e, s) => [],
  );
});

final canLoadMoreProvider = Provider<bool>((ref) {
  final query = ref.watch(searchQueryProvider);
  if (query.isNotEmpty) return false;

  final limit = ref.watch(displayLimitProvider);
  final total = ref.watch(sortedBuildingRoomInfosProvider).length;
  return limit < total;
});

final roomsInActiveBuildingProvider = Provider<List<BuildingRoomInfo>>((ref) {
  final sortedRoomList = ref.watch(sortedBuildingRoomInfosProvider);
  final activeBuilding = ref.watch(activeBuildingProvider);
  return sortedRoomList
      .where((info) => info.buildingId == activeBuilding.id)
      .toList();
});

class FinderView extends CustomView {
  const FinderView({super.key}) : super(mode: CustomViewMode.finder);

  @override
  ConsumerState<FinderView> createState() => _FinderViewState();
}

class _FinderViewState extends ConsumerState<FinderView>
    with InteractiveImageMixin<FinderView> {
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();

    pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final rooms = ref.read(buildingRoomInfosProvider);
      if (rooms.isEmpty) {
        ref.read(buildingRepositoryProvider.notifier).refresh();
      }

      final active = ref.read(activeBuildingProvider);
      final notifier = ref.read(interactiveImageProvider.notifier);

      notifier.handleBuildingChanged(active.id);

      ref.listenManual<InteractiveImageState>(interactiveImageProvider, (
        prev,
        next,
      ) {
        if (!mounted) return;
        if (next.needsNavigationOnBuild) {
          ref
              .read(interactiveImageProvider.notifier)
              .clearNeedsNavigationOnBuild();

          WidgetsBinding.instance.addPostFrameCallback((_) async {
            if (!mounted) return;
            await Future.delayed(const Duration(milliseconds: 50));
            if (!mounted) return;
            await _startNavigation();
          });
        }
      });

      ref.listenManual<InteractiveImageState>(interactiveImageProvider, (
        prev,
        next,
      ) {
        if (!mounted) return;
        final activeSnapshot = ref.read(activeBuildingProvider);
        final correctPageIndex = activeSnapshot.floorCount - next.currentFloor;
        if (pageController.hasClients) {
          final current = pageController.page?.round();
          if (current != correctPageIndex) {
            pageController.animateToPage(
              correctPageIndex,
              duration: const Duration(milliseconds: 500),
              curve: Curves.decelerate,
            );
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _activateRoom(BuildingRoomInfo info, {bool switchToDetail = false}) {
    final img = ref.read(interactiveImageProvider.notifier);
    img.activateRoom(info, switchToDetail: switchToDetail);
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

  Future<void> _focusEntrance(CachedSData entrance) async {
    final notifier = ref.read(interactiveImageProvider.notifier);
    final pageIndex = notifier.syncToBuilding(focusElement: entrance);

    if (pageIndex != null) {
      if (pageController.hasClients) {
        await pageController.animateToPage(
          pageIndex,
          duration: const Duration(milliseconds: 500),
          curve: Curves.decelerate,
        );
        await Future.delayed(const Duration(milliseconds: 550));
        if (mounted) {
          notifier.applyPendingFocusIfAny();
        }
      }
    }
  }

  Future<void> _startNavigation() async {
    final active = ref.read(activeBuildingProvider);
    final targetElement = _resolveNavigationTarget();
    final messenger = ScaffoldMessenger.of(context);
    if (targetElement == null) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('目的地が選択されていません。')));
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
            switchToDetail: false,
          );
    }

    final entrances = active.elements
        .where((e) => e.type == PlaceType.entrance)
        .toList();
    if (entrances.isEmpty) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text("この建物に入口が見つかりません。")));
      return;
    }

    CachedSData? startNode;
    if (entrances.length == 1) {
      startNode = entrances.first;
      await _focusEntrance(startNode);
    } else {
      final initial = entrances.first;
      await _focusEntrance(initial);
      if (!mounted) return;
      startNode = await showEntranceSelector(
        context: context,
        entrances: entrances,
        initialId: initial.id,
        onFocus: (focusEntrance) => _focusEntrance(focusEntrance),
      );

      ref
          .read(interactiveImageProvider.notifier)
          .selectElementOnly(targetElement);
    }
    if (startNode == null) return;

    final ok = await ref
        .read(interactiveImageProvider.notifier)
        .calculateRoute(
          startNodeId: startNode.id,
          targetElementId: targetElement.id,
        );

    if (!ok) {
      if (!mounted) return;
      messenger.showSnackBar(const SnackBar(content: Text('ルートが見つかりません。')));
    }
  }

  @override
  void syncToBuilding(BuildingSnapshot snapshot, {CachedSData? focusElement}) {
    ref
        .read(interactiveImageProvider.notifier)
        .syncToBuilding(focusElement: focusElement);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final isLoading = ref.watch(
          buildingRepositoryProvider.select((s) => s.isLoading),
        );
        final imageState = ref.watch(interactiveImageProvider);
        final activeBuilding = ref.watch(activeBuildingProvider);

        final bool isQueryEmpty = ref.watch(searchQueryProvider).isEmpty;
        final bool canLoadMore = ref.watch(canLoadMoreProvider);

        final shouldShowSearch =
            imageState.isSearchMode || imageState.selectedRoomInfo == null;

        final content = shouldShowSearch
            ? FinderSearchContent(
                isLoading: isLoading,
                searchFocusNode: _searchFocusNode,
                isQueryEmpty: isQueryEmpty,
                canLoadMore: canLoadMore,
                onLoadMore: () =>
                    ref.read(displayLimitProvider.notifier).state +=
                        _limitIncrement,
                onQueryChanged: (query) {
                  ref.read(searchQueryProvider.notifier).state = query;
                },
                onClearQuery: () {
                  ref.read(searchQueryProvider.notifier).state = '';
                  ref.read(displayLimitProvider.notifier).state = 30;
                },
                onRoomTap: (info) {
                  _activateRoom(info, switchToDetail: true);
                },
              )
            : () {
                final inSameBuilding = ref.watch(roomsInActiveBuildingProvider);
                final hasValue = inSameBuilding.any(
                  (info) => info.room.id == imageState.currentBuildingRoomId,
                );
                final dropdownValue = hasValue
                    ? imageState.currentBuildingRoomId
                    : null;

                return FinderDetailContent(
                  currentFloor: imageState.currentFloor,
                  dropdownValue: dropdownValue,
                  roomsInBuilding: inSameBuilding,
                  selectedRoomInfo: imageState.selectedRoomInfo,
                  onRoomSelected: (value) async {
                    if (value == null || inSameBuilding.isEmpty) return;
                    final match = inSameBuilding.firstWhere(
                      (info) => info.room.id == value,
                      orElse: () => imageState.selectedRoomInfo!,
                    );
                    _activateRoom(match);
                    await _focusEntrance(match.room);
                  },
                  onReturnToSearch: _returnToSearch,
                  interactiveImage: buildInteractiveImage(),
                  selectedElementLabel: _selectedElementLabel(activeBuilding),
                  onStartNavigation: isLoading ? null : _startNavigation,
                );
              }();

        return content;
      },
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
}
