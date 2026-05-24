import 'package:flutter_application_1/models/session_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  setUpAll(() async {
    Hive.init('.test_hive');
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(SessionModelAdapter());
  });

  test('SessionModel round-trips through Hive', () async {
    final box = await Hive.openBox<SessionModel>('test_sessions');
    final start = DateTime.now().subtract(const Duration(minutes: 15));
    final end = DateTime.now();
    final s = SessionModel(
      id: 'sess1',
      packageName: 'com.instagram.android',
      appDisplayName: 'Instagram',
      startedAt: start,
      endedAt: end,
      durationSeconds: 15 * 60,
      intervened: true,
      snoozeCount: 1,
    );
    await box.put(s.id, s);
    final back = box.get('sess1');
    expect(back, isNotNull);
    expect(back!.packageName, 'com.instagram.android');
    expect(back.durationSeconds, 15 * 60);
    expect(back.durationMinutes, 15);
    expect(back.intervened, true);
    expect(back.snoozeCount, 1);
    await box.clear();
    await box.close();
  });
}
