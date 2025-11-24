import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/active_building_notifier.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/room_editor/room_finder_invocation_provider.dart';
import 'package:tamanavi_app/viewer/interactive_image_notifier.dart';

class SnapshotScreen extends ConsumerStatefulWidget {

  const SnapshotScreen({
    required this.onSettingsPressed, required this.onUploadPressed, super.key,
  });
  final VoidCallback onSettingsPressed;
  final Future<void> Function() onUploadPressed;

  @override
  ConsumerState<SnapshotScreen> createState() => _SnapshotScreenState();
}

class _SnapshotScreenState extends ConsumerState<SnapshotScreen> {
  late final ProviderSubscription<CachedSData?> _selectionSubscription;

  @override
  void initState() {
    super.initState();
    _selectionSubscription = ref.listenManual<CachedSData?>(
      interactiveImageProvider.select((s) => s.selectedElement),
      (prev, next) {
        if (next == null) {
          return;
        }

        final notifier = ref.read(roomFinderInvocationProvider.notifier);
        if (next.type == PlaceType.entrance) {
          notifier.setNavigateFrom(next.id);
        } else {
          notifier.setNavigateTo(next.id);
        }
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _selectionSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedElement = ref.watch(
      interactiveImageProvider.select((state) => state.selectedElement),
    );
    final invocationState = ref.watch(roomFinderInvocationProvider);
    final invocationSnippet = _buildRoomFinderInvocation(
      invocationState,
      selectedElement,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: Row(
              children: [
                Expanded(
                  child: _InvocationPreview(snippet: invocationSnippet),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: widget.onSettingsPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.note_add),
                  tooltip: '新規ドラフト',
                  onPressed: () {
                    ref
                        .read(activeBuildingProvider.notifier)
                        .startNewBuildingDraft();
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  tooltip: 'アップロード',
                  onPressed: () => widget.onUploadPressed(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _InvocationPreview extends StatelessWidget {
  const _InvocationPreview({required this.snippet});

  final String snippet;

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: snippet));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('RoomFinder呼び出しをコピーしました。')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.bodyMedium?.copyWith(
      fontFamily: 'monospace',
    );

    return Tooltip(
      message: 'タップしてコピー',
      child: InkWell(
        onTap: () => _copyToClipboard(context),
        borderRadius: BorderRadius.circular(4),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Text(snippet, style: textStyle),
        ),
      ),
    );
  }
}

String _buildRoomFinderInvocation(
  RoomFinderInvocationState state,
  CachedSData? selection,
) {
  final args = <String>[];

  if (state.navigateFrom != null) {
    final escaped = state.navigateFrom!.replaceAll("'", r"\'");
    args.add("navigateFrom: '$escaped'");
  }

  if (state.navigateTo != null) {
    final escaped = state.navigateTo!.replaceAll("'", r"\'");
    args.add("navigateTo: '$escaped'");
  }

  if (args.isEmpty) {
    final placeholder = selection == null
        ? 'navigateFrom: ..., navigateTo: ...'
        : selection.type == PlaceType.entrance
        ? 'navigateFrom: ...'
        : 'navigateTo: ...';
    return 'const RoomFinder($placeholder)';
  }

  return 'const RoomFinder(${args.join(', ')})';
}
