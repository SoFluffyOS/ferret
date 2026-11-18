/// The words the ringing notice shows, in the person's language.
class RingTexts {
  const RingTexts({
    required this.title,
    required this.body,
    required this.foundIt,
  });

  /// English, for when no strings were given, such as in tests.
  factory RingTexts.english(String requesterName) => RingTexts(
    title: 'Ferret is ringing',
    body: '$requesterName is looking for this device.',
    foundIt: 'Found it',
  );

  final String title;
  final String body;
  final String foundIt;
}
