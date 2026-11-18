// Makes this computer visible to Quick Share for a while and prints the
// offers that come in, to try the package against a real phone:
//
//   dart run tool/advertise.dart [seconds] [name]
//
// Everything is accepted and saved to a new temporary folder.
// ignore_for_file: avoid_print
import 'dart:io';

import 'package:interop_quickshare/interop_quickshare.dart';

Future<void> main(List<String> arguments) async {
  final seconds = switch (arguments) {
    [final first, ...] => int.tryParse(first) ?? 120,
    _ => 120,
  };
  final name = switch (arguments) {
    [_, final second, ...] => second,
    _ => 'Ferret test',
  };
  final folder = await Directory.systemTemp.createTemp('quickshare');
  final server = QuickShareServer(delegate: _PrintingDelegate(folder));
  final port = await server.start();
  final advertiser = QuickShareAdvertiser(
    info: () => QuickShareEndpointInfo(name: name, kind: .laptop),
  );
  await advertiser.start(port);
  print('Visible as "$name" on port $port for $seconds s.');
  print('Saving to ${folder.path}');

  await Future<void>.delayed(Duration(seconds: seconds));
  await advertiser.stop();
  await server.stop();
}

class _PrintingDelegate implements QuickShareReceiveDelegate {
  _PrintingDelegate(this.folder);

  final Directory folder;

  @override
  Future<bool> onOffer(QuickShareOffer offer) async {
    print(
      'Offer with PIN ${offer.pin}: ${offer.files.length} files, '
      '${offer.texts.length} texts, ${offer.totalBytes} bytes',
    );
    return true;
  }

  @override
  Future<File> partFile(QuickShareOffer offer, QuickShareFile file) async =>
      File('${folder.path}/${file.payloadId}.part');

  @override
  void onProgress(QuickShareOffer offer, int receivedBytes) {}

  @override
  Future<void> onFileReceived(
    QuickShareOffer offer,
    QuickShareFile file,
    File part,
  ) async {
    print('Received a file of ${file.size} bytes');
  }

  @override
  void onTextReceived(
    QuickShareOffer offer,
    QuickShareText text,
    String content,
  ) => print('Received a text of ${content.length} characters');

  @override
  void onSessionEnded(QuickShareOffer offer, QuickShareSessionEnd end) =>
      print('Session ended: ${end.name}');
}
