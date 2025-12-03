import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

Future<CachedSData?> showEntranceSelector({
  required BuildContext context,
  required List<CachedSData> entrances,
  required String initialId,
  required ValueChanged<CachedSData> onFocus,
}) {
  if (entrances.isEmpty) return Future.value();

  return showGeneralDialog<CachedSData>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'entrance_selector',
    barrierColor: Colors.transparent,
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (dialogContext, animation, secondaryAnimation) {
      String? selectedId = initialId;
      return Align(
        alignment: Alignment.bottomCenter,
        child: Material(
          color: Colors.transparent,
          child: StatefulBuilder(
            builder: (context, setSheetState) {
              final colorScheme = Theme.of(context).colorScheme;
              final textTheme = Theme.of(context).textTheme;
              return SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: colorScheme.outlineVariant,
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '入口を選択',
                        style: textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: min(entrances.length * 40.0, 220),
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemExtent: 40,
                          itemCount: entrances.length,
                          itemBuilder: (context, index) {
                            final entrance = entrances[index];
                            final title = entrance.name.isEmpty
                                ? entrance.id
                                : entrance.name;
                            final isSelected = selectedId == entrance.id;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? colorScheme.primary
                                    : colorScheme.outline,
                              ),
                              title: Text(
                                title,
                                style: textTheme.bodyLarge,
                              ),
                              onTap: () {
                                setSheetState(() => selectedId = entrance.id);
                                onFocus(entrance);
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(),
                              child: const Text(
                                'キャンセル',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.secondary,
                                foregroundColor: colorScheme.onSecondary,
                              ),
                              onPressed: () {
                                final selected = entrances.firstWhere(
                                  (e) => e.id == selectedId,
                                  orElse: () => entrances.first,
                                );
                                Navigator.of(dialogContext).pop(selected);
                              },
                              child: const Text(
                                '確定',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      );
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
  );
}
