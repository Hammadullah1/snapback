import 'package:flutter_application_1/agents/reflection_agent.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback gives sage emoji when high completion', () {
    final r = ReflectionResult.fallback(5, 5, 3);
    expect(r.moodEmoji.isNotEmpty, true);
    expect(r.reflection.length, 3);
    expect(r.streakMessage.contains('3'), true);
  });

  test('fallback handles zero planned without divide-by-zero', () {
    final r = ReflectionResult.fallback(0, 0, 0);
    expect(r.reflection.length, 3);
    expect(r.streakMessage, contains('Tomorrow'));
  });

  test('fallback streak message uses singular for 1 day', () {
    final r = ReflectionResult.fallback(2, 3, 1);
    expect(r.streakMessage, contains('1 day '));
  });

  test('fallback tomorrow_challenge always populated', () {
    final r = ReflectionResult.fallback(1, 4, 0);
    expect(r.tomorrowChallenge.isNotEmpty, true);
  });
}
