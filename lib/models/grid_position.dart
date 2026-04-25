class GridPosition {
  const GridPosition(this.x, this.y);

  final int x;
  final int y;

  int distanceTo(GridPosition other) {
    return (x - other.x).abs() + (y - other.y).abs();
  }

  Iterable<GridPosition> neighbors() sync* {
    yield GridPosition(x + 1, y);
    yield GridPosition(x - 1, y);
    yield GridPosition(x, y + 1);
    yield GridPosition(x, y - 1);
  }

  @override
  bool operator ==(Object other) {
    return other is GridPosition && other.x == x && other.y == y;
  }

  @override
  int get hashCode => Object.hash(x, y);

  @override
  String toString() => '$x-$y';
}
