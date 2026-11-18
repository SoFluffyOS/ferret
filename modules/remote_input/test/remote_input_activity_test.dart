import 'package:feature_kit/feature_kit.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:protocol/remote_input.dart' hide Key;
import 'package:remote_input/l10n/l10n.dart';
import 'package:remote_input/remote_input.dart';

import 'helpers/fakes.dart';
import 'helpers/test_app.dart';

class _NoContext implements FeatureContext {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeHost host;
  late FakeSession pixel;
  late FakeInjector injector;
  late RemoteInputFeature feature;
  late HostViewModel viewModel;

  final l10n = lookupRemoteInputLocalizations(const Locale('en'));

  List<ActivityItem> activity({HostKind thisComputer = .mac}) =>
      remoteInputActivity(l10n, viewModel, thisComputer: thisComputer);

  Future<void> ask() async =>
      feature.controlHost?.onRequest(pixel, ControlRequest(version: 1));

  Future<void> control() async {
    await ask();
    await feature.controlHost?.answer(.allowOnce);
  }

  setUp(() async {
    host = await FakeHost.create();
    pixel = FakeSession('pixel', name: 'Pixel');
    host.sessions = [pixel];
    injector = FakeInjector();
    feature = RemoteInputFeature(
      injector: () => injector,
      canBeControlled: true,
      canControl: false,
    );
    await feature.start(host);
    viewModel = HostViewModel(feature);
  });

  tearDown(() async {
    viewModel.dispose();
    await feature.stop();
  });

  test('nothing while no device controls this computer', () {
    expect(activity(), isEmpty);
  });

  test('a device that only asks is the card\'s business', () async {
    await ask();

    expect(activity(), isEmpty);
    expect(viewModel.hasCard, isTrue);
  });

  test('a controlling device is one pinned line with Stop', () async {
    await control();

    final line = activity().single;

    expect(line.title, 'Pixel is controlling this Mac');
    expect(line.pinned, isTrue);
    expect(line.at, feature.controlHost?.active?.startedAt);
    expect(line.actions.single.label, 'Stop');
    expect(viewModel.hasCard, isFalse);
  });

  test('the line names this kind of computer', () async {
    await control();

    expect(
      activity(thisComputer: .windows).single.title,
      'Pixel is controlling this PC',
    );
    expect(
      activity(thisComputer: .linux).single.title,
      'Pixel is controlling this computer',
    );
  });

  test('Stop takes control back and leaves a line that it happened', () async {
    await control();

    activity().single.actions.single.onPressed();
    await settle();
    final line = activity().single;

    expect(feature.controlHost?.active, isNull);
    expect(injector.releases, 1);
    expect(line.title, 'Pixel controlled this Mac');
    expect(line.detail, 'For less than a minute');
    expect(line.pinned, isFalse);
    expect(line.at, feature.controlHost?.lastRecord?.endedAt);
    expect(line.actions, isEmpty);
    expect(viewModel.hasCard, isFalse);
  });

  test('the line that it happened can be dismissed', () async {
    await control();
    activity().single.actions.single.onPressed();
    await settle();

    activity().single.onDismiss?.call();

    expect(activity(), isEmpty);
    expect(feature.controlHost?.lastRecord, isNull);
  });

  testWidgets('the feature UI words it for the platform it runs on', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = .windows;
    await tester.runAsync(control);
    final ui = RemoteInputFeatureUi(feature: feature);
    addTearDown(() => tester.runAsync(ui.dispose));
    await tester.pumpWidget(testApp(const SizedBox.shrink()));
    await tester.pumpAndSettle();

    final lines = ui.activity(
      tester.element(find.byType(SizedBox).first),
      _NoContext(),
    );
    debugDefaultTargetPlatformOverride = null;

    expect(lines.single.title, 'Pixel is controlling this PC');
    expect(ui.hasHomeCard(_NoContext()), isFalse);
  });
}
