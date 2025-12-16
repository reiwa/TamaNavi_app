import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:tamanavi_app/services/performance_tier_provider.dart';
import 'package:tamanavi_app/theme/theme_mode_provider.dart';

Future<void> showFinderSettingsDialog(BuildContext context) async {
  await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return const FinderSettingsDialog();
    },
  );
}

class FinderSettingsDialog extends ConsumerWidget {
  const FinderSettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      title: const Text('設定'),
      content: const SizedBox(
        width: double.maxFinite,
        child: _SettingsContent(),
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

class _SettingsContent extends ConsumerWidget {
  const _SettingsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;
    final textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: isDarkMode,
          onChanged: (value) {
            ref.read(themeModeProvider.notifier).setIsDark(isDark: value);
          },
          title: Text('ダークモード', style: textTheme.titleMedium),
          subtitle: Text(
            'アプリの配色を変更します。',
            style: textTheme.bodySmall,
          ),
        ),
        const SizedBox(height: 16),
        const _PerformanceSection(),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        const _AppInfoSection(),
      ],
    );
  }
}

class _PerformanceSection extends ConsumerWidget {
  const _PerformanceSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tier = ref.watch(performanceTierProvider);
    final notifier = ref.read(performanceTierProvider.notifier);
    final textTheme = Theme.of(context).textTheme;
    final options = [
      (
        tier: PerformanceTier.medium,
        title: '中',
      ),
      (
        tier: PerformanceTier.high,
        title: '高',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('パフォーマンス設定', style: textTheme.titleMedium),
        const SizedBox(height: 8),
        SegmentedButton<PerformanceTier>(
          segments: [
            for (final option in options)
              ButtonSegment<PerformanceTier>(
                value: option.tier,
                label: Text(option.title),
              ),
          ],
          selected: {tier},
          onSelectionChanged: (selection) {
            if (selection.isEmpty) return;
            notifier.overrideTier(selection.first);
          },
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: () {
              unawaited(notifier.clearManualOverride());
            },
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('推奨設定に戻す'),
          ),
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
      children: [
        const Icon(Icons.info_outline, size: 16),
        const SizedBox(width: 8),
        Expanded(
          child: Text('TamaNavi App • v1.0.0', style: textTheme.labelMedium),
        ),
      ],
    );
  }
}
