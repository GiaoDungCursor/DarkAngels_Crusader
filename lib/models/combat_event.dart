class CombatEvent {
  const CombatEvent(this.message, {this.important = false});

  final String message;
  final bool important;
}
