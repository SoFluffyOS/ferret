import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:interop_quickshare/interop_quickshare.dart';

import 'localsend_devices.dart';

/// An Android phone sending with Quick Share, played by the package's own
/// sender.
class QuickSharePhone {
  QuickSharePhone(this.laptop, {this.name = 'Pixel 8'});

  final SoloDevice laptop;
  final String name;

  /// The PIN the phone's screen would show for the last transfer.
  String? pin;
  QuickShareSendJob? _job;

  /// Starts sending, as tapping the laptop in the share sheet would.
  Future<QuickShareSendResult> send({
    List<QuickShareOutgoingFile> files = const [],
    String? text,
  }) {
    final job = QuickShareSendJob(
      address: InternetAddress.loopbackIPv4,
      port: laptop.quickShare.port ?? 0,
      sender: QuickShareEndpointInfo(name: name, kind: .phone),
      files: files,
      text: text,
      chunkSize: 8 * 1024,
      timeouts: loopbackQuickShare.timeouts,
      onPin: (shown) => pin = shown,
    );
    _job = job;
    return job.run();
  }

  Future<void> cancel() async {
    await _job?.cancel();
  }
}

QuickShareOutgoingFile phoneFile(String name, List<int> bytes) =>
    QuickShareOutgoingFile(
      name: name,
      size: bytes.length,
      open: () => Stream.fromIterable([
        for (var start = 0; start < bytes.length; start += 4096)
          bytes.sublist(start, min(start + 4096, bytes.length)),
      ]),
    );

/// [file] as part of a shared folder.
QuickShareOutgoingFile inFolder(QuickShareOutgoingFile file, String folder) =>
    QuickShareOutgoingFile(
      name: file.name,
      size: file.size,
      open: file.open,
      mimeType: file.mimeType,
      parentFolder: folder,
    );

/// A file that sends [first], then waits for [gate] before the [rest].
QuickShareOutgoingFile gatedPhoneFile(
  String name,
  List<int> first,
  List<int> rest,
  Future<void> gate,
) => QuickShareOutgoingFile(
  name: name,
  size: first.length + rest.length,
  open: () async* {
    yield first;
    await gate;
    yield rest;
  },
);
