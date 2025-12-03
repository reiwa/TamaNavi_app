import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/utility/platform_utils.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/viewer/node_marker.dart';
import 'package:tamanavi_app/viewer/passage_painter.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';
import 'package:uuid/uuid.dart';

typedef _InteractionOverlayState = ({
  Offset? tapPosition,
  CachedSData? selectedElement,
  bool isConnecting,
  bool isDragging,
  CachedSData? connectingStart,
  Offset? previewPosition,
  PlaceType currentType,
});

class InteractiveLayer extends StatelessWidget {
  const InteractiveLayer({
    required this.self,
    required this.floor,
    required this.imageUrl,
    required this.viewerSize,
    required this.relevantElements,
    required this.routeNodeIds,
    required this.routeVisualSegments,
    required this.elevatorLinks,
    required this.passageEdges,
    required this.hasActiveRoute,
    required this.ref,
    super.key,
    this.previewEdge,
  });

  final InteractiveImageMixin self;
  final int floor;
  final String imageUrl;
  final Size viewerSize;
  final List<CachedSData> relevantElements;
  final Set<String> routeNodeIds;
  final List<RouteVisualSegment> routeVisualSegments;
  final List<ElevatorVerticalLink> elevatorLinks;
  final List<Edge> passageEdges;
  final Edge? previewEdge;
  final bool hasActiveRoute;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final transformationController = ref
        .read(interactiveImageProvider.notifier)
        .transformationController;
    var cachedScale = transformationController.value.getMaxScaleOnAxis();
    return RepaintBoundary(
      child: Stack(
        children: [
          IgnorePointer(
            ignoring: self.canSwipeFloors,
            child: InteractiveViewer(
              transformationController: transformationController,
              minScale: self.minScale,
              maxScale: self.maxScale,
              boundaryMargin: const EdgeInsets.all(200),
              onInteractionStart: (_) {
                cachedScale =
                    transformationController.value.getMaxScaleOnAxis();
              },
              onInteractionEnd: (_) {
                if (transformationController.value.getMaxScaleOnAxis() <=
                        1.05 &&
                    cachedScale -
                            transformationController.value.getMaxScaleOnAxis() >
                        0) {
                  transformationController.value = Matrix4.identity();
                  ref
                      .read(interactiveImageProvider.notifier)
                      .updateCurrentZoomScale();
                }
              },
              child: _InteractiveContent(
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
              ),
            ),
          ),
          if (isDesktopOrElse)
            Positioned(
              right: 10,
              bottom: 10,
              child: IconButton(
                icon: Icon(
                  transformationController.value.getMaxScaleOnAxis() <= 1.05
                      ? Icons.zoom_out_map
                      : Icons.zoom_in_map,
                ),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.7),
                  foregroundColor: Colors.black87,
                ),
                onPressed: () {
                  ref.read(interactiveImageProvider.notifier).toggleZoom();
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _InteractiveContent extends ConsumerStatefulWidget {
  const _InteractiveContent({
    required this.self,
    required this.floor,
    required this.imageUrl,
    required this.viewerSize,
    required this.relevantElements,
    required this.routeNodeIds,
    required this.routeVisualSegments,
    required this.elevatorLinks,
    required this.passageEdges,
    required this.hasActiveRoute,
    required this.ref,
    this.previewEdge,
  });

  final InteractiveImageMixin self;
  final int floor;
  final String imageUrl;
  final Size viewerSize;
  final List<CachedSData> relevantElements;
  final Set<String> routeNodeIds;
  final List<RouteVisualSegment> routeVisualSegments;
  final List<ElevatorVerticalLink> elevatorLinks;
  final List<Edge> passageEdges;
  final Edge? previewEdge;
  final bool hasActiveRoute;
  final WidgetRef ref;

  @override
  ConsumerState<_InteractiveContent> createState() =>
      _InteractiveContentState();
}

class _InteractiveContentState extends ConsumerState<_InteractiveContent>
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  late final AnimationController _routePulseController;
  late final ProviderSubscription<InteractiveImageState>
      _imageStateSubscription;
  ProviderSubscription<AsyncValue<SvgPayload>>? _svgPayloadSubscription;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _routePulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _syncRoutePulseState();

    _imageStateSubscription = ref.listenManual<InteractiveImageState>(
      interactiveImageProvider,
      _onImageStateChange,
    );
    _listenToSvgPayload(widget.imageUrl);

    if (widget.self.showSelectedPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final currentSelected = ref
            .read(interactiveImageProvider)
            .selectedElement;
        if (currentSelected != null && currentSelected.floor == widget.floor) {
          await _iconController.forward(from: 0);
        }
      });
    }
  }

  void _listenToSvgPayload(String imageUrl) {
    _svgPayloadSubscription?.close();
    _svgPayloadSubscription = ref.listenManual<AsyncValue<SvgPayload>>(
      svgPayloadProvider(imageUrl),
      (_, next) {
        next.whenData((payload) {
          if (!mounted) return;
          ref
              .read(interactiveImageProvider.notifier)
              .setImageDimensions(widget.floor, payload.size);
        });
      },
      fireImmediately: true,
    );
  }

  bool get _shouldAnimateRoute =>
      widget.hasActiveRoute && widget.routeVisualSegments.isNotEmpty;

  void _syncRoutePulseState() {
    if (_shouldAnimateRoute) {
      if (!_routePulseController.isAnimating) {
        unawaited(_routePulseController.repeat());
      }
    } else if (_routePulseController.isAnimating) {
      _routePulseController..stop()
      ..value = 0;
    }
  }

  @override
  void didUpdateWidget(covariant _InteractiveContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hasActiveRoute != widget.hasActiveRoute ||
        oldWidget.routeVisualSegments.length !=
            widget.routeVisualSegments.length) {
      _syncRoutePulseState();
    }
    if (oldWidget.imageUrl != widget.imageUrl ||
        oldWidget.floor != widget.floor) {
      _listenToSvgPayload(widget.imageUrl);
    }
  }

