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
import 'package:tamanavi_app/room_finder/settings_dialog.dart';
import 'detail_screen.dart';
import 'search_screen.dart';
import 'entrance_selector.dart';

const List<String> kFinderTagOptions = kBuildingTagOptions;

final selectedTagProvider = StateProvider<String>((ref) => kFinderTagOptions.first);

final tagSearchResultsProvider =
    FutureProvider<List<BuildingRoomInfo>>((ref) async {
  final selectedTag = ref.watch(selectedTagProvider);

  await ref
      .read(buildingRepositoryProvider.notifier)
      .fetchBuildingsByTag(selectedTag);

  final map = ref.read(buildingRepositoryProvider).asData?.value ??
      const <String, BuildingSnapshot>{};

  final results = <BuildingRoomInfo>[];
  for (final snapshot in map.values) {
    if (snapshot.id == kDraftBuildingId) continue;
    if (!snapshot.tags.contains(selectedTag)) continue;
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
    return other.navigateTo == navigateTo &&
        other.navigateFrom == navigateFrom;
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
  ProviderSubscription<AsyncValue<Map<String, BuildingSnapshot>>>?
      _repositorySubscription;

  @override
  void initState() {
    super.initState();

    _pendingIntent = widget.initialIntent;

    pageController = PageController();

    _repositorySubscription =
        ref.listenManual<AsyncValue<Map<String, BuildingSnapshot>>>(
      buildingRepositoryProvider,
      (previous, next) {
        if (!mounted) return;
        next.whenData((_) => _maybeProcessPendingIntent());
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _firstFrameRendered = true;

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

      _maybeProcessPendingIntent();
    });
  }

  @override
  void didUpdateWidget(covariant FinderView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIntent != oldWidget.initialIntent) {
      _pendingIntent = widget.initialIntent;
      _maybeProcessPendingIntent();
    }
  }

  @override
  void dispose() {
    _repositorySubscription?.close();
    super.dispose();
  }

  void _activateRoom(
    BuildingRoomInfo info, {
    bool switchToDetail = false,
    bool autoNavigate = true,
  }) {
    final img = ref.read(interactiveImageProvider.notifier);
    img.activateRoom(
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
      } else {
        notifier.applyPendingFocusIfAny();
      }
    }
  }

  Future<void> _startNavigation({
    String? startElementId,
    bool promptForEntranceSelection = false,
  }) async {
    final active = ref.read(activeBuildingProvider);
    final targetElement = _resolveNavigationTarget();
    if (targetElement == null) {
      _showSnackBar('目的地が選択されていません。');
      return;
    }

    if (targetElement.type == PlaceType.room && mounted) {
      ref.read(interactiveImageProvider.notifier).activateRoom(
            BuildingRoomInfo(
              buildingId: active.id,
              buildingName: active.name,
              room: targetElement,
            ),
            switchToDetail: false,
          );
    }

    CachedSData? startNode;
    if (startElementId != null) {
      startNode = _findElementById(active, startElementId);
      if (startNode == null) {
        _showSnackBar('出発地点が見つかりません: $startElementId');
        return;
      }
    } else {
      final entrances = active.elements
          .where((e) => e.type == PlaceType.entrance)
          .toList();
      if (entrances.isEmpty) {
        _showSnackBar('この建物に入口が見つかりません。');
        return;
      }
      if (promptForEntranceSelection && entrances.length > 1) {
        final selectedEntrance = await showEntranceSelector(
          context: context,
          entrances: entrances,
          initialId: entrances.first.id,
          onFocus: (entrance) {
            _focusOnElement(entrance);
          },
        );

        if (!mounted) return;
        if (selectedEntrance == null) {
          return;
        }
        startNode = selectedEntrance;
      } else {
        startNode = entrances.first;
      }
    }

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

      Future.microtask(() async {
        if (!mounted) return;

        _activateRoom(
          resolvedTarget,
          switchToDetail: true,
          autoNavigate: false,
        );

        await Future.delayed(const Duration(milliseconds: 50));
        if (!mounted) return;

        if (intent.hasNavigateFrom) {
          await _startNavigation(startElementId: intent.navigateFrom);
        } else {
          await _focusOnElement(resolvedTarget.room);
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

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
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
                    await _focusOnElement(match.room);
                  },
                  onReturnToSearch: _returnToSearch,
                  interactiveImage: buildInteractiveImage(),
                  selectedElementLabel: _selectedElementLabel(activeBuilding),
                  onStartNavigation: () =>
                      _startNavigation(promptForEntranceSelection: true),
                );
              }();

        return Column(
          children: [
            SafeArea(bottom: false, child: _buildHeader(context)),
            Expanded(child: content),
          ],
        );
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.lightGreen.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          Expanded(child: SizedBox.shrink()),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '設定',
            onPressed: () => showFinderSettingsDialog(context),
          ),
        ],
      ),
    );
  }
}
