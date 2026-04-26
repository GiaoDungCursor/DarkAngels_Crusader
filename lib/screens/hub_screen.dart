import 'package:flutter/material.dart';

import 'armory_screen.dart';
import 'mission_select_screen.dart';

class HubScreen extends StatelessWidget {
  const HubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final mapper = _CoverImageMapper(
            viewport: Size(constraints.maxWidth, constraints.maxHeight),
            source: const Size(1024, 1024),
          );

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset('assets/images/backgrounds/hub_spaceship.png', fit: BoxFit.cover),
              _ImageAnchoredZone(
                mapper: mapper,
                sourceRect: const Rect.fromLTWH(260, 575, 405, 155),
                child: InteractiveZone(
                  title: 'TACTICAL TABLE',
                  subtitle: 'Select Mission',
                  icon: Icons.public,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const MissionSelectScreen(),
                      ),
                    );
                  },
                ),
              ),
              _ImageAnchoredZone(
                mapper: mapper,
                sourceRect: const Rect.fromLTWH(735, 330, 250, 350),
                child: InteractiveZone(
                  title: 'ARMORY',
                  subtitle: 'Upgrade Squad',
                  icon: Icons.shield,
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) =>
                          const ArmoryScreen(selectedMarineIndex: 0),
                    );
                  },
                ),
              ),
              Positioned(
                top: 20,
                left: 20,
                child: IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.white,
                    size: 30,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              const Positioned(left: 28, bottom: 28, child: _HubHelpCard()),
            ],
          );
        },
      ),
    );
  }
}

class _CoverImageMapper {
  const _CoverImageMapper({required this.viewport, required this.source});

  final Size viewport;
  final Size source;

  double get scale {
    return (viewport.width / source.width > viewport.height / source.height)
        ? viewport.width / source.width
        : viewport.height / source.height;
  }

  Offset get offset {
    final painted = Size(source.width * scale, source.height * scale);
    return Offset(
      (viewport.width - painted.width) / 2,
      (viewport.height - painted.height) / 2,
    );
  }

  Rect map(Rect sourceRect) {
    final topLeft =
        offset + Offset(sourceRect.left * scale, sourceRect.top * scale);
    return Rect.fromLTWH(
      topLeft.dx,
      topLeft.dy,
      sourceRect.width * scale,
      sourceRect.height * scale,
    );
  }
}

class _ImageAnchoredZone extends StatelessWidget {
  const _ImageAnchoredZone({
    required this.mapper,
    required this.sourceRect,
    required this.child,
  });

  final _CoverImageMapper mapper;
  final Rect sourceRect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final rect = mapper.map(sourceRect);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: child,
    );
  }
}

class _HubHelpCard extends StatelessWidget {
  const _HubHelpCard();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xDD0A1017),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF31404C)),
      ),
      child: const Padding(
        padding: EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'STRATEGIUM',
              style: TextStyle(
                color: Color(0xFFD8A93A),
                fontWeight: FontWeight.w900,
                letterSpacing: 1.2,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Click the tactical table to deploy.\nClick the armory door to upgrade the squad.',
              style: TextStyle(
                color: Color(0xFFB9C3CC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class InteractiveZone extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const InteractiveZone({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  @override
  State<InteractiveZone> createState() => _InteractiveZoneState();
}

class _InteractiveZoneState extends State<InteractiveZone> {
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
          decoration: BoxDecoration(
            color: const Color(
              0xFFD8A93A,
            ).withValues(alpha: _isHovering ? 0.30 : 0.14),
            border: Border.all(
              color: const Color(
                0xFFD8A93A,
              ).withValues(alpha: _isHovering ? 1.0 : 0.65),
              width: _isHovering ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(4),
            boxShadow: _isHovering
                ? [
                    BoxShadow(
                      color: const Color(0xFFD8A93A).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 5,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: const Color(0xFFD8A93A).withValues(alpha: 0.22),
                      blurRadius: 18,
                      spreadRadius: 2,
                    ),
                  ],
          ),
          child: Center(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 200),
              scale: _isHovering ? 1.04 : 1.0,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xCC0A1017),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: const Color(0xFFD8A93A)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(widget.icon, color: const Color(0xFFD8A93A)),
                    const SizedBox(width: 10),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 18,
                            letterSpacing: 1.2,
                          ),
                        ),
                        Text(
                          widget.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFD8A93A),
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
