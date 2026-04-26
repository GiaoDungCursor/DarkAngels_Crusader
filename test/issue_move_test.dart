import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_code/models/grid_position.dart';
import 'package:game_code/providers/game_state_provider.dart';

void main() {
  test('issueMove adjacent tile', () {
    final container = ProviderContainer();
    final notifier = container.read(gameStateProvider.notifier);
    
    // Start mission
    notifier.startMission(0);
    var state = container.read(gameStateProvider);
    
    // Find adjacent reachable tile
    final target = const GridPosition(1, 7);
    
    // Attempt move
    notifier.setActionMode(ActionMode.move);
    notifier.handleTileTap(target);
    state = container.read(gameStateProvider);
    
    expect(state.squad[0].gridPosition, target);
  });
}
