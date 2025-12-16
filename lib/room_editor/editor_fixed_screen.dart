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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      runSpacing: 8,
      children: PlaceType.values.map((type) {
        final isSelected = currentType == type;
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            minimumSize: const Size(0, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            elevation: isSelected ? 2 : 0,
            backgroundColor: isSelected ? type.color : colorScheme.surface,
            foregroundColor: isSelected ? Colors.white : colorScheme.onSurface,
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
      height: 110,
      width: double.infinity,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              '画像をタップして座標を取得\n上下スワイプで階層移動',
              style: TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size.fromHeight(32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onRebuildPressed,
                  child: const Text('部屋と廊下を接続'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
