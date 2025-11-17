part of 'room_finder_viewer.dart';

class _FloorPageView extends ConsumerWidget {
  const _FloorPageView({required this.self, required this.floor});

  final InteractiveImageMixin self;
  final int floor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snap = ref.watch(activeBuildingProvider);
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
          ),
        );
      }
      if (segment.from.floor != segment.to.floor &&
          (segment.from.type == PlaceType.elevator ||
              segment.to.type == PlaceType.elevator)) {
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
          color: PlaceType.elevator.color,
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
      if (first.type != PlaceType.elevator ||
          second.type != PlaceType.elevator) {
        continue;
      }
      if (first.floor == second.floor) continue;
      pushElevatorLink(first, second);
      pushElevatorLink(second, first);
    }

    final imageState = ref.watch(interactiveImageProvider);

    Edge? previewEdge;
    if (imageState.isConnecting &&
        imageState.connectingStart != null &&
        imageState.previewPosition != null &&
        imageState.connectingStart!.floor == floor) {
      previewEdge = Edge(
        start: imageState.connectingStart!.position,
        end: imageState.previewPosition!,
      );
    }

    final imagePattern = snap.imagePattern.trim();
    final imageKey = (imagePattern: imagePattern, floor: floor);
    final imageUrlValue = ref.watch(floorImageUrlProvider(imageKey));

    void scheduleDeferredPrefetch() {
      if (imagePattern.isEmpty) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!context.mounted) return;
        Future.microtask(() async {
          if (!context.mounted) return;
          final prefetchNotifier = ref.read(
            floorImagePrefetchNotifierProvider.notifier,
          );
          for (var f = 1; f <= snap.floorCount; f++) {
            if (f == floor) continue;
            final key = (imagePattern: imagePattern, floor: f);
            await prefetchNotifier.ensurePrefetched(context, key);
          }
        });
      });
    }

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
      return '$floor階の画像を取得できませんでした\n${error.toString()}';
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
        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: Colors.green.withValues(alpha: 0.45),
                width: 1.0,
              ),
              bottom: BorderSide(
                color: Colors.green.withValues(alpha: 0.45),
                width: 1.0,
              ),
            ),
          ),
          clipBehavior: Clip.hardEdge,
          child: imageUrlValue.when(
            data: (imageUrl) {
              scheduleDeferredPrefetch();
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
                    ref: ref,
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
