import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flame/effects.dart';
import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/animation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/grid_position.dart';
import '../providers/game_state_provider.dart';
import 'components/bullet_component.dart';
import 'components/cover_component.dart';
import 'components/drop_pod_component.dart';
import 'components/enemy_base_component.dart';
import 'components/enemy_component.dart';
import 'components/grid_overlay_component.dart';
import 'components/marine_component.dart';

class CrusadeGame extends FlameGame {
  CrusadeGame(this.ref);

  static const double tileSize = 64;
  static final Vector2 boardOrigin = Vector2.zero();

  final WidgetRef ref;

  GameState get gameState => ref.read(gameStateProvider);

  late SpriteComponent _background;
  late GridOverlayComponent _gridOverlay;
  int _lastRevision = -1;
  String _lastCoverKey = '';
  bool _audioReady = false;
  bool _bgmStarted = false;

  final Map<int, MarineComponent> _marineComponents = {};
  final Map<String, EnemyComponent> _enemyComponents = {};
  final Map<GridPosition, EnemyBaseComponent> _baseComponents = {};
  final List<CoverComponent> _coverComponents = [];

  bool _cutsceneActive = false;
  bool _hasTriggeredDeployment = false;
  bool _hasSpawnedDropPod = false;
  bool get isCutsceneActive => _cutsceneActive;

  bool _isFullyLoaded = false;
  bool get isFullyLoaded => _isFullyLoaded;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    await _loadAudio();

    final state = ref.read(gameStateProvider);
    final mapSprite = await loadSprite(state.map.background);
    _background = SpriteComponent(
      sprite: mapSprite,
      size: Vector2(state.map.width * tileSize, state.map.height * tileSize),
      priority: 0,
    );
    world.add(_background);

    _gridOverlay = GridOverlayComponent()..priority = 1;
    world.add(_gridOverlay);

