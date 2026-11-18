import 'package:ferret_power/ferret_power.dart';
import 'package:ferret_power/testing.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> settle() => Future<void>.delayed(Duration.zero);

void main() {
  late FakePowerPlatform phone;
  late PowerCapabilities power;

  void start(PowerStatus status) {
    phone = FakePowerPlatform(status: status);
    power = PowerCapabilities.withPlatform(phone);
    addTearDown(power.dispose);
  }

  const plain = PowerStatus(supported: true);
  const shizukuReady = PowerStatus(supported: true, shizuku: .ready);
  const shizukuStopped = PowerStatus(supported: true, shizuku: .notRunning);
  const rooted = PowerStatus(
    supported: true,
    root: .found,
    rootManager: .magisk,
  );

  group('tier detection', () {
    test('a phone with nothing stays on the standard tier', () async {
      start(plain);

      await power.configure(shizuku: true, root: true);

      expect(power.activeTier, PowerTier.standard);
      expect(phone.rootRequests, 0);
    });

    test('Shizuku that is ready but not turned on is not a tier', () async {
      start(shizukuReady);

      await power.configure(shizuku: false, root: false);

      expect(power.status.shizuku, ShizukuStatus.ready);
      expect(power.activeTier, PowerTier.standard);
    });

    test('authorizing Shizuku turns the tier on', () async {
      start(const PowerStatus(supported: true, shizuku: .notAuthorized));
      await power.configure(shizuku: false, root: false);
      final tiers = <PowerTier>[];
      power.tierChanges.listen(tiers.add);

      final granted = await power.authorizeShizuku();
      await settle();

      expect(granted, isTrue);
      expect(power.shizukuEnabled, isTrue);
      expect(tiers, [PowerTier.shizuku]);
    });

    test('a refused Shizuku dialog changes nothing', () async {
      start(const PowerStatus(supported: true, shizuku: .notAuthorized));
      await power.configure(shizuku: false, root: false);
      phone.shizukuAnswer = false;

      final granted = await power.authorizeShizuku();

      expect(granted, isFalse);
      expect(power.shizukuEnabled, isFalse);
      expect(power.activeTier, PowerTier.standard);
    });

    test('the tier follows Shizuku stopping and starting', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      final tiers = <PowerTier>[];
      power.tierChanges.listen(tiers.add);

      phone.emit(shizukuStopped);
      await settle();
      phone.emit(shizukuReady);
      await settle();

      expect(tiers, [PowerTier.standard, PowerTier.shizuku]);
    });

    test('root is never asked for unless the user turned it on', () async {
      start(rooted);

      await power.configure(shizuku: false, root: false);
      await power.refresh();

      expect(phone.rootRequests, 0);
      expect(power.status.root, RootStatus.found);
      expect(power.activeTier, PowerTier.standard);
    });

    test('root turned on earlier is checked once at startup', () async {
      start(rooted);

      await power.configure(shizuku: false, root: true);
      await power.refresh();

      expect(phone.rootRequests, 1);
      expect(power.activeTier, PowerTier.root);
    });

    test('root that now says no leaves the tier off', () async {
      start(rooted);
      phone.rootAnswer = false;

      await power.configure(shizuku: false, root: true);

      expect(power.activeTier, PowerTier.standard);
      expect(power.status.root, RootStatus.found);
    });

    test('enabling root asks, and a no keeps it off', () async {
      start(rooted);
      await power.configure(shizuku: false, root: false);
      phone.rootAnswer = false;

      final denied = await power.enableRoot();
      phone.rootAnswer = true;
      final granted = await power.enableRoot();

      expect(denied, isFalse);
      expect(granted, isTrue);
      expect(power.rootEnabled, isTrue);
      expect(power.activeTier, PowerTier.root);
    });

    test('root wins over Shizuku, and turning it off falls back', () async {
      start(
        const PowerStatus(supported: true, shizuku: .ready, root: .granted),
      );
      await power.configure(shizuku: true, root: true);
      expect(power.activeTier, PowerTier.root);

      power.disableRoot();
      expect(power.activeTier, PowerTier.shizuku);

      power.setShizukuEnabled(false);
      expect(power.activeTier, PowerTier.standard);
    });
  });

  group('capability gating', () {
    test('nothing reaches a shell on the standard tier', () async {
      start(shizukuReady);
      await power.configure(shizuku: false, root: false);
      phone.clip = const PowerClip('secret');
      final clips = <PowerClip>[];
      power.clipboardChanges.listen(clips.add);

      final read = await power.readClipboard();
      final granted = await power.grant(.notificationAccess);
      phone.copy('copied elsewhere');
      await settle();

      expect(read, isNull);
      expect(granted, isFalse);
      expect(clips, isEmpty);
      expect(phone.shellCalls, isEmpty);
    });

    test('an active tier reads and grants through that tier', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      phone.clip = const PowerClip('hello', sensitive: true);

      final read = await power.readClipboard();
      final granted = await power.grant(.notificationAccess);

      expect(read?.text, 'hello');
      expect(read?.sensitive, isTrue);
      expect(granted, isTrue);
      expect(power.status.notificationAccess, isTrue);
      expect(phone.shellCalls, [
        'read:shizuku',
        'grant:shizuku:notificationAccess',
      ]);
    });

    test('the watch runs only while someone listens', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      await settle();
      expect(phone.watchedTier, isNull);

      final clips = <PowerClip>[];
      final subscription = power.clipboardChanges.listen(clips.add);
      await settle();
      expect(phone.watchedTier, PowerTier.shizuku);
      expect(power.isWatchingClipboard, isTrue);

      phone.copy('copied elsewhere');
      await settle();
      expect(clips.single.text, 'copied elsewhere');

      await subscription.cancel();
      await settle();
      expect(phone.watchedTier, isNull);
      expect(power.isWatchingClipboard, isFalse);
    });

    test('the watch stops with the tier and comes back with it', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      final clips = <PowerClip>[];
      power.clipboardChanges.listen(clips.add);
      await settle();

      phone.emit(shizukuStopped);
      await settle();
      expect(phone.watchedTier, isNull);
      phone.copy('while stopped');
      await settle();

      phone.emit(shizukuReady);
      await settle();

      expect(clips, isEmpty);
      expect(phone.watchedTier, PowerTier.shizuku);
    });

    test('turning the tier off stops a running watch', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      power.clipboardChanges.listen((_) {});
      await settle();

      power.setShizukuEnabled(false);
      await settle();

      expect(phone.watchedTier, isNull);
      expect(phone.shellCalls.last, 'stop');
    });

    test('a watch that ends on its own is restarted', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      power.clipboardChanges.listen((_) {});
      await settle();

      phone.stopWatch();
      await settle();
      await settle();

      expect(phone.watchedTier, PowerTier.shizuku);
    });

    test('a watch that keeps ending is left alone until a refresh', () async {
      start(shizukuReady);
      await power.configure(shizuku: true, root: false);
      power.clipboardChanges.listen((_) {});
      await settle();

      for (var round = 0; round < PowerCapabilities.maxWatchRestarts; round++) {
        phone.stopWatch();
        await settle();
        await settle();
      }
      expect(phone.watchedTier, isNull);

      await power.refresh();
      await settle();
      expect(phone.watchedTier, PowerTier.shizuku);
    });

    test('a watch that cannot start is given up on, not looped', () async {
      start(shizukuReady);
      phone.failWatch = true;
      await power.configure(shizuku: true, root: false);
      power.clipboardChanges.listen((_) {});

      for (var round = 0; round < 6; round++) {
        phone.emit(
          PowerStatus(
            supported: true,
            shizuku: .ready,
            notificationAccess: round.isEven,
          ),
        );
        await settle();
      }

      expect(power.isWatchingClipboard, isFalse);
      expect(
        phone.shellCalls.where((call) => call.startsWith('watch')),
        hasLength(PowerCapabilities.maxWatchRestarts),
      );
    });
  });

  test('other platforms have nothing to offer and run nothing', () async {
    final desktop = PowerCapabilities.withPlatform(
      const UnsupportedPowerPlatform(),
    );
    addTearDown(desktop.dispose);

    await desktop.configure(shizuku: true, root: true);

    expect(desktop.status.supported, isFalse);
    expect(desktop.activeTier, PowerTier.standard);
    expect(await desktop.readClipboard(), isNull);
    expect(await desktop.enableRoot(), isFalse);
  });
}
