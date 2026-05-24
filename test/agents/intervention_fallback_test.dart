import 'package:flutter_application_1/config/constants.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fallback pool has 5 messages, each under 280 chars', () {
    final pool = AppConstants.fallbackInterventions;
    expect(pool.length, 5);
    for (final m in pool) {
      expect(m.length, lessThanOrEqualTo(280),
          reason: 'message exceeds overlay budget: "$m"');
      expect(m.trim(), isNotEmpty);
    }
  });

  test('fallback messages do not contain forbidden moralizing words', () {
    final forbidden = ['doom-scroll', 'addiction', 'wasted'];
    for (final m in AppConstants.fallbackInterventions) {
      final lower = m.toLowerCase();
      for (final f in forbidden) {
        expect(lower.contains(f), isFalse,
            reason: 'forbidden word "$f" found in: $m');
      }
    }
  });
}
