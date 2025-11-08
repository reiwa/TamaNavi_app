import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/utility/platform_utils.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';
import 'package:tamanavi_app/viewer/interactive_image_state.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/viewer/room_finder_viewer.dart';

import 'building_settings_dialog.dart';
import 'editor_fixed_screen.dart';
import 'editor_action_screen.dart';

class EditorView extends CustomView {
  const EditorView({super.key}) : super(mode: CustomViewMode.editor);

  @override
  ConsumerState<EditorView> createState() => _EditorViewState();
}

class _EditorViewState extends ConsumerState<EditorView>
    with InteractiveImageMixin<EditorView>
    implements EditorControllerHost {
  final _nameController = TextEditingController();
  final _xController = TextEditingController();
  final _yController = TextEditingController();

  @override
  TextEditingController get nameController => _nameController;

  @override
  TextEditingController get xController => _xController;

  @override
  TextEditingController get yController => _yController;

  Future<void> _handleUploadPressed() async {
    if (!mounted) return;

    final activeSnapshot = ref.read(activeBuildingProvider);
    final notifier = ref.read(activeBuildingProvider.notifier);
    final sourceId = notifier.sourceBuildingId ?? activeSnapshot.id;

    final isNew =
        ref.read(buildingRepositoryProvider).asData?.value[sourceId] == null;

    final String message = isNew
        ? '「${activeSnapshot.name}」を新しい建物としてサーバーに保存します。\nよろしいですか？'
        : '既存の建物データ（ID: $sourceId）を「${activeSnapshot.name}」として上書き保存します。\nよろしいですか？';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('アップロード確認'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('キャンセル'),
              onPressed: () => Navigator.of(dialogContext).pop(false),
            ),
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.primary,
              ),
              child: const Text('保存する!'),
              onPressed: () => Navigator.of(dialogContext).pop(true),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('アップロード中...'),
        duration: Duration(seconds: 15),
      ),
    );

    try {
      final uploadedId = await notifier.uploadDraftToFirestore();

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('アップロードが完了しました (ID: $uploadedId)'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text('アップロード中にエラーが発生しました: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _ensureDraftIsActive({bool checkAgain = true}) {
    if (!mounted) return;

    final currentSnapshot = ref.read(activeBuildingProvider);
    if (currentSnapshot.id != kDraftBuildingId) {
      if (checkAgain) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted &&
              ref.read(activeBuildingProvider).id != kDraftBuildingId) {
            ref.read(activeBuildingProvider.notifier).startDraftFromActive();
          }
        });
      } else {
        ref.read(activeBuildingProvider.notifier).startDraftFromActive();
      }
    }
  }

  @override
  void initState() {
    super.initState();

    pageController = PageController();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ensureDraftIsActive(checkAgain: false);

      final snap = ref.read(activeBuildingProvider);
      final notifier = ref.read(interactiveImageProvider.notifier);

      notifier.handleBuildingChanged(snap.id);

      ref.read(activeRouteProvider.notifier).clearActiveRouteNodes();

      _xController.addListener(_updateTapPositionFromTextFields);
      _yController.addListener(_updateTapPositionFromTextFields);
      _nameController.addListener(_updateNameFromTextField);

      pageController = PageController(initialPage: snap.floorCount - 1);

      isPageScrollable = canSwipeFloors;
      ref.listenManual<InteractiveImageState>(interactiveImageProvider, (
        prev,
        next,
      ) {
        if (!mounted) return;
        if (next.selectedElement == null &&
            prev?.tapPosition != next.tapPosition) {
          final p = next.tapPosition;
          if (p == null) {
            _nameController.clear();
            _xController.clear();
            _yController.clear();
          } else {
            _nameController.text = '新しい要素';
            final imageDimensions =
                next.imageDimensionsByFloor[next.currentFloor];

            if (imageDimensions != null &&
                imageDimensions.width > 0 &&
                imageDimensions.height > 0) {
              final absolutePos = Offset(
                p.dx * imageDimensions.width,
                p.dy * imageDimensions.height,
              );
              _xController.text = absolutePos.dx.toStringAsFixed(0);
              _yController.text = absolutePos.dy.toStringAsFixed(0);
            } else {
              _xController.text = p.dx.toStringAsFixed(0);
              _yController.text = p.dy.toStringAsFixed(0);
            }
          }
        }

        if (prev?.currentFloor != next.currentFloor) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;

            ref
                .read(interactiveImageProvider.notifier)
                .applyPendingFocusIfAny();

            if (next.pendingFocusElement != null) {
              ref
                  .read(interactiveImageProvider.notifier)
                  .updateCurrentZoomScale();
            }
          });
        }
      });
    });
  }

  @override
  void dispose() {
    _xController.removeListener(_updateTapPositionFromTextFields);
    _yController.removeListener(_updateTapPositionFromTextFields);
    _nameController.removeListener(_updateNameFromTextField);

    _nameController.dispose();
    _xController.dispose();
    _yController.dispose();

    super.dispose();
  }

  void _updateNameFromTextField() {
    ref
        .read(interactiveImageProvider.notifier)
        .updateElementName(_nameController.text);
  }

  void _updateTapPositionFromTextFields() {
    final double? x = double.tryParse(_xController.text);
    final double? y = double.tryParse(_yController.text);
    if (x == null || y == null) return;

    final Offset absolutePos = Offset(x, y);

    final imgState = ref.read(interactiveImageProvider);
    final imageDimensions =
        imgState.imageDimensionsByFloor[imgState.currentFloor];

    if (imageDimensions == null ||
        imageDimensions.width == 0 ||
        imageDimensions.height == 0) {
      return;
    }

    final Offset relativePos = Offset(
      (absolutePos.dx / imageDimensions.width).clamp(0.0, 1.0),
      (absolutePos.dy / imageDimensions.height).clamp(0.0, 1.0),
    );

    ref
        .read(interactiveImageProvider.notifier)
        .updateElementPosition(relativePos);
  }

  void _toggleConnectionMode() {
    ref.read(interactiveImageProvider.notifier).toggleConnectionMode();
  }

  void _openSettingsDialog() async {
    final active = ref.read(activeBuildingProvider);
    final imageState = ref.watch(interactiveImageProvider);

    final BuildingSettings? newSettings = await showDialog<BuildingSettings>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return SettingsDialog(
          initialBuildingName: active.name,
          initialFloorCount: active.floorCount,
          initialImagePattern: active.imagePattern,
        );
      },
    );

    if (newSettings != null && mounted) {
      ref
          .read(activeBuildingProvider.notifier)
          .updateBuildingSettings(
            name: newSettings.buildingName,
            floors: newSettings.floorCount,
            pattern: newSettings.imageNamePattern,
          );

      if (imageState.currentFloor > newSettings.floorCount) {
        pageController.jumpToPage(newSettings.floorCount - 1);
      }
    }
  }

  void _rebuildRoomPassageEdges() {
    ref.read(activeBuildingProvider.notifier).rebuildRoomPassageEdges();
  }

  void _handleAddPressed() {
    final name = _nameController.text.trim();
    final double? x = double.tryParse(_xController.text);
    final double? y = double.tryParse(_yController.text);

    final messenger = ScaffoldMessenger.of(context);

    if (name.isEmpty || x == null || y == null) {
      messenger.showSnackBar(
        const SnackBar(content: Text("入力エラー: 名前、X、Yを正しく入力してください。")),
      );
      return;
    }

    final imgState = ref.read(interactiveImageProvider);
    final imageDimensions =
        imgState.imageDimensionsByFloor[imgState.currentFloor];

    if (imageDimensions == null ||
        imageDimensions.width == 0 ||
        imageDimensions.height == 0) {
      messenger.showSnackBar(
        const SnackBar(content: Text("エラー: 画像の寸法が取得できません。")),
      );
      return;
    }

    final Offset relativePos = Offset(
      (x / imageDimensions.width).clamp(0.0, 1.0),
      (y / imageDimensions.height).clamp(0.0, 1.0),
    );

    ref
        .read(interactiveImageProvider.notifier)
        .addElement(name: name, position: relativePos);
  }

  Future<void> _handleDeletePressed() async {
    final elementToDelete = ref.read(interactiveImageProvider).selectedElement;
    if (elementToDelete == null) return;

    bool shouldDelete = true;

    if (elementToDelete.type.isGraphNode &&
        ref
            .read(activeBuildingProvider.notifier)
            .hasEdges(elementToDelete.id)) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('削除の確認'),
            content: const Text(
              'この要素には接続されたエッジがあります。本当に削除しますか？\n関連するエッジもすべて削除されます。',
            ),
            actions: <Widget>[
              TextButton(
                child: const Text('キャンセル'),
                onPressed: () => Navigator.of(dialogContext).pop(false),
              ),
              TextButton(
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('削除する!'),
                onPressed: () => Navigator.of(dialogContext).pop(true),
              ),
            ],
          );
        },
      );

      if (confirmed != true) {
        shouldDelete = false;
      }
    }

    if (!shouldDelete || !mounted) return;

    ref.read(interactiveImageProvider.notifier).deleteSelectedElement();
  }

  @override
  Widget build(BuildContext context) {
    final activeSnapshot = ref.watch(activeBuildingProvider);
    if (activeSnapshot.id != kDraftBuildingId) {
      _ensureDraftIsActive(checkAgain: true);

      return const Center(child: CircularProgressIndicator());
    }

    final imageState = ref.watch(interactiveImageProvider);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        _FloorHeader(
          currentType: imageState.currentType,
          onTypeSelected: (type) =>
              ref.read(interactiveImageProvider.notifier).setCurrentType(type),
        ),
        Expanded(
          child: Stack(
            children: [
              buildInteractiveImage(),
              Positioned(
                top: 12,
                left: 16,
                child: Text(
                  '${imageState.currentFloor}F',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        if (imageState.tapPosition != null || imageState.isConnecting)
          EditorActionScreen(
            isConnecting: imageState.isConnecting,
            selectedElement: imageState.selectedElement,
            nameController: _nameController,
            xController: _xController,
            yController: _yController,
            onAdd: _handleAddPressed,
            onDelete: _handleDeletePressed,
            onToggleConnect: _toggleConnectionMode,
          )
        else
          EditorIdleScreen(onRebuildPressed: _rebuildRoomPassageEdges),
        const SizedBox(height: 4),
        Container(height: 2, color: Colors.grey[300]),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: _openSettingsDialog,
            ),
            IconButton(
              icon: const Icon(Icons.cloud_upload),
              tooltip: 'アップロード',
              onPressed: () => _handleUploadPressed(),
            ),
          ],
        ),
      ],
    );
  }
}

class _FloorHeader extends StatelessWidget {
  final PlaceType currentType;
  final ValueChanged<PlaceType> onTypeSelected;

  const _FloorHeader({required this.currentType, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: PlaceTypeSelector(
              currentType: currentType,
              onTypeSelected: onTypeSelected,
            ),
          ),
        ],
      ),
    );
  }
}
