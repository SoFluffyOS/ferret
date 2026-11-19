import 'package:feature_kit/feature_kit.dart';
import 'package:protocol/messages.dart';

/// How people in a conversation are called on screen.
extension ConversationNames on Conversation {
  /// Contact names, or the numbers of people who aren't contacts, joined.
  String get title {
    final names = [for (final participant in participants) participant.label];
    return ListText.join(names.where((name) => name.isNotEmpty));
  }

  /// The person with [address], matching numbers loosely since the phone
  /// stores them in several formats.
  Participant? participantFor(String address) {
    final wanted = _digitsOf(address);
    for (final participant in participants) {
      if (participant.address == address) {
        return participant;
      }

      if (wanted.length >= _minDigits &&
          _digitsOf(participant.address).endsWith(wanted)) {
        return participant;
      }
    }

    return null;
  }

  /// The name of whoever sent from [address], or the address itself.
  String nameFor(String address) => participantFor(address)?.label ?? address;

  static const _minDigits = 6;

  static String _digitsOf(String address) =>
      address.replaceAll(RegExp(r'\D'), '');
}

extension ParticipantLabel on Participant {
  String get label => switch (name.isEmpty) {
    true => address,
    false => name,
  };
}
