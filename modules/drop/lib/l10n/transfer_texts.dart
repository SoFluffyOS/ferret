import 'dart:math';

import 'package:drop/l10n/generated/drop_localizations.dart';
import 'package:drop/models/models.dart';
import 'package:intl/intl.dart';

/// Plain-word descriptions of a transfer, shared by the home card and the
/// notices.
class TransferTexts {
  const TransferTexts(this.l10n);

  final DropLocalizations l10n;

  static const _kilo = 1024;

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
      TransferFailure.disconnected => l10n.failureDisconnected(device),
      TransferFailure.notConnected => l10n.failureNotConnected(device),
      TransferFailure.unsupported => l10n.failureUnsupported(device),
      TransferFailure.storage => l10n.failureStorage,
      TransferFailure.checksum => l10n.failureChecksum,
      TransferFailure.sourceChanged => l10n.failureSourceChanged,
      TransferFailure.cancelledByPeer => l10n.failureCancelledByPeer(device),
      TransferFailure.unknownTransfer => l10n.failureUnknownTransfer(device),
      TransferFailure.protocol || null => l10n.failureProtocol(device),
    };
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
