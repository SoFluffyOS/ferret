import 'package:core/core.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

class _FakeLogin extends StartAtLogin {
  _FakeLogin({this.enabled = false, this.saysYes = true})
    : super(operatingSystem: 'linux');

  bool enabled;
  final bool saysYes;
  bool? remembered;

  @override
  Future<bool> isEnabled({bool remembered = false}) async {
    this.remembered = remembered;
    return enabled;
  }

  @override
  Future<bool> setEnabled(bool enabled) async {
    this.enabled = enabled && saysYes;
    return saysYes;
  }
}

void main() {
  testWidgets('on Linux the switch shows and changes starting at login', (
    tester,
  ) async {
    final login = _FakeLogin(enabled: true);
    final settings = MemorySettingsStore();

    await tester.pumpWidget(
      testApp(LoginSettings(settings: settings, login: login)),
    );
    await tester.pump();

    expect(find.text('Start Ferret when I log in'), findsOneWidget);
    expect(
      tester.widget<SwitchToggle>(find.byType(SwitchToggle)).value,
      isTrue,
    );

    await tester.tap(find.byType(SwitchToggle));
    await tester.pumpAndSettle();

    expect(login.enabled, isFalse);
    expect(settings.get<bool>(LoginSettings.startAtLoginKey), isFalse);
  });

  testWidgets('when the desktop says no, the switch goes back off and says '
      'why', (tester) async {
    final login = _FakeLogin(saysYes: false);
    final settings = MemorySettingsStore();

    await tester.pumpWidget(
      testApp(LoginSettings(settings: settings, login: login)),
    );
    await tester.pump();
    await tester.tap(find.byType(SwitchToggle));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchToggle>(find.byType(SwitchToggle)).value,
      isFalse,
    );
    expect(settings.get<bool>(LoginSettings.startAtLoginKey), isFalse);
    expect(find.textContaining('Your desktop said no.'), findsOneWidget);
  });

  testWidgets('a Mac has it too, and says the menu bar', (tester) async {
    var item = false;
    await tester.pumpWidget(
      testApp(
        LoginSettings(
          settings: MemorySettingsStore(),
          login: StartAtLogin(
            operatingSystem: 'macos',
            isLoginItem: () async => item,
            setLoginItem: (enabled) async {
              item = enabled;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Start Ferret when I log in'), findsOneWidget);
  });

  testWidgets('without a tray it says the window opens, and follows a '
      'tray that turns up later', (tester) async {
    final tray = ValueNotifier(false);
    addTearDown(tray.dispose);

    await tester.pumpWidget(
      testApp(
        LoginSettings(
          settings: MemorySettingsStore(),
          login: _FakeLogin(),
          tray: tray,
        ),
      ),
    );
    await tester.pump();

    expect(find.textContaining('Its window opens'), findsOneWidget);
    expect(find.textContaining('starts in the tray'), findsNothing);

    tray.value = true;
    await tester.pump();

    expect(find.textContaining('starts in the tray'), findsOneWidget);
  });

  testWidgets('a phone shows nothing here', (tester) async {
    await tester.pumpWidget(
      testApp(
        LoginSettings(
          settings: MemorySettingsStore(),
          login: StartAtLogin(operatingSystem: 'android'),
        ),
      ),
    );

    expect(find.text('Start Ferret when I log in'), findsNothing);
  });
}
