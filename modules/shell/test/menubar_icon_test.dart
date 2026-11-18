import 'dart:async';
import 'dart:ui';

import 'package:feature_kit/feature_kit.dart';
import 'package:ferret_menubar/ferret_menubar.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

class _HeldTimer implements Timer {
  _HeldTimer(this.hold, this._onEnded);

  final Duration hold;
  final void Function() _onEnded;

  @override
  bool isActive = true;

  @override
  int get tick => 0;

  @override
  void cancel() => isActive = false;

  void end() {
    if (!isActive) {
      return;
    }

    isActive = false;
    _onEnded();
  }
}

void main() {
  late List<_HeldTimer> timers;
  late int holdsEnded;
  late MenubarIconResolver resolver;

  setUp(() {
    timers = [];
    holdsEnded = 0;
    resolver = MenubarIconResolver(
      onHoldEnded: () => holdsEnded++,
      createTimer: (hold, onEnded) {
        final timer = _HeldTimer(hold, onEnded);
        timers.add(timer);
        return timer;
      },
    );
  });

  group('which state the icon shows', () {
    test('alone with nothing connected, normal with a device', () {
      expect(
        resolver.resolve(const MenubarIconInputs()),
        MenubarIconState.alone,
      );
      expect(
        resolver.resolve(const MenubarIconInputs(connectedCount: 2)),
        MenubarIconState.normal,
      );
    });

    test('paused beats connected or alone', () {
      const inputs = MenubarIconInputs(connectedCount: 1, isPaused: true);

      expect(resolver.resolve(inputs), MenubarIconState.paused);
    });

    test('a running transfer beats paused', () {
      const inputs = MenubarIconInputs(isPaused: true, progress: 0);

      expect(resolver.resolve(inputs), MenubarIconState.working);
    });

    test('a request waiting for the person beats everything', () {
      const inputs = MenubarIconInputs(
        connectedCount: 1,
        isPaused: true,
        progress: 0.5,
        waitingCount: 1,
        finishedCount: 1,
      );

      expect(resolver.resolve(inputs), MenubarIconState.needsYou);
    });

    test('never asks for the drag-over state, which is the icon\'s own', () {
      const all = [
        MenubarIconInputs(),
        MenubarIconInputs(connectedCount: 1),
        MenubarIconInputs(isPaused: true),
        MenubarIconInputs(progress: 1),
        MenubarIconInputs(waitingCount: 3),
        MenubarIconInputs(finishedCount: 1),
      ];

      final states = [for (final inputs in all) resolver.resolve(inputs)];

      expect(states, isNot(contains(MenubarIconState.dragOver)));
    });
  });

  group('the check', () {
    test('shows for 1.5 s after a transfer went through, then goes', () {
      const working = MenubarIconInputs(connectedCount: 1, progress: 0.9);
      const finished = MenubarIconInputs(connectedCount: 1, finishedCount: 1);

      expect(resolver.resolve(working), MenubarIconState.working);
      expect(resolver.resolve(finished), MenubarIconState.done);
      expect(timers.single.hold, const Duration(milliseconds: 1500));
      expect(resolver.resolve(finished), MenubarIconState.done);

      timers.single.end();

      expect(holdsEnded, 1);
      expect(resolver.resolve(finished), MenubarIconState.normal);
    });

    test('never shows when the transfer failed', () {
      const working = MenubarIconInputs(connectedCount: 1, progress: 0.4);
      const failed = MenubarIconInputs(connectedCount: 1);

      resolver.resolve(working);

      expect(resolver.resolve(failed), MenubarIconState.normal);
      expect(timers, isEmpty);
    });

    test('waits for the last transfer while another still runs', () {
      const oneLeft = MenubarIconInputs(progress: 0.2, finishedCount: 1);
      const lastFailed = MenubarIconInputs(finishedCount: 1);

      expect(resolver.resolve(oneLeft), MenubarIconState.working);
      expect(timers, isEmpty);
      expect(resolver.resolve(lastFailed), MenubarIconState.alone);
    });

    test('shows when the last of several transfers went through', () {
      const oneLeft = MenubarIconInputs(progress: 0.2, finishedCount: 1);
      const allDone = MenubarIconInputs(finishedCount: 2);

      resolver.resolve(oneLeft);

      expect(resolver.resolve(allDone), MenubarIconState.done);
    });

    test('gives way to a new transfer, a request and a pause', () {
      resolver.resolve(const MenubarIconInputs(finishedCount: 1));

      expect(
        resolver.resolve(
          const MenubarIconInputs(finishedCount: 1, progress: 0),
        ),
        MenubarIconState.working,
      );
      expect(
        resolver.resolve(
          const MenubarIconInputs(finishedCount: 1, waitingCount: 1),
        ),
        MenubarIconState.needsYou,
      );
      expect(
        resolver.resolve(
          const MenubarIconInputs(finishedCount: 1, isPaused: true),
        ),
        MenubarIconState.paused,
      );
    });

    test('starts over when another transfer finishes meanwhile', () {
      resolver.resolve(const MenubarIconInputs(finishedCount: 1));
      resolver.resolve(const MenubarIconInputs(finishedCount: 2));

      expect(timers, hasLength(2));
      expect(timers.first.isActive, isFalse);

      timers.first.end();

      expect(
        resolver.resolve(const MenubarIconInputs(finishedCount: 2)),
        MenubarIconState.done,
      );
    });

    test('is forgotten on dispose', () {
      resolver.resolve(const MenubarIconInputs(finishedCount: 1));

      resolver.dispose();
      timers.single.end();

      expect(holdsEnded, 0);
    });
  });

  group('gathering the inputs', () {
    test('names the one connected device, counts several', () {
      final one = MenubarIconInputs.gather(
        connectedNames: ['Pixel 9'],
        isPaused: false,
        pairingName: null,
        busy: const [],
      );
      final two = MenubarIconInputs.gather(
        connectedNames: ['Pixel 9', 'iPad'],
        isPaused: true,
        pairingName: null,
        busy: const [],
      );

      expect(one.connectedCount, 1);
      expect(one.connectedName, 'Pixel 9');
      expect(one.progress, isNull);
      expect(two.connectedCount, 2);
      expect(two.connectedName, isEmpty);
      expect(two.isPaused, isTrue);
    });

    test('a pairing request counts and is named before a file request', () {
      final inputs = MenubarIconInputs.gather(
        connectedNames: const [],
        isPaused: false,
        pairingName: 'ThinkPad',
        busy: const [FeatureBusy(waitingCount: 2, waitingName: 'Ana')],
      );

      expect(inputs.waitingCount, 3);
      expect(inputs.waitingName, 'ThinkPad');
      expect(inputs.isPairingWaiting, isTrue);
    });

    test('sums up what the features are busy with', () {
      final inputs = MenubarIconInputs.gather(
        connectedNames: const ['Pixel 9'],
        isPaused: false,
        pairingName: null,
        busy: const [
          FeatureBusy(finishedCount: 2),
          FeatureBusy(
            progress: 0.5,
            peerName: 'Pixel 9',
            isSending: false,
            waitingCount: 1,
            waitingName: 'Ana',
            finishedCount: 1,
          ),
          FeatureBusy(progress: 1),
        ],
      );

      expect(inputs.progress, 0.75);
      expect(inputs.peerName, 'Pixel 9');
      expect(inputs.isSending, isFalse);
      expect(inputs.waitingCount, 1);
      expect(inputs.waitingName, 'Ana');
      expect(inputs.isPairingWaiting, isFalse);
      expect(inputs.finishedCount, 3);
    });
  });

  group('the tooltip', () {
    final tooltips = MenubarTooltips(
      lookupShellLocalizations(const Locale('en')),
    );

    test('says who is connected', () {
      expect(
        tooltips.of(
          .normal,
          const MenubarIconInputs(connectedCount: 1, connectedName: 'Pixel 9'),
        ),
        'Ferret · Connected to Pixel 9',
      );
      expect(
        tooltips.of(.normal, const MenubarIconInputs(connectedCount: 3)),
        'Ferret · 3 devices connected',
      );
      expect(
        tooltips.of(.alone, const MenubarIconInputs()),
        'Ferret · No device connected',
      );
    });

    test('names the device a transfer is with', () {
      expect(
        tooltips.of(
          .working,
          const MenubarIconInputs(progress: 0.1, peerName: 'Pixel 9'),
        ),
        'Ferret · Sending to Pixel 9',
      );
      expect(
        tooltips.of(
          .working,
          const MenubarIconInputs(
            progress: 0.1,
            peerName: 'Pixel 9',
            isSending: false,
          ),
        ),
        'Ferret · Receiving from Pixel 9',
      );
      expect(
        tooltips.of(.working, const MenubarIconInputs(progress: 0.1)),
        'Ferret · Sending',
      );
      expect(tooltips.of(.done, const MenubarIconInputs()), 'Ferret · Done');
    });

    test('says who is waiting, or how many', () {
      expect(
        tooltips.of(
          .needsYou,
          const MenubarIconInputs(
            waitingCount: 1,
            waitingName: 'Pixel 9',
            isPairingWaiting: true,
          ),
        ),
        'Ferret · Pixel 9 wants to pair',
      );
      expect(
        tooltips.of(
          .needsYou,
          const MenubarIconInputs(waitingCount: 1, waitingName: 'Ana'),
        ),
        'Ferret · Ana wants to send you something',
      );
      expect(
        tooltips.of(
          .needsYou,
          const MenubarIconInputs(waitingCount: 2, waitingName: 'Ana'),
        ),
        'Ferret · 2 requests are waiting for you',
      );
    });

    test('says paused', () {
      expect(
        tooltips.of(.paused, const MenubarIconInputs(isPaused: true)),
        'Ferret · Paused',
      );
    });
  });
}
