import 'package:core/core.dart';
import 'package:ferret_system/ferret_system.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/ui/frames/frames.dart';
import 'package:sofluffy_ui/sofluffy_ui.dart';

import 'test_app.dart';

class _FakeLogin extends StartAtLogin {
  _FakeLogin({this.enabled = false}) : super(operatingSystem: 'linux');

  bool enabled;
  bool? remembered;

  @override
  Future<bool> isEnabled({bool remembered = false}) async {
    this.remembered = remembered;
    return enabled;
  }

  @override
  Future<void> setEnabled(bool enabled) async => this.enabled = enabled;
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

  testWidgets('a Mac shows nothing here', (tester) async {
    await tester.pumpWidget(
      testApp(
        LoginSettings(
          settings: MemorySettingsStore(),
          login: StartAtLogin(operatingSystem: 'macos'),
        ),
      ),
    );

    expect(find.text('Start Ferret when I log in'), findsNothing);
  });
}
