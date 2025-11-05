import 'package:flutter/material.dart';
import 'package:test_project/room_finder/room_finder_app.dart';
import 'package:test_project/room_editor/room_finder_app_editor.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const ProviderScope(child: MyApp()));
}

class RoomFinder extends StatefulWidget {
  const RoomFinder({super.key});

  @override
  State<RoomFinder> createState() => _RoomFinderState();
}

enum CustomViewType { editor, finder }

class _RoomFinderState extends State<RoomFinder> {
  Widget currentView = const FinderView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) => Container(
                width: constraints.maxWidth,
                height: constraints.maxHeight,
                color: Colors.grey[50],
                child: currentView,
              ),
            ),
            Positioned(
              bottom: 0,
              right: 78,
              child: PopupMenuButton<CustomViewType>(
                onSelected: (type) {
                  setState(() {
                    currentView = type == CustomViewType.editor
                        ? const EditorView()
                        : const FinderView();
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
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isMessageVisible = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      //showPerformanceOverlay: true,
      title: 'Hello Flutter',
      home: Scaffold(
        appBar: AppBar(title: const Text('Hello Flutter')),
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
                        _isMessageVisible = true;
                      });
                    },
                  ),
                ],
              ),

              _isMessageVisible ? const RoomFinder() : Container(),
            ],
          ),
        ),
      ),
    );
  }
}