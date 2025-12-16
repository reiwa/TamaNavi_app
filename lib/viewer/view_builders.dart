part of 'room_finder_viewer.dart';

class _FloorPageView extends ConsumerStatefulWidget {
  const _FloorPageView({required this.self, required this.floor});

  final InteractiveImageMixin self;
  final int floor;

  @override
  ConsumerState<_FloorPageView> createState() => _FloorPageViewState();
}

class _FloorPageViewState extends ConsumerState<_FloorPageView> {
  String? _lastPrefetchPattern;
  String? _lastPrefetchBuildingId;
  int? _lastPrefetchFloorCount;

  void _schedulePrefetchOnce({
    required String buildingId,
    required String imagePattern,
    required int floorCount,
    required int currentFloor,
  }) {
    if (imagePattern.isEmpty) return;
    final alreadyPrefetched =
        _lastPrefetchPattern == imagePattern &&
        _lastPrefetchBuildingId == buildingId &&
        _lastPrefetchFloorCount == floorCount;
    if (alreadyPrefetched) {
      return;
    }

    _lastPrefetchPattern = imagePattern;
    _lastPrefetchBuildingId = buildingId;
    _lastPrefetchFloorCount = floorCount;

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final prefetchNotifier =
          ref.read(floorImagePrefetchNotifierProvider.notifier);

      final futures = <Future<void>>[];
      for (var f = 1; f <= floorCount; f++) {
        if (f == currentFloor) continue;
        final key = (imagePattern: imagePattern, floor: f);
        futures.add(prefetchNotifier.ensurePrefetched(key));
      }

      if (futures.isNotEmpty) {
        await Future.wait(futures);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final self = widget.self;
    final floor = widget.floor;
    final snap = ref.watch(activeBuildingProvider);
    final currentFloor = ref.watch(
      interactiveImageProvider.select((s) => s.currentFloor),
    );
    final isPrimaryFloor = currentFloor == floor;
    final relevantElements = snap.elements
        .where((sData) => sData.floor == floor)
        .toList();
    final passageEdges = ref.watch(graphEdgesProvider(floor));
    final elementsById = {
      for (final element in snap.elements) element.id: element,
    };
    final routeSegments = ref.watch(activeRouteSegmentsProvider);
    final hasActiveRoute = routeSegments.isNotEmpty;
    final routeNodeIds = {
      for (final node in ref.watch(activeRouteProvider)) node.id,
    };
    final routeElevatorPairs = <String>{};
    final routeElevatorDirections = <String>{};
    final routeVisualSegments = <RouteVisualSegment>[];

    for (final segment in routeSegments) {
      if (segment.from.floor == floor && segment.to.floor == floor) {
        routeVisualSegments.add(
          RouteVisualSegment(
            start: segment.from.position,
            end: segment.to.position,
            fromType: segment.from.type,
            toType: segment.to.type,
          ),
        );
      }
      final crossesFloors = segment.from.floor != segment.to.floor;
      final connectsVerticalNodes =
          segment.from.type.isVerticalConnector &&
          segment.to.type.isVerticalConnector;
      if (crossesFloors && connectsVerticalNodes) {
        final sortedIds = [segment.from.id, segment.to.id]..sort();
        routeElevatorPairs.add('${sortedIds[0]}|${sortedIds[1]}');
        routeElevatorDirections.add('${segment.from.id}->${segment.to.id}');
      }
    }

    bool routeMatchesDirection(String fromId, String toId) =>
        routeElevatorDirections.contains('$fromId->$toId');

    bool routeUsesPair(String a, String b) {
      if (!hasActiveRoute) return true;
      final ids = [a, b]..sort();
      return routeElevatorPairs.contains('${ids[0]}|${ids[1]}');
    }

    final elevatorLinks = <ElevatorVerticalLink>[];
    void pushElevatorLink(CachedSData source, CachedSData target) {
      if (source.floor != floor) return;
      if (!routeUsesPair(source.id, target.id)) return;
      final matchesDirection = routeMatchesDirection(source.id, target.id);
      if (hasActiveRoute && !matchesDirection) return;
      elevatorLinks.add(
        ElevatorVerticalLink(
          origin: source.position,
          isUpward: target.floor > source.floor,
          color: source.type.color,
          targetFloor: target.floor,
          highlight: matchesDirection,
          message: self.widget.mode == CustomViewMode.editor
              ? '${target.floor}階'
              : (matchesDirection ? '${target.floor}階へ' : null),
        ),
      );
    }

    for (final edgeSet in snap.passages.expand((pData) => pData.edges)) {
      if (edgeSet.length != 2) continue;
      final ids = edgeSet.toList(growable: false);
      final first = elementsById[ids[0]];
      final second = elementsById[ids[1]];
      if (first == null || second == null) continue;
      final isVerticalPair =
          first.type.isVerticalConnector &&
          second.type.isVerticalConnector &&
          first.type == second.type;
      if (!isVerticalPair) continue;
      if (first.floor == second.floor) continue;
      pushElevatorLink(first, second);
      pushElevatorLink(second, first);
    }

    final connectionState = ref.watch(
      interactiveImageProvider.select(
        (s) => (
          isConnecting: s.isConnecting,
          connectingStart: s.connectingStart,
          previewPosition: s.previewPosition,
        ),
      ),
    );

    Edge? previewEdge;
    if (connectionState.isConnecting &&
        connectionState.connectingStart != null &&
        connectionState.previewPosition != null &&
        connectionState.connectingStart!.floor == floor) {
      previewEdge = Edge(
        start: connectionState.connectingStart!.position,
        end: connectionState.previewPosition!,
      );
    }

    final imagePattern = snap.imagePattern.trim();
    final imageKey = (imagePattern: imagePattern, floor: floor);
    final imageUrlValue = ref.watch(floorImageUrlProvider(imageKey));

    String buildImageErrorText(Object error) {
      if (error is FloorImagePatternMissingException) {
        return error.message;
      }
      if (error is FirebaseException) {
        final message = error.message?.trim() ?? '';
        final code = error.code.trim();
        final details = <String>[];
        if (message.isNotEmpty) {
          details.add(message);
        }
        if (code.isNotEmpty) {
          details.add('[${error.code}]');
        }
        final suffix = details.isEmpty ? '' : '\n${details.join(' ')}';
        return '$floor階の画像を取得できませんでした$suffix';
      }
      return '$floor階の画像を取得できませんでした\n$error';
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final mediaSize = MediaQuery.sizeOf(context);
        final viewerSize = Size(
          constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : (constraints.minWidth.isFinite
                    ? constraints.minWidth
                    : mediaSize.width),
          constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : (constraints.minHeight.isFinite
                    ? constraints.minHeight
                    : mediaSize.height),
        );
        return ClipRect(
          child: imageUrlValue.when(
            data: (imageUrl) {
              _schedulePrefetchOnce(
                buildingId: snap.id,
                imagePattern: imagePattern,
                floorCount: snap.floorCount,
                currentFloor: floor,
              );
              return Stack(
                children: [
                  InteractiveLayer(
                    self: self,
                    floor: floor,
                    imageUrl: imageUrl,
                    viewerSize: viewerSize,
                    relevantElements: relevantElements,
                    routeNodeIds: routeNodeIds,
                    routeVisualSegments: routeVisualSegments,
                    elevatorLinks: elevatorLinks,
                    passageEdges: passageEdges,
                    previewEdge: previewEdge,
                    hasActiveRoute: hasActiveRoute,
                    ref: ref,
                    isPrimaryFloor: isPrimaryFloor,
                  ),
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stackTrace) => Center(
              child: Text(
                buildImageErrorText(error),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        );
      },
    );
  }
}
