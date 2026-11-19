// ignore_for_file: depend_on_referenced_packages
import 'package:drop/drop.dart';
import 'package:ferret/wiring/wiring.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:photos/photos.dart';

void main() {
  Transfer transfer(TransferStatus status, {int done = 0}) => Transfer(
    id: 't1',
    direction: .incoming,
    deviceId: 'pixel',
    deviceName: 'Pixel 7',
    files: const [
      TransferFile(name: 'a.jpg', size: 100, location: '/r/a.jpg'),
      TransferFile(name: 'b.jpg', size: 100, location: '/r/b.jpg'),
    ],
    status: status,
    startedAt: DateTime(2026, 11, 19),
    bytesDone: done,
  );

  test('a running transfer reports how far it got', () {
    final progress = DropPhotoTransfers.progressOf(
      transfer(.transferring, done: 50),
    );

    expect(progress.status, PhotoTransferStatus.running);
    expect(progress.fraction, 0.25);
    expect(progress.paths, isEmpty);
  });

  test('a finished transfer says where the photos were saved', () {
    final progress = DropPhotoTransfers.progressOf(transfer(.done));

    expect(progress.status, PhotoTransferStatus.done);
    expect(progress.paths, ['/r/a.jpg', '/r/b.jpg']);
  });

  test('a cancelled or failed transfer is a failed save', () {
    expect(
      DropPhotoTransfers.progressOf(transfer(.cancelled)).status,
      PhotoTransferStatus.failed,
    );
    expect(
      DropPhotoTransfers.progressOf(transfer(.failed)).status,
      PhotoTransferStatus.failed,
    );
  });
}
