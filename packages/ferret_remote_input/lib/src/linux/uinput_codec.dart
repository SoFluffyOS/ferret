import 'dart:convert';
import 'dart:typed_data';

/// The bytes and ioctl numbers of the Linux uinput API
/// (`linux/uinput.h`, `linux/input.h`), as generic ioctl encoding on x86
/// and ARM.
abstract final class UinputCodec {
  static const path = '/dev/uinput';

  static const evSyn = 0x00;
  static const evKey = 0x01;
  static const evRel = 0x02;

  static const synReport = 0;

  static const relX = 0x00;
  static const relY = 0x01;
  static const relHWheel = 0x06;
  static const relWheel = 0x08;
  static const relWheelHiRes = 0x0b;
  static const relHWheelHiRes = 0x0c;

  /// One wheel notch in high-resolution units.
  static const hiResPerNotch = 120;

  static const busVirtual = 0x06;

  static const _base = 0x55;
  static const _write = 1 << 30;

  /// `struct uinput_setup`: `input_id` (4 × u16), `name[80]`, u32.
  static const setupSize = 92;
  static const nameSize = 80;

  static const uiDevCreate = (_base << 8) | 1;
  static const uiDevDestroy = (_base << 8) | 2;
  static const uiDevSetup = _write | (setupSize << 16) | (_base << 8) | 3;
  static const uiSetEvBit = _write | (4 << 16) | (_base << 8) | 100;
  static const uiSetKeyBit = _write | (4 << 16) | (_base << 8) | 101;
  static const uiSetRelBit = _write | (4 << 16) | (_base << 8) | 102;

  /// `struct input_event`: a `timeval` of two longs (left zero, the kernel
  /// stamps it), then u16 type, u16 code, s32 value.
  static int eventSize(int longSize) => longSize * 2 + 8;

  static Uint8List event(
    int type,
    int code,
    int value, {
    required int longSize,
  }) {
    final bytes = ByteData(eventSize(longSize));
    final offset = longSize * 2;
    bytes
      ..setUint16(offset, type, Endian.host)
      ..setUint16(offset + 2, code, Endian.host)
      ..setInt32(offset + 4, value, Endian.host);
    return bytes.buffer.asUint8List();
  }

  static Uint8List setup(String name) {
    final bytes = ByteData(setupSize)
      ..setUint16(0, busVirtual, Endian.host)
      ..setUint16(2, 0, Endian.host)
      ..setUint16(4, 0, Endian.host)
      ..setUint16(6, 1, Endian.host);
    final encoded = utf8.encode(name);
    final length = switch (encoded.length < nameSize) {
      true => encoded.length,
      false => nameSize - 1,
    };
    final list = bytes.buffer.asUint8List();
    list.setRange(8, 8 + length, encoded);
    return list;
  }
}
