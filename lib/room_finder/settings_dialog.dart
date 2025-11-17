import 'package:flutter/material.dart';

Future<void> showFinderSettingsDialog(BuildContext context) async {
  await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return const FinderSettingsDialog();
    },
  );
}

class FinderSettingsDialog extends StatelessWidget {
  const FinderSettingsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('設定'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text('More options coming soon...'),
            SizedBox(height: 24),
            Divider(),
            SizedBox(height: 8),
            _AppInfoSection(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('閉じる'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('保存する!'),
        ),
      ],
    );
  }
}

class _AppInfoSection extends StatelessWidget {
  const _AppInfoSection();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Icon(Icons.info_outline, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('TamaNavi App • v0.9.9', style: textTheme.labelMedium),
        ),
      ],
    );
  }
}
