import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class TolerantPageScrollPhysics extends PageScrollPhysics {

  const TolerantPageScrollPhysics({
    required this.canScroll,
    this.directionTolerance = pi / 6,
    super.parent,
  });
  final bool Function() canScroll;
  final double directionTolerance;

  @override
  bool shouldAcceptUserOffset(ScrollMetrics position) =>
      canScroll() && super.shouldAcceptUserOffset(position);

  @override
  TolerantPageScrollPhysics applyTo(ScrollPhysics? ancestor) {
    return TolerantPageScrollPhysics(
      canScroll: canScroll,
      directionTolerance: directionTolerance,
      parent: buildParent(ancestor),
    );
  }

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    if (!canScroll()) return 0;
    return super.applyPhysicsToUserOffset(position, offset * 0.9);
  }

  @override
  bool get allowImplicitScrolling =>
      canScroll() && super.allowImplicitScrolling;
}

class CustomScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
  };
}
