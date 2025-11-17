import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:tamanavi_app/utility/animation_math.dart';

Future<void> preloadSvgs(List<String> assetPaths) async {
  final futures = <Future>[];
  for (final path in assetPaths) {
    final loader = SvgAssetLoader(path);

    futures.add(
      svg.cache.putIfAbsent(loader.cacheKey(null), () async {
        try {
          final ByteData data = await loader.loadBytes(null);
          return data;
        } catch (e) {
          debugPrint('Failed to preload SVG $path: $e');
          return ByteData(0);
        }
      }),
    );
  }
  await Future.wait(futures);
}

class LogoSplashAnimation extends StatefulWidget {
  final VoidCallback onAnimationComplete;

  const LogoSplashAnimation({super.key, required this.onAnimationComplete});

  @override
  State<LogoSplashAnimation> createState() => _LogoSplashAnimationState();
}

class _LogoSplashAnimationState extends State<LogoSplashAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  late Animation<double> _ballScaleX;
  late Animation<double> _ballScaleY;

  late Animation<double> _tamaScaleX;
  late Animation<double> _tamaScaleY;

  late Animation<double> _naOpacity;
  late Animation<double> _naScaleX;
  late Animation<double> _naScaleY;

  late Animation<double> _biOpacity;
  late Animation<double> _biScaleX;
  late Animation<double> _biScaleY;

  static const double _fps = 60.0;
  static const double _totalFrames = 77.0;
  static final int _animationDurationMs = (_totalFrames / _fps * 1000).round();

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: _animationDurationMs),
    );

    _ballScaleX = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.51, end: 0.46).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 100.0)),
          ),
        ),
        weight: 37.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.46, end: 0.51).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1000.0)),
          ),
        ),
        weight: 8.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.51),
        weight: _totalFrames - 45.0,
      ),
    ]).animate(_controller);

    _ballScaleY = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.51, end: 0.0).chain(
          CurveTween(
            curve: CustomCurve(
              (t) => elasticEaseIn(t, amplitude: 1, period: 8),
            ),
          ),
        ),
        weight: 45.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.0),
        weight: _totalFrames - 45.0,
      ),
    ]).animate(_controller);

    _tamaScaleX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.40), weight: 44.0),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.40,
          end: 0.50,
        ).chain(CurveTween(curve: const Cubic(0.3, 0.0, 0.5, 1.0))),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.50),
        weight: _totalFrames - 59.0,
      ),
    ]).animate(_controller);

    _tamaScaleY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.0), weight: 44.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 0.50).chain(
          CurveTween(
            curve: CustomCurve(
              (t) => elasticEaseOut(t, amplitude: 1, period: 1),
            ),
          ),
        ),
        weight: 15.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.50),
        weight: _totalFrames - 59.0,
      ),
    ]).animate(_controller);

    _naOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1.0)),
          ),
        ),
        weight: 61.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: _totalFrames - 61.0,
      ),
    ]).animate(_controller);

    _naScaleX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.40), weight: 52.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.40, end: 0.38).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1000.0)),
          ),
        ),
        weight: 9.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.38,
          end: 0.40,
        ).chain(CurveTween(curve: const Cubic(0.1, 0.0, 0.7, 1.0))),
        weight: 9.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.40),
        weight: _totalFrames - 70.0,
      ),
    ]).animate(_controller);

    _naScaleY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.40), weight: 52.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.40, end: 0.50).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1000.0)),
          ),
        ),
        weight: 9.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.50,
          end: 0.40,
        ).chain(CurveTween(curve: const Cubic(0.1, 0.0, 0.7, 1.0))),
        weight: 9.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(0.40),
        weight: _totalFrames - 70.0,
      ),
    ]).animate(_controller);

    _biOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.0).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1.0)),
          ),
        ),
        weight: 68.0,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: _totalFrames - 68.0,
      ),
    ]).animate(_controller);

    _biScaleX = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.40), weight: 59.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.40, end: 0.38).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1000.0)),
          ),
        ),
        weight: 9.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.38,
          end: 0.40,
        ).chain(CurveTween(curve: const Cubic(0.1, 0.0, 0.7, 1.0))),
        weight: 9.0,
      ),
    ]).animate(_controller);

    _biScaleY = TweenSequence<double>([
      TweenSequenceItem(tween: ConstantTween<double>(0.40), weight: 59.0),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.40, end: 0.50).chain(
          CurveTween(
            curve: CustomCurve((t) => explosiveEaseIn(t, period: 1000.0)),
          ),
        ),
        weight: 9.0,
      ),
      TweenSequenceItem(
        tween: Tween<double>(
          begin: 0.50,
          end: 0.40,
        ).chain(CurveTween(curve: const Cubic(0.1, 0.0, 0.7, 1.0))),
        weight: 9.0,
      ),
    ]).animate(_controller);

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete();
      }
    });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Transform.translate(
        offset: const Offset(0, -60),
        child: SizedBox(
          width: 500,
          height: 500,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  Transform.translate(
                    offset: const Offset(-95.0, 63.0),
                    child: Transform.scale(
                      scaleX: _ballScaleX.value * 3.8,
                      scaleY: _ballScaleY.value * 3.8,
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset('assets/images/ball.svg'),
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(-95.0, 52.5),
                    child: Transform.scale(
                      scaleX: _tamaScaleX.value * 4.0,
                      scaleY: _tamaScaleY.value * 4.0,
                      alignment: Alignment.bottomCenter,
                      child: SvgPicture.asset('assets/images/玉.svg'),
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(23.0, 48.5),
                    child: Opacity(
                      opacity: _naOpacity.value,
                      child: Transform.scale(
                        scaleX: _naScaleX.value * 3.8,
                        scaleY: _naScaleY.value * 3.8,
                        alignment: Alignment.bottomCenter,
                        child: SvgPicture.asset('assets/images/ナ.svg'),
                      ),
                    ),
                  ),

                  Transform.translate(
                    offset: const Offset(121.5, 48.5),
                    child: Opacity(
                      opacity: _biOpacity.value,
                      child: Transform.scale(
                        scaleX: _biScaleX.value * 3.8,
                        scaleY: _biScaleY.value * 3.8,
                        alignment: Alignment.bottomCenter,
                        child: SvgPicture.asset('assets/images/ビ.svg'),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
