import 'dart:convert';

import 'package:interop_localsend/interop_localsend.dart';
import 'package:test/test.dart';

/// The examples from the protocol README, without their comments.
const _announce = '''
{
  "alias": "Nice Orange",
  "version": "2.0",
  "deviceModel": "Samsung",
  "deviceType": "mobile",
  "fingerprint": "random string",
  "port": 53317,
  "protocol": "https",
  "download": true,
  "announce": true
}''';

const _registerAnswer = '''
{
  "alias": "Nice Orange",
  "version": "2.0",
  "deviceModel": "Samsung",
  "deviceType": "mobile",
  "fingerprint": "random string",
  "download": true
}''';

const _prepareUpload = '''
{
  "info": {
    "alias": "Nice Orange",
    "version": "2.0",
    "deviceModel": "Samsung",
    "deviceType": "mobile",
    "fingerprint": "random string",
    "port": 53317,
    "protocol": "https",
    "download": true
  },
  "files": {
    "some file id": {
      "id": "some file id",
      "fileName": "my image.png",
      "size": 324242,
      "fileType": "image/jpeg",
      "sha256": "*sha256 hash*",
      "preview": "*preview data*",
      "metadata": {
        "modified": "2021-01-01T12:34:56Z",
        "accessed": "2021-01-01T12:34:56Z"
      }
    },
    "another file id": {
      "id": "another file id",
      "fileName": "another image.jpg",
      "size": 1234,
      "fileType": "image/jpeg",
      "sha256": "*sha256 hash*",
      "preview": "*preview data*"
    }
  }
}''';

const _prepareAnswer = '''
{
  "sessionId": "mySessionId",
  "files": {
    "someFileId": "someFileToken",
    "someOtherFileId": "someOtherFileToken"
  }
}''';

