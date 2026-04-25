import 'package:flutter_riverpod/flutter_riverpod.dart';

enum Difficulty { easy, normal, hard }

class SettingsState {
  final Difficulty difficulty;
  final double volume;

  const SettingsState({required this.difficulty, required this.volume});

  SettingsState copyWith({Difficulty? difficulty, double? volume}) {
    return SettingsState(
      difficulty: difficulty ?? this.difficulty,
      volume: volume ?? this.volume,
    );
  }
}

class SettingsNotifier extends Notifier<SettingsState> {
  @override
  SettingsState build() {
    return const SettingsState(difficulty: Difficulty.normal, volume: 1.0);
  }

  void setDifficulty(Difficulty diff) {
    state = state.copyWith(difficulty: diff);
  }

  void setVolume(double vol) {
    state = state.copyWith(volume: vol);
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, SettingsState>(() {
  return SettingsNotifier();
});
