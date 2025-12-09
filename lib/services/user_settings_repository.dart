import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

final userSettingsRepositoryProvider = Provider<UserSettingsRepository>((ref) {
  throw UnimplementedError('userSettingsRepositoryProvider must be overridden.');
});

class UserSettingsRepository {
  UserSettingsRepository._(this._box);

  static const String _boxName = 'user_settings';
  static const String _themeModeKey = 'themeMode';
  static const String _performanceTierKey = 'performanceTier';

  final Box<dynamic> _box;

  static Future<UserSettingsRepository> initialize() async {
    final box = await Hive.openBox<dynamic>(_boxName);
    return UserSettingsRepository._(box);
  }

  ThemeMode? readThemeMode() {
    final raw = _box.get(_themeModeKey);
    if (raw is! String) {
      return null;
    }
    return ThemeMode.values.firstWhere(
      (mode) => mode.name == raw,
      orElse: () => ThemeMode.light,
    );
  }

  Future<void> writeThemeMode(ThemeMode mode) {
    return _box.put(_themeModeKey, mode.name);
  }

  String? readPerformanceTierName() {
    final raw = _box.get(_performanceTierKey);
    return raw is String ? raw : null;
  }

  Future<void> writePerformanceTierName(String tierName) {
    return _box.put(_performanceTierKey, tierName);
  }

  Future<void> clearPerformanceTier() {
    return _box.delete(_performanceTierKey);
  }

  bool get hasPerformanceTier => _box.containsKey(_performanceTierKey);
}