void main() {
  group('device description', () {
    test('reads the announcement example', () {
      final info = LocalSendInfo.fromJson(jsonDecode(_announce));

      expect(info?.alias, 'Nice Orange');
      expect(info?.version, '2.0');
      expect(info?.deviceModel, 'Samsung');
      expect(info?.deviceType, LocalSendDeviceType.mobile);
      expect(info?.fingerprint, 'random string');
      expect(info?.port, 53317);
      expect(info?.protocol, 'https');
      expect(info?.download, isTrue);
      expect(info?.isEncrypted, isTrue);
    });

    test('reads a register answer, which has no port or protocol', () {
      final info = LocalSendInfo.fromJson(jsonDecode(_registerAnswer));

      expect(info?.alias, 'Nice Orange');
      expect(info?.port, isNull);
      expect(info?.protocol, isNull);
    });

    test('writes the fields the protocol lists', () {
      const info = LocalSendInfo(
        alias: 'Secret Banana',
        fingerprint: 'abc',
        deviceModel: 'Windows',
        deviceType: .desktop,
        port: 53317,
        protocol: 'https',
        download: true,
      );

      expect(info.toJson(), {
        'alias': 'Secret Banana',
        'version': '2.2',
        'deviceModel': 'Windows',
        'deviceType': 'desktop',
        'fingerprint': 'abc',
        'port': 53317,
        'protocol': 'https',
        'download': true,
      });
      expect(info.toAnswerJson().keys, isNot(contains('port')));
      expect(LocalSendInfo.fromJson(info.toJson())?.toJson(), info.toJson());
    });

    test('nullable fields may be missing or null', () {
      final info = LocalSendInfo.fromJson({
        'alias': 'Pad',
        'fingerprint': 'f',
        'deviceModel': null,
        'deviceType': null,
      });

      expect(info?.deviceModel, isNull);
      expect(info?.deviceType, LocalSendDeviceType.desktop);
      expect(info?.download, isFalse);
    });

    test('unknown device types fall back to desktop', () {
      expect(LocalSendDeviceType.parse('fridge'), LocalSendDeviceType.desktop);
      expect(
        LocalSendDeviceType.parse('headless'),
        LocalSendDeviceType.headless,
      );
    });

    test('refuses descriptions without an alias or a fingerprint', () {
      expect(LocalSendInfo.fromJson({'alias': 'A'}), isNull);
      expect(LocalSendInfo.fromJson({'fingerprint': 'f'}), isNull);
      expect(LocalSendInfo.fromJson({'alias': 7, 'fingerprint': 'f'}), isNull);
      expect(LocalSendInfo.fromJson('nope'), isNull);
      expect(
        LocalSendInfo.fromJson({'alias': 'A', 'fingerprint': 'f', 'port': 0}),
        isNull,
      );
    });

    test('cleans names that come from the network', () {
      final info = LocalSendInfo.fromJson({
        'alias': 'Nice\nOrange\u0000${'x' * 200}',
        'fingerprint': 'f',
      });

      expect(info?.alias, hasLength(64));
      expect(info?.alias, startsWith('Nice Orange'));
    });
  });

  group('prepare-upload', () {
    test('reads the request example', () {
      final request = PrepareUploadRequest.fromJson(jsonDecode(_prepareUpload));

      expect(request?.info.alias, 'Nice Orange');
      expect(request?.files.keys, ['some file id', 'another file id']);
      final first = request?.files['some file id'];
      expect(first?.fileName, 'my image.png');
      expect(first?.size, 324242);
      expect(first?.fileType, 'image/jpeg');
      expect(first?.sha256, '*sha256 hash*');
      expect(first?.preview, '*preview data*');
      expect(first?.modified, DateTime.utc(2021, 1, 1, 12, 34, 56));
      expect(request?.files['another file id']?.modified, isNull);
      expect(request?.totalBytes, 324242 + 1234);
    });

    test('a request survives writing and reading back', () {
      final request = PrepareUploadRequest.fromJson(jsonDecode(_prepareUpload));
      final again = PrepareUploadRequest.fromJson(
        jsonDecode(jsonEncode(request?.toJson())),
      );

      expect(again?.toJson(), request?.toJson());
      expect(
        jsonDecode(jsonEncode(request?.toJson())),
        jsonDecode(_prepareUpload),
      );
    });

    test('refuses malformed requests', () {
      final good = jsonDecode(_prepareUpload) as Map<String, dynamic>;

      expect(PrepareUploadRequest.fromJson({...good, 'files': {}}), isNull);
      expect(PrepareUploadRequest.fromJson({'files': good['files']}), isNull);
      expect(
        PrepareUploadRequest.fromJson({
          ...good,
          'files': {
            'a': {'id': 'b', 'fileName': 'x', 'size': 1},
          },
        }),
        isNull,
      );
      expect(
        PrepareUploadRequest.fromJson({
          ...good,
          'files': {
            'a': {'id': 'a', 'fileName': 'x', 'size': -1},
          },
        }),
        isNull,
      );
    });

    test('reads and writes the answer example', () {
      final answer = PrepareUploadResponse.fromJson(jsonDecode(_prepareAnswer));

      expect(answer?.sessionId, 'mySessionId');
      expect(answer?.files, {
        'someFileId': 'someFileToken',
        'someOtherFileId': 'someOtherFileToken',
      });
      expect(answer?.toJson(), jsonDecode(_prepareAnswer));
      expect(PrepareUploadResponse.fromJson({'files': {}}), isNull);
    });

    test('a text file with a preview is a message', () {
      const message = LocalSendFile(
        id: 'm',
        fileName: 'm.txt',
        size: 5,
        fileType: 'text/plain',
        preview: 'hello',
      );
      const photo = LocalSendFile(id: 'p', fileName: 'p.jpg', size: 5);

      expect(message.isMessage, isTrue);
      expect(photo.isMessage, isFalse);
      expect(photo.toJson().keys, isNot(contains('metadata')));
    });
  });

  test('HTTP statuses map to the protocol error tables', () {
    expect(LocalSendFailure.fromStatus(400), LocalSendFailure.invalidRequest);
    expect(LocalSendFailure.fromStatus(401), LocalSendFailure.pinRequired);
    expect(LocalSendFailure.fromStatus(403), LocalSendFailure.rejected);
    expect(LocalSendFailure.fromStatus(409), LocalSendFailure.busy);
    expect(LocalSendFailure.fromStatus(422), LocalSendFailure.checksum);
    expect(LocalSendFailure.fromStatus(429), LocalSendFailure.tooManyRequests);
    expect(LocalSendFailure.fromStatus(500), LocalSendFailure.receiverError);
    expect(LocalSendFailure.fromStatus(418), LocalSendFailure.unexpected);
  });
}
