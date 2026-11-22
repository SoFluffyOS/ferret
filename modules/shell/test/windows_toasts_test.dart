import 'package:feature_kit/feature_kit.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

void main() {
  LocalNotice sending(double progress) => LocalNotice(
    id: 'drop.1',
    channel: .transfers,
    title: 'Sending to Pixel 9',
    body: 'Holiday.mov · 12 MB/s',
    silent: true,
    progress: progress,
  );

  test('a transfer pops one toast, then moves its bar in place', () {
    final toasts = WindowsToasts();

    expect(toasts.update(1, sending(0.1)), isNull);
    final first = toasts.toast(1, sending(0.1), const []);
    expect(first.title, '{${WindowsToasts.titleKey}}');
    expect(first.details.progressBars.single.value, 0.1);
    expect(
      first.details.bindings[WindowsToasts.titleKey],
      'Sending to Pixel 9',
    );

    expect(toasts.update(1, sending(0.5)), {
      WindowsToasts.titleKey: 'Sending to Pixel 9',
      WindowsToasts.bodyKey: 'Holiday.mov · 12 MB/s',
      WindowsToasts.statusKey: '',
      '${WindowsToasts.barId}-progressValue': '0.5',
    });
  });

  test('the finished transfer gets a toast of its own, with its words', () {
    final toasts = WindowsToasts()..toast(1, sending(0.9), const []);
    const done = LocalNotice(
      id: 'drop.1',
      channel: .transfers,
      title: 'Received from Pixel 9',
      body: 'Holiday.mov',
    );

    expect(toasts.update(1, done), isNull);
    final toast = toasts.toast(1, done, const []);
    expect(toast.title, 'Received from Pixel 9');
    expect(toast.details.progressBars, isEmpty);
    expect(toast.details.audio, isNull);
    expect(toasts.update(1, sending(0.1)), isNull);
  });

  test('a cancelled toast starts over', () {
    final toasts = WindowsToasts()..toast(1, sending(0.2), const []);

    toasts.forget(1);

    expect(toasts.update(1, sending(0.3)), isNull);
  });

  test('silent notices make no sound; a ringing call shows as a call', () {
    final toasts = WindowsToasts();
    const quiet = LocalNotice(
      id: 'q',
      channel: .transfers,
      title: 'Paused',
      silent: true,
    );
    const call = LocalNotice(
      id: 'c',
      channel: .incoming,
      title: 'Mum',
      ringing: true,
    );

    expect(toasts.toast(2, quiet, const []).details.audio, isNotNull);
    final ringing = toasts.toast(3, call, const []).details;
    expect(ringing.scenario, WindowsNotificationScenario.incomingCall);
    expect(ringing.audio, isNull);
  });

  test('a reply button comes with its text box', () {
    final toasts = WindowsToasts();
    const reply = NoticeAction(id: 'reply', label: 'Reply', isReply: true);
    const notice = LocalNotice(id: 'm', channel: .incoming, title: 'Mum');

    final details = toasts.toast(4, notice, const [reply]).details;

    expect(details.actions.single.inputId, 'reply');
    expect(details.inputs.single.id, 'reply');
  });
}
