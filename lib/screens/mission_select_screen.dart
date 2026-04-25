import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/mission.dart';
import '../models/tactical_map.dart';
import '../widgets/ui_components.dart';
import 'mission_briefing_screen.dart';

class MissionSelectScreen extends StatefulWidget {
  const MissionSelectScreen({super.key});

  @override
  State<MissionSelectScreen> createState() => _MissionSelectScreenState();
}

class _MissionSelectScreenState extends State<MissionSelectScreen> {
  int missionIndex = 0;

  final List<Mission> missions = [
    for (final map in campaignMaps)
      Mission(
        map.name,
        map.subtitle,
        map.icon,
        map.control,
        map.threat,
        map.rewardRP,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF070A0E),
      appBar: AppBar(
        title: const Text(
          'Planetfall Coordinates',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: const Color(0xFF101820),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.travel_explore, color: Color(0xFFB9C3CC)),
            tooltip: 'Lore Database Search',
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  final controller = TextEditingController();
                  return AlertDialog(
                    backgroundColor: const Color(0xFF101820),
                    title: const Text(
                      'Lore Database Query',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: TextField(
                      controller: controller,
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Enter search term...',
                        hintStyle: TextStyle(color: Colors.white54),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFD8A93A)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFFFB15E)),
                        ),
                      ),
                      onSubmitted: (val) async {
                        Navigator.pop(context);
                        if (val.trim().isEmpty) return;
                        final url = Uri.parse(
                          'https://www.google.com/search?q=${Uri.encodeComponent(val)}',
                        );
                        if (await canLaunchUrl(url)) await launchUrl(url);
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'CANCEL',
                          style: TextStyle(color: Colors.white54),
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          if (controller.text.trim().isEmpty) return;
                          final url = Uri.parse(
                            'https://www.google.com/search?q=${Uri.encodeComponent(controller.text)}',
                          );
                          if (await canLaunchUrl(url)) await launchUrl(url);
                        },
                        child: const Text(
                          'SEARCH',
                          style: TextStyle(color: Color(0xFFD8A93A)),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF070A0E), Color(0xFF111922)],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 980;
              final list = _MissionList(
                missions: missions,
                selectedIndex: missionIndex,
                onSelected: (index) => setState(() => missionIndex = index),
              );
              final detail = _MissionDetail(
                mission: missions[missionIndex],
                map: campaignMaps[missionIndex],
                onDeploy: _deploy,
              );

              if (!wide) {
                return ListView(
                  children: [list, const SizedBox(height: 16), detail],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(width: 430, child: list),
                  const SizedBox(width: 18),
                  Expanded(child: detail),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  void _deploy() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MissionBriefingScreen(
          mission: missions[missionIndex],
          missionIndex: missionIndex,
        ),
      ),
    );
  }
}

class _MissionList extends StatelessWidget {
  const _MissionList({
    required this.missions,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<Mission> missions;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const HeaderCard(
            title: 'Drop Console',
            subtitle: 'Choose the next battlefield.',
            icon: Icons.public,
          ),
          const SizedBox(height: 16),
          Panel(
            title: 'Available Missions',
            child: Column(
              children: [
                for (var i = 0; i < missions.length; i++)
                  MissionTile(
                    mission: missions[i],
                    selected: i == selectedIndex,
                    onTap: () => onSelected(i),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Panel(
            title: 'Battle Rules',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _RuleLine(icon: Icons.open_with, text: 'Move up to 2 tiles.'),
                _RuleLine(icon: Icons.gps_fixed, text: 'Shoot up to 3 tiles.'),
                _RuleLine(
                  icon: Icons.hardware,
                  text: 'Melee adjacent enemies.',
                ),
                _RuleLine(
                  icon: Icons.shield,
                  text: 'Cover blocks movement and line of sight.',
                ),
                _RuleLine(
                  icon: Icons.mouse,
                  text: 'Mouse wheel zooms the battlefield.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MissionDetail extends StatelessWidget {
  const _MissionDetail({
    required this.mission,
    required this.map,
    required this.onDeploy,
  });

  final Mission mission;
  final TacticalMap map;
  final VoidCallback onDeploy;

  @override
  Widget build(BuildContext context) {
    return Panel(
      title: mission.name,
      action: Text(
        '${mission.threat}% THREAT',
        style: const TextStyle(
          color: Color(0xFFFFB15E),
          fontWeight: FontWeight.w900,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 21 / 9,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/images/${map.background}',
                    fit: BoxFit.cover,
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.62),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 18,
                    right: 18,
                    bottom: 18,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Text(
                            mission.subtitle,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w900,
                              fontSize: 20,
                              shadows: [
                                Shadow(color: Colors.black87, blurRadius: 4),
                              ],
                            ),
                          ),
                        ),
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: () async {
                              final query = '${mission.subtitle} Warhammer 40k';
                              final url = Uri.parse(
                                'https://www.google.com/search?q=${Uri.encodeComponent(query)}',
                              );
                              if (await canLaunchUrl(url)) await launchUrl(url);
                            },
                            borderRadius: BorderRadius.circular(20),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(
                                Icons.info_outline,
                                color: Color(0xFFD8A93A),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: StatRow(
                  'Control',
                  '${mission.control}%',
                  mission.control / 100,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: StatRow(
                  'Reward',
                  '${mission.rewardRP} RP',
                  mission.rewardRP / 250,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: SizedBox(
              width: 260,
              child: FilledButton.icon(
                onPressed: onDeploy,
                icon: const Icon(Icons.flight_land),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'INITIATE DROP',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF9A3232),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RuleLine extends StatelessWidget {
  const _RuleLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFFD8A93A)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFB9C3CC),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
