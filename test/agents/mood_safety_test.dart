import 'package:flutter_application_1/agents/mood_safety_gate.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MoodClassification.safe() returns non-distress default', () {
    final m = MoodClassification.safe();
    expect(m.isDistress, false);
    expect(m.severity, 'low');
    expect(m.response, '');
  });

  test('toMap exposes helpline + is_distress + severity', () {
    final m = MoodClassification(
      isDistress: true,
      severity: 'high',
      response: 'I hear you.',
    );
    final map = m.toMap();
    expect(map['is_distress'], true);
    expect(map['severity'], 'high');
    expect(map['response'], 'I hear you.');
    expect(map['helpline'], isNotNull);
    expect((map['helpline'] as String).isNotEmpty, true);
  });
}
