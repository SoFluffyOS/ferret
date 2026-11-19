import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:scripting/scripting.dart';

void main() {
  test('lets a few through each minute, per device', () {
    var now = DateTime.utc(2026, 11, 19, 9);
    final limit = NoticeLimit(perMinute: 2, clock: () => now);

    expect(limit.allow('a'), isTrue);
    expect(limit.allow('a'), isTrue);
    expect(limit.allow('a'), isFalse);
    expect(limit.allow('b'), isTrue);

    now = now.add(const Duration(seconds: 61));

    expect(limit.allow('a'), isTrue);
  });

  test('scripts may not notify by default', () {
    final settings = ScriptingSettings(MemorySettingsStore());

    expect(settings.allowsNotices('aaaa-1111'), isFalse);
  });
}
