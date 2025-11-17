import 'dart:ui';

import 'package:tamanavi_app/models/element_data_models.dart';

CachedSData? findElementAtPosition(
  Offset position,
  Iterable<CachedSData> elements, {
  double radius = 12.0,
}) {
  for (final element in elements) {
    final distance = (position - element.position).distance;
    if (distance <= radius) {
      return element;
    }
  }
  return null;
}

bool canConnectNodes(CachedSData start, CachedSData tapped) {
  if (start.id == tapped.id) {
    return false;
  }

  final sameFloor = tapped.floor == start.floor;
  if (!sameFloor) {
    return start.type == PlaceType.elevator &&
        tapped.type == PlaceType.elevator;
  }

  final bool tappedIsConnectable = tapped.type.isGraphNode;
  final bool startIsSpecial =
      start.type == PlaceType.elevator || start.type == PlaceType.entrance;
  final bool tappedIsSpecial =
      tapped.type == PlaceType.elevator || tapped.type == PlaceType.entrance;

  final bool isProhibitedConnection = startIsSpecial && tappedIsSpecial;

  return tappedIsConnectable && !isProhibitedConnection;
}
