import 'package:ferret_bonjour/ferret_bonjour.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('io.sofluffy.ferret_bonjour/local_network');

  void answer(Object? Function() reply) => TestDefaultBinaryMessengerBinding
      .instance
      .defaultBinaryMessenger
      .setMockMethodCallHandler(channel, (call) async => reply());

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  test('reads what the iPhone says', () async {
    for (final (reply, state) in [
      ('denied', LocalNetworkState.denied),
      ('allowed', LocalNetworkState.allowed),
      ('unknown', LocalNetworkState.unknown),
      (null, LocalNetworkState.unknown),
    ]) {
      answer(() => reply);
      expect(await const LocalNetworkProbe(isIos: true).check(), state);
    }
  });

  test('a failing check tells nothing', () async {
    answer(() => throw PlatformException(code: 'boom'));
    expect(
      await const LocalNetworkProbe(isIos: true).check(),
      LocalNetworkState.unknown,
    );
  });

  test('asks nothing off an iPhone', () async {
    var asked = false;
    answer(() {
      asked = true;
      return 'denied';
    });

    expect(
      await const LocalNetworkProbe(isIos: false).check(),
      LocalNetworkState.unknown,
    );
    expect(asked, isFalse);
  });
}
