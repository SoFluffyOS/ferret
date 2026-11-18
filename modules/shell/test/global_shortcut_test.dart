import 'package:core/core.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

void main() {
  test('⌃⌥Space opens the popover until the person picks other keys', () {
    final shortcut = GlobalShortcut.read(MemorySettingsStore());

    expect(shortcut?.label, '⌃⌥Space');
    expect(shortcut?.keyCode, 49);
    expect([shortcut?.control, shortcut?.option], [true, true]);
    expect([shortcut?.command, shortcut?.shift], [false, false]);
  });

  test('picked keys are kept, and so is turning it off', () async {
    final settings = MemorySettingsStore();

    await GlobalShortcut.write(
      settings,
      MenubarShortcut(keyCode: 3, label: '⌘⇧F', command: true, shift: true),
    );
    final picked = GlobalShortcut.read(settings);
    await GlobalShortcut.write(settings, null);

    expect(picked?.label, '⌘⇧F');
    expect(picked?.keyCode, 3);
    expect([picked?.command, picked?.shift], [true, true]);
    expect(GlobalShortcut.read(settings), isNull);
  });

  test('something unreadable in settings falls back to the default', () {
    final settings = MemorySettingsStore({
      GlobalShortcut.key: {'key_code': 'F'},
    });

    expect(GlobalShortcut.read(settings)?.label, '⌃⌥Space');
  });
}
