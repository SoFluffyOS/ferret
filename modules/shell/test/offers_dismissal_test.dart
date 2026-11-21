import 'package:core/core.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shell/services/services.dart';

void main() {
  test('the card shows until it is waved off', () async {
    final dismissal = OffersDismissal(MemorySettingsStore());

    expect(dismissal.hides({'calls', 'messages'}), isFalse);

    await dismissal.dismiss({'calls', 'messages'});

    expect(dismissal.hides({'calls', 'messages'}), isTrue);
    expect(dismissal.hides({'calls'}), isTrue);
    expect(dismissal.hides({}), isTrue);
  });

  test(
    'a feature offered for the first time brings the card back once',
    () async {
      final dismissal = OffersDismissal(MemorySettingsStore());
      await dismissal.dismiss({'calls'});

      expect(dismissal.hides({'calls', 'clipboard'}), isFalse);

      await dismissal.dismiss({'calls', 'clipboard'});

      expect(dismissal.hides({'calls', 'clipboard'}), isTrue);
      expect(dismissal.hides({'clipboard'}), isTrue);
    },
  );
}
