import 'dart:math';

/// Random ids for transfers, unique enough to never collide between devices.
abstract final class TransferIds {
  static final _random = Random.secure();

  static String next() => [
    for (var index = 0; index < 16; index++)
      _random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ].join();
}
