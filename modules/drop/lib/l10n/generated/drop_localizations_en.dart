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
  String failurePinRequired(String device) {
    return '$device asks for a PIN. Enter the one it shows.';
  }

  @override
  String failureTooManyAttempts(String device) {
    return 'Too many wrong PINs for $device. Wait a moment, then try again.';
  }

  @override
  String failureBusy(String device) {
    return '$device is busy with another transfer. Try again when it\'s done.';
  }

  @override
  String failureUnreachable(String device) {
    return 'Couldn\'t reach $device. Keep LocalSend open on it, on the same Wi-Fi.';
  }

  @override
  String failureUntrusted(String device) {
    return '$device isn\'t the device it said it was. Nothing was sent.';
  }

  @override
  String get actionEnterPin => 'Enter PIN';

  @override
  String pinTitle(String device) {
    return 'PIN for $device';
  }

  @override
  String get pinLabel => 'PIN';

  @override
  String get pinSend => 'Send';

  @override
  String offerFrom(String model, String address) {
    return '$model · $address';
  }

  @override
  String offerFingerprint(String fingerprint) {
    return 'Fingerprint $fingerprint';
  }

  @override
  String offerFiles(String names) {
    return '$names';
  }

  @override
  String offerFilesMore(String names, int count) {
    return '$names and $count more';
  }

  @override
  String offerTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files',
      one: '1 file',
    );
    return '$_temp0 · $size';
  }

  @override
  String get offerWarning =>
      'This device isn\'t paired with Ferret. Accept only if you expect it.';

  @override
  String get pickerLocalSend => 'LocalSend';

  @override
  String pickerLocalSendModel(String model) {
    return 'LocalSend · $model';
  }

  @override
  String get pickerScanning => 'Looking for LocalSend devices…';

  @override
  String get pickerNoLocalSend =>
      'No LocalSend devices found. Open LocalSend on the other device, on the same Wi-Fi.';

  @override
  String get pickerNoDevices => 'None of your devices is connected.';

  @override
  String get pickerSearchAgain => 'Search again';

  @override
  String get noticeGone => 'That device is gone';

  @override
  String get noticeGoneBody =>
      'It\'s no longer on the network. Open LocalSend on it and try again.';

  @override
  String get receiveTitle => 'Receive from LocalSend';

  @override
  String get receiveOff => 'Off. LocalSend devices can\'t send to this one.';

  @override
  String get receiveStarting => 'Turning on…';

  @override
  String receiveTimed(String alias, String time) {
    return 'Visible as $alias · $time left';
  }

  @override
  String receiveAlwaysOn(String alias) {
    return 'Visible as $alias · stays on';
  }

  @override
  String get receiveCannotListen =>
      'Couldn\'t start. A firewall or another app may be blocking it.';

  @override
  String get receiveNoIdentity =>
      'Couldn\'t prepare this device for LocalSend.';

  @override
  String get receiveTurnOn => 'On for 10 min';

  @override
  String get receiveTryAgain => 'Try again';

  @override
  String get receiveStop => 'Stop';

  @override
  String get settingsLocalSend => 'Work with LocalSend';

  @override
  String get settingsLocalSendBody =>
      'Send files to devices running the LocalSend app, and receive from them when you turn it on. Each file from LocalSend asks first.';

  @override
  String get settingsReceiveAlways => 'Always receive from LocalSend';

  @override
  String get settingsReceiveAlwaysBody =>
      'Keeps this device visible to LocalSend devices on your network, also after a restart. Off, it\'s visible for 10 minutes when you ask.';

  @override
  String failureConnectionLost(String device) {
    return 'The connection to $device dropped. Send it again from there.';
  }

  @override
  String failureQuickShare(String device) {
    return 'Something went wrong with $device. Send it again from the phone.';
  }

  @override
  String offerPin(String pin) {
    return 'PIN $pin. It must match the one on the phone.';
  }

  @override
  String noticePin(String pin) {
    return 'PIN $pin';
  }

  @override
  String get quickShareTitle => 'Receive from Quick Share';

  @override
  String get quickShareOff => 'Off. Android phones can\'t see this device.';

  @override
  String get quickShareFinishing => 'No longer visible. Finishing a transfer…';

  @override
  String get quickShareCannotAdvertise =>
      'Couldn\'t become visible. A firewall or VPN may be blocking local discovery.';

  @override
  String get quickShareTurnOn => 'Visible for 10 min';

  @override
  String get settingsQuickShare => 'Work with Quick Share';

  @override
  String get settingsQuickShareBody =>
      'Android phones can send files to this device with Quick Share while you make it visible. Each file asks first.';

  @override
  String get healthOk => 'Ready';

  @override
  String get healthSent => 'The last transfer went through.';

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
