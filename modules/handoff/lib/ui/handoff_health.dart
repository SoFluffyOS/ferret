import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:handoff/feature/handoff_feature.dart';
import 'package:handoff/l10n/l10n.dart';
import 'package:handoff/models/models.dart';

/// How Continue is doing with the device behind [session], called [name]:
/// whether the last link sent there arrived and opened, and what happens to
/// the links it sends here.
FeatureHealth continueHealthOf(
  HandoffLocalizations l10n, {
  required Session session,
  required String name,
  required SendOutcome? lastSendProblem,
  required bool opensAutomatically,
}) {
  if (!session.supports(HandoffFeature.featureId)) {
    return FeatureHealth(.off, reason: l10n.healthUnsupported(name));
  }

  switch (lastSendProblem) {
    case .failed:
      return FeatureHealth(
        .failing,
        reason: l10n.healthLastOpenFailed(name),
        help: l10n.healthLastOpenFailedHelp(name),
      );
    case .unreachable:
      return FeatureHealth(
        .failing,
        reason: l10n.healthLastSendFailed(name),
        help: l10n.healthLastSendFailedHelp(name),
      );
    case .opened || .suggested || null:
      break;
  }

  return FeatureHealth(
    .ok,
    reason: switch (opensAutomatically) {
      true => l10n.healthOpensRightAway(name),
      false => l10n.healthWaits(name),
    },
  );
}

/// Continue's state in a few words, for its row in Settings.
String continueSummaryOf(
  HandoffLocalizations l10n, {
  required bool passiveEnabled,
}) => switch (passiveEnabled) {
  true => l10n.summaryPassive,
  false => l10n.summarySendsOnly,
};

/// The browser extension's state in a few words: the browsers that may use
/// Ferret, or that there is none yet.
String browserSummaryOf(
  HandoffLocalizations l10n, {
  required bool isEnabled,
  required List<BrowserClient> clients,
}) {
  if (!isEnabled) {
    return l10n.summaryBrowserOff;
  }

  if (clients.isEmpty) {
    return l10n.summaryNoBrowser;
  }

  return ListText.join(
    clients.map((client) => client.name),
    localeName: l10n.localeName,
  );
}
