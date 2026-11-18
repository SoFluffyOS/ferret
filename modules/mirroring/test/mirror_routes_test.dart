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
  late Map<String, String> paired;

  Future<void> create({
    bool lookForCable = true,
    Map<String, Object?> stored = const {},
    FakeReceiver? withReceiver,
  }) async {
    host = await FakeHost.create(
      settings: {MirroringSettings.lookForCableKey: lookForCable, ...stored},
    );
    host.sessions = [FakeSession('pixel')];
    paired = {'pixel': 'Pixel', 'galaxy': 'Galaxy S24'};
    cable = FakeRoute('cable');
    other = FakeRoute('other');
    receiver = withReceiver ?? FakeReceiver('cast');
    settings = MirroringSettings(host.settings);
    routes = MirrorRoutes(
      ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
      settings: settings,
      receiverName: () => 'MacBook',
      pairedPhones: () => paired,
      routes: [cable, other],
      receivers: [receiver],
    )..start();
    await settle();
  }

  tearDown(() => routes.dispose());

  group('looking for phones on a cable', () {
    test('stays off until asked for, and nothing listens', () async {
      await create(lookForCable: false);
      cable.find([cable.target('a1', 'Old tablet')]);
      await settle();

      expect(routes.hasCable, isTrue);
      expect(routes.cableOn, isFalse);
      expect(routes.targets, isEmpty);
      expect(receiver.isListening, isFalse);
      expect(routes.routeFor(cable.target('a1', 'Old tablet')), isNull);
    });

    test('turning it on lists what the cable finds; off again forgets '
        'it', () async {
      await create(lookForCable: false);
      cable.found = [cable.target('a1', 'Old tablet')];

      await settings.setLookForCable(true);
      await settle();
      expect(routes.targets.single.name, 'Old tablet');
      expect(routes.routeFor(routes.targets.single), cable);
      expect(receiver.isListening, isFalse, reason: 'its own switch');

      await settings.setLookForCable(false);
      await settle();
      expect(routes.targets, isEmpty);
    });

    test('a computer that had the old shared switch on keeps the cable '
        'and its receivers', () async {
      await create(
        stored: {
          MirroringSettings.lookForCableKey: null,
          MirroringSettings.moreWaysKey: true,
        },
      );

      expect(routes.cableOn, isTrue);
      expect(receiver.listeningAs, 'MacBook');
    });
  });

  group('picking the way to a paired phone', () {
    test('Ferret when it is connected, because the phone asks there', () async {
      await create();

      final target = routes.bestTargetFor('pixel');

      expect(target.routeId, FerretRoute.routeId);
      expect(target.ferretDeviceId, 'pixel');
    });

    test('a phone that is also plugged in still goes over Ferret, and the '
        'cable only when control is asked for', () async {
      await create();
      cable.find([cable.target('2A13', 'pixel')]);
      await settle();

      expect(routes.bestTargetFor('pixel').routeId, FerretRoute.routeId);

      final control = routes.bestTargetFor('pixel', preferControl: true);
      expect(control.routeId, 'cable');
      expect(control.id, '2A13');
      expect(control.ferretDeviceId, 'pixel');
      expect(control.name, 'Pixel', reason: 'the name it is paired under');
    });

    test('the cable when Ferret is not connected', () async {
      await create();
      cable.find([cable.target('R58', 'Galaxy S24')]);
      await settle();

      final target = routes.bestTargetFor('galaxy');

      expect(target.routeId, 'cable');
      expect(target.ferretDeviceId, 'galaxy');
    });

    test('Ferret, to say the phone is not connected, when nothing reaches '
        'it', () async {
      await create();

      final target = routes.bestTargetFor('galaxy');

      expect(target.routeId, FerretRoute.routeId);
      expect(routes.isReachable(target), isFalse);
    });

    test('no control over the cable while it is off', () async {
      await create(lookForCable: false);
      cable.find([cable.target('2A13', 'Pixel')]);
      await settle();

      final target = routes.bestTargetFor('pixel', preferControl: true);

      expect(target.routeId, FerretRoute.routeId);
    });
  });

  group('a paired phone on a cable', () {
    test('is found by the device it says it is, or by its name, and is no '
        'longer listed as a stranger', () async {
      await create();
      cable.find([
        cable.target('a1', 'Galaxy S24'),
        cable.target('a2', 'Some model', ferretDeviceId: 'pixel'),
        cable.target('a3', 'Old tablet'),
      ]);
      await settle();

      expect(routes.cableTargetFor('galaxy')?.id, 'a1');
      expect(routes.cableTargetFor('pixel')?.id, 'a2');
      expect(
        [for (final target in routes.targets) target.name],
        [
          'Old tablet',
        ],
      );
    });

    test('a phone seen over USB and over Wi-Fi debugging is one phone, and '
        'the real cable is the one used', () async {
      await create();
      cable.find([
        const MirrorTarget(
          routeId: 'cable',
          id: '192.168.1.78:5555',
          name: 'Galaxy S24',
          wireless: true,
        ),
        cable.target('R58', 'Galaxy S24'),
      ]);
      await settle();

      expect(routes.cableTargetFor('galaxy')?.id, 'R58');
      expect(routes.targets, isEmpty, reason: 'neither is a stranger');
    });

    test('two paired phones with one name are not guessed apart', () async {
      await create();
      paired = {'one': 'Galaxy S24', 'two': 'Galaxy S24'};
      cable.find([cable.target('R58', 'Galaxy S24')]);
      await settle();

      expect(routes.cableTargetFor('one'), isNull);
      expect(routes.targets, hasLength(1));
    });

    test('the only phone on a cable counts for an owner who followed the '
        'steps, whatever it is called', () async {
      await create();
      paired = {'phone': "Simon's phone"};
      cable.find([cable.target('a1', 'SM-S921B')]);
      await settle();

      expect(routes.cableTargetFor('phone'), isNull);

      final target = routes.cableTargetFor('phone', orOnlyOne: true);
      expect(target?.id, 'a1');
      expect(target?.name, "Simon's phone");
    });

    test('a phone two routes reach shows once', () async {
      await create();
      cable.find([cable.target('a1', 'Tab', ferretDeviceId: 'tab')]);
      other.find([
        other.target('b1', 'Tab', ferretDeviceId: 'tab'),
        other.target('b2', 'Fridge'),
      ]);
      await settle();

      expect(
        [
          for (final target in routes.targets)
            '${target.routeId}/${target.name}',
        ],
        ['cable/Tab', 'other/Fridge'],
      );
    });

    test('is reachable only while the cable sees it', () async {
      await create();
      final target = cable.target('a1', 'Old tablet');
      expect(routes.isReachable(target), isFalse);

      cable.find([target]);
      await settle();
      expect(routes.isReachable(target), isTrue);
    });
  });

  group('the cable steps', () {
    test('say what is missing, then that nothing is', () async {
      await create();
      cable.statusNow = const RouteNeedsSetup(
        .authorizeComputer,
        detail: 'S24',
      );
      other.statusNow = const RouteUnsupported();

      expect(
        await routes.cableSetup(),
        const CableSetup(step: .authorizeComputer, detail: 'S24'),
      );

      cable.statusNow = const RouteReady();
      expect(await routes.cableSetup(), CableSetup.ready);
    });

    test('nothing to do where no cable route works at all', () async {
      await create();
      cable.statusNow = const RouteUnsupported();
      other.statusNow = const RouteUnsupported();

      expect(await routes.cableSetup(), isNull);
    });

    Future<FakeToolRoute> withTool() async {
      host = await FakeHost.create();
      final adb = FakeToolRoute('adb')
        ..statusNow = const RouteNeedsSetup(.installTool, detail: 'adb');
      cable = FakeRoute('cable');
      receiver = FakeReceiver('cast');
      settings = MirroringSettings(host.settings);
      routes = MirrorRoutes(
        ferret: FerretRoute(host: host, featureId: MirroringFeature.featureId),
        settings: settings,
        receiverName: () => 'MacBook',
        routes: [adb],
      )..start();
      await settle();
      return adb;
    }

    test('offer the download, and nothing is fetched until asked', () async {
      final adb = await withTool();

      expect((await routes.cableSetup())?.help, SetupHelp.download);
      expect(adb.installs, 0);

      await routes.installTool();
      expect(adb.installs, 1);
      expect(await routes.cableSetup(), CableSetup.ready);
    });

    test('say to start the tool where a download would not help', () async {
      final adb = await withTool();
      adb.statusNow = const RouteNeedsSetup(
        .installTool,
        detail: FakeToolRoute.notStarted,
      );

      expect((await routes.cableSetup())?.help, SetupHelp.startTool);

      adb
        ..statusNow = const RouteNeedsSetup(.installTool, detail: 'adb')
        ..canInstallTool = false;
      expect((await routes.cableSetup())?.help, SetupHelp.none);
      await routes.installTool();
      expect(adb.installs, 0);
    });
  });

  group('receivers', () {
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

    test('each listens only while its own switch is on', () async {
      await create();
      expect(receiver.isListening, isFalse);
      expect(routes.receivers, const [
        ReceiverSwitch(receiverId: 'cast', on: false),
      ]);

      await routes.setReceiverOn('cast', true);
      await settle();
      expect(receiver.listeningAs, 'MacBook');
      expect(routes.receivers.single.on, isTrue);

      await routes.setReceiverOn('cast', false);
      await settle();
      expect(receiver.isListening, isFalse);
    });

    test('one that still needs something does not listen', () async {
      await create(
        withReceiver: FakeReceiver(
          'cast',
          statusNow: const RouteNeedsSetup(.grantPermission),
        ),
      );

      await routes.setReceiverOn('cast', true);
      await settle();

      expect(receiver.isListening, isFalse);
    });

    test('asked for, they listen for two minutes whatever the switch '
        'says, then stop', () {
      fakeAsync((async) {
        create();
        async.flushMicrotasks();

        routes.armReceivers();
        async.flushMicrotasks();
        expect(receiver.listeningAs, 'MacBook');
        expect(routes.armedUntil, isNotNull);

        async.elapse(const Duration(minutes: 2, seconds: 1));
        expect(receiver.isListening, isFalse);
        expect(routes.armedUntil, isNull);
      });
    });

    test('one that shows a screen keeps listening past the two minutes, '
        'until that screen is done', () {
      fakeAsync((async) {
        create();
        async.flushMicrotasks();
        var showing = true;
        routes.isShowingIncoming = () => showing;

        routes.armReceivers();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 3));
        expect(receiver.isListening, isTrue);

        showing = false;
        routes.refreshReceivers();
        async.flushMicrotasks();
        expect(receiver.isListening, isFalse);
      });
    });

    test('a device is only let in with a yes; a no, and no answer in 30 '
        'seconds, turn it away', () {
      fakeAsync((async) {
        create();
        async.flushMicrotasks();
        routes.setReceiverOn('cast', true);
        async.flushMicrotasks();
        final answers = <bool>[];

        receiver.ask("Simon's iPhone").then(answers.add);
        async.flushMicrotasks();
        final request = routes.requests.single;
        expect(request.deviceName, "Simon's iPhone");
        expect(
          request.deadline.difference(request.askedAt),
          const Duration(seconds: 30),
        );
        routes.answer(request, allow: true);
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
  });

  test('letting go disposes every way', () async {
    await create();

    await routes.dispose();

    expect(cable.disposed, isTrue);
    expect(receiver.disposed, isTrue);
  });
}
