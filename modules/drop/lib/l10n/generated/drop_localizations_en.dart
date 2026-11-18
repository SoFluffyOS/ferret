// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'drop_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DropLocalizationsEn extends DropLocalizations {
  DropLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Drop';

  @override
  String get cardEmpty =>
      'Drop files on Ferret, or pick Send files… on a device.';

  @override
  String get sendFiles => 'Send files…';

  @override
  String get clearFinished => 'Clear';

  @override
  String transferFiles(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '$name',
    );
    return '$_temp0';
  }

  @override
  String get transferText => 'Text';

  @override
  String statusWaitingOutgoing(String device) {
    return 'Waiting for $device to accept…';
  }

  @override
  String statusWaitingIncoming(String device) {
    return '$device wants to send this';
  }

  @override
  String statusSending(String device, String done, String total) {
    return 'To $device · $done of $total';
  }

  @override
  String statusReceiving(String device, String done, String total) {
    return 'From $device · $done of $total';
  }

  @override
  String statusSpeed(String speed) {
    return '$speed/s';
  }

  @override
  String statusSpeedEta(String speed, String eta) {
    return '$speed/s · $eta left';
  }

  @override
  String get statusVerifying => 'Checking the file…';

  @override
  String statusSent(String device) {
    return 'Sent to $device ✓';
  }

  @override
  String statusReceived(String device) {
    return 'Saved ✓ · from $device';
  }

  @override
  String statusTextReceived(String device) {
    return 'From $device';
  }

  @override
  String get statusCancelled => 'Cancelled';

  @override
  String failureDeclined(String device) {
    return '$device said no.';
  }

  @override
  String failureTimedOut(String device) {
    return '$device didn\'t answer in time.';
  }

  @override
  String failureDisconnected(String device) {
    return '$device went offline. It continues when it\'s back.';
  }

  @override
  String failureNotConnected(String device) {
    return '$device isn\'t connected. Open Ferret on it, then retry.';
  }

  @override
  String failureUnsupported(String device) {
    return '$device needs a newer Ferret to receive files.';
  }

  @override
  String get failureStorage =>
      'Couldn\'t write the file. Check free space and the receive folder.';

  @override
  String get failureChecksum =>
      'The file arrived damaged. Retry sends it again.';

  @override
  String get failureSourceChanged =>
      'The file changed or moved while it was being sent.';

  @override
  String failureCancelledByPeer(String device) {
    return '$device cancelled.';
  }

  @override
  String failureUnknownTransfer(String device) {
    return '$device lost track of this transfer. Send it again.';
  }

  @override
  String failureProtocol(String device) {
    return 'Something went wrong with $device. Retry to continue.';
  }

  @override
  String get actionOpen => 'Open';

  @override
  String get actionReveal => 'Show in folder';

  @override
  String get actionRetry => 'Retry';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionAccept => 'Accept';

  @override
  String get actionDecline => 'Decline';

  @override
  String get actionCopy => 'Copy';

  @override
  String get actionDismiss => 'Dismiss';

  @override
  String noticeSending(String device) {
    return 'Sending to $device';
  }

  @override
  String noticeReceiving(String device) {
    return 'Receiving from $device';
  }

  @override
  String noticeSent(String device) {
    return 'Sent to $device';
  }

  @override
  String noticeReceived(String device) {
    return 'Received from $device';
  }

  @override
  String noticeText(String device) {
    return 'Text from $device';
  }

  @override
  String noticeFailed(String device) {
    return 'Transfer with $device stopped';
  }

  @override
  String noticeOffer(String device) {
    return '$device wants to send you something';
  }

  @override
  String get noticeNoDevice => 'No device to send to';

  @override
  String get noticeNoDeviceBody =>
      'Connect one of your paired devices, then try again.';

  @override
  String get noticeNothing => 'Nothing to send';

  @override
  String get noticeNothingBody =>
      'Folders can\'t be sent yet. Pick the files inside instead.';

  @override
  String get pickerTitle => 'Send to which device?';

  @override
  String get settingsReceiveFolder => 'Receive folder';

  @override
  String get settingsChange => 'Change…';

  @override
  String get settingsUseDefault => 'Use default';

  @override
  String get settingsFolderName => 'Folder name in Downloads';

  @override
  String get settingsSave => 'Save';

  @override
  String get settingsAutoAccept => 'Accept from my devices';

  @override
  String get settingsAutoAcceptBody =>
      'Files from your paired devices go straight to the receive folder. Turn this off to approve each one.';

  @override
  String sizeBytes(String value) {
    return '$value B';
  }

  @override
  String sizeKilobytes(String value) {
    return '$value KB';
  }

  @override
  String sizeMegabytes(String value) {
    return '$value MB';
  }

  @override
  String sizeGigabytes(String value) {
    return '$value GB';
  }

  @override
  String etaSeconds(int seconds) {
    return '$seconds s';
  }

  @override
  String etaMinutes(int minutes) {
    return '$minutes min';
  }

  @override
  String etaHours(int hours, int minutes) {
    return '$hours h $minutes min';
  }
}
