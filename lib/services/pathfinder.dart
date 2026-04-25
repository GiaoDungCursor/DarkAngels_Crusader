import 'dart:collection';
import 'dart:math';

import '../models/grid_position.dart';
import '../models/tactical_map.dart';

class Pathfinder {
  const Pathfinder();

  List<GridPosition> findPath({
    required TacticalMap map,
    required GridPosition start,
    required GridPosition goal,
    required Set<GridPosition> blockers,
  }) {
    if (start == goal) return [start];
    if (!map.isWalkable(start) ||
        !map.isWalkable(goal) ||
        blockers.contains(goal)) {
      return const [];
    }

    final open = <GridPosition>[start];
    final cameFrom = <GridPosition, GridPosition>{};
    final gScore = <GridPosition, int>{start: 0};
    final fScore = <GridPosition, int>{start: start.distanceTo(goal)};

    while (open.isNotEmpty) {
      open.sort((a, b) => (fScore[a] ?? 9999).compareTo(fScore[b] ?? 9999));
      final current = open.removeAt(0);
      if (current == goal) {
        return _reconstruct(cameFrom, current);
      }

      for (final neighbor in current.neighbors()) {
        if (!map.isWalkable(neighbor) || blockers.contains(neighbor)) continue;
        final tentative = (gScore[current] ?? 9999) + 1;
        if (tentative >= (gScore[neighbor] ?? 9999)) continue;
        cameFrom[neighbor] = current;
        gScore[neighbor] = tentative;
        fScore[neighbor] = tentative + neighbor.distanceTo(goal);
        if (!open.contains(neighbor)) open.add(neighbor);
      }
    }

    return const [];
  }

  Set<GridPosition> reachable({
    required TacticalMap map,
    required GridPosition start,
    required int maxSteps,
    required Set<GridPosition> blockers,
  }) {
    final visited = <GridPosition>{start};
    final result = <GridPosition>{};
    final queue = Queue<(GridPosition, int)>()..add((start, 0));

    while (queue.isNotEmpty) {
      final (tile, steps) = queue.removeFirst();
      if (steps >= maxSteps) continue;
      for (final next in tile.neighbors()) {
        if (!map.isWalkable(next) ||
            visited.contains(next) ||
            blockers.contains(next)) {
          continue;
        }
        visited.add(next);
        result.add(next);
        queue.add((next, steps + 1));
      }
    }

    return result;
  }

  bool hasLineOfSight({
    required TacticalMap map,
    required GridPosition from,
    required GridPosition to,
  }) {
    final dx = to.x - from.x;
    final dy = to.y - from.y;
    final steps = max(dx.abs(), dy.abs());
    if (steps <= 1) return true;

    for (var i = 1; i < steps; i++) {
      final t = i / steps;
      final tile = GridPosition(
        (from.x + dx * t).round(),
        (from.y + dy * t).round(),
      );
      if (tile != from && tile != to && map.blocksLineOfSight(tile)) {
        return false;
      }
    }
    return true;
  }

  List<GridPosition> _reconstruct(
    Map<GridPosition, GridPosition> cameFrom,
    GridPosition current,
  ) {
    final path = <GridPosition>[current];
    while (cameFrom.containsKey(current)) {
      current = cameFrom[current]!;
      path.insert(0, current);
    }
    return path;
  }
}
