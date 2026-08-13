// Widget tests for LifeLoop.
//
// The full app requires Firebase initialisation, so these tests cover the
// pure presentation widgets that carry the alert-severity logic.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:disaster_alert_system/theme/app_theme.dart';
import 'package:disaster_alert_system/widgets/severity_badge.dart';

void main() {
  testWidgets('SeverityBadge renders the severity label in upper case', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SeverityBadge(severity: 'critical')),
      ),
    );

    expect(find.text('CRITICAL'), findsOneWidget);
  });

  test('severityColor maps each level to a distinct colour', () {
    final colors = {
      severityColor('low'),
      severityColor('moderate'),
      severityColor('high'),
      severityColor('critical'),
    };

    expect(colors.length, 4);
  });

  test('severityColor is case insensitive', () {
    expect(severityColor('CRITICAL'), severityColor('critical'));
  });
}
