import 'package:flutter/material.dart';
import 'package:test_project/models/room_finder_models.dart';

class FinderSearchContent extends StatelessWidget {
  const FinderSearchContent({
    super.key,
    required this.isLoading,
    required this.searchController,
    required this.searchFocusNode,
    required this.results,
    required this.isQueryEmpty,
    required this.canLoadMore,
    required this.onLoadMore,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onRoomTap,
  });

  final bool isLoading;
  final TextEditingController searchController;
  final FocusNode searchFocusNode;
  final List<BuildingRoomInfo> results;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<BuildingRoomInfo> onRoomTap;
  final bool isQueryEmpty;
  final bool canLoadMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context) {
    final bool showLoadMoreButton = !isLoading && isQueryEmpty && canLoadMore;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            controller: searchController,
            focusNode: searchFocusNode,
            enabled: !isLoading,
            onChanged: onQueryChanged,
            decoration: InputDecoration(
              labelText: '部屋を検索',
              labelStyle: const TextStyle(fontSize: 14),
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: onClearQuery,
                    ),
            ),
          ),
        ),
        Expanded(
          child: isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : results.isEmpty
              ? const Center(
                  child: Text('該当する部屋がありません', style: TextStyle(fontSize: 13)),
                )
              : ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: results.length + (showLoadMoreButton ? 1 : 0),
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    if (showLoadMoreButton && index == results.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        child: TextButton(
                          onPressed: onLoadMore,
                          child: const Text('もっと探す!'),
                        ),
                      );
                    }

                    final info = results[index];
                    final title = info.room.name.isEmpty
                        ? info.room.id
                        : info.room.name;
                    return ListTile(
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
                      onTap: () => onRoomTap(info),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
