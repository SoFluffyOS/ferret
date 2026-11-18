import 'package:drop/l10n/l10n.dart';
import 'package:drop/models/models.dart';
import 'package:feature_kit/feature_kit.dart';

/// How Files is doing with the device called [name]: whether it takes files
/// at all, and how the [last] transfer with it really ended, said for the
/// side that sent. [folder] is where files arrive here; [onRetry] picks a
/// failed transfer up again when that is possible.
FeatureHealth dropHealthOf(
  DropLocalizations l10n, {
  required String name,
  required bool supported,
  required Transfer? last,
  required String folder,
  void Function()? onRetry,
}) {
  if (!supported) {
    return FeatureHealth(.off, reason: l10n.failureUnsupported(name));
  }

  if (last == null) {
    return FeatureHealth(
      .ok,
      reason: switch (folder) {
        '' => l10n.healthOk,
        final folder => l10n.healthArrive(folder),
      },
    );
  }

  if (last.status == .failed && !_stoppedByPeople(last)) {
    return FeatureHealth(
      .failing,
      reason: TransferTexts(l10n).failure(last),
      help: switch (last.isOutgoing) {
        true => l10n.healthSendAgain,
        false => l10n.healthSendAgainThere(name),
      },
      onFix: onRetry,
    );
  }

  return FeatureHealth(.ok, reason: _lastOutcome(l10n, last, name));
}

bool _stoppedByPeople(Transfer transfer) => switch (transfer.failure) {
  TransferFailure.declined ||
  TransferFailure.cancelledByPeer ||
  TransferFailure.timedOut => true,
  _ => false,
};

/// What became of the last transfer that didn't break: it arrived, or
/// someone said no or stopped it.
String _lastOutcome(DropLocalizations l10n, Transfer last, String name) =>
    switch ((last.failure, last.status, last.isOutgoing)) {
      (TransferFailure.declined, _, true) => l10n.healthDeclinedThere(name),
      (TransferFailure.declined, _, false) => l10n.healthDeclinedHere(name),
      (TransferFailure.cancelledByPeer, _, _) => l10n.healthCancelledThere(
        name,
      ),
      (TransferFailure.timedOut, _, true) => l10n.healthNoAnswerThere(name),
      (TransferFailure.timedOut, _, false) => l10n.healthNoAnswerHere(name),
      (_, .cancelled, _) => l10n.healthCancelledHere,
      (_, _, true) => l10n.healthLastSent(name),
      (_, _, false) => l10n.healthLastReceived(name),
    };

/// Where files go, for the Files row in Settings.
String filesSummaryOf(DropLocalizations l10n, String folder) =>
    switch (folder) {
      '' => '',
      final folder => l10n.summaryFolder(folder),
    };

/// LocalSend's state in a few words.
String localSendSummaryOf(
  DropLocalizations l10n, {
  required bool isEnabled,
  required bool receiveAlways,
  required LocalSendReceiveState state,
}) {
  if (!isEnabled) {
    return l10n.summaryOff;
  }

  if (state.problem != null) {
    return l10n.summaryCannotReceive;
  }

  if (receiveAlways) {
    return l10n.summaryAlwaysReceives;
  }

  if (state.isOn) {
    return l10n.summaryReceivingNow;
  }

  return l10n.summaryReceivesOnAsk;
}

/// Quick Share's state in a few words.
String quickShareSummaryOf(
  DropLocalizations l10n, {
  required bool isEnabled,
  required QuickShareReceiveState state,
}) {
  if (!isEnabled) {
    return l10n.summaryOff;
  }

  if (state.isOn) {
    return l10n.summaryReceivingNow;
  }

  return l10n.summaryReceivesOnAsk;
}