  Future<void> _onImageStateChange(
    InteractiveImageState? previous,
    InteractiveImageState next,
  ) async {
    if (!widget.self.showSelectedPin) {
      if (_iconController.status != AnimationStatus.dismissed) {
        _iconController.reset();
      }
      return;
    }
    final wasSelected = previous?.selectedElement != null;
    final isSelected = next.selectedElement != null;

    if (!wasSelected && isSelected) {
      await _iconController.forward(from: 0);
    } else if (wasSelected && !isSelected) {
      _iconController.reset();
    }
  }

  @override
  void dispose() {
    _imageStateSubscription.close();
    _svgPayloadSubscription?.close();
    _iconController.dispose();
    _routePulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final _InteractionOverlayState overlayState = ref.watch(
      interactiveImageProvider.select(
        (s) => (
          tapPosition: s.tapPosition,
          selectedElement: s.selectedElement,
          isConnecting: s.isConnecting,
          isDragging: s.isDragging,
          connectingStart: s.connectingStart,
          previewPosition: s.previewPosition,
          currentType: s.currentType,
        ),
      ),
    );

    final imageDimensions = ref.watch(
      interactiveImageProvider.select(
        (s) => s.imageDimensionsByFloor[widget.floor],
      ),
    );

    final selected = overlayState.selectedElement;
    final isSelectedOnThisFloor =
        selected != null && selected.floor == widget.floor;
    final shouldShowPin = widget.self.showSelectedPin && isSelectedOnThisFloor;

    if (widget.self.showSelectedPin) {
      if (shouldShowPin) {
        if (_iconController.status == AnimationStatus.dismissed) {
          unawaited(_iconController.forward());
        }
      } else if (_iconController.status != AnimationStatus.dismissed) {
        _iconController.reset();
      }
    } else if (_iconController.status != AnimationStatus.dismissed) {
      _iconController.reset();
    }

    final transformationController = ref
        .read(interactiveImageProvider.notifier)
        .transformationController;

    final svgAsync = ref.watch(svgPayloadProvider(widget.imageUrl));
    final svgPayload = svgAsync.asData?.value;

    final resolvedDimensions = imageDimensions ?? svgPayload?.size;
    if (svgPayload != null && imageDimensions == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref
            .read(interactiveImageProvider.notifier)
            .setImageDimensions(widget.floor, svgPayload.size);
      });
    }

    if (resolvedDimensions == null) {
      return svgAsync.when(
        data: (_) => const Center(child: CircularProgressIndicator()),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text('${widget.floor}階の画像が読み込めません\n(${widget.imageUrl})'),
        ),
      );
    }

    var displaySize = resolvedDimensions;
    if (resolvedDimensions.width > widget.viewerSize.width) {
      final scale = widget.viewerSize.width / resolvedDimensions.width;
      displaySize = Size(
        widget.viewerSize.width,
        resolvedDimensions.height * scale,
      );
    }
    if (displaySize.height > widget.viewerSize.height) {
      final scale = widget.viewerSize.height / displaySize.height;
      displaySize = Size(displaySize.width * scale, widget.viewerSize.height);
    }

    return Container(
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          svgAsync.when(
            data: (payload) => SvgPicture.memory(
              payload.bytes,
              width: displaySize.width,
              height: displaySize.height,
            ),
            loading: () => SizedBox(
              width: displaySize.width,
              height: displaySize.height,
              child: const Center(child: CircularProgressIndicator()),
            ),
            error: (err, stack) => SizedBox(
              width: displaySize.width,
              height: displaySize.height,
              child: Center(
                child: Text(
                  '${widget.floor}階の画像が読み込めません\n(${widget.imageUrl})',
                ),
              ),
            ),
          ),
          _GestureLayer(
            self: widget.self,
            floor: widget.floor,
            ref: widget.ref,
            imageDimensions: displaySize,
            isConnecting: overlayState.isConnecting,
            connectingStart: overlayState.connectingStart,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                size: displaySize,
                painter: PassagePainter(
                  edges: widget.passageEdges,
                  previewEdge: widget.previewEdge,
                  connectingType: overlayState.connectingStart?.type,
                  controller: transformationController,
                  routeSegments: widget.routeVisualSegments,
                  viewerSize: widget.viewerSize,
                  elevatorLinks: widget.elevatorLinks,
                  imageDimensions: displaySize,
                  hideBaseEdges:
                      widget.self.widget.mode == CustomViewMode.finder ||
                      widget.hasActiveRoute,
                  routePulse:
                      _shouldAnimateRoute ? _routePulseController : null,
                  elements: widget.relevantElements
                      .where((e) => e.floor == widget.floor)
                      .toList(),
                  selectedElement: isSelectedOnThisFloor ? selected : null,
                  labelStyle: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: AnimatedBuilder(
              animation: transformationController,
              builder: (context, child) {
                final scale = transformationController.value
                    .getMaxScaleOnAxis();
                final pointerSize = 12 / sqrt(scale);

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    ...buildNodeMarkers(
                      self: widget.self,
                      context: context,
                      floor: widget.floor,
                      pointerSize: pointerSize,
                      relevantElements: widget.relevantElements,
                      routeNodeIds: widget.routeNodeIds,
                      selectedElement: selected,
                      isConnecting: overlayState.isConnecting,
                      isDragging: overlayState.isDragging,
                      ref: widget.ref,
                      imageDimensions: displaySize,
                    ),

                    if (widget.self.showTapDot &&
                        overlayState.tapPosition != null &&
                        overlayState.selectedElement == null)
                      _TapDot(
                        self: widget.self,
                        pointerSize: pointerSize,
                        floor: widget.floor,
                        ref: widget.ref,
                        imageDimensions: displaySize,
                        tapPosition: overlayState.tapPosition!,
                        currentType: overlayState.currentType,
                      ),
                    if (widget.self.showSelectedPin &&
                        overlayState.selectedElement != null) ...[
                      Builder(
                        builder: (context) {
                          final element = overlayState.selectedElement!;
                          final iconX = element.position.dx * displaySize.width;
                          final iconY =
                              element.position.dy * displaySize.height;
                          final iconSize = pointerSize * 3.5;

                          return Positioned(
                            left: iconX - (iconSize / 2),
                            top: iconY - iconSize * 0.9,
                            child: ScaleTransition(
                              scale: _iconAnimation,
                              alignment: Alignment.bottomCenter,
                              child: Icon(
                                Icons.location_on,
                                color: Colors.redAccent,
                                size: iconSize,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GestureLayer extends StatelessWidget {
  const _GestureLayer({
    required this.self,
    required this.floor,
    required this.ref,
    required this.imageDimensions,
    required this.isConnecting,
    required this.connectingStart,
  });

  final InteractiveImageMixin self;
  final int floor;
  final WidgetRef ref;
  final Size imageDimensions;
  final bool isConnecting;
  final CachedSData? connectingStart;

  Offset _toRelative(Offset absolutePosition) {
    if (imageDimensions.width == 0 || imageDimensions.height == 0) {
      return Offset.zero;
    }
    return Offset(
      (absolutePosition.dx / imageDimensions.width).clamp(0.0, 1.0),
      (absolutePosition.dy / imageDimensions.height).clamp(0.0, 1.0),
    );
  }

  Offset _toAbsolute(Offset relativePosition) {
    return Offset(
      relativePosition.dx * imageDimensions.width,
      relativePosition.dy * imageDimensions.height,
    );
  }

  void _handleTap(BuildContext context, Offset absolutePos) {
    final notifier = ref.read(interactiveImageProvider.notifier);
    final relativePos = _toRelative(absolutePos);

    final prevSelectedElement = ref
        .read(interactiveImageProvider)
        .selectedElement;

    notifier.onTapDetected(relativePos);

    if (self is EditorControllerHost) {
      final host = self as EditorControllerHost;
      final state = ref.read(interactiveImageProvider);

      if (state.selectedElement == null) {
        final absoluteTapPos = _toAbsolute(relativePos);
        host.xController.text = absoluteTapPos.dx.toStringAsFixed(0);
        host.yController.text = absoluteTapPos.dy.toStringAsFixed(0);
        if (prevSelectedElement != null) {
          host.nameController.text = '新しい要素';
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(interactiveImageProvider.notifier);
    return Positioned.fill(
      child: Listener(
        onPointerMove: (details) {
          if (isConnecting && connectingStart?.floor == floor) {
            notifier.updatePreviewPosition(_toRelative(details.localPosition));
          }
        },
        child: GestureDetector(
          onTapDown: (details) => _handleTap(context, details.localPosition),
          child: Container(color: Colors.transparent),
        ),
      ),
    );
  }
}

class _TapDot extends StatelessWidget {
  const _TapDot({
    required this.self,
    required this.pointerSize,
    required this.floor,
    required this.ref,
    required this.imageDimensions,
    required this.tapPosition,
    required this.currentType,
  });

  final InteractiveImageMixin self;
  final double pointerSize;
  final int floor;
  final WidgetRef ref;
  final Size imageDimensions;
  final Offset tapPosition;
  final PlaceType currentType;

  Offset _toAbsolute(Offset relativePosition) {
    return Offset(
      relativePosition.dx * imageDimensions.width,
      relativePosition.dy * imageDimensions.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(interactiveImageProvider.notifier);

    final absoluteTapPos = _toAbsolute(tapPosition);

    return Positioned(
      left: absoluteTapPos.dx - pointerSize / 8 * 5 / 2,
      top: absoluteTapPos.dy - pointerSize / 8 * 5 / 2,
      child: GestureDetector(
        onTap: () => notifier.onTapDetected(tapPosition),
        onDoubleTap: () {
          final newSData = CachedSData(
            id: const Uuid().v4(),
            name: '新しい要素',
            position: tapPosition,
            floor: floor,
            type: currentType,
          );
          ref.read(activeBuildingProvider.notifier).addSData(newSData);

          notifier.clearSelectionState();
          if (self is EditorControllerHost) {
            final host = self as EditorControllerHost;
            host.nameController.clear();
            host.xController.clear();
            host.yController.clear();
          }
        },
        child: Container(
          width: pointerSize / 8 * 5,
          height: pointerSize / 8 * 5,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.7),
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
