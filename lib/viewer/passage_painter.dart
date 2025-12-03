import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

class ElevatorVerticalLink {
  const ElevatorVerticalLink({
    required this.origin,
    required this.isUpward,
    required this.color,
    required this.targetFloor,
    this.highlight = false,
    this.message,
  });

  final Offset origin;
  final bool isUpward;
  final Color color;
  final int targetFloor;
  final bool highlight;
  final String? message;
}

class _NavigationEdgePalette {
  const _NavigationEdgePalette._();

  static const Color base = Color(0xFF0E9F6E);
}

class PassagePainter extends CustomPainter {
  PassagePainter({
    required this.edges,
    required this.controller,
    required this.viewerSize,
    required this.imageDimensions,
    this.previewEdge,
    this.connectingType,
    this.routeSegments = const [],
    this.elevatorLinks = const [],
    this.hideBaseEdges = false,
    this.routePulse,
    this.elements = const [],
    this.selectedElement,
    this.labelStyle,
  }) : super(
          repaint: Listenable.merge([
            controller,
            ?routePulse,
          ]),
        );

  final List<Edge> edges;
  final Edge? previewEdge;
  final PlaceType? connectingType;
  final TransformationController controller;
  final List<RouteVisualSegment> routeSegments;
  final Size viewerSize;
  final List<ElevatorVerticalLink> elevatorLinks;
  final Size imageDimensions;
  final bool hideBaseEdges;
  final Animation<double>? routePulse;
  final List<CachedSData> elements;
  final CachedSData? selectedElement;
  final TextStyle? labelStyle;

  Offset _toAbsolute(Offset relative) {
    if (imageDimensions.width == 0 || imageDimensions.height == 0) {
      return Offset.zero;
    }
    return Offset(
      relative.dx * imageDimensions.width,
      relative.dy * imageDimensions.height,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    final scale = controller.value.getMaxScaleOnAxis();

    final baseColor = PlaceType.passage.color;
    final previewColor = (connectingType ?? PlaceType.passage).color;

    final edgePaint = Paint()
      ..color = baseColor.withValues(alpha: 0.8)
      ..strokeWidth = 3.0 / scale.clamp(1.0, 10.0)
      ..style = PaintingStyle.stroke;

    final drawBaseEdges = routeSegments.isEmpty;
    final shouldDrawEdges = !hideBaseEdges && drawBaseEdges;
    if (shouldDrawEdges) {
      for (final edge in edges) {
        canvas.drawLine(
          _toAbsolute(edge.start),
          _toAbsolute(edge.end),
          edgePaint,
        );
      }
    }

    if (routeSegments.isNotEmpty) {
      _paintRouteSegments(canvas);
    }

    if (previewEdge != null) {
      final previewPaint = Paint()
        ..color = previewColor.withValues(alpha: 0.5)
        ..strokeWidth = 2.0 / scale.clamp(1.0, 10.0)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      final dashPath = _dashPath(
        _toAbsolute(previewEdge!.start),
        _toAbsolute(previewEdge!.end),
        5,
        5,
      );
      canvas.drawPath(dashPath, previewPaint);
    }
    if (elevatorLinks.isNotEmpty) {
      _paintElevatorLinks(canvas);
    }
    _paintNodeNames(canvas);
  }

  void _paintNodeNames(Canvas canvas) {
    final effectiveScale = controller.value.getMaxScaleOnAxis().clamp(
      1.0,
      10.0,
    );
    final occupiedRects = <Rect>[];

    if (selectedElement != null) {
      final absolutePos = _toAbsolute(selectedElement!.position);
      final pointerSize = 12 / sqrt(effectiveScale);
      final iconSize = pointerSize * 3.5;
      final textOffset = Offset(0, iconSize * 0.35);

      final rect = _drawLabel(
        canvas,
        selectedElement!.name,
        absolutePos + textOffset,
        effectiveScale,
        isSelected: true,
      );
      occupiedRects.add(rect);
    }

    for (final element in elements) {
      if (element.type != PlaceType.room) continue;
      if (element.id == selectedElement?.id) continue;

      if (element.name.length > effectiveScale * 6) continue;

      final displayName = element.name;
      final absolutePos = _toAbsolute(element.position);

      final textSpan = TextSpan(
        text: displayName,
        style: (labelStyle ?? const TextStyle()).copyWith(
          fontSize: 10.0 / effectiveScale,
          fontWeight: FontWeight.w500,
        ),
      );
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
      )..layout();

      final width = textPainter.width;
      final height = textPainter.height;
      final rect = Rect.fromCenter(
        center: absolutePos,
        width: width,
        height: height,
      );

      var overlaps = false;
      for (final occupied in occupiedRects) {
        if (rect.overlaps(occupied)) {
          overlaps = true;
          break;
        }
      }

      if (!overlaps) {
        _drawLabel(
          canvas,
          displayName,
          absolutePos,
          effectiveScale,
          isSelected: false,
        );
        occupiedRects.add(rect);
      }
    }
  }

