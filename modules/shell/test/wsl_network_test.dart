import 'package:flutter_test/flutter_test.dart';
import 'package:shell/shell.dart';

void main() {
  WslNetwork wsl({
    Map<String, String> environment = const {},
    String? procVersion,
    String? mode,
  }) => WslNetwork(
    environment: environment,
    readFile: (path) async => switch (path) {
      WslNetwork.procVersion => procVersion,
      _ => null,
    },
    networkingMode: () async => mode,
  );

  test('WSL_DISTRO_NAME says it is WSL', () async {
    expect(
      await wsl(environment: {'WSL_DISTRO_NAME': 'Ubuntu'}).isWsl(),
      isTrue,
    );
  });

  test('a Microsoft kernel says it is WSL', () async {
    expect(
      await wsl(
        procVersion:
            'Linux version 6.6.87.2-microsoft-standard-WSL2 (root@x) …',
      ).isWsl(),
      isTrue,
    );
  });

  test('a plain Linux kernel is not WSL', () async {
    final plain = wsl(procVersion: 'Linux version 6.17.0-5-generic …');

    expect(await plain.isWsl(), isFalse);
    expect(await plain.keepsDevicesApart(), isFalse);
  });

  test('NAT, or no answer about it, keeps devices apart; mirrored does '
      'not', () async {
    final inside = {'WSL_DISTRO_NAME': 'Ubuntu'};

    expect(
      await wsl(environment: inside, mode: 'nat\n').keepsDevicesApart(),
      isTrue,
    );
    expect(await wsl(environment: inside).keepsDevicesApart(), isTrue);
    expect(
      await wsl(environment: inside, mode: 'mirrored\n').keepsDevicesApart(),
      isFalse,
    );
  });

  test('none is never WSL', () async {
    expect(await WslNetwork.none().keepsDevicesApart(), isFalse);
  });
}
