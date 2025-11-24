import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/room_finder/room_finder_app.dart';

class FinderSearchContent extends ConsumerStatefulWidget {
  const FinderSearchContent({
    super.key,
    required this.onTagSelected,
    required this.onRoomTap,
  });

  final ValueChanged<String> onTagSelected;
  final ValueChanged<BuildingRoomInfo> onRoomTap;

  @override
  ConsumerState<FinderSearchContent> createState() => _FinderSearchContentState();
}

class _FinderSearchContentState extends ConsumerState<FinderSearchContent> {
  late final TextEditingController _searchController;
  Timer? _queryDebounce;
  static const Duration _debounceDuration = Duration(milliseconds: 250);

  @override
  void initState() {
    super.initState();
    _searchController =
        TextEditingController(text: ref.read(finderSearchQueryProvider));
    _searchController.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _queryDebounce?.cancel();
    _searchController.removeListener(_handleQueryChanged);
    _searchController.dispose();
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
              fit: FlexFit.loose,
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
                    style: TextStyle(color: Theme.of(context).colorScheme.error),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Center(
        child: Wrap(
          spacing: 18,
          runSpacing: 9,
          alignment: WrapAlignment.center,
          children: [
            for (int i = 0; i < kFinderTagOptions.length; i++)
              SizedBox(
                width: 140,
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    backgroundColor: selectedTag == kFinderTagOptions[i]
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey.shade200,
                    foregroundColor: selectedTag == kFinderTagOptions[i]
                        ? Colors.white
                        : Theme.of(context).colorScheme.onSurface,
                    elevation: selectedTag == kFinderTagOptions[i] ? 4 : 0,
                  ),
                  onPressed: () {
                    if (selectedTag == kFinderTagOptions[i]) {
                      return;
                    }
                    widget.onTagSelected(kFinderTagOptions[i]);
                  },
                  child: Text(
                    kFinderTagOptions[i],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchField(BuildContext context, String searchQuery) {
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
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'クリア',
                      icon: const Icon(Icons.clear),
                      onPressed: () => _searchController.clear(),
                    ),
              isDense: true,
              filled: true,
              fillColor: Colors.grey.shade100,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultList(List<BuildingRoomInfo> visibleResults) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      itemCount: visibleResults.length,
      itemBuilder: (context, index) {
        final info = visibleResults[index];
        final title = info.room.name.isEmpty ? info.room.id : info.room.name;

        return Column(
          children: [
            ListTile(
              dense: true,
              title: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                info.buildingName,
                style: const TextStyle(fontSize: 13),
              ),
              trailing: Text(
                '${info.room.floor}階',
                style: const TextStyle(fontSize: 13),
              ),
              onTap: () => widget.onRoomTap(info),
            ),
            const Divider(height: 1),
          ],
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
      final roomLabel =
          (info.room.name.isEmpty ? info.room.id : info.room.name)
              .toLowerCase();
      final buildingLabel = info.buildingName.toLowerCase();
      return roomLabel.contains(query) ||
          buildingLabel.contains(query);
    }).toList();
  }
}
