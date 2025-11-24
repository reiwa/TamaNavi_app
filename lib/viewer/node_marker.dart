import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';

class NodeMarker extends StatefulWidget {
  const NodeMarker({
    required this.data, required this.isSelected, required this.pointerSize, required this.color, required this.enableDrag, required this.isConnecting, required this.onTap, required this.onDragStart, required this.onDragUpdate, required this.onDragEnd, required this.imageDimensions, super.key,
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
          // Allow slight noise in the scale value while dragging.
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
  required WidgetRef ref,
  required Size imageDimensions,
}) {
  final imageState = ref.watch(interactiveImageProvider);
  final notifier = ref.read(interactiveImageProvider.notifier);
  final hasActiveRoute = routeNodeIds.isNotEmpty;

  final markers = <Widget>[];
  for (final sData in relevantElements) {
    final isSelected = imageState.selectedElement?.id == sData.id;
    final isRouteNode = routeNodeIds.contains(sData.id);

    if (hasActiveRoute &&
        isRouteNode &&
        sData.type == PlaceType.passage &&
        !isSelected) {
      continue;
    }

    final baseColor = sData.type.color;
    final shouldDim = hasActiveRoute && !isRouteNode && !isSelected;
    final color = shouldDim
        ? _dimColorForType(baseColor, sData.type)
        : baseColor;

    markers.add(
      NodeMarker(
        key: ValueKey('${floor}_${sData.id}'),
        data: isSelected && imageState.selectedElement != null
            ? imageState.selectedElement!
            : sData,
        isSelected: isSelected,
        pointerSize: pointerSize,
        color: color,
        enableDrag: self.enableElementDrag,
        isConnecting: imageState.isConnecting,
        imageDimensions: imageDimensions,
        onTap: () => self.handleMarkerTap(sData, isSelected),
        onDragStart: () {
          if (!imageState.isDragging) {
            notifier.setDragging(true);
          }
        },
        onDragUpdate: (_) {},
        onDragEnd: (position) => self.handleMarkerDragEnd(position, isSelected),
      ),
    );
  }

  return markers;
}

Color _dimColorForType(Color baseColor, PlaceType type) {
  const defaultAlpha = 0.5;
  const subduedPassageAlpha = 0.25;

  var alpha = defaultAlpha;
  switch (type) {
    case PlaceType.passage:
    case PlaceType.elevator:
      alpha = subduedPassageAlpha;
    default:
      alpha = defaultAlpha;
  }

  return baseColor.withValues(alpha: alpha);
}
