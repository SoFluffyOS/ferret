import 'package:clipboard/feature/clipboard_feature.dart';
import 'package:clipboard/l10n/l10n.dart';
import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';

/// How Clipboard is doing with the device behind [session], called [name]:
/// which side sends what it copies by itself, and which side sends by hand.
FeatureHealth clipboardHealthOf(
  ClipboardLocalizations l10n, {
  required Session session,
  required String name,
  required bool sendsOnItsOwn,
}) {
  final support = session.remoteFeature(ClipboardFeature.featureId);
  if (support == null) {
    return FeatureHealth(.off, reason: l10n.healthUnsupported(name));
  }

  final theySend = support.flags.contains(ClipboardFeature.sendFlag);
  return FeatureHealth(
    .ok,
    reason: switch ((sendsOnItsOwn, theySend)) {
      (true, true) => l10n.healthSyncs,
      (true, false) => l10n.healthOnlyHereSends(name),
      (false, true) => l10n.healthOnlyTheySend(name),
      (false, false) => l10n.healthByHand,
    },
  );
}

/// Clipboard's state in a few words, for its row in Settings.
String clipboardSummaryOf(
  ClipboardLocalizations l10n, {
  required bool sendsOnItsOwn,
  required bool autoReceive,
}) => switch ((sendsOnItsOwn, autoReceive)) {
  (true, true) => l10n.summarySyncs,
  (true, false) => l10n.summarySends,
  (false, _) => l10n.summaryByHand,
};
