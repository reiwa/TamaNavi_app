import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:tamanavi_app/room_editor/room_finder_app_editor.dart';
import 'package:tamanavi_app/room_finder/room_finder_app.dart';
import 'package:tamanavi_app/viewer/interactions/editor_interaction_delegate.dart';
import 'package:tamanavi_app/viewer/interactions/finder_interaction_delegate.dart';
import 'package:tamanavi_app/viewer/interactions/interaction_delegate.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'firebase_options.dart';

import 'splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class FinderWithSplash extends ConsumerStatefulWidget {
  const FinderWithSplash({super.key, this.initialIntent});

  final FinderLaunchIntent? initialIntent;

  @override
  ConsumerState<FinderWithSplash> createState() => _FinderWithSplashState();
}

class _FinderWithSplashState extends ConsumerState<FinderWithSplash> {
  bool _isDataLoaded = false;
  bool _isAnimationDone = false;
  bool _showSplash = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.endOfFrame.then((_) {
      _startDataLoading();
    });
  }

  void _startDataLoading() {
    if (!mounted) return;
    setState(() {
      _isDataLoaded = true;
    });
    _checkAndTransition();
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _checkAndTransition() {
    if (_isDataLoaded && _isAnimationDone && _showSplash) {
      if (mounted) {
        setState(() {
          _showSplash = false;
        });
      }
    }
  }

  void _onAnimationComplete() {
    if (mounted) {
      setState(() {
        _isAnimationDone = true;
      });
      _checkAndTransition();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Offstage(
          offstage: _showSplash,
          child: _isDataLoaded
              ? FinderView(initialIntent: widget.initialIntent)
              : const SizedBox.shrink(),
        ),
        AnimatedOpacity(
          opacity: _showSplash ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 300),
          child: IgnorePointer(
            ignoring: !_showSplash,
            child: Container(
              color: Theme.of(context).scaffoldBackgroundColor,
              alignment: Alignment.center,
              child: RepaintBoundary(
                child: LogoSplashAnimation(
                  onAnimationComplete: _onAnimationComplete,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

void startSvgLoading() async {
  await preloadSvgs([
    'assets/images/ball.svg',
    'assets/images/玉.svg',
    'assets/images/ナ.svg',
    'assets/images/ビ.svg',
  ]);
}

void startFontLoading() async {
  final loader = FontLoader('RoundedMgenPlus')
    ..addFont(rootBundle.load('assets/fonts/rounded-x-mgenplus-2c-black.ttf'));
  await loader.load();
  const textStyle = TextStyle(fontFamily: 'RoundedMgenPlus');
  TextPainter(
    text: const TextSpan(text: ' 日本語 ', style: textStyle),
    maxLines: 1,
    textDirection: TextDirection.ltr,
  );
}

class RoomFinder extends StatefulWidget {
  const RoomFinder({
    super.key,
    this.navigateTo,
    this.navigateFrom,
    this.isDarkMode,
  });

  final String? navigateTo;
  final String? navigateFrom;
  final bool? isDarkMode;

  @override
  State<RoomFinder> createState() => _RoomFinderState();
}

enum CustomViewType { editor, finder }

class _RoomFinderState extends State<RoomFinder> {
  CustomViewType _mode = CustomViewType.finder;
  FinderLaunchIntent? _initialIntent;

  @override
  void initState() {
    super.initState();
    _initialIntent = FinderLaunchIntent.maybeFrom(
      navigateTo: widget.navigateTo,
      navigateFrom: widget.navigateFrom,
    );
  }

  @override
  void didUpdateWidget(covariant RoomFinder oldWidget) {
    super.didUpdateWidget(oldWidget);
    final hasToChanged = widget.navigateTo != oldWidget.navigateTo;
    final hasFromChanged = widget.navigateFrom != oldWidget.navigateFrom;
    if (hasToChanged || hasFromChanged) {
      final nextIntent = FinderLaunchIntent.maybeFrom(
        navigateTo: widget.navigateTo,
        navigateFrom: widget.navigateFrom,
      );
      if (nextIntent != _initialIntent) {
        setState(() {
          _initialIntent = nextIntent;
        });
      } else {
        _initialIntent = nextIntent;
      }
    }
  }

  ProviderScope _buildScopedView() {
    final delegateOverride = interactionDelegateProvider.overrideWith(
      (ref) => _mode == CustomViewType.editor
          ? EditorInteractionDelegate(ref: ref)
          : FinderInteractionDelegate(ref: ref),
    );

    final view = _mode == CustomViewType.editor
        ? const EditorView()
        : FinderWithSplash(initialIntent: _initialIntent);

    return ProviderScope(
      key: ValueKey(_mode),
      overrides: [
        delegateOverride,
        interactiveImageProvider.overrideWith(
          (ref) => InteractiveImageNotifier(
            ref: ref,
            delegate: ref.watch(interactionDelegateProvider),
          ),
        ),
      ],
      child: view,
    );
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily: 'RoundedMgenPlus',
        textTheme: ThemeData.light().textTheme.apply(
          fontFamily: 'RoundedMgenPlus',
        ),
      ),
      home: Scaffold(
        body: Center(
          child: Stack(
            children: [
              LayoutBuilder(
                builder: (context, constraints) => Container(
                  width: constraints.maxWidth,
                  height: constraints.maxHeight,
                  color: Colors.grey[50],
                  child: _buildScopedView(),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 126,
                child: PopupMenuButton<CustomViewType>(
                  onSelected: (type) {
                    setState(() {
                      _mode = type;
                    });
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: CustomViewType.editor,
                      child: Text('Editor'),
                    ),
                    PopupMenuItem(
                      value: CustomViewType.finder,
                      child: Text('Finder'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isFinderVisible = false;

  @override
  void initState() {
    super.initState();
    startSvgLoading();
    startFontLoading();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hello Flutter',
      //showPerformanceOverlay: true,
      home: Scaffold(
        body: Center(
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  const Text('Hello World!', style: TextStyle(fontSize: 24)),
                  ElevatedButton(
                    child: const Text('RoomFinder'),
                    onPressed: () {
                      setState(() {
                        _isFinderVisible = true;
                      });
                    },
                  ),
                ],
              ),
              _isFinderVisible ? const RoomFinder() : Container(),
            ],
          ),
        ),
      ),
    );
  }
}
