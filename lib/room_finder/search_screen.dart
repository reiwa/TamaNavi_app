import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/room_finder/room_finder_app.dart';

class FinderSearchContent extends HookConsumerWidget {
  const FinderSearchContent({
    super.key,
    required this.isLoading,
    required this.searchFocusNode,
    required this.isQueryEmpty,
    required this.canLoadMore,
    required this.onLoadMore,
    required this.onQueryChanged,
    required this.onClearQuery,
    required this.onRoomTap,
  });

  final bool isLoading;
  final FocusNode searchFocusNode;
  final ValueChanged<String> onQueryChanged;
  final VoidCallback onClearQuery;
  final ValueChanged<BuildingRoomInfo> onRoomTap;
  final bool isQueryEmpty;
  final bool canLoadMore;
  final VoidCallback onLoadMore;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final query = ref.watch(searchQueryProvider);
    final controller = useTextEditingController(text: query);
    final results = ref.watch(filteredRoomsProvider);
    final bool showLoadMoreButton = !isLoading && isQueryEmpty && canLoadMore;

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: controller,
                focusNode: searchFocusNode,
                enabled: !isLoading,
                onChanged: onQueryChanged,
                decoration: InputDecoration(
                  labelText: '部屋を検索',
                  labelStyle: const TextStyle(fontSize: 14),
                  filled: true,
                  fillColor: Colors.lightGreen.shade200,
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: onClearQuery,
                        ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            Flexible(
              fit: FlexFit.loose,
              child: isLoading
                  ? const SizedBox.shrink()
                  : results.isEmpty
                      ? const Center(
                          child: Text('該当する部屋がありません',
                              style: TextStyle(fontSize: 13)),
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount:
                              results.length + (showLoadMoreButton ? 1 : 0),
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            if (showLoadMoreButton && index == results.length) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8.0),
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
        ),
        Positioned(
          bottom: 24,
          right: 24,
          child: FloatingActionButton(
            heroTag: 'focus_search',
            onPressed: () =>
                FocusScope.of(context).requestFocus(searchFocusNode),
            backgroundColor: Colors.lightGreen.shade400,
            tooltip: '検索ボックスにフォーカス',
            child: const Icon(Icons.search),
          ),
        ),
      ],
    );
  }
}