  Rect _drawLabel(
    Canvas canvas,
    String text,
    Offset center,
    double scale, {
    required bool isSelected,
  }) {
    final fontSize = (isSelected ? 14.0 : 10.0) / scale;
    final color = isSelected
        ? Colors.black87
        : Colors.black.withValues(alpha: 0.75);
    final fontWeight = isSelected ? FontWeight.bold : FontWeight.w500;

    final style = (labelStyle ?? const TextStyle()).copyWith(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
    );

    final span = TextSpan(text: text, style: style);
    final textPainter = TextPainter(
      text: span,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout();

    final offset = center - Offset(
      textPainter.width / 2,
      textPainter.height / 2,
    );

    final strokeSpan = TextSpan(
      text: text,
      style: style.copyWith(
        foreground: Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0 / scale
          ..color = Colors.white.withValues(alpha: 0.8),
      ),
    );
    TextPainter(
      text: strokeSpan,
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout()
    ..paint(canvas, offset);
    textPainter.paint(canvas, offset);

    return offset & textPainter.size;
  }

  void _paintRouteSegments(Canvas canvas) {
    final effectiveScale = controller.value.getMaxScaleOnAxis().clamp(
      1.0,
      10.0,
    );
    final animationPhase = routePulse?.value ?? 0.0;
    final pulseWave = routePulse == null
        ? 0.0
        : (sin(2 * pi * animationPhase) + 1) / 2;
    final opacityFactor = routePulse == null ? 1.0 : 0.8 + 0.2 * pulseWave;
    final widthFactor = routePulse == null ? 1.0 : 0.96 + 0.04 * pulseWave;

    for (final segment in routeSegments) {
      final baseColor = _routeColorForSegment(segment);
      final pulsedColor = baseColor.withValues(alpha: 
        (baseColor.a * opacityFactor).clamp(0.0, 1.0),
      );
      final segmentPaint = Paint()
        ..color = pulsedColor
        ..strokeWidth =
            _routeStrokeWidth(segment, widthFactor) / effectiveScale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      _drawChevronSequence(
        canvas,
        _toAbsolute(segment.start),
        _toAbsolute(segment.end),
        segmentPaint,
        effectiveScale,
        animationPhase,
      );
    }
  }

  void _drawChevronSequence(
    Canvas canvas,
    Offset start,
    Offset end,
    Paint chevronPaint,
    double effectiveScale,
    double animationPhase,
  ) {
    final delta = end - start;
    final length = delta.distance;
    if (length <= 0.0001) return;

    final direction = delta / length;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final spacing = 20.0 / effectiveScale;
    final depth = 9.0 / effectiveScale;
    final halfWidth = 7.0 / effectiveScale;
    final double tailPadding = max(depth * 0.2, 0);

    final shift = (spacing * animationPhase) % spacing;
    var walk = shift;

    final originalColor = chevronPaint.color;
    final fadeLength = 28.0 / effectiveScale;

    while (walk <= length - tailPadding) {
      var opacity = 1.0;

      if (walk < fadeLength) {
        opacity *= walk / fadeLength;
      }

      if (walk > length - fadeLength) {
        opacity *= (length - walk) / fadeLength;
      }

      opacity = opacity.clamp(0.0, 1.0);

      if (opacity > 0.01) {
        chevronPaint.color = originalColor.withValues(
          alpha: originalColor.a * opacity,
        );

        final tip = start + direction * walk;
        _drawChevron(
          canvas,
          tip,
          direction,
          perpendicular,
          depth,
          halfWidth,
          chevronPaint,
        );
      }

      walk += spacing;
    }
    chevronPaint.color = originalColor;
  }

  Color _routeColorForSegment(RouteVisualSegment segment) {
    return _NavigationEdgePalette.base.withValues(alpha: 0.85);
  }

  double _routeStrokeWidth(RouteVisualSegment segment, double widthFactor) {
    if (segment.touchesEntrance) {
      return 4.4 * widthFactor;
    }
    if (segment.touchesElevator) {
      return 3 * widthFactor;
    }
    return 3.6 * widthFactor;
  }

  void _drawChevron(
    Canvas canvas,
    Offset tip,
    Offset direction,
    Offset perpendicular,
    double depth,
    double halfWidth,
    Paint paint,
  ) {
    final base = tip - direction * depth;
    final left = base + perpendicular * halfWidth;
    final right = base - perpendicular * halfWidth;
    canvas
      ..drawLine(tip, left, paint)
      ..drawLine(tip, right, paint);
  }

  Path _dashPath(Offset start, Offset end, double dashWidth, double dashSpace) {
    return Path()..addPath(
      _generateDashedLine(start, end, dashWidth, dashSpace),
      Offset.zero,
    );
  }

  Path _generateDashedLine(
    Offset start,
    Offset end,
    double dashWidth,
    double dashSpace,
  ) {
    final path = Path();
    final totalLength = (end - start).distance;
    final fullDash = dashWidth + dashSpace;
    final numDashes = (totalLength / fullDash).floor();

    for (var i = 0; i < numDashes; i++) {
      final dashStart = start + (end - start) * (i * fullDash / totalLength);
      final dashEnd =
          start + (end - start) * ((i * fullDash + dashWidth) / totalLength);
      path
        ..moveTo(dashStart.dx, dashStart.dy)
        ..lineTo(dashEnd.dx, dashEnd.dy);
    }
    return path;
  }

  void _paintElevatorLinks(Canvas canvas) {
    const baseLength = 50;
    final effectiveScale = controller.value.getMaxScaleOnAxis().clamp(
      1.0,
      10.0,
    );
    for (final link in elevatorLinks) {
      final absoluteOrigin = _toAbsolute(link.origin);
      final direction = link.isUpward ? -1.0 : 1.0;
      final arrowLength = baseLength / effectiveScale;
      final endPoint = absoluteOrigin + Offset(0, arrowLength * direction);
      final arrowColorBase = link.highlight ? Colors.orangeAccent : link.color;
      final shaftPaint = Paint()
        ..color = arrowColorBase.withValues(alpha: link.highlight ? 1.0 : 0.4)
        ..strokeWidth = 3.2 / effectiveScale
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      canvas.drawLine(absoluteOrigin, endPoint, shaftPaint);

      final headSize = 6.0 / effectiveScale;
      final headPath = Path()
        ..moveTo(endPoint.dx - headSize, endPoint.dy)
        ..lineTo(endPoint.dx + headSize, endPoint.dy)
        ..lineTo(endPoint.dx, endPoint.dy + headSize * direction * 1.5)
        ..close();

      canvas.drawPath(
        headPath,
        Paint()
          ..color = shaftPaint.color
          ..style = PaintingStyle.fill,
      );

      if (link.message != null && link.message!.isNotEmpty) {
        final textPainter = TextPainter(
          text: TextSpan(
            text: link.message,
            style: TextStyle(
              color: link.highlight ? shaftPaint.color : Colors.black87,
              fontSize: 12.0 / effectiveScale,
              fontWeight: link.highlight ? FontWeight.bold : FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final labelOffset =
            endPoint +
            Offset(
              6.0 / effectiveScale,
              direction == -1.0 ? -textPainter.height : headSize * 0.5,
            );

        final strokeSpan = TextSpan(
          text: link.message,
          style: TextStyle(
            fontSize: 12.0 / effectiveScale,
            fontWeight: link.highlight ? FontWeight.bold : FontWeight.w600,
            foreground: Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 2.0 / effectiveScale
              ..color = Colors.white.withValues(alpha: 0.8),
          ),
        );
        TextPainter(
          text: strokeSpan,
          textDirection: TextDirection.ltr,
        )..layout()
        ..paint(canvas, labelOffset);
        textPainter.paint(canvas, labelOffset);
      }
    }
  }

  @override
  bool shouldRepaint(covariant PassagePainter old) {
    if (old.imageDimensions != imageDimensions) return true;
    if (old.controller != controller) return true;
    if (old.viewerSize != viewerSize) return true;
    if (old.routeSegments != routeSegments) return true;
    if (old.connectingType != connectingType) return true;
    if ((old.previewEdge?.start != previewEdge?.start) ||
        (old.previewEdge?.end != previewEdge?.end)) {
      return true;
    }
    if (old.edges.length != edges.length) return true;
    for (var i = 0; i < edges.length; i++) {
      if (old.edges[i].start != edges[i].start ||
          old.edges[i].end != edges[i].end) {
        return true;
      }
    }
    if (old.elevatorLinks.length != elevatorLinks.length) return true;
    for (var i = 0; i < elevatorLinks.length; i++) {
      final oldLink = old.elevatorLinks[i];
      final newLink = elevatorLinks[i];
      if (oldLink.origin != newLink.origin ||
          oldLink.isUpward != newLink.isUpward ||
          oldLink.targetFloor != newLink.targetFloor ||
          oldLink.highlight != newLink.highlight ||
          oldLink.message != newLink.message) {
        return true;
      }
    }
    if (old.routeSegments.length != routeSegments.length) return true;
    for (var i = 0; i < routeSegments.length; i++) {
      if (old.routeSegments[i].start != routeSegments[i].start ||
          old.routeSegments[i].end != routeSegments[i].end) {
        return true;
      }
    }
    if (old.hideBaseEdges != hideBaseEdges) return true;
    if (old.routePulse != routePulse) return true;
    return false;
  }
}
