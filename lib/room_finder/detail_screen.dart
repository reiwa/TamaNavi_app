import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';

class FinderDetailContent extends StatefulWidget {
  const FinderDetailContent({
    required this.currentFloor,
    required this.dropdownValue,
    required this.roomsInBuilding,
    required this.selectedRoomInfo,
    required this.entrances,
    required this.selectedEntranceId,
    required this.onRoomSelected,
    required this.onEntranceSelected,
    required this.onReturnToSearch,
    required this.interactiveImage,
    required this.selectedElementLabel,
    required this.onStartNavigation,
    required this.canStartNavigation,
    required this.allowStairs,
    required this.allowElevators,
    required this.onAllowStairsChanged,
    required this.onAllowElevatorsChanged,
    super.key,
  });

  final int currentFloor;
  final String? dropdownValue;
  final List<BuildingRoomInfo> roomsInBuilding;
  final BuildingRoomInfo? selectedRoomInfo;
  final List<CachedSData> entrances;
  final String? selectedEntranceId;
  final ValueChanged<String?> onRoomSelected;
  final ValueChanged<CachedSData> onEntranceSelected;
  final VoidCallback onReturnToSearch;
  final Widget interactiveImage;
  final String selectedElementLabel;
  final VoidCallback? onStartNavigation;
  final bool canStartNavigation;
  final bool allowStairs;
  final bool allowElevators;
  final ValueChanged<bool> onAllowStairsChanged;
  final ValueChanged<bool> onAllowElevatorsChanged;

  @override
  State<FinderDetailContent> createState() => _FinderDetailContentState();
}

class _FinderDetailContentState extends State<FinderDetailContent> {
  late final ScrollController _infoScrollController;

  @override
  void initState() {
    super.initState();
    _infoScrollController = ScrollController();
  }

