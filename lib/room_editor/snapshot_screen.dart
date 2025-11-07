import 'package:flutter/material.dart';

class SnapshotScreen extends StatelessWidget {
  final VoidCallback onSettingsPressed;
  final Future<void> Function() onUploadPressed;

  const SnapshotScreen({
    super.key,
    required this.onSettingsPressed,
    required this.onUploadPressed,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          width: constraints.maxWidth - 16,
          height: 120,
          child: Positioned(
            top: 0,
            right: 8,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.settings),
                  onPressed: onSettingsPressed,
                ),
                IconButton(
                  icon: const Icon(Icons.cloud_upload),
                  tooltip: 'アップロード',
                  onPressed: () => onUploadPressed(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
