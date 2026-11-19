import 'package:ferret_cli/commands/commands.dart';
import 'package:test/test.dart';

void main() {
  const device = {'id': 'aaaa', 'name': 'Pixel 7'};

  String line(Map<String, Object?> event) =>
      WatchLine.of({'at': '2026-11-19T09:30:00.000Z', ...event}).substring(10);

  test('says each event in words', () {
    expect(
      line({'type': 'battery', 'device': device, 'percent': 42}),
      'Pixel 7 battery 42%',
    );
    expect(
      line({
        'type': 'file.received',
        'device': device,
        'files': 2,
        'bytes': 1200000,
      }),
      'Pixel 7 sent 2 files (1.2 MB)',
    );
    expect(
      line({
        'type': 'notification.received',
        'device': device,
        'app': 'Signal',
        'title': 'Anna',
      }),
      'Pixel 7 notification from Signal: Anna',
    );
    expect(
      line({'type': 'call.ended', 'device': device, 'missed': true}),
      'Pixel 7 missed call',
    );
    expect(
      line({'type': 'something.new', 'device': device}),
      'something.new Pixel 7',
    );
  });

  test('prints a clip only when its text came with it', () {
    expect(
      line({'type': 'clipboard.received', 'device': device, 'kind': 'text'}),
      'Pixel 7 sent a clip (text)',
    );
    expect(
      line({
        'type': 'clipboard.received',
        'device': device,
        'kind': 'text',
        'text': 'hello',
      }),
      'Pixel 7 sent a clip: hello',
    );
  });
}
