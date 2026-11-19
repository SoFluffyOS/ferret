// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'drop_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class DropLocalizationsEn extends DropLocalizations {
  DropLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Files';

  @override
  String get cardEmpty => 'Drop files here to send them to your devices.';

  @override
  String get cardEmptyPhone => 'Send photos and files to your other devices.';

  @override
  String get otherApps => 'Let other phones send you files';

  @override
  String get sendFiles => 'Send files';

  @override
  String activityFrom(String what, String device) {
    return '$what from $device';
  }

  @override
  String activityTo(String what, String device) {
    return '$what to $device';
  }

  @override
  String get activityText => 'Text';

  @override
  String activitySavedTo(String folder) {
    return 'Saved to $folder';
  }

  @override
  String get activitySaved => 'Saved';

  @override
  String get activitySent => 'Sent';

  @override
  String activityProgress(String done, String total) {
    return '$done of $total';
  }

  @override
  String activityProgressEta(String done, String total, String eta) {
    return '$done of $total · $eta left';
  }

  @override
  String get activityWaiting => 'Waiting for an answer…';

  @override
  String activityOffer(String device) {
    return '$device wants to send';
  }

  @override
  String activityOfferSize(String what, String size) {
    return '$what · $size';
  }

  @override
  String get actionRevealFinder => 'Show in Finder';

  @override
  String get guestTitle => 'Receive a file from a guest';

  @override
  String get guestBody =>
      'A phone without Ferret can send one file here with Quick Share or LocalSend, for 10 minutes or until the first file arrives.';

  @override
  String get guestAction => 'Allow once';

  @override
  String get guestWaiting =>
      'Open for one file from a guest. It closes once the file arrives.';

  @override
  String get clearFinished => 'Clear finished';

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
    return '$device declined.';
  }

  @override
  String failureTimedOut(String device) {
    return '$device didn\'t answer in time.';
  }

  @override
  String failureDisconnected(String device) {
    return '$device went offline. It continues when $device is back.';
  }

  @override
  String failureDisconnectedSending(String device) {
    return '$device went offline. It goes on when $device is back.';
  }

  @override
  String statusPaused(String done, String total, String device) {
    return 'Paused at $done of $total. It goes on when $device is back.';
  }

  @override
  String statusWaitingForDevice(String device) {
    return 'Waiting for $device. It goes as soon as $device is back.';
  }

  @override
  String noticePaused(String device) {
    return 'Paused with $device';
  }

  @override
  String get actionTryNow => 'Try now';

  @override
  String failureNotConnected(String device) {
    return '$device isn\'t connected. On $device: open Ferret, then try again here.';
  }

  @override
  String failureUnsupported(String device) {
    return '$device needs a newer Ferret to receive files.';
  }

  @override
  String get failureStorage =>
      'Couldn\'t save the file. Check free space and the receive folder.';

  @override
  String failureStorageSending(String device) {
    return '$device couldn\'t save the file. It may be out of space.';
  }

  @override
  String get failureChecksum =>
      'The file arrived damaged. Try again to send it once more.';

  @override
  String get failureSourceChanged =>
      'The file changed or moved while it was being sent. Send it again.';

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
    return 'Something went wrong with $device. Try again to continue.';
  }

  @override
  String get actionOpen => 'Open';

  @override
  String get actionReveal => 'Show in folder';

  @override
  String get actionRetry => 'Try again';

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
      'Open Ferret on one of your devices, then try again.';

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
    return 'Couldn\'t reach $device. On $device: keep LocalSend open, on the same Wi-Fi.';
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
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count more',
    );
    return '$names and $_temp0';
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
  String offerWarning(String device) {
    return '$device isn\'t paired with Ferret. Accept only if you expect it.';
  }

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
      'No LocalSend devices found. On the other device: open LocalSend, on the same Wi-Fi.';

  @override
  String get pickerNoDevices => 'None of your devices is connected.';

  @override
  String get pickerSearchAgain => 'Search again';

  @override
  String noticeGone(String device) {
    return 'Couldn\'t find $device';
  }

  @override
  String noticeGoneBody(String device) {
    return 'On $device: open LocalSend, then send again.';
  }

  @override
  String get receiveTitle => 'LocalSend';

  @override
  String get receiveOff => 'Let devices with the LocalSend app send here.';

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
  String get receiveTurnOn => 'Allow 10 min';

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
    return 'The connection to $device dropped. On $device: send it again.';
  }

  @override
  String failureQuickShare(String device) {
    return 'Something went wrong with $device. On $device: send it again.';
  }

  @override
  String offerPin(String pin, String device) {
    return 'PIN $pin. It must match the one on $device.';
  }

  @override
  String noticePin(String pin) {
    return 'PIN $pin';
  }

  @override
  String get quickShareTitle => 'Quick Share';

  @override
  String get quickShareOff => 'Let Android phones without Ferret send here.';

  @override
  String get quickShareFinishing => 'No longer visible. Finishing a transfer…';

  @override
  String get quickShareCannotAdvertise =>
      'Couldn\'t become visible. A firewall or VPN may be blocking it.';

  @override
  String get quickShareTurnOn => 'Show 10 min';

  @override
  String get settingsQuickShare => 'Work with Quick Share';

  @override
  String get settingsQuickShareBody =>
      'Android phones can send files to this device with Quick Share while you make it visible. Each file asks first.';

  @override
  String get healthOk => 'Nothing sent yet';

  @override
  String healthArrive(String folder) {
    return 'Arrive in $folder';
  }

  @override
  String healthLastSent(String name) {
    return '$name got the last thing you sent';
  }

  @override
  String healthLastReceived(String name) {
    return 'The last thing $name sent arrived';
  }

  @override
  String healthDeclinedThere(String name) {
    return '$name declined the last thing you sent';
  }

  @override
  String healthDeclinedHere(String name) {
    return 'You declined the last thing $name sent';
  }

  @override
  String healthCancelledThere(String name) {
    return '$name cancelled the last transfer';
  }

  @override
  String get healthCancelledHere => 'You cancelled the last transfer';

  @override
  String healthNoAnswerThere(String name) {
    return '$name didn\'t answer the last time you sent';
  }

  @override
  String healthNoAnswerHere(String name) {
    return 'The last thing $name sent wasn\'t accepted in time';
  }

  @override
  String get healthSendAgain => 'Send the files again from here.';

  @override
  String healthSendAgainThere(String name) {
    return 'On $name: send the files again.';
  }

  @override
  String summaryFolder(String folder) {
    return 'To $folder';
  }

  @override
  String get summaryOff => 'Off';

  @override
  String get summaryAlwaysReceives => 'Always receives';

  @override
  String get summaryReceivingNow => 'Receiving now';

  @override
  String get summaryReceivesOnAsk => 'Receives when you allow it';

  @override
  String get summaryCannotReceive => 'Can\'t receive right now';

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
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds s',
    );
    return '$_temp0';
  }

  @override
  String etaMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return '$_temp0';
  }

  @override
  String etaHours(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours h',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes min',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String filesDropHere(String device) {
    return 'Drop files here to send them to $device.';
  }

  @override
  String get filesChoose => 'Choose files…';

  @override
  String filesOffline(String device) {
    return '$device isn\'t connected. Send it files once it is.';
  }

  @override
  String get filesRecent => 'Sent and received';

  @override
  String filesNone(String device) {
    return 'Files you send to $device, and the ones it sends you, show here.';
  }

  @override
  String get back => 'Back';

  @override
  String progressWeak(String progress) {
    return 'Weak connection · $progress';
  }

  @override
  String get actionTryAll => 'Try all again';

  @override
  String failureFoldersUnsupported(String device) {
    return '$device\'s Ferret is too old for folders. Update it, or send the files.';
  }

  @override
  String get actionSendLoose => 'Send the files';

  @override
  String get filesChooseFolder => 'Choose a folder…';

  @override
  String get sendFolder => 'Send a folder';

  @override
  String folderFilesDone(int done, int total) {
    String _temp0 = intl.Intl.pluralLogic(
      total,
      locale: localeName,
      other: '$total files',
      one: '1 file',
    );
    return '$done of $_temp0';
  }

  @override
  String folderProgressDone(String files, String size) {
    return '$files · $size';
  }

  @override
  String folderSkipped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count links or special files left out',
      one: '1 link or special file left out',
    );
    return '$_temp0';
  }
}
