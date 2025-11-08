import 'dart:math';
import 'package:flutter/material.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

Future<CachedSData?> showEntranceSelector({
  required BuildContext context,
  required List<CachedSData> entrances,
  required String initialId,
  required ValueChanged<CachedSData> onFocus,
}) {
  if (entrances.isEmpty) return Future.value(null);

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
              return SafeArea(
                top: false,
                child: Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    boxShadow: const [
                      BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, -4)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        '入口を選択',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                            final title =
                                entrance.name.isEmpty ? entrance.id : entrance.name;
                            final isSelected = selectedId == entrance.id;
                            return ListTile(
                              dense: true,
                              leading: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_unchecked,
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : null,
                              ),
                              title: Text(title, style: const TextStyle(fontSize: 16)),
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
                              onPressed: () => Navigator.of(dialogContext).pop(null),
                              child: const Text('キャンセル', style: TextStyle(fontSize: 14)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
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
                                style: TextStyle(fontSize: 14, color: Colors.white),
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
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: child,
      );
    },
  );
}
