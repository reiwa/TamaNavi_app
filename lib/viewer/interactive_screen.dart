import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/utility/platform_utils.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/viewer/node_marker.dart';
import 'package:tamanavi_app/viewer/passage_painter.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';
import 'package:uuid/uuid.dart';

class InteractiveLayer extends StatelessWidget {
  const InteractiveLayer({
    super.key,
    required this.self,
    required this.floor,
    required this.imageUrl,
    required this.viewerSize,
    required this.relevantElements,
    required this.routeNodeIds,
    required this.routeVisualSegments,
    required this.elevatorLinks,
    required this.passageEdges,
    this.previewEdge,
    required this.ref,
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
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final transformationController = ref
        .read(interactiveImageProvider.notifier)
        .transformationController;
    var cachedScale = transformationController.value.getMaxScaleOnAxis();
    return Stack(
      children: [
        IgnorePointer(
          ignoring: self.canSwipeFloors,
          child: InteractiveViewer(
            transformationController: transformationController,
            minScale: self.minScale,
            maxScale: self.maxScale,
            panEnabled: true,
            clipBehavior: Clip.hardEdge,
            boundaryMargin: const EdgeInsets.all(200),
            onInteractionStart: (_) {
              cachedScale = transformationController.value.getMaxScaleOnAxis();
            },
            onInteractionEnd: (_) {
              if (transformationController.value.getMaxScaleOnAxis() <= 1.05 &&
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
              ref: ref,
            ),
          ),
        ),

        if (isDesktopOrElse)
          Positioned(
            right: 10.0,
            bottom: 10.0,
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
    this.previewEdge,
    required this.ref,
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
  final WidgetRef ref;

  @override
  ConsumerState<_InteractiveContent> createState() =>
      _InteractiveContentState();
}

class _InteractiveContentState extends ConsumerState<_InteractiveContent>
    with SingleTickerProviderStateMixin {
  static const int _maxSvgBytes = 2 * 1024 * 1024;

  Future<_SvgPayload>? _svgFuture;
  int _svgLoadToken = 0;

  late AnimationController _iconController;
  late Animation<double> _iconAnimation;
  ProviderSubscription<InteractiveImageState>? _imageStateSubscription;

  @override
  void initState() {
    super.initState();
    _reloadSvg();

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _iconAnimation = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );

    _subscribeToImageState();

    if (widget.self.showSelectedPin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final currentSelected = ref
            .read(interactiveImageProvider)
            .selectedElement;
        if (currentSelected != null && currentSelected.floor == widget.floor) {
          _iconController.forward(from: 0.0);
        }
      });
    }
  }

  @override
  void didUpdateWidget(_InteractiveContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl) {
      _reloadSvg();
    }

    if (oldWidget.floor != widget.floor) {
      _subscribeToImageState();
      final hasDimensions = ref
              .read(interactiveImageProvider)
              .imageDimensionsByFloor
              .containsKey(widget.floor) &&
          ref
                  .read(interactiveImageProvider)
                  .imageDimensionsByFloor[widget.floor] !=
              null;
      if (!hasDimensions) {
        _reloadSvg();
      }
    }
  }

  void _reloadSvg() {
    final imageUrl = widget.imageUrl;
    final loadId = ++_svgLoadToken;

    final future = _fetchSvg(imageUrl);
    _svgFuture = future;
    setState(() {});

    future.then((payload) {
      if (!mounted || loadId != _svgLoadToken) return;
      final notifier = ref.read(interactiveImageProvider.notifier);
      notifier.setImageDimensions(widget.floor, payload.size);
    }).catchError((_) {
      // Loading errors are surfaced via FutureBuilder; nothing to do here.
    });
  }

  void _subscribeToImageState() {
    _imageStateSubscription?.close();
    _imageStateSubscription = ref.listenManual<InteractiveImageState>(
      interactiveImageProvider,
      _onImageStateChange,
    );
  }

  void _onImageStateChange(
    InteractiveImageState? previous,
    InteractiveImageState next,
  ) {
    if (!widget.self.showSelectedPin) {
      if (_iconController.status != AnimationStatus.dismissed) {
        _iconController.reset();
      }
      return;
    }
    final wasSelected = previous?.selectedElement != null;
    final isSelected = next.selectedElement != null;

    if (!wasSelected && isSelected) {
      _iconController.forward(from: 0.0);
    } else if (wasSelected && !isSelected) {
      _iconController.reset();
    }
  }

  @override
  void dispose() {
    _imageStateSubscription?.close();
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imageDimensions = ref.watch(
      interactiveImageProvider.select(
        (s) => s.imageDimensionsByFloor[widget.floor],
      ),
    );

    final imageState = ref.watch(interactiveImageProvider);

    final selected = imageState.selectedElement;
    final isSelectedOnThisFloor =
        selected != null && selected.floor == widget.floor;
    final shouldShowPin = widget.self.showSelectedPin && isSelectedOnThisFloor;

    if (widget.self.showSelectedPin) {
      if (shouldShowPin) {
        if (_iconController.status == AnimationStatus.dismissed) {
          _iconController.forward();
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
    if (imageDimensions == null) {
      return Container(
        alignment: Alignment.center,
        child: const CircularProgressIndicator(),
      );
    }
    Size displaySize = imageDimensions;
    if (imageDimensions.width > widget.viewerSize.width) {
      final scale = widget.viewerSize.width / imageDimensions.width;
      displaySize = Size(
        widget.viewerSize.width,
        imageDimensions.height * scale,
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
          FutureBuilder<_SvgPayload>(
            future: _svgFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return SizedBox(
                  width: displaySize.width,
                  height: displaySize.height,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (snapshot.hasError || snapshot.data == null) {
                return SizedBox(
                  width: displaySize.width,
                  height: displaySize.height,
                  child: Center(
                    child: Text(
                      '${widget.floor}階の画像が読み込めません\n(${widget.imageUrl})',
                    ),
                  ),
                );
              }

              final payload = snapshot.data!;
              return SvgPicture.memory(
                payload.bytes,
                width: displaySize.width,
                height: displaySize.height,
                fit: BoxFit.contain,
              );
            },
          ),
          _GestureLayer(
            self: widget.self,
            floor: widget.floor,
            ref: widget.ref,
            imageDimensions: displaySize,
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                size: displaySize,
                painter: PassagePainter(
                  edges: widget.passageEdges,
                  previewEdge: widget.previewEdge,
                  connectingType: imageState.connectingStart?.type,
                  controller: transformationController,
                  routeSegments: widget.routeVisualSegments,
                  viewerSize: widget.viewerSize,
                  elevatorLinks: widget.elevatorLinks,
                  imageDimensions: displaySize,
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
                      ref: widget.ref,
                      imageDimensions: displaySize,
                    ),

                    if (widget.self.showTapDot &&
                        imageState.tapPosition != null &&
                        imageState.selectedElement == null)
                      _TapDot(
                        self: widget.self,
                        pointerSize: pointerSize,
                        floor: widget.floor,
                        ref: widget.ref,
                        imageDimensions: displaySize,
                      ),
                    if (widget.self.showSelectedPin &&
                        imageState.selectedElement != null) ...[
                      Builder(
                        builder: (context) {
                          final element = imageState.selectedElement!;
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

class _SvgPayload {
  const _SvgPayload({required this.bytes, required this.size});

  final Uint8List bytes;
  final Size size;
}

final Map<String, Future<_SvgPayload>> _svgPayloadCache = {};

Future<_SvgPayload> _fetchSvg(String url) {
  final cached = _svgPayloadCache[url];
  if (cached != null) {
    return cached;
  }

  final future = () async {
    final storageRef = FirebaseStorage.instance.refFromURL(url);
    final rawBytes =
        await storageRef.getData(_InteractiveContentState._maxSvgBytes);
    if (rawBytes == null || rawBytes.isEmpty) {
      throw StateError('Empty SVG data for $url');
    }
    final size = _parseSvgSize(rawBytes);
    return _SvgPayload(bytes: rawBytes, size: size);
  }();

  _svgPayloadCache[url] = future.catchError((error, stackTrace) {
    _svgPayloadCache.remove(url);
    throw error;
  });

  return future;
}

Size _parseSvgSize(Uint8List svgBytes) {
  final svgString = utf8.decode(svgBytes);
  final width = _parseSvgLength(_extractSvgAttribute(svgString, 'width'));
  final height = _parseSvgLength(_extractSvgAttribute(svgString, 'height'));

  if (width != null && height != null && width > 0 && height > 0) {
    return Size(width, height);
  }

  final viewBox = _extractSvgAttribute(svgString, 'viewBox');
  if (viewBox != null) {
    final parts = viewBox
        .split(RegExp(r'[\s,]+'))
        .where((value) => value.isNotEmpty)
        .toList(growable: false);
    if (parts.length == 4) {
      final vbWidth = double.tryParse(parts[2]);
      final vbHeight = double.tryParse(parts[3]);
      if (vbWidth != null && vbHeight != null && vbWidth > 0 && vbHeight > 0) {
        return Size(vbWidth, vbHeight);
      }
    }
  }

  // Fallback to a square canvas when no explicit sizing is present.
  return const Size.square(1024);
}

String? _extractSvgAttribute(String svgContent, String attribute) {
  final regex =
      RegExp('$attribute\\s*=\\s*"([^"]+)"', caseSensitive: false);
  final match = regex.firstMatch(svgContent);
  return match?.group(1)?.trim();
}

double? _parseSvgLength(String? rawValue) {
  if (rawValue == null || rawValue.isEmpty) {
    return null;
  }

  final trimmed = rawValue.trim();
  final valueMatch = RegExp(r'(-?\d*\.?\d+)').firstMatch(trimmed);
  if (valueMatch == null) {
    return null;
  }

  return double.tryParse(valueMatch.group(1)!);
}

class _GestureLayer extends StatelessWidget {
  const _GestureLayer({
    required this.self,
    required this.floor,
    required this.ref,
    required this.imageDimensions,
  });

  final InteractiveImageMixin self;
  final int floor;
  final WidgetRef ref;
  final Size imageDimensions;

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
    final imageState = ref.watch(interactiveImageProvider);
    final notifier = ref.read(interactiveImageProvider.notifier);
    return Positioned.fill(
      child: Listener(
        onPointerMove: (details) {
          if (imageState.isConnecting &&
              imageState.connectingStart?.floor == floor) {
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
  });

  final InteractiveImageMixin self;
  final double pointerSize;
  final int floor;
  final WidgetRef ref;
  final Size imageDimensions;

  Offset _toAbsolute(Offset relativePosition) {
    return Offset(
      relativePosition.dx * imageDimensions.width,
      relativePosition.dy * imageDimensions.height,
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageState = ref.watch(interactiveImageProvider);
    final notifier = ref.read(interactiveImageProvider.notifier);

    final relativeTapPos = imageState.tapPosition!;
    final absoluteTapPos = _toAbsolute(relativeTapPos);

    return Positioned(
      left: absoluteTapPos.dx - pointerSize / 8 * 5 / 2,
      top: absoluteTapPos.dy - pointerSize / 8 * 5 / 2,
      child: GestureDetector(
        onTap: () => notifier.onTapDetected(relativeTapPos),
        onDoubleTap: () {
          if (imageState.tapPosition == null) return;
          final newSData = CachedSData(
            id: const Uuid().v4(),
            name: '新しい要素',
            position: relativeTapPos,
            floor: floor,
            type: imageState.currentType,
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
