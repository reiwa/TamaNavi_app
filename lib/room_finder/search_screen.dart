import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/room_finder/room_finder_app.dart';

class FinderSearchContent extends ConsumerStatefulWidget {
  const FinderSearchContent({
    required this.onTagSelected,
    required this.onRoomTap,
    super.key,
  });

  final ValueChanged<String> onTagSelected;
  final ValueChanged<BuildingRoomInfo> onRoomTap;

  @override
  ConsumerState<FinderSearchContent> createState() =>
      _FinderSearchContentState();
}

class _FinderSearchContentState extends ConsumerState<FinderSearchContent> {
  late final TextEditingController _searchController;
  Timer? _queryDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: ref.read(finderSearchQueryProvider),
    );
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _searchController
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  void _handleQueryChanged() {
    final nextValue = _searchController.text;
    _queryDebounce?.cancel();
    _queryDebounce = Timer(_debounceDuration, () {
      final notifier = ref.read(finderSearchQueryProvider.notifier);
      if (notifier.state == nextValue) {
        return;
      }
      notifier.state = nextValue;
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedTag = ref.watch(selectedTagProvider);
    final resultsAsync = ref.watch(tagSearchResultsProvider);
    final searchQuery = ref.watch(finderSearchQueryProvider);

    if (_searchController.text != searchQuery) {
      _searchController.value = TextEditingValue(
        text: searchQuery,
        selection: TextSelection.collapsed(offset: searchQuery.length),
      );
    }

    return Stack(
      children: [
        Column(
          children: [
            _buildTagSelector(context, selectedTag),
            _buildSearchField(context, searchQuery),
            Flexible(
              child: resultsAsync.when(
                data: (results) {
                  if (results.isEmpty) {
                    return const Center(
                      child: Text(
                        '該当する部屋がありません',
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  final filtered = _filterResults(results, searchQuery);
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        '検索条件に一致する部屋がありません',
                        style: TextStyle(fontSize: 13),
                      ),
                    );
                  }

                  return _buildResultList(filtered);
                },
                error: (error, stack) => Center(
                  child: Text(
                    '読み込みに失敗しました',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTagSelector(BuildContext context, String selectedTag) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Center(
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: [
            for (final tag in kFinderTagOptions)
              AnimatedScale(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutBack,
                scale: selectedTag == tag ? 1.05 : 1,
                child: SizedBox(
                  width: 132,
                  child: ChoiceChip(
                    label: Center(
                      child: Text(
                        tag,
                        style: textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: selectedTag == tag
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface,
                        ),
                      ),
                    ),
                    tooltip: '$tagを絞り込む',
                    selected: selectedTag == tag,
                    onSelected: (value) {
                      if (!value || selectedTag == tag) {
                        return;
                      }
                      widget.onTagSelected(tag);
                    },
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                      side: BorderSide(
                        color: selectedTag == tag
                            ? colorScheme.primary
                            : colorScheme.outlineVariant,
                        width: 1.2,
                      ),
                    ),
                    selectedColor: colorScheme.primary,
                    backgroundColor: colorScheme.surface,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 10,
                    ),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    showCheckmark: false,
                    visualDensity: VisualDensity.comfortable,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, String searchQuery) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: '部屋名・建物名で検索',
              prefixIcon: Icon(
                Icons.search,
                color: colorScheme.primary,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'クリア',
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(18),
                borderSide: BorderSide(color: colorScheme.outlineVariant),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultList(List<BuildingRoomInfo> visibleResults) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: visibleResults.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final info = visibleResults[index];
        final title = info.room.name.isEmpty ? info.room.id : info.room.name;
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () => widget.onRoomTap(info),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: colorScheme.primary.withValues(
                      alpha: 0.15,
                    ),
                    foregroundColor: colorScheme.primary,
                    child: Text(
                      '${info.room.floor}F',
                      style: textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.buildingName,
                          style: textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurface.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurface.withValues(alpha: 0.5),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<BuildingRoomInfo> _filterResults(
    List<BuildingRoomInfo> source,
    String rawQuery,
  ) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }

    return source.where((info) {
      final roomLabel = (info.room.name.isEmpty ? info.room.id : info.room.name)
          .toLowerCase();
      final buildingLabel = info.buildingName.toLowerCase();
      return roomLabel.contains(query) || buildingLabel.contains(query);
    }).toList();
  }
}
