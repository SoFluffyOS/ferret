import 'dart:async';

import 'package:engine/engine.dart';
import 'package:feature_kit/feature_kit.dart';
import 'package:media/feature/feature.dart';
import 'package:media/l10n/l10n.dart';
import 'package:media/view_models/view_models.dart';

/// How Media is doing with the device behind [session], called [name]: what
/// each side sees of the other's players. A check only while something
/// really goes across: their player shows here, or this device shares
/// its own; a dash while nothing plays. Null when neither side can share
/// what it plays.
FeatureHealth? mediaHealthOf(
  MediaLocalizations l10n, {
  required Session session,
  required String name,
  required MediaViewModel model,
}) {
  final support = session.remoteFeature(MediaFeature.featureId);
  if (support == null) {
    return FeatureHealth(.off, reason: l10n.healthUnsupported(name));
  }

  final theyCanShare = support.flags.contains(MediaFeature.shareFlag);
  if (!theyCanShare && !model.canShare) {
    return null;
  }

  final here = model.platform.name;
  if (model.lostAccess) {
    return FeatureHealth(
      .needsAttention,
      reason: l10n.healthLostAccess(here),
      onFix: () => unawaited(model.fixAccess()),
    );
  }

  final showsTheirs = model.showRemote && theyCanShare;
  if (!showsTheirs && !model.isSharing) {
    return _off(l10n, here: here, hidesTheirs: theyCanShare);
  }

  final showsPlaying =
      showsTheirs &&
      model.players.any((player) => player.deviceId == session.remoteDeviceId);
  if (!showsPlaying && !model.isSharing) {
    return FeatureHealth(.off, reason: l10n.healthNothingPlaying);
  }

  return FeatureHealth(
    .ok,
    reason: switch ((showsPlaying, model.isSharing)) {
      (true, true) => l10n.healthShowsAndShares(name, here),
      (true, false) => l10n.healthShowsTheirs,
      _ => l10n.healthSharesMine(name, here),
    },
  );
}

/// Nothing goes either way: showing their media is off here, or this
/// device, the only one that could share, doesn't.
FeatureHealth _off(
  MediaLocalizations l10n, {
  required String here,
  required bool hidesTheirs,
}) {
  if (hidesTheirs) {
    return FeatureHealth(
      .off,
      reason: l10n.healthOffHere(here),
      help: l10n.healthShowHelp,
    );
  }

  return FeatureHealth(
    .off,
    reason: l10n.healthNotShared(here),
    help: l10n.healthShareHelp,
  );
}

/// Media's state in a few words, for its row in Settings.
String mediaSummaryOf(MediaLocalizations l10n, MediaViewModel model) =>
    switch ((model.showRemote, model.isSharing)) {
      (true, true) => l10n.summaryShowsAndShares,
      (true, false) => l10n.summaryShows,
      (false, true) => l10n.summaryShares,
      (false, false) => l10n.summaryOff,
    };
