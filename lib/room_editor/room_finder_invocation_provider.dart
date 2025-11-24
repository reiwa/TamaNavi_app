import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/legacy.dart';

@immutable
class RoomFinderInvocationState {
  const RoomFinderInvocationState({this.navigateFrom, this.navigateTo});

  final String? navigateFrom;
  final String? navigateTo;

  RoomFinderInvocationState copyWith({
    String? navigateFrom,
    String? navigateTo,
  }) {
    return RoomFinderInvocationState(
      navigateFrom: navigateFrom ?? this.navigateFrom,
      navigateTo: navigateTo ?? this.navigateTo,
    );
  }

  bool get hasAny => navigateFrom != null || navigateTo != null;
}

final roomFinderInvocationProvider = StateProvider<RoomFinderInvocationState>(
  (ref) => const RoomFinderInvocationState(),
);

extension RoomFinderInvocationController
    on StateController<RoomFinderInvocationState> {
  void setNavigateFrom(String value) {
    state = state.copyWith(navigateFrom: value);
  }

  void setNavigateTo(String value) {
    state = state.copyWith(navigateTo: value);
  }

  void clearNavigateFrom() {
    if (state.navigateFrom != null) {
      state = state.copyWith();
    }
  }

  void clearNavigateTo() {
    if (state.navigateTo != null) {
      state = state.copyWith();
    }
  }

  void clear() {
    if (state.hasAny) {
      state = const RoomFinderInvocationState();
    }
  }
}
