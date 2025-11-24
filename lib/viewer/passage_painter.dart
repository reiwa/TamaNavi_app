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

class PassagePainter extends CustomPainter {
  PassagePainter({
    required this.edges,
    required this.controller, required this.viewerSize, required this.imageDimensions, this.previewEdge,
    this.connectingType,
    this.routeSegments = const [],
    this.elevatorLinks = const [],
    this.hideBaseEdges = false,
  }) : super(repaint: controller);

  final List<Edge> edges;
  final Edge? previewEdge;
  final PlaceType? connectingType;
  final TransformationController controller;
  final List<RouteVisualSegment> routeSegments;
  final Size viewerSize;
  final List<ElevatorVerticalLink> elevatorLinks;
  final Size imageDimensions;
  final bool hideBaseEdges;

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
  }

  void _paintRouteSegments(Canvas canvas) {
    final effectiveScale = controller.value.getMaxScaleOnAxis().clamp(
      1.0,
      10.0,
    );
    final chevronPaint = Paint()
      ..color = Colors.redAccent
      ..strokeWidth = 3.6 / effectiveScale
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (final segment in routeSegments) {
      final absoluteSegment = RouteVisualSegment(
        start: _toAbsolute(segment.start),
        end: _toAbsolute(segment.end),
      );
      _drawChevronSequence(
        canvas,
        absoluteSegment,
        chevronPaint,
        effectiveScale,
      );
    }
  }

  void _drawChevronSequence(
    Canvas canvas,
    RouteVisualSegment segment,
    Paint chevronPaint,
    double effectiveScale,
  ) {
    final delta = segment.end - segment.start;
    final length = delta.distance;
    if (length <= 0.0001) return;

    final direction = delta / length;
    final perpendicular = Offset(-direction.dy, direction.dx);
    final spacing = 16.0 / effectiveScale;
    final depth = 12.0 / effectiveScale;
    final halfWidth = 9.0 / effectiveScale;
    final double tailPadding = max(depth * 1.0, 0.0 / effectiveScale);

    final positions = <double>[];
    var walk = spacing * 0.6;
    while (walk < length - tailPadding) {
      positions.add(walk);
      walk += spacing;
    }

    final finalPosition = length - tailPadding;
    if (finalPosition > depth &&
        (positions.isEmpty ||
            (finalPosition - positions.last) > (spacing * 0.4))) {
      positions.add(finalPosition);
    } else if (positions.isEmpty) {
      positions.add(length / 2);
    }

    for (final position in positions) {
      final tip = segment.start + direction * position;
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
    canvas.drawLine(tip, left, paint);
    canvas.drawLine(tip, right, paint);
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
      path.moveTo(dashStart.dx, dashStart.dy);
      path.lineTo(dashEnd.dx, dashEnd.dy);
    }
    return path;
  }

  void _paintElevatorLinks(Canvas canvas) {
    const baseLength = 60;
    final effectiveScale = controller.value.getMaxScaleOnAxis().clamp(
      1.0,
      10.0,
    );
    for (final link in elevatorLinks) {
      final absoluteOrigin = _toAbsolute(link.origin);
      final direction = link.isUpward ? -1.0 : 1.0;
      final arrowLength = baseLength / effectiveScale;
      final endPoint =
          absoluteOrigin + Offset(0, arrowLength * direction);
      final arrowColorBase = link.highlight
          ? Colors.orangeAccent
          : link.color;
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
              fontSize: 10.0 / effectiveScale,
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
    return false;
  }
}
