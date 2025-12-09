import 'dart:async';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/legacy.dart';
import 'package:tamanavi_app/services/user_settings_repository.dart';

enum PerformanceTier {
  medium,
  high,
}

extension PerformanceTierLabel on PerformanceTier {
  String get label => switch (this) {
        PerformanceTier.high => '高',
        PerformanceTier.medium => '中',
      };
}

extension PerformanceTierSettings on PerformanceTier {
  bool get enableRoutePulse => this == PerformanceTier.high;
  bool get showRoomLabels => this == PerformanceTier.high;
  bool get enableSelectedPinAnimation => this == PerformanceTier.high;
}

class PerformanceBenchmarker {
  const PerformanceBenchmarker();

  static const int _iterationCount = 250000;

  Future<PerformanceTier> detectTier() async {
    final elapsed = await _measure();
    final micros = elapsed.inMicroseconds <= 0 ? 1 : elapsed.inMicroseconds;
    final opsPerMillisecond =
        _iterationCount / (micros.toDouble() / Duration.microsecondsPerMillisecond);

    return opsPerMillisecond >= 250 ? PerformanceTier.high : PerformanceTier.medium;
  }

  Future<Duration> _measure() {
    return Future<Duration>.microtask(() {
      final watch = Stopwatch()..start();
      var acc = 0.0;
      for (var i = 0; i < _iterationCount; i++) {
        final seed = (i % 97) + 1;
        acc += sqrt(seed + acc * 0.0001);
        if (acc > 1000) {
          acc -= 1000;
        }
      }
      watch.stop();
      if (kDebugMode) {
        debugPrint('Performance benchmark accumulator: $acc');
      }
      return watch.elapsed;
    });
  }
}

class PerformanceTierController extends StateNotifier<PerformanceTier> {
  factory PerformanceTierController({
    required UserSettingsRepository repository,
    PerformanceBenchmarker? benchmarker,
  }) {
    final storedName = repository.readPerformanceTierName();
    final initialTier = _tierFromName(storedName);
    final hasStoredTier = storedName != null;
    return PerformanceTierController._(
      benchmarker ?? const PerformanceBenchmarker(),
      repository,
      initialTier,
      hasStoredTier,
    );
  }

  PerformanceTierController._(
    this._benchmarker,
    this._repository,
    PerformanceTier initialTier,
    this._hasStoredTier,
  ) : super(initialTier);

  static PerformanceTier _tierFromName(String? name) {
    if (name == null) {
      return PerformanceTier.high;
    }
    return PerformanceTier.values.firstWhere(
      (tier) => tier.name == name,
      orElse: () => PerformanceTier.high,
    );
  }

  final PerformanceBenchmarker _benchmarker;
  final UserSettingsRepository _repository;
  Future<void>? _initialization;
  bool _hasManualOverride = false;
  bool _hasStoredTier;

  Future<void> ensureInitialized() {
    if (_hasStoredTier) {
      return Future<void>.value();
    }
    return _initialization ??= _runBenchmark();
  }

  void overrideTier(PerformanceTier tier) {
    _hasManualOverride = true;
    _hasStoredTier = true;
    state = tier;
    unawaited(_repository.writePerformanceTierName(tier.name));
  }

  Future<void> clearManualOverride() async {
    _hasManualOverride = false;
    _hasStoredTier = false;
    _initialization = null;
    await _repository.clearPerformanceTier();
    await ensureInitialized();
  }

  Future<void> _runBenchmark() async {
    if (_hasManualOverride || _hasStoredTier) {
      return;
    }
    try {
      final tier = await _benchmarker.detectTier();
      if (_hasManualOverride) {
        return;
      }
      state = tier;
      _hasStoredTier = true;
      await _repository.writePerformanceTierName(tier.name);
    } on Object catch (error, stackTrace) {
      if (kDebugMode) {
        debugPrint('Performance benchmark failed: $error\n$stackTrace');
      }
    }
  }
}

final performanceTierProvider =
    StateNotifierProvider<PerformanceTierController, PerformanceTier>(
      (ref) {
        final repository = ref.watch(userSettingsRepositoryProvider);
        final controller = PerformanceTierController(repository: repository);
        unawaited(controller.ensureInitialized());
        return controller;
      },
    );
