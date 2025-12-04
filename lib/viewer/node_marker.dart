import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';

class NodeMarker extends StatefulWidget {
  const NodeMarker({
    required this.data,
    required this.isSelected,
    required this.pointerSize,
    required this.color,
    required this.enableDrag,
    required this.isConnecting,
    required this.onTap,
    required this.onDragStart,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.imageDimensions,
    super.key,
  });

  final CachedSData data;
  final bool isSelected;
  final double pointerSize;
  final Color color;
  final bool enableDrag;
  final bool isConnecting;
  final VoidCallback onTap;
  final VoidCallback onDragStart;
  final ValueChanged<Offset> onDragUpdate;
  final ValueChanged<Offset> onDragEnd;
  final Size imageDimensions;

  @override
  State<NodeMarker> createState() => _NodeMarkerState();
}

class _NodeMarkerState extends State<NodeMarker> {
  Offset? _dragOverride;
  bool _isDragging = false;

  bool get _canDrag =>
      widget.enableDrag && widget.isSelected && !widget.isConnecting;

  double get _baseSize => widget.pointerSize;
  double get _selectedSize => widget.pointerSize / 8 * 10;

  Offset get _effectiveRelativePosition =>
      _dragOverride ?? widget.data.position;

  double get _effectiveSize => widget.isSelected ? _selectedSize : _baseSize;

  Offset _toAbsolute(Offset relative) {
    return Offset(
      relative.dx * widget.imageDimensions.width,
      relative.dy * widget.imageDimensions.height,
    );
  }

  @override
  void didUpdateWidget(covariant NodeMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.isSelected && oldWidget.isSelected ||
        widget.data.id != oldWidget.data.id) {
      _dragOverride = null;
      _isDragging = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final relativePosition = _effectiveRelativePosition;
    final absolutePosition = _toAbsolute(relativePosition);
    final size = _effectiveSize;

    return Positioned(
      left: absolutePosition.dx - size / 2,
      top: absolutePosition.dy - size / 2,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: widget.onTap,
        onScaleStart: (_) {
          if (!_canDrag) return;
          _isDragging = true;
          _dragOverride = widget.data.position;
          widget.onDragStart();
          setState(() {});
        },
        onScaleUpdate: (details) {
          if (!_canDrag || !_isDragging) return;
          if ((details.scale - 1.0).abs() > 0.02) return;

          final relativeDelta = Offset(
            details.focalPointDelta.dx / widget.imageDimensions.width,
            details.focalPointDelta.dy / widget.imageDimensions.height,
          );

          final current = _dragOverride ?? widget.data.position;
          final nextRelative = Offset(
            (current.dx + relativeDelta.dx).clamp(0.0, 1.0),
            (current.dy + relativeDelta.dy).clamp(0.0, 1.0),
          );

          _dragOverride = nextRelative;
          widget.onDragUpdate(nextRelative);
          setState(() {});
        },
        onScaleEnd: (_) {
          if (!_canDrag || !_isDragging) return;
          final result = _dragOverride ?? widget.data.position;
          _isDragging = false;
          _dragOverride = null;
          widget.onDragEnd(result);
          setState(() {});
        },
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: widget.isSelected ? Colors.orange : widget.color,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}

List<Widget> buildNodeMarkers({
  required InteractiveImageMixin self,
  required BuildContext context,
  required int floor,
  required double pointerSize,
  required List<CachedSData> relevantElements,
  required Set<String> routeNodeIds,
  required CachedSData? selectedElement,
  required bool isConnecting,
  required bool isDragging,
  required WidgetRef ref,
  required Size imageDimensions,
}) {
  final notifier = ref.read(interactiveImageProvider.notifier);
  final hasActiveRoute = routeNodeIds.isNotEmpty;
  final isFinderMode = self.widget.mode == CustomViewMode.finder;
  final colorScheme = Theme.of(context).colorScheme;

  final markers = <Widget>[];
  for (final sData in relevantElements) {
    final isSelected = selectedElement?.id == sData.id;
    final isRouteNode = routeNodeIds.contains(sData.id);

    final entranceOnRoute =
        isFinderMode && isRouteNode && sData.type == PlaceType.entrance;
    final elevatorOnRoute =
        isFinderMode && isRouteNode && sData.type == PlaceType.elevator;

    final shouldHideInFinder =
        isFinderMode && !isSelected && !entranceOnRoute && !elevatorOnRoute;
    if (shouldHideInFinder) {
      continue;
    }

    if (hasActiveRoute &&
        isRouteNode &&
        sData.type == PlaceType.passage &&
        !isSelected) {
      continue;
    }

    final baseColor = sData.type.color;
    final shouldDim =
        !isFinderMode && hasActiveRoute && !isRouteNode && !isSelected;
    var color = shouldDim
        ? _dimColorForType(baseColor, sData.type)
        : baseColor;

    if (isFinderMode && !isSelected) {
      if (entranceOnRoute) {
        color = colorScheme.secondary.withValues(alpha: 0.95);
      } else if (elevatorOnRoute) {
        color = colorScheme.primary.withValues(alpha: 0.4);
      }
    }

    markers.add(
      NodeMarker(
        key: ValueKey('${floor}_${sData.id}'),
        data: isSelected && selectedElement != null
            ? selectedElement
            : sData,
        isSelected: isSelected,
        pointerSize: pointerSize,
        color: color,
        enableDrag: self.enableElementDrag,
        isConnecting: isConnecting,
        imageDimensions: imageDimensions,
        onTap: () => self.handleMarkerTap(
          sData,
          wasSelected: isSelected,
        ),
        onDragStart: () {
          if (!isDragging) {
            notifier.setDragging(isDragging: true);
          }
        },
        onDragUpdate: (_) {},
        onDragEnd: (position) => self.handleMarkerDragEnd(
          position,
          wasSelected: isSelected,
        ),
      ),
    );
  }

  return markers;
}

Color _dimColorForType(Color baseColor, PlaceType type) {
  const defaultAlpha = 0.5;
  const subduedPassageAlpha = 0.25;

  final alpha = (type == PlaceType.passage || type == PlaceType.elevator)
      ? subduedPassageAlpha
      : defaultAlpha;

  return baseColor.withValues(alpha: alpha);
}
