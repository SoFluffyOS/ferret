import 'package:flutter_test/flutter_test.dart';
import 'package:messages/messages.dart';
import 'package:messages/ui/ui.dart';
import 'package:provider/provider.dart';

import 'support/fakes.dart';
import 'support/test_app.dart';

void main() {
  late FakeSmsSource source;
  late MessagesFeature feature;

  Future<void> pumpSetup(WidgetTester tester, {bool enabled = false}) async {
    await tester.runAsync(() async {
      feature = MessagesFeature(source: source);
      await feature.start(FakeHost({MessagesSettings.enabledKey: enabled}));
    });
    final service = feature.sourceService;
    if (service == null) {
      fail('a phone has a source service');
    }

    await tester.pumpWidget(
      testApp(
        ChangeNotifierProvider(
          create: (_) => PhoneSetupViewModel(service),
          child: const PhoneSetupFrame(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void resume(WidgetTester tester) {
    tester.binding
      ..handleAppLifecycleStateChanged(.inactive)
      ..handleAppLifecycleStateChanged(.resumed);
  }

  setUp(() {
    source = FakeSmsSource(
      canRead: false,
      canSend: false,
      canReadContacts: false,
    );
  });

  testWidgets('starts with the explainer and the RCS limit', (tester) async {
    await pumpSetup(tester);

    expect(
      find.text('Read and reply to your texts from your computer.'),
      findsOneWidget,
    );
    expect(find.text('Turn on'), findsOneWidget);
    expect(
      find.textContaining('Chats in Google Messages'),
      findsOneWidget,
    );
  });

  testWidgets('turning on asks for access, then says it works', (tester) async {
    await pumpSetup(tester);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(source.requests, 1);
    expect(feature.settings.enabled, isTrue);
    expect(
      find.text('Your computers can read and reply to your texts'),
      findsOneWidget,
    );
  });

  testWidgets('a denied dialog says it is still off, with a retry', (
    tester,
  ) async {
    source.grantOnRequest = false;
    await pumpSetup(tester);

    await tester.tap(find.text('Turn on'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Still off.'), findsOneWidget);
    expect(find.text('Allow access'), findsOneWidget);
  });

  testWidgets('when Android won\'t ask again, opens settings and re-checks', (
    tester,
  ) async {
    source.blocked = true;
    await pumpSetup(tester, enabled: true);

    expect(find.textContaining("Android won't ask again"), findsOneWidget);
    await tester.tap(find.text('Open settings'));
    await tester.pumpAndSettle();
    expect(source.openedSettings, 1);

    source
      ..canRead = true
      ..canSend = true
      ..canReadContacts = true;
    resume(tester);
    await tester.pumpAndSettle();

    expect(
      find.text('Your computers can read and reply to your texts'),
      findsOneWidget,
    );
  });

  testWidgets('says plainly when contacts are off', (tester) async {
    source
      ..canRead = true
      ..canSend = true;
    await pumpSetup(tester, enabled: true);

    expect(
      find.text(
        'Contacts are off, so conversations show numbers instead of names.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('a device without SMS says so and offers nothing', (
    tester,
  ) async {
    source.hasTelephony = false;
    await pumpSetup(tester);

    expect(find.textContaining("can't send or receive texts"), findsOneWidget);
    expect(find.text('Turn on'), findsNothing);
  });
}
