import 'package:ferret_messages/ferret_messages.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingHostApi implements MessagesHostApi {
  final List<Object?> calls = [];

  @override
  Future<PlatformMessagePage> listMessages(
    int threadId,
    int beforeDateMs,
    List<String> skipIds,
    int limit,
  ) async {
    calls.add((
      'listMessages',
      threadId,
      beforeDateMs,
      skipIds.join(','),
      limit,
    ));
    return PlatformMessagePage(messages: [], hasMore: false);
  }

  @override
  Future<PlatformSendResult> send(
    int threadId,
    List<String> addresses,
    String text,
  ) async {
    calls.add(('send', threadId, addresses.join(','), text));
    return PlatformSendResult(failure: .none, threadId: 4);
  }

  @override
  Future<PlatformConversationPage> listConversations(
    int beforeDateMs,
    int limit,
  ) async {
    calls.add(('listConversations', beforeDateMs, limit));
    return PlatformConversationPage(conversations: [], hasMore: false);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _RecordingHostApi host;
  late FerretMessages messages;

  setUp(() {
    host = _RecordingHostApi();
    messages = FerretMessages(hostApi: host);
  });

  test('the newest page is asked with no date', () async {
    await messages.listConversations(limit: 30);
    await messages.listMessages(7, limit: 50);

    expect(host.calls, [
      ('listConversations', 0, 30),
      ('listMessages', 7, 0, '', 50),
    ]);
  });

  test('older pages pass the date and the ids already held', () async {
    await messages.listMessages(
      7,
      beforeDateMs: 1000,
      skipIds: ['sms:1'],
      limit: 50,
    );

    expect(host.calls.single, ('listMessages', 7, 1000, 'sms:1', 50));
  });

  test('a reply goes to its conversation', () async {
    final result = await messages.send(threadId: 7, text: 'hi');

    expect(host.calls.single, ('send', 7, '', 'hi'));
    expect(result.failure, PlatformSendFailure.none);
  });
}