    // Don't sync yet - wait for startMission to be called from CommandScreen
    _isFullyLoaded = true;
  }

  Future<void> changeBackground(String imageName) async {
    final mapSprite = await loadSprite(imageName);
    _background.sprite = mapSprite;
  }

  Vector2 gridToWorld(GridPosition tile) {
    return Vector2(
      boardOrigin.x + tile.x * tileSize + tileSize / 2,
      boardOrigin.y + tile.y * tileSize + tileSize / 2,
    );
  }

  Vector2 gridToTileTopLeft(GridPosition tile) {
    return Vector2(
      boardOrigin.x + tile.x * tileSize,
      boardOrigin.y + tile.y * tileSize,
    );
  }

  GridPosition? worldToGrid(Vector2 worldPosition) {
    final local = worldPosition - boardOrigin;
    final x = local.x ~/ tileSize;
    final y = local.y ~/ tileSize;
    final tile = GridPosition(x, y);
    return ref.read(gameStateProvider).isInside(tile) ? tile : null;
  }

  void panCamera(Vector2 delta) {
    camera.viewfinder.position += delta / camera.viewfinder.zoom;
  }

  void zoomCamera(double delta) {
    camera.viewfinder.zoom = (camera.viewfinder.zoom + delta).clamp(0.55, 2.2);
  }

  void selectMarine(int index) {
    ref.read(gameStateProvider.notifier).selectMarine(index);
    _playSfx('select.wav');
    _syncFromState(force: true);
  }

  void handleTileTap(GridPosition tile) {
    final before = ref.read(gameStateProvider);
    final mode = before.actionMode;
    final selectedIndex = before.selectedMarineIndex;
    final attacker = before.selectedMarine;
    final targetEnemyIndex = before.enemyAt(tile);
    ref.read(gameStateProvider.notifier).handleTileTap(tile);
    if (mode == ActionMode.move) {
      _playSfx('move.wav');
    } else if (mode == ActionMode.deployReserve) {
      _playSfx('turn.wav');
    } else if (mode == ActionMode.shoot ||
        mode == ActionMode.melee ||
        mode == ActionMode.ability) {
      _playSfx('attack.wav');
      _marineComponents[selectedIndex]?.pulseAttack();
      if (attacker != null &&
          mode != ActionMode.melee &&
          (targetEnemyIndex != -1 || mode == ActionMode.ability)) {
        _spawnProjectile(attacker.gridPosition, tile);
      }
      if (targetEnemyIndex != -1) {
        final targetEnemy = before.enemies[targetEnemyIndex];
        _enemyComponents[targetEnemy.id]?.pulseHit();
      }
    }
    _syncFromState(force: true);
  }

  void attackEnemy(String enemyId) {
    final state = ref.read(gameStateProvider);
    final enemyIndex = state.enemies.indexWhere((enemy) => enemy.id == enemyId);
    if (enemyIndex == -1) return;
    final enemy = state.enemies[enemyIndex];
    ref.read(gameStateProvider.notifier).handleTileTap(enemy.position);
    _playSfx('attack.wav');
    _enemyComponents[enemyId]?.pulseHit();
    _marineComponents[state.selectedMarineIndex]?.pulseAttack();
    _spawnProjectile(state.selectedMarine!.gridPosition, enemy.position);
    _syncFromState(force: true);
  }

  void addRequisitionPoints(int amount) {
    ref.read(gameStateProvider.notifier).addRP(amount);
  }

  void playTurnCue() {
    _playSfx('turn.wav');
  }

  void _spawnProjectile(GridPosition from, GridPosition to) {
    final start = gridToWorld(from);
    final target = gridToWorld(to);
    world.add(
      BulletComponent(position: start, target: target, damage: 0)..priority = 6,
    );
  }

  @override
  void update(double dt) {
    super.update(dt);
    if (!_isFullyLoaded) return;

    Future.microtask(() {
      final state = ref.read(gameStateProvider);
      if (state.activationPhase == ActivationPhase.marines &&
          !_hasTriggeredDeployment) {
        _hasTriggeredDeployment = true;
        _cutsceneActive = true;

        final dropZone = state.selectedDropZones.isNotEmpty
            ? state.selectedDropZones.first
            : (state.squad.isNotEmpty ? state.squad.first.gridPosition : null);
        final dropFocus = dropZone == null
            ? _mapCenter(state)
            : gridToWorld(dropZone);

        camera.viewfinder.add(
          MoveEffect.to(
            dropFocus,
            EffectController(duration: 1.15, curve: Curves.easeOutCubic),
            onComplete: () {
              _cutsceneActive = false;
            },
          ),
        );
        camera.viewfinder.add(
          ScaleEffect.to(
            Vector2.all(1.15),
            EffectController(duration: 1.7, curve: Curves.easeOutCubic),
          ),
        );
      }

      ref.read(gameStateProvider.notifier).tickSimulation(dt);
      _syncFromState();
    });
  }

  void _syncFromState({bool force = false}) {
    if (!_isFullyLoaded) return;
    final state = ref.read(gameStateProvider);
    if (!force && state.revision == _lastRevision) return;
    _lastRevision = state.revision;
    _gridOverlay.state = state;
    _gridOverlay.size = Vector2(
      state.map.width * tileSize,
      state.map.height * tileSize,
    );
    _background.size = Vector2(
      state.map.width * tileSize,
      state.map.height * tileSize,
    );

    _syncCover(state);
    _syncBases(state);
    _syncMarines(state);
    _syncEnemies(state);
  }

  void _syncBases(GameState state) {
    // Remove destroyed bases
    final staleBases = _baseComponents.keys
        .where((pos) => !state.activeEnemyBases.contains(pos))
        .toList();
    for (final pos in staleBases) {
      _baseComponents.remove(pos)?.destroyBase();
    }

    // Add new or update existing bases
    for (final pos in state.activeEnemyBases) {
      final component = _baseComponents[pos];
      if (component == null) {
        final newComponent = EnemyBaseComponent(gridPosition: pos)
          ..priority = 2;
        _baseComponents[pos] = newComponent;
        world.add(newComponent);
      }

      // If a bomb is planted, show the indicator
      if (state.plantedBombs.containsKey(pos)) {
        _baseComponents[pos]?.showPlantedBomb();
      }
    }
  }

  void _syncCover(GameState state) {
    final coverKey = state.coverTiles.map((tile) => '$tile').join(',');
    if (_lastCoverKey == coverKey) return;
    _lastCoverKey = coverKey;
    for (final component in _coverComponents) {
      component.removeFromParent();
    }
    _coverComponents.clear();
    for (final tile in state.coverTiles) {
      final component = CoverComponent(gridPosition: tile)..priority = 2;
      _coverComponents.add(component);
      world.add(component);
    }
  }

  void _syncMarines(GameState state) {
    // Determine if this is the initial deployment drop (all marines are new)
    final isInitialDrop = _marineComponents.isEmpty && state.squad.isNotEmpty;
    final initialDropZone = state.selectedDropZones.isNotEmpty
        ? state.selectedDropZones.first
        : (state.squad.isNotEmpty ? state.squad.first.gridPosition : null);
    final initialDropWorld = initialDropZone == null
        ? null
        : gridToWorld(initialDropZone);

    // Add any new marine components (hidden initially during drop pod animation)
    for (var i = 0; i < state.squad.length; i++) {
      final marine = state.squad[i];
      final component = _marineComponents[i];
      if (component == null) {
        final newComponent = MarineComponent(
          index: i,
          marine: marine,
          position: isInitialDrop && initialDropWorld != null
              ? initialDropWorld.clone()
              : gridToWorld(marine.gridPosition),
        )..priority = 4;
        _marineComponents[i] = newComponent;
        world.add(newComponent);
        if (!isInitialDrop) {
          newComponent.sync(marine, selected: i == state.selectedMarineIndex);
        }
        // Hide all marines initially – they reveal on pod landing
        if (isInitialDrop) newComponent.opacity = 0;
      } else {
        component.sync(marine, selected: i == state.selectedMarineIndex);
      }
    }

    // Spawn exactly ONE drop pod at the selectedDropZone (or squad leader position)
    // only on the very first sync where marines appear.
    if (isInitialDrop && !_hasSpawnedDropPod) {
      _hasSpawnedDropPod = true;
      final dropZone = initialDropZone;

      if (dropZone != null) {
        final pod = DropPodComponent(
          gridPosition: dropZone,
          targetPosition: gridToWorld(dropZone),
          onLanded: () {
            // Reveal marines at the pod, then animate them out to their
            // planned insertion tiles.
            for (var i = 0; i < state.squad.length; i++) {
              final component = _marineComponents[i];
              if (component == null) continue;
              component.opacity = 1.0;
              component.sync(
                state.squad[i],
                selected: i == state.selectedMarineIndex,
              );
            }
          },
        )..priority = 5;
        world.add(pod);
      } else {
        // No drop zone – reveal marines immediately
        for (final c in _marineComponents.values) {
          c.opacity = 1.0;
        }
      }
    }
  }

  void _syncEnemies(GameState state) {
    final activeIds = state.enemies.map((enemy) => enemy.id).toSet();
    final staleIds = _enemyComponents.keys
        .where((enemyId) => !activeIds.contains(enemyId))
        .toList();
    for (final enemyId in staleIds) {
      _enemyComponents.remove(enemyId)?.removeFromParent();
    }

    for (final enemy in state.enemies) {
      final component = _enemyComponents[enemy.id];
      if (component == null) {
        final newComponent = EnemyComponent(
          enemyId: enemy.id,
          enemy: enemy,
          position: gridToWorld(enemy.position),
        )..priority = 3;
        _enemyComponents[enemy.id] = newComponent;
        world.add(newComponent);
      } else {
        component.sync(enemy);
      }
    }
  }

  Future<void> _loadAudio() async {
    try {
      await FlameAudio.audioCache.loadAll([
        'select.wav',
        'move.wav',
        'attack.wav',
        'turn.wav',
        'ambient.wav',
      ]);
      _audioReady = true;
      FlameAudio.bgm.initialize();
      try {
        await FlameAudio.bgm.play('ambient.wav', volume: 0.12);
        _bgmStarted = true;
      } catch (_) {
        _bgmStarted = false;
      }
    } catch (_) {
      _audioReady = false;
    }
  }

  void _playSfx(String fileName) {
    if (!_audioReady) return;
    if (!_bgmStarted) {
      FlameAudio.bgm
          .play('ambient.wav', volume: 0.12)
          .then((_) {
            _bgmStarted = true;
          })
          .catchError((_) {
            _bgmStarted = false;
          });
    }
    FlameAudio.play(fileName, volume: 0.55);
  }

  /// Called from CommandScreen after startMission() updates the state.
  /// Clears all existing entity components and re-syncs from scratch.
  void resetWorld() {
    // Clear all existing unit components
    for (final c in _marineComponents.values) {
      c.removeFromParent();
    }
    _marineComponents.clear();
    for (final c in _enemyComponents.values) {
      c.removeFromParent();
    }
    _enemyComponents.clear();
    for (final c in _baseComponents.values) {
      c.removeFromParent();
    }
    _baseComponents.clear();
    for (final c in _coverComponents) {
      c.removeFromParent();
    }
    _coverComponents.clear();
    _lastCoverKey = '';
    _lastRevision = -1;
    _hasTriggeredDeployment = false;
    _hasSpawnedDropPod = false;

    final state = ref.read(gameStateProvider);

    // Update background to match new map
    _background.size = Vector2(
      state.map.width * tileSize,
      state.map.height * tileSize,
    );

    final dropZone = state.selectedDropZones.isNotEmpty
        ? state.selectedDropZones.first
        : (state.squad.isNotEmpty ? state.squad.first.gridPosition : null);
    final centerPos = dropZone == null
        ? _mapCenter(state)
        : gridToWorld(dropZone);

    // Start wide above the insertion point so the player sees the orbital
    // impact before the camera settles into command zoom.
    camera.viewfinder.position = Vector2(centerPos.x, centerPos.y - 420);
    camera.viewfinder.zoom = 0.55;

    // Now sync all components from the fresh state
    _syncFromState(force: true);
  }

  Vector2 _mapCenter(GameState state) {
    return Vector2(
      state.map.width * tileSize / 2,
      state.map.height * tileSize / 2,
    );
  }
}
