import 'dart:math';

import 'package:drop/l10n/generated/drop_localizations.dart';
import 'package:drop/models/models.dart';
import 'package:interop_localsend/interop_localsend.dart' show Fingerprints;
import 'package:intl/intl.dart';

/// Plain-word descriptions of a transfer, shared by the home card and the
/// notices.
class TransferTexts {
  const TransferTexts(this.l10n);

  final DropLocalizations l10n;

  static const _kilo = 1024;
  static const _namesShown = 3;

  String title(Transfer transfer) {
    if (transfer.isText) {
      return preview(transfer.text ?? '');
    }

    return l10n.transferFiles(transfer.files.length, transfer.files.first.name);
  }

  /// The first line of [text], shortened.
  String preview(String text) {
    final firstLine = text.trim().split('\n').first;
    if (firstLine.isEmpty) {
      return l10n.transferText;
    }

    if (firstLine.length <= 80) {
      return firstLine;
    }

    return '${firstLine.substring(0, 80)}…';
  }

  String status(Transfer transfer) {
    final device = transfer.deviceName;
    return switch (transfer.status) {
      .waiting => switch (transfer.isOutgoing) {
        true => l10n.statusWaitingOutgoing(device),
        false => l10n.statusWaitingIncoming(device),
      },
      .transferring => switch (transfer.isOutgoing) {
        true => l10n.statusSending(
          device,
          size(transfer.bytesDone),
          size(transfer.totalBytes),
        ),
        false => l10n.statusReceiving(
          device,
          size(transfer.bytesDone),
          size(transfer.totalBytes),
        ),
      },
      .verifying => l10n.statusVerifying,
      .done => switch ((transfer.isOutgoing, transfer.isText)) {
        (true, _) => l10n.statusSent(device),
        (false, true) => l10n.statusTextReceived(device),
        (false, false) => l10n.statusReceived(device),
      },
      .failed => failure(transfer),
      .cancelled => switch (transfer.failure) {
        TransferFailure.cancelledByPeer => l10n.failureCancelledByPeer(device),
        TransferFailure.declined => l10n.failureDeclined(device),
        _ => l10n.statusCancelled,
      },
    };
  }

  /// Speed and time left while bytes move, or null.
  String? speed(Transfer transfer) {
    if (transfer.status != .transferring || transfer.bytesPerSecond <= 0) {
      return null;
    }

    final perSecond = size(transfer.bytesPerSecond.round());
    if (transfer.eta case final left?) {
      return l10n.statusSpeedEta(perSecond, eta(left));
    }

    return l10n.statusSpeed(perSecond);
  }

  String failure(Transfer transfer) {
    final device = transfer.deviceName;
    return switch (transfer.failure) {
      TransferFailure.declined => l10n.failureDeclined(device),
      TransferFailure.timedOut => l10n.failureTimedOut(device),
      TransferFailure.disconnected => switch (transfer.isOutgoing) {
        true => l10n.failureDisconnectedSending(device),
        false => l10n.failureDisconnected(device),
      },
      TransferFailure.notConnected => l10n.failureNotConnected(device),
      TransferFailure.unsupported => l10n.failureUnsupported(device),
      TransferFailure.storage => switch (transfer.isOutgoing) {
        true => l10n.failureStorageSending(device),
        false => l10n.failureStorage,
      },
      TransferFailure.checksum => l10n.failureChecksum,
      TransferFailure.sourceChanged => l10n.failureSourceChanged,
      TransferFailure.cancelledByPeer => l10n.failureCancelledByPeer(device),
      TransferFailure.unknownTransfer => l10n.failureUnknownTransfer(device),
      TransferFailure.pinRequired => l10n.failurePinRequired(device),
      TransferFailure.tooManyAttempts => l10n.failureTooManyAttempts(device),
      TransferFailure.busy => l10n.failureBusy(device),
      TransferFailure.unreachable => l10n.failureUnreachable(device),
      TransferFailure.untrusted => l10n.failureUntrusted(device),
      TransferFailure.connectionLost => l10n.failureConnectionLost(device),
      TransferFailure.protocol || null => switch (transfer.isQuickShare) {
        true => l10n.failureQuickShare(device),
        false => l10n.failureProtocol(device),
      },
    };
  }

  /// What to know before accepting an offer from a device that isn't
  /// paired: for LocalSend what the device says it is and its
  /// fingerprint, for Quick Share the PIN to compare with the phone, then
  /// the files and their size. Empty for paired devices.
  List<String> offerDetails(Transfer transfer) {
    if (!transfer.isUnpaired || !transfer.needsAnswer) {
      return const [];
    }

    final names = [
      for (final file in transfer.files.take(_namesShown)) file.name,
    ];
    final more = transfer.files.length - names.length;
    return [
      if (transfer.localSend case final origin?) ...[
        switch (origin.deviceModel.isEmpty) {
          true => origin.address,
          false => l10n.offerFrom(origin.deviceModel, origin.address),
        },
        l10n.offerFingerprint(Fingerprints.short(origin.fingerprint)),
      ],
      if (transfer.quickShare case final origin?) ...[
        l10n.offerPin(origin.pin, transfer.deviceName),
        origin.address,
      ],
      if (more > 0) l10n.offerFilesMore(names.join(', '), more),
      if (more <= 0 && names.length > 1) l10n.offerFiles(names.join(', ')),
      if (transfer.files.isNotEmpty)
        l10n.offerTotal(transfer.files.length, size(transfer.totalBytes)),
      l10n.offerWarning(transfer.deviceName),
    ];
  }

  /// Time left in a receive window, as `9:41`.
  String countdown(Duration left) {
    final seconds = (left.inMilliseconds / 1000).ceil();
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String size(int bytes) {
    final format = NumberFormat('0.#', l10n.localeName);
    if (bytes < _kilo) {
      return l10n.sizeBytes('$bytes');
    }

    if (bytes < _kilo * _kilo) {
      return l10n.sizeKilobytes(format.format(bytes / _kilo));
    }

    if (bytes < _kilo * _kilo * _kilo) {
      return l10n.sizeMegabytes(format.format(bytes / (_kilo * _kilo)));
    }

    return l10n.sizeGigabytes(format.format(bytes / (_kilo * _kilo * _kilo)));
  }

  String eta(Duration left) {
    final seconds = max(1, (left.inMilliseconds / 1000).ceil());
    if (seconds < 60) {
      return l10n.etaSeconds(seconds);
    }

    if (seconds < 3600) {
      return l10n.etaMinutes((seconds / 60).ceil());
    }

    return l10n.etaHours(left.inHours, left.inMinutes % 60);
  }
}
