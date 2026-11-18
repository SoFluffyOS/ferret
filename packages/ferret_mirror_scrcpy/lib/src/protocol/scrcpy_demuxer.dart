import 'dart:convert';
import 'dart:typed_data';

import 'package:ferret_mirror_scrcpy/src/protocol/byte_queue.dart';
import 'package:ferret_mirror_scrcpy/src/protocol/scrcpy_packet.dart';

/// Reads the video socket of scrcpy's server (protocol of scrcpy 4.0 and
/// later, checked against 5.0.1): on a forward tunnel one dummy byte, then
/// 64 bytes of device name, the codec id, and from there 12-byte headers,
/// each one a session packet or the header of a media packet.
class ScrcpyDemuxer {
  ScrcpyDemuxer({this.expectDummyByte = true});

  static const int deviceNameLength = 64;
  static const int headerLength = 12;

  /// A sane ceiling for one encoded picture: a bigger size means the stream
  /// is out of step, not a real frame.
  static const int maxPacketLength = 64 * 1024 * 1024;

  static const int _sessionFlag = 0x80;
  static const int _configFlag = 0x40;
  static const int _keyframeFlag = 0x20;
  static const int _ptsMask = 0x1FFFFFFFFFFFFFFF;

  /// The server sends it on a forward tunnel only, where a connection opens
  /// even when nothing listens on the device.
  final bool expectDummyByte;

  final ByteQueue _queue = .new();
  _Step _step = .start;
  Uint8List? _mediaHeader;

  /// Feeds what the socket gave and returns every packet now complete.
  /// Throws a [FormatException] when the stream can't be scrcpy's.
  List<ScrcpyPacket> add(List<int> chunk) {
    _queue.add(chunk);

    final packets = <ScrcpyPacket>[];
    while (_readNext(packets)) {}

    return packets;
  }

  /// Whether a step finished, so the next one may have its bytes too.
  bool _readNext(List<ScrcpyPacket> packets) {
    return switch (_step) {
      .start => _readStart(),
      .deviceMeta => _readDeviceMeta(packets),
      .codec => _readCodec(packets),
      .header => _readHeader(packets),
      .payload => _readPayload(packets),
    };
  }

  bool _readStart() {
    if (expectDummyByte && _queue.take(1) == null) {
      return false;
    }

    _step = .deviceMeta;
    return true;
  }

  bool _readDeviceMeta(List<ScrcpyPacket> packets) {
    final field = _queue.take(deviceNameLength);
    if (field == null) {
      return false;
    }

    final end = field.indexOf(0);
    final nameBytes = switch (end) {
      -1 => field,
      _ => Uint8List.sublistView(field, 0, end),
    };

    _step = .codec;
    packets.add(DeviceMetaPacket(utf8.decode(nameBytes, allowMalformed: true)));
    return true;
  }

  bool _readCodec(List<ScrcpyPacket> packets) {
    final field = _queue.take(4);
    if (field == null) {
      return false;
    }

    _step = .header;
    packets.add(CodecPacket(ByteData.sublistView(field).getUint32(0)));
    return true;
  }

  bool _readHeader(List<ScrcpyPacket> packets) {
    final header = _queue.take(headerLength);
    if (header == null) {
      return false;
    }

    final fields = ByteData.sublistView(header);
    if (header[0] & _sessionFlag != 0) {
      packets.add(
        SessionPacket(width: fields.getUint32(4), height: fields.getUint32(8)),
      );
      return true;
    }

    if (fields.getUint32(8) > maxPacketLength) {
      throw const FormatException('Media packet too large');
    }

    _mediaHeader = header;
    _step = .payload;
    return true;
  }

  bool _readPayload(List<ScrcpyPacket> packets) {
    final header = _mediaHeader;
    if (header == null) {
      throw StateError('Payload without a header');
    }

    final fields = ByteData.sublistView(header);
    final data = _queue.take(fields.getUint32(8));
    if (data == null) {
      return false;
    }

    final isConfig = header[0] & _configFlag != 0;
    final ptsUs = switch (isConfig) {
      true => 0,
      false => fields.getUint64(0) & _ptsMask,
    };

    _mediaHeader = null;
    _step = .header;
    packets.add(
      MediaPacket(
        data: data,
        ptsUs: ptsUs,
        isConfig: isConfig,
        isKeyframe: !isConfig && header[0] & _keyframeFlag != 0,
      ),
    );
    return true;
  }
}

enum _Step { start, deviceMeta, codec, header, payload }