  @override
  void dispose() {
    _infoScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = theme.brightness == Brightness.dark;
    final elevatedSurfaceColor =
        isDark ? colorScheme.surface : Colors.white;
    final elevatedShadowColor = colorScheme.shadow.withValues(
      alpha: isDark ? 0.45 : 0.08,
    );
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 6),
          child: Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: elevatedSurfaceColor,
              border: Border.all(
                color: colorScheme.outlineVariant.withValues(alpha: 0.7),
                width: 0.8,
              ),
              boxShadow: [
                BoxShadow(
                  color: elevatedShadowColor,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: _RoomDropdownField(
                    dropdownValue: widget.dropdownValue,
                    roomsInBuilding: widget.roomsInBuilding,
                    colorScheme: colorScheme,
                    textTheme: textTheme,
                    onRoomSelected: widget.onRoomSelected,
                  ),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  onPressed: widget.onReturnToSearch,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text('検索へ戻る'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: RepaintBoundary(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: colorScheme.primary.withValues(alpha: 0.2),
                    width: 1.4,
                  ),
                  color: colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.25,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: Stack(
                    children: [
                      widget.interactiveImage,
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            '${widget.currentFloor}F',
                            style: textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
          child: SizedBox(
            height: 160,
            child: RepaintBoundary(
              child: Card(
                color: elevatedSurfaceColor,
                elevation: isDark ? 0 : 8,
                shadowColor: elevatedShadowColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                    width: 0.6,
                  ),
                ),
                child: Scrollbar(
                  controller: _infoScrollController,
                  thumbVisibility: false,
                  child: SingleChildScrollView(
                    controller: _infoScrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _DetailInfoTile(
                                label: '建物',
                                value:
                                    widget.selectedRoomInfo?.buildingName ?? '-',
                                textTheme: textTheme,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _DetailInfoTile(
                                label: '選択中',
                                value: widget.selectedElementLabel,
                                textAlign: TextAlign.right,
                                textTheme: textTheme,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _EntranceSelectionPanel(
                          entrances: widget.entrances,
                          selectedEntranceId: widget.selectedEntranceId,
                          onEntranceSelected: widget.onEntranceSelected,
                          textTheme: textTheme,
                          colorScheme: colorScheme,
                          canStartNavigation: widget.canStartNavigation,
                          onStartNavigation: widget.onStartNavigation,
                          allowStairs: widget.allowStairs,
                          allowElevators: widget.allowElevators,
                          onAllowStairsChanged: widget.onAllowStairsChanged,
                          onAllowElevatorsChanged:
                              widget.onAllowElevatorsChanged,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomDropdownField extends StatefulWidget {
  const _RoomDropdownField({
    required this.dropdownValue,
    required this.roomsInBuilding,
    required this.colorScheme,
    required this.textTheme,
    required this.onRoomSelected,
  });

  final String? dropdownValue;
  final List<BuildingRoomInfo> roomsInBuilding;
  final ColorScheme colorScheme;
  final TextTheme textTheme;
  final ValueChanged<String?> onRoomSelected;

  @override
  State<_RoomDropdownField> createState() => _RoomDropdownFieldState();
}

class _RoomDropdownFieldState extends State<_RoomDropdownField> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final baseColor = widget.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.35,
    );
    final hoverColor = widget.colorScheme.surfaceContainerHighest.withValues(
      alpha: 0.65,
    );

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: _isHovering ? hoverColor : baseColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: widget.dropdownValue,
            isExpanded: true,
            hint: Text(
              '部屋を選択',
              style: widget.textTheme.bodyMedium?.copyWith(
                color: widget.colorScheme.onSurface.withValues(
                  alpha: 0.6,
                ),
              ),
            ),
            borderRadius: BorderRadius.circular(16),
            style: widget.textTheme.bodyMedium,
            icon: Icon(
              Icons.unfold_more_rounded,
              color: widget.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            items: widget.roomsInBuilding.map((info) {
              final title = info.room.name.isEmpty
                  ? info.room.id
                  : info.room.name;
              return DropdownMenuItem<String>(
                value: info.room.id,
                child: Text(title),
              );
            }).toList(),
            onChanged: widget.onRoomSelected,
          ),
        ),
      ),
    );
  }
}

class _EntranceSelectionPanel extends StatelessWidget {
  const _EntranceSelectionPanel({
    required this.entrances,
    required this.selectedEntranceId,
    required this.onEntranceSelected,
    required this.textTheme,
    required this.colorScheme,
    required this.canStartNavigation,
    required this.onStartNavigation,
    required this.allowStairs,
    required this.allowElevators,
    required this.onAllowStairsChanged,
    required this.onAllowElevatorsChanged,
  });

  final List<CachedSData> entrances;
  final String? selectedEntranceId;
  final ValueChanged<CachedSData> onEntranceSelected;
  final TextTheme textTheme;
  final ColorScheme colorScheme;
  final bool canStartNavigation;
  final VoidCallback? onStartNavigation;
  final bool allowStairs;
  final bool allowElevators;
  final ValueChanged<bool> onAllowStairsChanged;
  final ValueChanged<bool> onAllowElevatorsChanged;

  @override
  Widget build(BuildContext context) {
    final hasEntrances = entrances.isNotEmpty;
    final enableButton =
        canStartNavigation && hasEntrances && selectedEntranceId != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '出発地点を選ぶ',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        if (!hasEntrances)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.35,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'この建物に登録された入口がありません。',
              style: textTheme.bodyMedium,
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: entrances.length,
            separatorBuilder: (_, _) => const SizedBox(height: 6),
            itemBuilder: (context, index) {
              final entrance = entrances[index];
              final title = entrance.name.isEmpty ? entrance.id : entrance.name;
              final isSelected = entrance.id == selectedEntranceId;
              return Material(
                color: isSelected
                    ? colorScheme.primary.withValues(alpha: 0.12)
                    : colorScheme.surface,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onEntranceSelected(entrance),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          isSelected
                              ? Icons.radio_button_checked
                              : Icons.radio_button_unchecked,
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.onSurface.withValues(
                                  alpha: 0.5,
                                ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textTheme.bodyMedium?.copyWith(
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        const SizedBox(height: 14),
        Text(
          '移動手段を選ぶ',
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        _VerticalPreferenceCheckbox(
          label: 'エレベーターを使う',
          value: allowElevators,
          onChanged: onAllowElevatorsChanged,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 6),
        _VerticalPreferenceCheckbox(
          label: '階段を使う',
          value: allowStairs,
          onChanged: onAllowStairsChanged,
          textTheme: textTheme,
          colorScheme: colorScheme,
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          icon: const Icon(Icons.alt_route_rounded),
          label: const Text('ルートを検索する'),
          onPressed: enableButton ? onStartNavigation : null,
        ),
      ],
    );
  }
}

class _VerticalPreferenceCheckbox extends StatelessWidget {
  const _VerticalPreferenceCheckbox({
    required this.label,
    required this.value,
    required this.onChanged,
    required this.textTheme,
    required this.colorScheme,
  });

  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  final TextTheme textTheme;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant, width: 0.8),
        color: colorScheme.surface.withValues(alpha: 0.6),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: (checked) => onChanged(checked ?? false),
        title: Text(
          label,
          style: textTheme.bodyMedium,
        ),
        dense: true,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      ),
    );
  }
}

class _DetailInfoTile extends StatelessWidget {
  const _DetailInfoTile({
    required this.label,
    required this.value,
    required this.textTheme,
    this.textAlign = TextAlign.left,
  });

  final String label;
  final String value;
  final TextTheme textTheme;
  final TextAlign textAlign;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: textAlign == TextAlign.left
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurface.withValues(
              alpha: 0.7,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: textAlign,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
