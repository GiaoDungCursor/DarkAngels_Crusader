import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:game_code/models/mission.dart';
import 'package:game_code/models/tactical_map.dart';
import 'package:game_code/screens/command_screen.dart';

void main() {
  testWidgets('Crusade command screen renders tactical prototype', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final map = campaignMaps.first;
    final mission = Mission(
      map.name,
      map.subtitle,
      map.icon,
      map.control,
      map.threat,
      map.rewardRP,
    );
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: CommandScreen(mission: mission, missionIndex: 0),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Mission Control'), findsOneWidget);
    expect(find.text('PLANETFALL PROTOCOL INITIATED'), findsOneWidget);
    expect(find.text('CONFIRM DROP'), findsOneWidget);
  });
}
