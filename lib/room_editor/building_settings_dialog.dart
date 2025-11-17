import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:tamanavi_app/models/building_snapshot.dart';

class BuildingSettings {
  final String buildingName;
  final int floorCount;
  final String imageNamePattern;
  final List<String> tags;

  BuildingSettings({
    required this.buildingName,
    required this.floorCount,
    required this.imageNamePattern,
    required this.tags,
  });
}

class SettingsDialog extends StatefulWidget {
  final String initialBuildingName;
  final int initialFloorCount;
  final String initialImagePattern;
  final List<String> initialTags;

  const SettingsDialog({
    super.key,
    required this.initialBuildingName,
    required this.initialFloorCount,
    required this.initialImagePattern,
    required this.initialTags,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _floorCountController;
  late final TextEditingController _imagePatternController;
  late Set<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialBuildingName);
    _floorCountController = TextEditingController(
      text: widget.initialFloorCount.toString(),
    );
    _imagePatternController = TextEditingController(
      text: widget.initialImagePattern,
    );
    final availableTagSet = kBuildingTagOptions.toSet();
    final normalizedInitialTags = widget.initialTags
        .map((tag) => tag.trim())
        .where((tag) => tag.isNotEmpty)
        .toSet();
    final intersected = normalizedInitialTags.intersection(availableTagSet);
    _selectedTags = intersected.isEmpty ? {'その他'} : intersected;
    if (_selectedTags.isEmpty) {
      _selectedTags = {'その他'};
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _floorCountController.dispose();
    _imagePatternController.dispose();
    super.dispose();
  }

  void _saveSettings() {
    if (_formKey.currentState!.validate()) {
      if (_selectedTags.isEmpty) {
        setState(() {
          _selectedTags = {'その他'};
        });
      }
      final settings = BuildingSettings(
        buildingName: _nameController.text.trim(),
        floorCount: int.parse(_floorCountController.text),
        imageNamePattern: _imagePatternController.text.trim(),
        tags: _sortedSelectedTags(),
      );
      Navigator.pop(context, settings);
    }
  }

  List<String> _sortedSelectedTags() {
    final selectedSet = _selectedTags;
    return [
      for (final tag in kBuildingTagOptions)
        if (selectedSet.contains(tag)) tag,
    ];
  }

  void _toggleTag(String tag, bool selected) {
    setState(() {
      if (selected) {
        if (tag == 'その他') {
          _selectedTags = {'その他'};
        } else {
          _selectedTags
            ..remove('その他')
            ..add(tag);
        }
      } else {
        if (_selectedTags.length == 1 && _selectedTags.contains(tag)) {
          return;
        }
        _selectedTags.remove(tag);
        if (_selectedTags.isEmpty) {
          _selectedTags = {'その他'};
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('建物設定'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '建物名',
                  hintText: '例: 全学講義棠1号館',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '建物名を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _floorCountController,
                decoration: const InputDecoration(labelText: '階層数'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '階層数を入力してください';
                  }
                  final int? count = int.tryParse(value);
                  if (count == null || count <= 0) {
                    return '1以上の数値を入力してください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _imagePatternController,
                decoration: const InputDecoration(
                  labelText: '画像ファイルの識別名',
                  helperText:
                      '例: "my_building"\n→ "my_building_1f.png", "my_building_2f.png"...',
                  helperMaxLines: 3,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return '識別名を入力してください';
                  }
                  if (value.contains(RegExp(r'[\s_]'))) {
                    return 'スペースやアンダースコア(_)は含めないでください';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'カテゴリタグ',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (int i = 0; i < kBuildingTagOptions.length; i++)
                    ChoiceChip(
                        label: Text(kBuildingTagOptions[i]),
                        selected:
                            _selectedTags.contains(kBuildingTagOptions[i]),
                        onSelected: (selected) =>
                            _toggleTag(kBuildingTagOptions[i], selected),
                      ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          child: const Text('キャンセル'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(onPressed: _saveSettings, child: const Text('保存')),
      ],
    );
  }
}
