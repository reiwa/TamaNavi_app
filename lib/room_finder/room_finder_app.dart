import 'package:test_project/models/active_building_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:test_project/models/building_snapshot.dart';
import 'package:test_project/models/element_data_models.dart';
import 'package:test_project/models/room_finder_models.dart';
import 'package:test_project/viewer/interactive_image_notifier.dart';
import 'package:test_project/viewer/interactive_image_state.dart';
import 'package:test_project/viewer/room_finder_viewer.dart';
import 'detail_screen.dart';
import 'entrance_selector.dart';
import 'search_screen.dart';

class FinderView extends CustomView {
  const FinderView({super.key}) : super(mode: CustomViewMode.finder);

  @override
  ConsumerState<FinderView> createState() => _FinderViewState();
}

class _FinderViewState extends ConsumerState<FinderView>
    with InteractiveImageMixin<FinderView> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int _initialDisplayLimit = 30;
  static const int _limitIncrement = 30;

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
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  List<BuildingRoomInfo> _filterRooms(List<BuildingRoomInfo> sortedRooms) {
    final query = _searchController.text.trim().toLowerCase();
    
    if (query.isEmpty) {
      return sortedRooms.take(_initialDisplayLimit).toList(); 
    }
    
    return sortedRooms.where((info) {
      final roomName = info.room.name.toLowerCase();
      final buildingName = info.buildingName.toLowerCase();
      final roomId = info.room.id.toLowerCase();
      return roomName.contains(query) ||
          buildingName.contains(query) ||
          roomId.contains(query);
    }).toList();
  }

  void _loadMoreRooms() {
    setState(() {
      _initialDisplayLimit += _limitIncrement;
    });
  }

  void _activateRoom(
    BuildingRoomInfo info, {
    bool switchToDetail = false,
  }) {
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
    if (targetElement == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('目的地が選択されていません。')));
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("この建物に入口が見つかりません。")));
      return;
    }

    CachedSData? startNode;
    if (entrances.length == 1) {
      startNode = entrances.first;
  await _focusEntrance(startNode);
    } else {
      final initial = entrances.first;
      await _focusEntrance(initial);
      if (!context.mounted) return;
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('ルートが見つかりません。')));
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
    final repo = ref.watch(buildingRepositoryProvider);
    final imageState = ref.watch(interactiveImageProvider);
    final isLoading = repo.isLoading;

    final sortedRoomList = ref.watch(sortedBuildingRoomInfosProvider);
    final filteredResults = _filterRooms(sortedRoomList);
    final activeBuilding = ref.watch(activeBuildingProvider);

    final bool isQueryEmpty = _searchController.text.trim().isEmpty;

    final bool canLoadMore =
        isQueryEmpty && (filteredResults.length < sortedRoomList.length);

    if (!isLoading && pageController.hasClients) {
      final correctPageIndex =
          activeBuilding.floorCount - imageState.currentFloor;

      if (pageController.page!.round() != correctPageIndex) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && pageController.hasClients) {
            if (pageController.page!.round() != correctPageIndex) {
              pageController.animateToPage(
                correctPageIndex,
                duration: const Duration(milliseconds: 500),
                curve: Curves.decelerate,
              );
            }
          }
        });
      }
    }

    final shouldShowSearch =
        imageState.isSearchMode || imageState.selectedRoomInfo == null;

    final content = shouldShowSearch
        ? FinderSearchContent(
            isLoading: isLoading,
            searchController: _searchController,
            searchFocusNode: _searchFocusNode,
            results: filteredResults,
            isQueryEmpty: isQueryEmpty,
            canLoadMore: canLoadMore,
            onLoadMore: _loadMoreRooms,
            onQueryChanged: (_) {
              setState(() {});
            },
            onClearQuery: () {
              _searchController.clear();
              _initialDisplayLimit = 30;
              setState(() {});
            },
            onRoomTap: (info) {
              _activateRoom(
                info,
                switchToDetail: true,
              );

              final active = ref.read(activeBuildingProvider);
              pageController = PageController(
                initialPage: active.floorCount - 1,
              );
            },
          )
        : () {
            final inSameBuilding = sortedRoomList
                .where((info) => info.buildingId == activeBuilding.id)
                .toList();
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

    return Stack(
      children: [
        content,
        if (shouldShowSearch)
          Positioned(
            bottom: 24,
            right: 24,
            child: FloatingActionButton(
              heroTag: 'focus_search',
              onPressed: () =>
                  FocusScope.of(context).requestFocus(_searchFocusNode),
              backgroundColor: Colors.green,
              tooltip: '検索ボックスにフォーカス',
              child: const Icon(Icons.search),
            ),
          ),
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
}
