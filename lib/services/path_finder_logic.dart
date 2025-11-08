import 'package:tamanavi_app/models/building_snapshot.dart';
import 'package:tamanavi_app/models/element_data_models.dart';

class _AStarNode {
  final String id;
  double fScore;

  _AStarNode({required this.id, required this.fScore});
}

class Pathfinder {
  static const double _floorChangeCost = 1.0;

  double _heuristic(CachedSData a, CachedSData b) {
    final posDistance = (a.position - b.position).distance;
    final floorDistance = (a.floor - b.floor).abs() * _floorChangeCost;
    return posDistance + floorDistance;
  }

  double _distanceBetween(CachedSData a, CachedSData b) {
    return _heuristic(a, b);
  }

  CachedSData _findClosestGraphNode(
    List<CachedSData> allGraphNodes,
    CachedSData targetRoom,
  ) {
    Iterable<CachedSData> nodesOnSameFloor = allGraphNodes.where(
      (node) => node.floor == targetRoom.floor,
    );

    if (nodesOnSameFloor.isEmpty) {
      nodesOnSameFloor = allGraphNodes;
    }

    CachedSData? closestNode;
    double minDistance = double.infinity;

    for (final node in nodesOnSameFloor) {
      final dist = _heuristic(node, targetRoom);
      if (dist < minDistance) {
        minDistance = dist;
        closestNode = node;
      }
    }
    return closestNode!;
  }

  Iterable<String> _getNeighbors(BuildingSnapshot snapshot, String nodeId) {
    final neighbors = <String>{};
    for (final pData in snapshot.passages) {
      for (final edge in pData.edges) {
        if (edge.contains(nodeId)) {
          neighbors.addAll(edge.where((id) => id != nodeId));
        }
      }
    }
    return neighbors;
  }

  List<CachedSData> findPathFromSnapshot(
    BuildingSnapshot snapshot,
    String startNodeId,
    String targetRoomId,
  ) {
    final allGraphNodes = snapshot.elements
        .where((e) => e.type.isGraphNode)
        .toList();
    final nodeMap = {for (var n in allGraphNodes) n.id: n};

    final startNode = nodeMap[startNodeId];
    CachedSData? targetRoom;
    for (final e in snapshot.elements) {
      if (e.id == targetRoomId) {
        targetRoom = e;
        break;
      }
    }

    if (startNode == null || targetRoom == null) {
      return [];
    }

    final CachedSData aStarTargetNode = targetRoom.type.isGraphNode
        ? targetRoom
        : _findClosestGraphNode(allGraphNodes, targetRoom);

    final openSet = <_AStarNode>[];
    final closedSet = <String>{};
    final cameFrom = <String, String>{};
    final gScores = <String, double>{startNode.id: 0};
    final fScores = <String, double>{
      startNode.id: _heuristic(startNode, aStarTargetNode),
    };

    openSet.add(_AStarNode(id: startNode.id, fScore: fScores[startNode.id]!));

    while (openSet.isNotEmpty) {
      openSet.sort((a, b) => a.fScore.compareTo(b.fScore));
      final current = openSet.removeAt(0);
      final currentNode = nodeMap[current.id]!;

      if (current.id == aStarTargetNode.id) {
        return _reconstructPath(cameFrom, current.id, nodeMap, targetRoom);
      }

      closedSet.add(current.id);

      for (final neighborId in _getNeighbors(snapshot, current.id)) {
        if (closedSet.contains(neighborId) ||
            !nodeMap.containsKey(neighborId)) {
          continue;
        }

        final neighborNode = nodeMap[neighborId]!;
        final tentativeGScore =
            gScores[current.id]! + _distanceBetween(currentNode, neighborNode);

        if (tentativeGScore < (gScores[neighborId] ?? double.infinity)) {
          cameFrom[neighborId] = current.id;
          gScores[neighborId] = tentativeGScore;
          fScores[neighborId] =
              tentativeGScore + _heuristic(neighborNode, aStarTargetNode);

          if (!openSet.any((node) => node.id == neighborId)) {
            openSet.add(
              _AStarNode(id: neighborId, fScore: fScores[neighborId]!),
            );
          }
        }
      }
    }

    return [];
  }

  List<CachedSData> _reconstructPath(
    Map<String, String> cameFrom,
    String currentId,
    Map<String, CachedSData> nodeMap,
    CachedSData targetRoom,
  ) {
    final pathNodes = <CachedSData>[];
    String current = currentId;

    while (true) {
      final node = nodeMap[current];
      if (node != null) {
        pathNodes.add(node);
      }
      final next = cameFrom[current];
      if (next == null) break;
      current = next;
    }

    final orderedPath = pathNodes.reversed.toList();
    if (orderedPath.isEmpty || orderedPath.last.id != targetRoom.id) {
      orderedPath.add(targetRoom);
    }

    return orderedPath;
  }
}
