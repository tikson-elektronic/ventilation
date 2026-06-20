import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:ventilation/models.dart';
import 'package:ventilation/theme.dart';
import 'package:ventilation/widgets/system_strip.dart';

void main() {
  test('VentStatus parses the documented /api/status shape', () {
    final status = VentStatus.fromJson({
      'link': 'Linked',
      'linked': true,
      'eStop': false,
      'status': 'NORMAL',
      'fault': false,
      'mainVoltage': 27.5,
      'temperature': 30.1,
      'totalAmps': 1.2,
      'secondsSinceGood': 0.0,
      'activePort': 'COM7',
      'channels': [
        {
          'id': 1,
          'name': 'FAN 1',
          'setpointPercent': 42,
          'forward': true,
          'power': true,
          'livePercent': 40,
          'state': 'Run',
          'rpm': 800,
          'amps': 1.2,
          'ratedRpm': 2000,
          'ratedAmps': 16,
          'accent': '#35d6c8',
        }
      ],
    });

    expect(status.link, LinkState.linked);
    expect(status.mainVoltage, 27.5);
    final ch = status.channel(1)!;
    expect(ch.name, 'FAN 1');
    expect(ch.isRunning, isTrue);
    expect(ch.accent, VentColors.ch1Cyan);
  });

  test('parseHexColor handles #rrggbb and bad input', () {
    expect(parseHexColor('#ffb13c'), const Color(0xFFFFB13C));
    expect(parseHexColor(null), isNull);
    expect(parseHexColor('nope'), isNull);
  });

  testWidgets('SystemStrip renders a parsed status', (tester) async {
    final status = VentStatus.fromJson({
      'link': 'Lost',
      'linked': false,
      'eStop': false,
      'status': '',
      'fault': false,
      'mainVoltage': null,
      'totalAmps': null,
      'channels': [
        {'id': 1, 'name': 'FAN 1', 'livePercent': 50, 'accent': '#35d6c8'},
      ],
    });
    await tester.pumpWidget(MaterialApp(theme: buildVentTheme(), home: Scaffold(body: SystemStrip(status: status))));
    expect(find.text('FAILSAFE (controller holding)'), findsOneWidget);
  });
}
