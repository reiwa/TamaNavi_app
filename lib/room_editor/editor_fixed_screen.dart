import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

class PlaceTypeSelector extends StatelessWidget {
  const PlaceTypeSelector({
    required this.currentType, required this.onTypeSelected, super.key,
  });

  final PlaceType currentType;
  final ValueChanged<PlaceType> onTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 4,
      children: PlaceType.values.map((type) {
        final isSelected = currentType == type;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? type.color : null,
            foregroundColor: isSelected ? Colors.white : null,
          ),
          onPressed: () => onTypeSelected(type),
          child: Text(type.label),
        );
      }).toList(),
    );
  }
}

class EditorCoordinateInputs extends StatelessWidget {
  const EditorCoordinateInputs({
    required this.nameController, required this.xController, required this.yController, super.key,
  });

  final TextEditingController nameController;
  final TextEditingController xController;
  final TextEditingController yController;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: 3,
          child: TextField(
            controller: nameController,
            decoration: const InputDecoration(labelText: '名前', isDense: true),
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: xController,
            decoration: const InputDecoration(labelText: 'X', isDense: true),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          flex: 2,
          child: TextField(
            controller: yController,
            decoration: const InputDecoration(labelText: 'Y', isDense: true),
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 14),
          ),
        ),
      ],
    );
  }
}

class EditorIdleScreen extends StatelessWidget {
  const EditorIdleScreen({required this.onRebuildPressed, super.key});

  final VoidCallback onRebuildPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text(
            '画像をタップして座標を取得\n上下スワイプで階層移動',
            style: TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onRebuildPressed,
                child: const Text('部屋と廊下を接続'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
