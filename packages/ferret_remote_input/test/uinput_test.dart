import 'dart:typed_data';

import 'package:ferret_remote_input/ferret_remote_input.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeSyscalls implements UinputSyscalls {
  bool writable = true;
  int failRequest = -1;
  final List<(int, int)> ioctls = [];
  Uint8List? setup;
  final List<Uint8List> writes = [];
  bool closed = false;

  @override
  int get longSize => 8;

  @override
  bool canWrite(String path) => writable;

  @override
  int openWrite(String path) => 7;

  @override
  int ioctlValue(int fd, int request, int value) {
    ioctls.add((request, value));
    if (request == failRequest) {
      return -1;
    }

    return 0;
  }

  @override
  int ioctlBytes(int fd, int request, Uint8List bytes) {
    setup = bytes;
    return 0;
  }

  @override
  int write(int fd, Uint8List bytes) {
    writes.add(bytes);
    return bytes.length;
  }

  @override
  void close(int fd) => closed = true;

  /// Every event written, as (type, code, value).
  List<(int, int, int)> get events {
    final all = <(int, int, int)>[];
    for (final bytes in writes) {
      final data = ByteData.sublistView(bytes);
      for (var offset = 0; offset < bytes.length; offset += 24) {
        all.add((
          data.getUint16(offset + 16, Endian.host),
          data.getUint16(offset + 18, Endian.host),
          data.getInt32(offset + 20, Endian.host),
        ));
      }
    }

    return all;
  }
}

void main() {
  const sync = (0, 0, 0);

  test('the ioctl numbers match linux/uinput.h', () {
    expect(UinputCodec.uiDevCreate, 0x5501);
    expect(UinputCodec.uiDevDestroy, 0x5502);
    expect(UinputCodec.uiDevSetup, 0x405C5503);
    expect(UinputCodec.uiSetEvBit, 0x40045564);
    expect(UinputCodec.uiSetKeyBit, 0x40045565);
    expect(UinputCodec.uiSetRelBit, 0x40045566);
  });

  test('an input event is a zero timeval, then type, code and value', () {
    final bytes = UinputCodec.event(2, 1, -7, longSize: 8);
    final data = ByteData.sublistView(bytes);

    expect(bytes, hasLength(24));
    expect(bytes.sublist(0, 16), everyElement(0));
    expect(data.getUint16(16, Endian.host), 2);
    expect(data.getUint16(18, Endian.host), 1);
    expect(data.getInt32(20, Endian.host), -7);
    expect(UinputCodec.event(1, 1, 1, longSize: 4), hasLength(16));
  });

  test('the setup names the device and says it is virtual', () {
    final setup = UinputCodec.setup('Ferret remote input');

    expect(setup, hasLength(92));
    expect(ByteData.sublistView(setup).getUint16(0, Endian.host), 0x06);
    expect(String.fromCharCodes(setup.sublist(8, 27)), 'Ferret remote input');
    expect(setup[27], 0);
  });

  test('creating the device declares keys, buttons and axes', () {
    final syscalls = FakeSyscalls();

    final device = UinputDevice.create(syscalls);

    expect(device, isNotNull);
    expect(
      syscalls.ioctls,
      contains((UinputCodec.uiSetEvBit, UinputCodec.evKey)),
    );
    expect(syscalls.ioctls, contains((UinputCodec.uiSetKeyBit, 0x110)));
    expect(syscalls.ioctls, contains((UinputCodec.uiSetKeyBit, 28)));
    expect(
      syscalls.ioctls,
      contains((UinputCodec.uiSetRelBit, UinputCodec.relWheelHiRes)),
    );
    expect(syscalls.ioctls.last, (UinputCodec.uiDevCreate, 0));
    expect(syscalls.setup, isNotNull);
  });

  test('no device without write access, or when setup fails', () {
    expect(UinputDevice.create(FakeSyscalls()..writable = false), isNull);

    final failing = FakeSyscalls()..failRequest = UinputCodec.uiDevCreate;
    expect(UinputDevice.create(failing), isNull);
    expect(failing.closed, isTrue);
  });

  test('moves and clicks become relative and key events', () {
    final syscalls = FakeSyscalls();
    final device = UinputDevice.create(syscalls);

    device?.send(const [
      MoveAction(5, -3),
      ButtonAction(.left, pressed: true),
      ButtonAction(.left, pressed: false),
    ]);

    expect(syscalls.events, [
      (2, 0, 5),
      (2, 1, -3),
      sync,
      (1, 0x110, 1),
      sync,
      (1, 0x110, 0),
      sync,
    ]);
  });

  test('scrolling sends high resolution steps and whole notches', () {
    final syscalls = FakeSyscalls();
    final device = UinputDevice.create(syscalls);

    device?.send(const [ScrollAction(0, 20), ScrollAction(0, 20)]);

    expect(syscalls.events, [
      (2, UinputCodec.relWheelHiRes, -60),
      sync,
      (2, UinputCodec.relWheelHiRes, -60),
      (2, UinputCodec.relWheel, -1),
      sync,
    ]);
  });

  test('a shortcut holds its modifier around the key', () {
    final syscalls = FakeSyscalls();
    final device = UinputDevice.create(syscalls);

    device?.send(const [
      KeyAction(.c, pressed: true, modifiers: {.control}),
      KeyAction(.c, pressed: false),
    ]);

    expect(syscalls.events.where((event) => event != sync), [
      (1, 29, 1),
      (1, 46, 1),
      (1, 46, 0),
      (1, 29, 0),
    ]);
  });

  test('text types on a US layout and hands back what it cannot', () {
    final syscalls = FakeSyscalls();
    final device = UinputDevice.create(syscalls);

    final untyped = device?.send(const [TextAction('Hé')]);

    expect(untyped, 'é');
    expect(syscalls.events.where((event) => event != sync), [
      (1, 42, 1),
      (1, 35, 1),
      (1, 35, 0),
      (1, 42, 0),
    ]);
  });

  test('closing destroys the device once', () {
    final syscalls = FakeSyscalls();
    final device = UinputDevice.create(syscalls);

    device
      ?..close()
      ..close();

    expect(
      syscalls.ioctls.where((ioctl) => ioctl.$1 == UinputCodec.uiDevDestroy),
      hasLength(1),
    );
    expect(device?.send(const [MoveAction(1, 1)]), '');
  });
}
