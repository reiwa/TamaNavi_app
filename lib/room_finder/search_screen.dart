import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tamanavi_app/models/room_finder_models.dart';
import 'package:tamanavi_app/room_finder/room_finder_app.dart';

class FinderSearchContent extends ConsumerWidget {
  const FinderSearchContent({
    super.key,
    required this.onTagSelected,
    required this.onRoomTap,
  });

  final ValueChanged<String> onTagSelected;
  final ValueChanged<BuildingRoomInfo> onRoomTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTag = ref.watch(selectedTagProvider);
    final resultsAsync = ref.watch(tagSearchResultsProvider);
    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Center(
                child: Wrap(
                  spacing: 18,
                  runSpacing: 18,
                  alignment: WrapAlignment.center,
                  children: [
                    for (int i = 0; i < kFinderTagOptions.length; i++)
                      SizedBox(
                        width: 140,
                        height: 64,
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
                            elevation:
                                selectedTag == kFinderTagOptions[i] ? 4 : 0,
                          ),
                          onPressed: () {
                            if (selectedTag == kFinderTagOptions[i]) {
                              return;
                            }
                            onTagSelected(kFinderTagOptions[i]);
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
            ),
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

                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      final info = results[index];
                      final title = info.room.name.isEmpty
                          ? info.room.id
                          : info.room.name;

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
                            onTap: () => onRoomTap(info),
                          ),
                          const Divider(height: 1),
                        ],
                      );
                    },
                  );
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
}
