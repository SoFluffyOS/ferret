import 'package:flutter_test/flutter_test.dart';
import 'package:remote_input/remote_input.dart';

void main() {
  test('names the app, not its helper or binary', () {
    expect(
      SecureInputHolder.appName(
        '/Applications/Bitwarden.app/Contents/MacOS/Bitwarden',
      ),
      'Bitwarden',
    );
    expect(
      SecureInputHolder.appName(
        '/Applications/1Password.app/Contents/Frameworks/'
        '1Password Helper.app/Contents/MacOS/1Password Helper',
      ),
      '1Password',
    );
    expect(SecureInputHolder.appName('/usr/local/bin/pinentry'), 'pinentry');
  });

  test('the login window and nothing name nobody', () {
    expect(
      SecureInputHolder.appName(
        '/System/Library/CoreServices/loginwindow.app/Contents/MacOS/'
        'loginwindow',
      ),
      isNull,
    );
    expect(SecureInputHolder.appName(''), isNull);
  });
}
