import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/settings_provider.dart';
import 'hub_screen.dart';

class MainMenuScreen extends ConsumerWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A0E),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.public, size: 80, color: Color(0xFFD8A93A)),
            const SizedBox(height: 20),
            const Text(
              'DARK ANGELS',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: 8.0,
              ),
            ),
            const Text(
              'CRUSADE COMMAND',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: Color(0xFFB9C3CC),
                letterSpacing: 4.0,
              ),
            ),
            const SizedBox(height: 80),
            _MenuButton(
              label: 'START CAMPAIGN',
              onTap: () {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const HubScreen()),
                );
              },
            ),
            const SizedBox(height: 16),
            _MenuButton(
              label: 'SETTINGS',
              onTap: () => _showSettingsDialog(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context, WidgetRef ref) {
    showDialog(context: context, builder: (ctx) => const SettingsDialog());
  }
}

class _MenuButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;

  const _MenuButton({required this.label, required this.onTap});

  @override
  State<_MenuButton> createState() => _MenuButtonState();
}

class _MenuButtonState extends State<_MenuButton> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _isHovering
                ? const Color(0xFFD8A93A)
                : const Color(0xFF101820),
            border: Border.all(color: const Color(0xFFD8A93A), width: 2),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            widget.label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              letterSpacing: 2.0,
              color: _isHovering
                  ? const Color(0xFF070A0E)
                  : const Color(0xFFD8A93A),
            ),
          ),
        ),
      ),
    );
  }
}

class SettingsDialog extends ConsumerWidget {
  const SettingsDialog({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return AlertDialog(
      backgroundColor: const Color(0xFF101820),
      title: const Text(
        'SETTINGS',
        style: TextStyle(color: Color(0xFFD8A93A), fontWeight: FontWeight.bold),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Difficulty', style: TextStyle(color: Colors.white)),
          const SizedBox(height: 8),
          SegmentedButton<Difficulty>(
            segments: const [
              ButtonSegment(value: Difficulty.easy, label: Text('Easy')),
              ButtonSegment(value: Difficulty.normal, label: Text('Normal')),
              ButtonSegment(value: Difficulty.hard, label: Text('Hard')),
            ],
            selected: {settings.difficulty},
            onSelectionChanged: (set) {
              ref.read(settingsProvider.notifier).setDifficulty(set.first);
            },
            style: SegmentedButton.styleFrom(
              backgroundColor: const Color(0xFF070A0E),
              foregroundColor: Colors.white,
              selectedForegroundColor: Colors.black,
              selectedBackgroundColor: const Color(0xFFD8A93A),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'CLOSE',
            style: TextStyle(color: Color(0xFFD8A93A)),
          ),
        ),
      ],
    );
  }
}
