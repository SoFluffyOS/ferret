import 'package:fake_async/fake_async.dart';
import 'package:ferret_mirroring/ferret_mirroring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirroring/mirroring.dart';

import 'helpers/fakes.dart';

void main() {
  late FakeHost host;
  late FakeRoute cable;
  late FakeRoute other;
  late FakeReceiver receiver;
  late MirroringSettings settings;
  late MirrorRoutes routes;

  Future<void> create({bool moreWays = true}) async {
    host = await FakeHost.create(
      settings: {MirroringSettings.moreWaysKey: moreWays},
    );
    host.sessions = [FakeSession('pixel')];
    cable = FakeRoute('cable');
    other = FakeRoute('other');
    receiver = FakeReceiver('cast');
    settings = MirroringSettings(host.settings);
    routes = MirrorRoutes(
      ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
      settings: settings,
      receiverName: () => 'MacBook',
      routes: [cable, other],
      receivers: [receiver],
    )..start();
    await settle();
  }

  tearDown(() => routes.dispose());

  test('the other ways stay off until asked for', () async {
    await create(moreWays: false);
    cable.find([cable.target('a1', 'Galaxy')]);
    await settle();

    expect(routes.hasMoreWays, isTrue);
    expect(routes.moreWaysOn, isFalse);
    expect(routes.targets, isEmpty);
    expect(receiver.isListening, isFalse);
    expect(routes.routeFor(cable.target('a1', 'Galaxy')), isNull);
  });

  test('turning them on lists what they find and starts listening under '
      'this computer\'s name; off again stops both', () async {
    await create(moreWays: false);
    cable.found = [cable.target('a1', 'Galaxy')];

    await settings.setMoreWays(true);
    await settle();
    expect(routes.targets.single.name, 'Galaxy');
    expect(receiver.listeningAs, 'MacBook');
    expect(routes.routeFor(routes.targets.single), cable);

    await settings.setMoreWays(false);
    await settle();
    expect(routes.targets, isEmpty);
    expect(receiver.isListening, isFalse);
  });

  test('a phone two ways reach shows once, and one Ferret can show itself '
      'isn\'t listed', () async {
    await create();

    cable.find([
      cable.target('a1', 'Galaxy', ferretDeviceId: 'galaxy'),
      cable.target('a2', 'Pixel', ferretDeviceId: 'pixel'),
      cable.target('a3', 'Old tablet'),
    ]);
    other.find([
      other.target('b1', 'Galaxy', ferretDeviceId: 'galaxy'),
      other.target('b2', 'Fridge'),
    ]);
    await settle();

    expect(
      [for (final target in routes.targets) '${target.routeId}/${target.name}'],
      ['cable/Galaxy', 'cable/Old tablet', 'other/Fridge'],
    );
    expect(routes.targetForDevice('galaxy')?.routeId, 'cable');
    expect(routes.targetForDevice('pixel'), isNull);
  });

  test('what a way still needs is kept, and goes once it is done', () async {
    await create(moreWays: false);
    cable.statusNow = const RouteNeedsSetup(.installTool, detail: '/opt/adb');
    receiver.statusNow = const RouteNeedsSetup(.grantPermission);
    await settings.setMoreWays(true);
    await settle();

    expect(routes.notices, const [
      RouteNotice(routeId: 'cable', step: .installTool, detail: '/opt/adb'),
      RouteNotice(routeId: 'cast', step: .grantPermission),
    ]);
    expect(receiver.isListening, isFalse, reason: 'not before it may');

    cable.statusNow = const RouteReady();
    receiver.statusNow = const RouteReady();
    await routes.refresh();

    expect(routes.notices, isEmpty);
    expect(receiver.isListening, isTrue);
  });

  group('a way that can fetch its own tool', () {
    late FakeToolRoute adb;

    Future<void> createWithTool(RouteStatus status) async {
      host = await FakeHost.create(
        settings: {MirroringSettings.moreWaysKey: true},
      );
      adb = FakeToolRoute('adb')..statusNow = status;
      cable = FakeRoute('cable');
      receiver = FakeReceiver('cast');
      settings = MirroringSettings(host.settings);
      routes = MirrorRoutes(
        ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
        settings: settings,
        receiverName: () => 'MacBook',
        routes: [adb, cable],
        receivers: [receiver],
      )..start();
      await settle();
    }

    test('offers the download, and nothing is fetched until asked', () async {
      await createWithTool(const RouteNeedsSetup(.installTool, detail: 'adb'));

      expect(routes.notices.single.help, SetupHelp.download);
      expect(adb.installs, 0);

      await routes.installTool('adb');

      expect(adb.installs, 1);
      expect(routes.notices, isEmpty);
    });

    test(
      'a tool only the owner can start is never offered as a download',
      () async {
        await createWithTool(
          const RouteNeedsSetup(.installTool, detail: FakeToolRoute.notStarted),
        );

        expect(routes.notices.single.help, SetupHelp.startTool);
      },
    );

    test('no download where it wouldn\'t help', () async {
      host = await FakeHost.create(
        settings: {MirroringSettings.moreWaysKey: true},
      );
      adb = FakeToolRoute('adb')
        ..canInstallTool = false
        ..statusNow = const RouteNeedsSetup(.installTool, detail: 'adb');
      settings = MirroringSettings(host.settings);
      routes = MirrorRoutes(
        ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
        settings: settings,
        receiverName: () => 'MacBook',
        routes: [adb],
      )..start();
      await settle();

      expect(routes.notices.single.help, SetupHelp.none);
    });
  });

  test('a screen a device sends here itself is passed on', () async {
    await create();
    final incoming = <MirrorFeed>[];
    routes.incoming.listen(incoming.add);
    final feed = FakeFeed(
      const MirrorTarget(routeId: 'cast', id: 'i1', name: 'iPhone'),
    );

    receiver.receive(feed);
    await settle();

    expect(incoming.single, feed);
  });

  test('a receiver that starts off stays off until its own switch, and '
      'one switched off stops listening', () async {
    await create(moreWays: false);
    await routes.dispose();
    final quiet = FakeReceiver('airplay', listensByDefault: false);
    routes = MirrorRoutes(
      ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
      settings: settings,
      receiverName: () => 'MacBook',
      receivers: [quiet],
    )..start();
    await settings.setMoreWays(true);
    await settle();
    expect(quiet.isListening, isFalse);
    expect(routes.receivers, const [
      ReceiverSwitch(receiverId: 'airplay', on: false),
    ]);

    await routes.setReceiverOn('airplay', true);
    await settle();
    expect(quiet.listeningAs, 'MacBook');
    expect(routes.receivers.single.on, isTrue);

    await routes.setReceiverOn('airplay', false);
    await settle();
    expect(quiet.isListening, isFalse);
  });

  test('a device is only let in with a yes; a no, and no answer in 30 '
      'seconds, turn it away', () {
    fakeAsync((async) {
      create();
      async.flushMicrotasks();
      final answers = <bool>[];

      receiver.ask("Simon's iPhone").then(answers.add);
      async.flushMicrotasks();
      expect(routes.requests.single.deviceName, "Simon's iPhone");
      routes.answer(routes.requests.single, allow: true);
      async.flushMicrotasks();
      expect(answers, [true]);
      expect(routes.requests, isEmpty);

      receiver.ask('Stranger').then(answers.add);
      async.flushMicrotasks();
      routes.answer(routes.requests.single, allow: false);
      async.flushMicrotasks();
      expect(answers, [true, false]);

      receiver.ask('Nobody home').then(answers.add);
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 31));
      expect(answers, [true, false, false]);
      expect(routes.requests, isEmpty);
    });
  });

  test('letting go disposes every way', () async {
    await create();

    await routes.dispose();

    expect(cable.disposed, isTrue);
    expect(receiver.disposed, isTrue);
  });
}
