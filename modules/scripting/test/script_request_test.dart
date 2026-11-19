import 'package:flutter_test/flutter_test.dart';
import 'package:scripting/scripting.dart';

void main() {
  ScriptRequest? read(Map<String, Object?> map) =>
      ScriptRequest.fromMap(ScriptSource.tasker, map);

  test('maps each command to the app command arguments', () {
    expect(
      read({'command': 'open', 'device': 'Mac', 'value': 'https://a.b'})
          ?.arguments,
      {'device': 'Mac', 'link': 'https://a.b'},
    );
    expect(
      read({'command': 'action_run', 'device': 'Mac', 'value': 'sleep'})
          ?.arguments,
      {'device': 'Mac', 'action': 'sleep'},
    );
    expect(
      read({
        'command': 'notify',
        'device': 'Mac',
        'value': 'Hi',
        'body': 'there',
      })?.arguments,
      {'device': 'Mac', 'title': 'Hi', 'body': 'there'},
    );
    expect(read({'command': 'ring', 'device': ' Mac '})?.arguments, {
      'device': 'Mac',
    });
  });

  test('text with no device goes to every connected device', () {
    expect(
      read({'command': 'clipboard_send', 'device': '', 'value': 'hi'})
          ?.arguments,
      {'text': 'hi'},
    );
  });

  test('a request with no command is ignored', () {
    expect(read({'device': 'Mac'}), isNull);
  });

  test('requests from before the app was ready run once it is', () async {
    final feature = ScriptingFeature();
    final ran = <String>[];
    final ring = read({'command': 'ring', 'device': 'Mac'});
    if (ring == null) {
      fail('should read');
    }

    feature.receive(ring);
    feature.runRequestsWith((request) async => ran.add(request.command));
    feature.receive(ring);
    await pumpEventQueue();

    expect(ran, ['ring', 'ring']);
  });
}
