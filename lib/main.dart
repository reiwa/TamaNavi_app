import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  Widget currentView = const EditorView();

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
                        //uploadBuildingsFromJson();
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

//jsonアップロード deprecated
Future<void> uploadBuildingsFromJson() async {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  try {
    final String jsonString = await rootBundle.loadString(
      'assets/data/buildings.json',
    );
    final Map<String, dynamic> data = json.decode(jsonString);

    final List<dynamic>? buildings = data['buildings'];
    if (buildings == null || buildings.isEmpty) {
      debugPrint('JSON内にbuildingsリストが見つからないか、空です。');
      return;
    }

    final WriteBatch batch = _firestore.batch();
    int buildingCount = 0;
    int elementCount = 0;

    for (final buildingData in buildings) {
      if (buildingData is! Map<String, dynamic>) continue;

      final String? buildingName = buildingData['building_name'];
      if (buildingName == null || buildingName.isEmpty) {
        debugPrint('building nameがないためスキップします。');
        continue;
      }

      final buildingDocRef = _firestore
          .collection('buildings')
          .doc(buildingName);

      final List<dynamic>? edgesList = buildingData['edges'];
      final Map<String, List<String>> edgesMap = <String, List<String>>{};
      if (edgesList != null) {
        for (final edge in edgesList) {
          if (edge is List && edge.length == 2) {
            final String id1 = edge[0].toString();
            final String id2 = edge[1].toString();
            edgesMap.putIfAbsent(id1, () => []).add(id2);
            edgesMap.putIfAbsent(id2, () => []).add(id1);
          }
        }
      }

      final Map<String, dynamic> buildingDocData = {
        'building_name': buildingData['building_name'],
        'floor_count': buildingData['floor_count'],
        'image_pattern': buildingData['image_pattern'],
        'edges_adjacency_list': edgesMap,
      };

      batch.set(buildingDocRef, buildingDocData);
      buildingCount++;

      final List<dynamic>? elementsList = buildingData['elements'];
      if (elementsList != null) {
        for (final elementData in elementsList) {
          if (elementData is! Map<String, dynamic>) continue;

          final String? elementId = elementData['id'];
          if (elementId == null || elementId.isEmpty) {
            debugPrint('Element IDがないためスキップします。');
            continue;
          }

          final elementDocRef = buildingDocRef
              .collection('elements')
              .doc(elementId);

          elementData.remove('id');

          batch.set(elementDocRef, elementData);
          elementCount++;
        }
      }
    }

    if (buildingCount > 0) {
      await batch.commit();
      debugPrint('成功: $buildingCount 件と $elementCount 件をアップロードしました。');
    } else {
      debugPrint('アップロードするビルディングデータがありませんでした。');
    }
  } catch (e) {
    debugPrint('JSONデータのアップロード中にエラーが発生しました: $e');
  }
}
