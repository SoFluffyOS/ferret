import 'package:drop/drop.dart';

Transfer sampleTransfer({
  String id = 't1',
  TransferDirection direction = .incoming,
  TransferStatus status = .transferring,
  TransferFailure? failure,
  List<TransferFile> files = const [
    TransferFile(
      name: 'photo.jpg',
      size: 4 * 1024 * 1024,
      location: '/tmp/photo.jpg',
    ),
  ],
  String? text,
  int bytesDone = 0,
  double bytesPerSecond = 0,
  bool needsAnswer = false,
}) => Transfer(
  id: id,
  direction: direction,
  deviceId: 'phone-id',
  deviceName: 'Pixel',
  files: files,
  text: text,
  status: status,
  failure: failure,
  bytesDone: bytesDone,
  bytesPerSecond: bytesPerSecond,
  needsAnswer: needsAnswer,
  startedAt: DateTime(2026, 11, 18),
);
