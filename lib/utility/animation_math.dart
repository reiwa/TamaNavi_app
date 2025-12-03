import 'dart:math' as math;
import 'package:flutter/material.dart';

double explosiveEaseIn(double t, {required double period}) {
  if (t == 0) return 0;
  if (t == 1) return 1;

  const maxPower = 10;
  const minPower = 2;
  const maxPeriod = 100;

  final clampedPeriod = period.clamp(1.0, maxPeriod);

  final tLerp = (clampedPeriod - 1.0) / (maxPeriod - 1.0);

  final power = maxPower + tLerp * (minPower - maxPower);

  return math.pow(t, power).toDouble();
}

double elasticEaseOut(double t, {double amplitude = 1.0, double period = 0.4}) {
  if (t == 0) return 0;
  if (t == 1) return 1;

  final p = _getSafePeriod(period);

  final double s;
  final double effectiveAmplitude;
  if (amplitude < 1.0) {
    effectiveAmplitude = 1.0;
    s = p / 4.0;
  } else {
    effectiveAmplitude = amplitude;
    s = p / (2.0 * math.pi) * math.asin(1.0 / amplitude);
  }

  return effectiveAmplitude *
          math.pow(2, -10 * t) *
          math.sin((t - s) * (math.pi * 2.0) / p) +
      1.0;
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

  final curve = Cubic(
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

  final p = period % 1.0;

  if (p == 0.0 && period >= 1.0) {
    return defaultPeriod;
  }

  return p;
}

class CustomCurve extends Curve {

  const CustomCurve(this.curveFn);
  final double Function(double) curveFn;

  @override
  double transformInternal(double t) => curveFn(t);
}
