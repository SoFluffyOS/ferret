import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protobuf/protobuf.dart';
import 'package:protocol/remote_input.dart' hide Key;
import 'package:provider/provider.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeInjector injector;
  late RemoteInputFeature feature;

  Future<void> startFeature({
    bool computer = true,
    InjectorStatus status = const .ready(.quartz),
  }) async {
    host = await FakeHost.create();
    pixel = FakeSession('pixel', name: 'Pixel');
    host.sessions = [pixel];
    injector = FakeInjector(statusNow: status);
    feature = RemoteInputFeature(
      injector: () => injector,
      canBeControlled: computer,
      canControl: !computer,
    );
    await feature.start(host);
  }

  group('consent dialog', () {
    for (final (label, choice) in [
      ('Always allow', ConsentChoice.always),
      ('Allow once', ConsentChoice.allowOnce),
      ("Don't allow", ConsentChoice.deny),
    ]) {
      testWidgets('$label answers ${choice.name}', (tester) async {
        ConsentChoice? answered;
        await tester.pumpWidget(
          testApp(
            ConsentDialog(
              deviceName: 'Pixel',
              onAnswer: (choice) => answered = choice,
            ),
          ),
        );

        expect(find.text('Let Pixel control this computer?'), findsOneWidget);
        await tester.tap(find.text(label));
        expect(answered, choice);
      });
    }

    testWidgets('the prompter shows it on a request and closes it once '
        'answered elsewhere', (tester) async {
      await tester.runAsync(startFeature);
      final viewModel = HostViewModel(feature);
      final navigatorKey = GlobalKey<NavigatorState>();
      await tester.pumpWidget(
        testApp(const SizedBox.shrink(), navigatorKey: navigatorKey),
      );
      final prompter = ConsentPrompter(
        viewModel: viewModel,
        navigatorKey: navigatorKey,
      )..start();

      await tester.runAsync(
        () async {
          await feature.controlHost?.onRequest(
            pixel,
            ControlRequest(version: 1),
          );
        },
      );
      await tester.pumpAndSettle();
      expect(find.text('Let Pixel control this computer?'), findsOneWidget);

      await tester.runAsync(
        () async => feature.controlHost?.answer(.allowOnce),
      );
      await tester.pumpAndSettle();
      expect(find.text('Let Pixel control this computer?'), findsNothing);

      prompter.dispose();
      viewModel.dispose();
    });
  });

  group('home card', () {
    Widget card() => ChangeNotifierProvider(
      create: (_) => HostViewModel(feature),
      child: const HostCardFrame(),
    );

    testWidgets('asks with three answers while a device waits', (
      tester,
    ) async {
      await tester.runAsync(startFeature);
      await tester.runAsync(
        () async {
          await feature.controlHost?.onRequest(
            pixel,
            ControlRequest(version: 1),
          );
        },
      );
      await tester.pumpWidget(testApp(card()));

      expect(find.text('Let Pixel control this computer?'), findsOneWidget);
      await tester.tap(find.text('Allow once'));
      await tester.runAsync(settle);
      await tester.pump();

      expect(feature.controlHost?.active?.deviceName, 'Pixel');
      expect(find.text('Pixel is controlling this computer'), findsOneWidget);
      await tester.runAsync(feature.stop);
    });

    testWidgets('Stop ends control and leaves an audit line', (tester) async {
      await tester.runAsync(startFeature);
      await tester.runAsync(() async {
        await feature.controlHost?.onRequest(pixel, ControlRequest(version: 1));
        await feature.controlHost?.answer(.allowOnce);
      });
      await tester.pumpWidget(testApp(card()));

      await tester.tap(find.text('Stop control'));
      await tester.runAsync(settle);
      await tester.pump();

      expect(feature.controlHost?.active, isNull);
      expect(injector.releases, 1);
      expect(
        find.textContaining('Pixel controlled this computer for less than'),
        findsOneWidget,
      );
    });

    testWidgets('a missing permission says how to fix it', (tester) async {
      await tester.runAsync(
        () => startFeature(status: const .needsPermission(.quartz)),
      );
      await tester.runAsync(
        () async {
          await feature.controlHost?.onRequest(
            pixel,
            ControlRequest(version: 1),
          );
        },
      );
      await tester.pumpWidget(testApp(card()));

      expect(
        find.text("Pixel can't control this computer yet"),
        findsOneWidget,
      );
      await tester.tap(find.text('Open Settings'));
      await tester.runAsync(settle);
      expect(injector.requests, 1);
    });
  });

  group('settings', () {
    testWidgets('lists allowed devices with Revoke, and the history', (
      tester,
    ) async {
      await tester.runAsync(startFeature);
      await tester.runAsync(() async {
        await feature.controlHost?.onRequest(pixel, ControlRequest(version: 1));
        await feature.controlHost?.answer(.always);
        await feature.controlHost?.onStop(pixel);
      });
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => HostViewModel(feature),
            child: const HostSettingsFrame(),
          ),
        ),
      );

      expect(find.text('On. Uses Accessibility access.'), findsOneWidget);
      expect(find.text('pixel'), findsOneWidget);
      expect(
        find.textContaining('Pixel controlled this computer'),
        findsOneWidget,
      );

      await tester.tap(find.text('Revoke'));
      await tester.runAsync(settle);
      await tester.pump();
      expect(feature.settings.allowedDevices, isEmpty);
    });

    testWidgets('Linux without a way to inject says what to install', (
      tester,
    ) async {
      await tester.runAsync(
        () => startFeature(status: const .unavailable(.noLinuxBackend)),
      );
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider(
            create: (_) => HostViewModel(feature),
            child: const HostSettingsFrame(),
          ),
        ),
      );

      expect(
        find.text("This computer can't be controlled yet"),
        findsOneWidget,
      );
      expect(find.textContaining('xdotool (X11)'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    });
  });

  group('touchpad page', () {
    Future<TouchpadViewModel> openPage(
      WidgetTester tester, {
      GeneratedMessage? reply,
    }) async {
      await tester.runAsync(() => startFeature(computer: false));
      pixel.answer = (_) => reply ?? ControlGrant(version: 1);
      final viewModel = TouchpadViewModel(feature);
      await tester.runAsync(() => viewModel.start('pixel'));
      await tester.pumpWidget(
        testApp(
          ChangeNotifierProvider.value(
            value: viewModel,
            child: const TouchpadPage(
              deviceId: 'pixel',
              deviceName: 'Pixel',
              hostKind: .mac,
            ),
          ),
          scroll: false,
        ),
      );
      return viewModel;
    }

    List<InputEvent> sent() => [
      for (final batch in pixel.sentOf<InputBatch>()) ...batch.events,
    ];

    testWidgets('a tap on the pad clicks', (tester) async {
      await openPage(tester);

      await tester.tap(find.byType(TouchpadSurface));
      await tester.pump(const Duration(milliseconds: 50));

      final buttons = [
        for (final event in sent())
          if (event.hasButton()) event.button.pressed,
      ];
      expect(buttons, [true, false]);
    });

    testWidgets('a drag on the pad moves the pointer', (tester) async {
      await openPage(tester);

      await tester.drag(find.byType(TouchpadSurface), const Offset(60, 20));
      await tester.pump(const Duration(milliseconds: 50));

      final moved = sent().where((event) => event.hasMove());
      expect(moved, isNotEmpty);
      expect(
        moved.fold<int>(0, (sum, event) => sum + event.move.dx),
        greaterThan(0),
      );
    });

    testWidgets('special keys and an armed modifier go as a shortcut', (
      tester,
    ) async {
      await openPage(tester);

      await tester.tap(find.text('Esc'));
      await tester.tap(find.text('Cmd'));
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'c');
      await tester.pump();

      final keys = [
        for (final event in sent())
          if (event.hasKey() && event.key.pressed) event.key,
      ];
      expect(keys.first.key.name, 'KEY_ESCAPE');
      expect(keys.last.key.name, 'KEY_C');
      expect(keys.last.modifiers, [Modifier.MODIFIER_META]);
    });

    testWidgets('typing sends text', (tester) async {
      await openPage(tester);

      await tester.enterText(find.byType(EditableText), 'hi');
      await tester.pump();

      expect(
        [
          for (final event in sent())
            if (event.hasText()) event.text.text,
        ],
        ['hi'],
      );
    });

    testWidgets('a no says why, with Try again', (tester) async {
      await openPage(
        tester,
        reply: ControlDeny(reason: .DENY_REASON_NEEDS_PERMISSION),
      );

      expect(
        find.text(
          'Pixel needs Accessibility access first. On Pixel: open Ferret and '
          'allow it.',
        ),
        findsOneWidget,
      );
      expect(find.text('Try again'), findsOneWidget);
    });

    testWidgets('waiting for the owner says so', (tester) async {
      await openPage(tester, reply: ControlPending(timeoutSeconds: 60));

      expect(find.text('Waiting for Pixel'), findsOneWidget);
    });
  });
}
