import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

import 'editor_fixed_screen.dart';

class EditorActionScreen extends StatelessWidget {
  final bool isConnecting;
  final CachedSData? selectedElement;
  final TextEditingController nameController;
  final TextEditingController xController;
  final TextEditingController yController;
  final VoidCallback onAdd;
  final Future<void> Function() onDelete;
  final VoidCallback onToggleConnect;

  const EditorActionScreen({
    super.key,
    required this.isConnecting,
    required this.selectedElement,
    required this.nameController,
    required this.xController,
    required this.yController,
    required this.onAdd,
    required this.onDelete,
    required this.onToggleConnect,
  });

  @override
  Widget build(BuildContext context) {
    final element = selectedElement;

    return SizedBox(
      height: 78,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
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
                        child: const Text(
                          '削除する!',
                          style: TextStyle(color: Colors.white),
                        ),
                        onPressed: () => onDelete(),
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
