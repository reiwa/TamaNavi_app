import 'dart:math' as math;
import 'package:flutter/material.dart';

double explosiveEaseIn(double t, {required double period}) {
  if (t == 0) return 0.0;
  if (t == 1) return 1.0;

  const double maxPower = 10.0;
  const double minPower = 2.0;
  const double maxPeriod = 100.0;

  final double clampedPeriod = period.clamp(1.0, maxPeriod);

  final double tLerp = (clampedPeriod - 1.0) / (maxPeriod - 1.0);

  final double power = maxPower + tLerp * (minPower - maxPower);

  return math.pow(t, power).toDouble();
}

double elasticEaseOut(double t, {double amplitude = 1.0, double period = 0.4}) {
  if (t == 0) return 0;
  if (t == 1) return 1;

  final double p = _getSafePeriod(period, 0.4);

  final double s;
  if (amplitude < 1.0) {
    amplitude = 1.0;
    s = p / 4.0;
  } else {
    s = p / (2.0 * math.pi) * math.asin(1.0 / amplitude);
  }

  return (amplitude *
          math.pow(2, -10 * t) *
          math.sin((t - s) * (math.pi * 2.0) / p) +
      1.0);
}

double elasticEaseIn(double t, {double amplitude = 1.0, double period = 0.4}) {
  if (t == 0) return 0;
  if (t == 1) return 1;

  return 1.0 - elasticEaseOut(1.0 - t, amplitude: amplitude, period: period);
}

double cubicBezierInterpolation(double t, List<double> controlPoints) {
  if (controlPoints.length != 4) {
    throw ArgumentError(
      'controlPoints must contain exactly 4 values: [x1, y1, x2, y2]',
    );
  }

  final Cubic curve = Cubic(
    controlPoints[0],
    controlPoints[1],
    controlPoints[2],
    controlPoints[3],
  );
  return curve.transform(t);
}

double _getSafePeriod(double period, [double defaultPeriod = 0.4]) {
  if (period <= 0.0) {
    return defaultPeriod;
  }

  double p = period % 1.0;

  if (p == 0.0 && period >= 1.0) {
    return defaultPeriod;
  }

  return p;
}

class CustomCurve extends Curve {
  final double Function(double) curveFn;

  const CustomCurve(this.curveFn);

  @override
  double transformInternal(double t) => curveFn(t);
}
