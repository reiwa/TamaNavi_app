import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:tamanavi_app/services/user_settings_repository.dart';

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>(
  (ref) {
    final repository = ref.watch(userSettingsRepositoryProvider);
    return ThemeModeController(repository: repository);
  },
);

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController({required UserSettingsRepository repository})
      : _repository = repository,
        super(repository.readThemeMode() ?? ThemeMode.light);

  final UserSettingsRepository _repository;

  void toggle() {
    _updateState(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }

  void setIsDark({required bool isDark}) {
    _updateState(isDark ? ThemeMode.dark : ThemeMode.light);
  }

  void setThemeMode(ThemeMode mode) {
    _updateState(mode);
  }

  void _updateState(ThemeMode mode) {
    if (state == mode) {
      return;
    }
    state = mode;
    unawaited(_repository.writeThemeMode(mode));
  }
}
