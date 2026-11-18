/// A step on the ladder of what Android lets Ferret do, lowest first.
enum LadderRung { basic, notifications, messagesAndCalls, shizuku, root }

/// One thing a [LadderRung] adds, shown with a lock until the rung is on.
enum LadderPerk {
  files(.basic),
  clipboardTap(.basic),
  handoff(.basic),
  media(.basic),
  find(.basic),
  notifications(.notifications),
  replies(.notifications),
  messages(.messagesAndCalls),
  calls(.messagesAndCalls),
  clipboardBackground(.shizuku),
  oneTapSetup(.shizuku),
  sameAsShizuku(.root),
  survivesRestart(.root);

  const LadderPerk(this.rung);

  final LadderRung rung;

  static List<LadderPerk> of(LadderRung rung) => [
    for (final perk in values)
      if (perk.rung == rung) perk,
  ];
}
