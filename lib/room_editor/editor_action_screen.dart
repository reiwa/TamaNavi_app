import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

import 'package:tamanavi_app/room_editor/editor_fixed_screen.dart';

class EditorActionScreen extends StatelessWidget {

  const EditorActionScreen({
    required this.isConnecting, required this.selectedElement, required this.nameController, required this.xController, required this.yController, required this.onAdd, required this.onDelete, required this.onToggleConnect, super.key,
  });
  final bool isConnecting;
  final CachedSData? selectedElement;
  final TextEditingController nameController;
  final TextEditingController xController;
  final TextEditingController yController;
  final VoidCallback onAdd;
  final Future<void> Function() onDelete;
  final VoidCallback onToggleConnect;

  @override
  Widget build(BuildContext context) {
    final element = selectedElement;

    return SizedBox(
      height: 110,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isConnecting) ...[
              EditorCoordinateInputs(
                nameController: nameController,
                xController: xController,
                yController: yController,
              ),
              const SizedBox(height: 8),
            ] else ...[
              const Text(
                '接続モード: 接続先のノードをタップ',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: Row(
                children: [
                  if (element == null && !isConnecting)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onAdd,
                        child: const Text('追加する!'),
                      ),
                    ),
                  if (element != null) ...[
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                        ),
                        onPressed: onDelete,
                        child: const Text(
                          '削除する!',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                    if (element.type.isGraphNode) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: onToggleConnect,
                          child: const Text('接続する!'),
                        ),
                      ),
                    ],
                  ],
                  if (isConnecting)
                    Expanded(
                      child: ElevatedButton(
                        onPressed: onToggleConnect,
                        child: const Text('接続しない!'),
                      ),
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
