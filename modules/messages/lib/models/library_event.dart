import 'package:protocol/messages.dart';

/// Something that happened to a phone's texts on a computer.
sealed class LibraryEvent {
  const LibraryEvent(this.deviceId);

  final String deviceId;
}

/// The phone's state, conversations or messages changed.
class LibraryChanged extends LibraryEvent {
  const LibraryChanged(super.deviceId);
}

/// A text arrived on the phone while connected. Never sent for texts found
/// by syncing after a reconnect.
class IncomingMessage extends LibraryEvent {
  const IncomingMessage(super.deviceId, this.message, this.conversation);

  final Message message;
  final Conversation? conversation;
}
