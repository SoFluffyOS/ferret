// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'drop_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class DropLocalizationsVi extends DropLocalizations {
  DropLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Tệp';

  @override
  String get cardEmpty => 'Thả tệp vào đây để gửi đến thiết bị của bạn.';

  @override
  String get cardEmptyPhone => 'Gửi ảnh và tệp đến các thiết bị khác của bạn.';

  @override
  String get otherApps => 'Cho điện thoại khác gửi tệp cho bạn';

  @override
  String get sendFiles => 'Gửi tệp';

  @override
  String activityFrom(String what, String device) {
    return '$what từ $device';
  }

  @override
  String activityTo(String what, String device) {
    return '$what đến $device';
  }

  @override
  String get activityText => 'Văn bản';

  @override
  String activitySavedTo(String folder) {
    return 'Đã lưu vào $folder';
  }

  @override
  String get activitySaved => 'Đã lưu';

  @override
  String get activitySent => 'Đã gửi';

  @override
  String activityProgress(String done, String total) {
    return '$done/$total';
  }

  @override
  String activityProgressEta(String done, String total, String eta) {
    return '$done/$total · còn $eta';
  }

  @override
  String get activityWaiting => 'Đang chờ phản hồi…';

  @override
  String activityOffer(String device) {
    return '$device muốn gửi';
  }

  @override
  String activityOfferSize(String what, String size) {
    return '$what · $size';
  }

  @override
  String get actionRevealFinder => 'Hiển thị trong Finder';

  @override
  String get guestTitle => 'Nhận tệp từ khách';

  @override
  String get guestBody =>
      'Điện thoại không có Ferret có thể gửi một tệp tới đây bằng Quick Share hoặc LocalSend, trong 10 phút hoặc đến khi tệp đầu tiên tới.';

  @override
  String get guestBodyLocalSend =>
      'Điện thoại không có Ferret có thể gửi một tệp tới đây bằng LocalSend, trong 10 phút hoặc đến khi tệp đầu tiên tới.';

  @override
  String get guestAction => 'Cho phép một lần';

  @override
  String get guestWaiting =>
      'Đang mở để nhận một tệp từ khách. Sẽ tự đóng khi tệp tới.';

  @override
  String get clearFinished => 'Xoá mục đã xong';

  @override
  String transferFiles(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
      one: '$name',
    );
    return '$_temp0';
  }

  @override
  String get transferText => 'Văn bản';

  @override
  String statusWaitingOutgoing(String device) {
    return 'Đang chờ $device chấp nhận…';
  }

  @override
  String statusWaitingIncoming(String device) {
    return '$device muốn gửi mục này';
  }

  @override
  String statusSending(String device, String done, String total) {
    return 'Đến $device · $done/$total';
  }

  @override
  String statusReceiving(String device, String done, String total) {
    return 'Từ $device · $done/$total';
  }

  @override
  String statusSpeed(String speed) {
    return '$speed/s';
  }

  @override
  String statusSpeedEta(String speed, String eta) {
    return '$speed/s · còn $eta';
  }

  @override
  String get statusVerifying => 'Đang kiểm tra tệp…';

  @override
  String statusSent(String device) {
    return 'Đã gửi đến $device ✓';
  }

  @override
  String statusReceived(String device) {
    return 'Đã lưu ✓ · từ $device';
  }

  @override
  String statusTextReceived(String device) {
    return 'Từ $device';
  }

  @override
  String get statusCancelled => 'Đã huỷ';

  @override
  String failureDeclined(String device) {
    return '$device đã từ chối.';
  }

  @override
  String failureTimedOut(String device) {
    return '$device không phản hồi kịp.';
  }

  @override
  String failureDisconnected(String device) {
    return '$device đã ngoại tuyến. Sẽ tiếp tục khi $device kết nối lại.';
  }

  @override
  String failureDisconnectedSending(String device) {
    return '$device đã ngoại tuyến. Sẽ gửi tiếp khi $device kết nối lại.';
  }

  @override
  String statusPaused(String done, String total, String device) {
    return 'Tạm dừng ở $done/$total. Sẽ tiếp tục khi $device kết nối lại.';
  }

  @override
  String statusWaitingForDevice(String device) {
    return 'Đang chờ $device. Sẽ gửi ngay khi $device kết nối lại.';
  }

  @override
  String noticePaused(String device) {
    return 'Đã tạm dừng với $device';
  }

  @override
  String get actionTryNow => 'Thử ngay';

  @override
  String failureNotConnected(String device) {
    return '$device chưa kết nối. Trên $device: mở Ferret, rồi thử lại ở đây.';
  }

  @override
  String failureUnsupported(String device) {
    return '$device cần Ferret bản mới hơn để nhận tệp.';
  }

  @override
  String get failureStorage =>
      'Không lưu được tệp. Hãy kiểm tra dung lượng trống và thư mục nhận.';

  @override
  String failureStorageSending(String device) {
    return '$device không lưu được tệp. Có thể máy đã hết dung lượng.';
  }

  @override
  String failureOutOfSpace(String name, String needed, String free) {
    return 'Không đủ dung lượng cho $name: cần $needed, còn trống $free';
  }

  @override
  String failureOutOfSpaceSending(String device, String needed, String free) {
    return '$device đã hết dung lượng: cần $needed, còn trống $free';
  }

  @override
  String get actionStorageSettings => 'Mở Cài đặt';

  @override
  String get failureChecksum =>
      'Tệp đến nơi bị hỏng. Hãy thử lại để gửi lần nữa.';

  @override
  String get failureSourceChanged =>
      'Tệp đã bị thay đổi hoặc di chuyển trong lúc gửi. Hãy gửi lại.';

  @override
  String failureCancelledByPeer(String device) {
    return '$device đã huỷ.';
  }

  @override
  String failureUnknownTransfer(String device) {
    return '$device không còn theo dõi lượt truyền này. Hãy gửi lại.';
  }

  @override
  String failureProtocol(String device) {
    return 'Đã xảy ra lỗi với $device. Hãy thử lại để tiếp tục.';
  }

  @override
  String get actionOpen => 'Mở';

  @override
  String get actionReveal => 'Hiển thị trong thư mục';

  @override
  String get actionRetry => 'Thử lại';

  @override
  String get actionCancel => 'Huỷ';

  @override
  String get actionAccept => 'Chấp nhận';

  @override
  String get actionDecline => 'Từ chối';

  @override
  String get actionCopy => 'Sao chép';

  @override
  String get actionDismiss => 'Bỏ qua';

  @override
  String noticeSending(String device) {
    return 'Đang gửi đến $device';
  }

  @override
  String noticeReceiving(String device) {
    return 'Đang nhận từ $device';
  }

  @override
  String noticeSent(String device) {
    return 'Đã gửi đến $device';
  }

  @override
  String noticeText(String device) {
    return 'Văn bản từ $device';
  }

  @override
  String noticeFailed(String device) {
    return 'Lượt truyền với $device đã dừng';
  }

  @override
  String noticeOffer(String device) {
    return '$device muốn gửi cho bạn';
  }

  @override
  String get noticeNoDevice => 'Không có thiết bị để gửi';

  @override
  String get noticeNoDeviceBody =>
      'Mở Ferret trên một thiết bị của bạn, rồi thử lại.';

  @override
  String get noticeNothing => 'Không có gì để gửi';

  @override
  String get noticeNothingBody =>
      'Chưa gửi được thư mục. Hãy chọn các tệp bên trong.';

  @override
  String get pickerTitle => 'Gửi đến thiết bị nào?';

  @override
  String get settingsReceiveFolder => 'Thư mục nhận';

  @override
  String get settingsChange => 'Thay đổi…';

  @override
  String get settingsUseDefault => 'Dùng mặc định';

  @override
  String get settingsFolderName => 'Tên thư mục trong Downloads';

  @override
  String get settingsSave => 'Lưu';

  @override
  String get settingsAutoAccept => 'Nhận từ thiết bị của tôi';

  @override
  String get settingsAutoAcceptBody =>
      'Tệp từ thiết bị đã ghép đôi được lưu thẳng vào thư mục nhận. Tắt để tự duyệt từng tệp.';

  @override
  String failurePinRequired(String device) {
    return '$device yêu cầu mã PIN. Hãy nhập mã hiển thị trên đó.';
  }

  @override
  String failureTooManyAttempts(String device) {
    return 'Nhập sai mã PIN cho $device quá nhiều lần. Chờ một lát rồi thử lại.';
  }

  @override
  String failureBusy(String device) {
    return '$device đang bận với lượt truyền khác. Hãy thử lại khi xong.';
  }

  @override
  String failureUnreachable(String device) {
    return 'Không kết nối được với $device. Trên $device: giữ LocalSend mở, cùng mạng Wi-Fi.';
  }

  @override
  String failureUntrusted(String device) {
    return '$device không đúng là thiết bị như nó tự nhận. Chưa gửi gì cả.';
  }

  @override
  String get actionEnterPin => 'Nhập mã PIN';

  @override
  String pinTitle(String device) {
    return 'Mã PIN cho $device';
  }

  @override
  String get pinLabel => 'Mã PIN';

  @override
  String get pinSend => 'Gửi';

  @override
  String offerFrom(String model, String address) {
    return '$model · $address';
  }

  @override
  String offerFingerprint(String fingerprint) {
    return 'Dấu vân tay $fingerprint';
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
      other: '$count tệp khác',
    );
    return '$names và $_temp0';
  }

  @override
  String offerTotal(int count, String size) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
    );
    return '$_temp0 · $size';
  }

  @override
  String offerWarning(String device) {
    return '$device chưa ghép đôi với Ferret. Chỉ chấp nhận nếu bạn đang chờ tệp này.';
  }

  @override
  String get pickerLocalSend => 'LocalSend';

  @override
  String pickerLocalSendModel(String model) {
    return 'LocalSend · $model';
  }

  @override
  String get pickerScanning => 'Đang tìm thiết bị LocalSend…';

  @override
  String get pickerNoLocalSend =>
      'Không tìm thấy thiết bị LocalSend nào. Trên thiết bị kia: mở LocalSend, cùng mạng Wi-Fi.';

  @override
  String get pickerNoDevices => 'Chưa có thiết bị nào của bạn kết nối.';

  @override
  String get pickerSearchAgain => 'Tìm lại';

  @override
  String get pickerLinkTitle => 'Gửi liên kết đến thiết bị nào?';

  @override
  String get pickerOpenTitle => 'Hoặc mở ngay trên đó';

  @override
  String pickerOpenOn(String device) {
    return 'Mở trên $device';
  }

  @override
  String noticeGone(String device) {
    return 'Không tìm thấy $device';
  }

  @override
  String noticeGoneBody(String device) {
    return 'Trên $device: mở LocalSend, rồi gửi lại.';
  }

  @override
  String get receiveTitle => 'LocalSend';

  @override
  String get receiveOff => 'Cho thiết bị có ứng dụng LocalSend gửi đến đây.';

  @override
  String get receiveStarting => 'Đang bật…';

  @override
  String receiveTimed(String alias, String time) {
    return 'Hiển thị với tên $alias · còn $time';
  }

  @override
  String receiveAlwaysOn(String alias) {
    return 'Hiển thị với tên $alias · luôn bật';
  }

  @override
  String get receiveCannotListen =>
      'Không khởi động được. Có thể tường lửa hoặc ứng dụng khác đang chặn.';

  @override
  String get receiveNoIdentity =>
      'Không chuẩn bị được thiết bị này cho LocalSend.';

  @override
  String get receiveTurnOn => 'Cho phép 10 phút';

  @override
  String get receiveTryAgain => 'Thử lại';

  @override
  String get receiveStop => 'Dừng';

  @override
  String get settingsLocalSend => 'Dùng với LocalSend';

  @override
  String get settingsLocalSendBody =>
      'Gửi tệp đến thiết bị chạy ứng dụng LocalSend, và nhận tệp từ chúng khi bạn bật. Mỗi tệp từ LocalSend đều hỏi trước.';

  @override
  String get settingsReceiveAlways => 'Luôn nhận từ LocalSend';

  @override
  String get settingsReceiveAlwaysBody =>
      'Giữ cho thiết bị này luôn hiển thị với các thiết bị LocalSend trong mạng, kể cả sau khi khởi động lại. Khi tắt, thiết bị chỉ hiển thị 10 phút mỗi lần bạn bật.';

  @override
  String failureConnectionLost(String device) {
    return 'Mất kết nối với $device. Trên $device: gửi lại.';
  }

  @override
  String failureQuickShare(String device) {
    return 'Đã xảy ra lỗi với $device. Trên $device: gửi lại.';
  }

  @override
  String offerPin(String pin, String device) {
    return 'Mã PIN $pin. Mã này phải khớp với mã trên $device.';
  }

  @override
  String noticePin(String pin) {
    return 'Mã PIN $pin';
  }

  @override
  String get quickShareTitle => 'Quick Share';

  @override
  String get quickShareOff =>
      'Cho điện thoại Android chưa có Ferret gửi đến đây.';

  @override
  String get quickShareFinishing =>
      'Không còn hiển thị. Đang hoàn tất lượt truyền…';

  @override
  String get quickShareCannotAdvertise =>
      'Không hiển thị được. Có thể tường lửa hoặc VPN đang chặn.';

  @override
  String get quickShareTurnOn => 'Hiển thị 10 phút';

  @override
  String get settingsQuickShare => 'Dùng với Quick Share';

  @override
  String get settingsQuickShareBody =>
      'Điện thoại Android có thể gửi tệp đến thiết bị này bằng Quick Share trong lúc bạn cho hiển thị. Mỗi tệp đều hỏi trước.';

  @override
  String get healthOk => 'Chưa gửi gì';

  @override
  String healthArrive(String folder) {
    return 'Lưu vào $folder';
  }

  @override
  String healthLastSent(String name) {
    return '$name đã nhận mục bạn gửi gần nhất';
  }

  @override
  String healthLastReceived(String name) {
    return 'Mục gần nhất $name gửi đã đến nơi';
  }

  @override
  String healthDeclinedThere(String name) {
    return '$name đã từ chối mục bạn gửi gần nhất';
  }

  @override
  String healthDeclinedHere(String name) {
    return 'Bạn đã từ chối mục gần nhất $name gửi';
  }

  @override
  String healthCancelledThere(String name) {
    return '$name đã huỷ lượt truyền gần nhất';
  }

  @override
  String get healthCancelledHere => 'Bạn đã huỷ lượt truyền gần nhất';

  @override
  String healthNoAnswerThere(String name) {
    return '$name không phản hồi lần gửi gần nhất của bạn';
  }

  @override
  String healthNoAnswerHere(String name) {
    return 'Mục gần nhất $name gửi chưa được chấp nhận kịp';
  }

  @override
  String get healthSendAgain => 'Gửi lại các tệp từ đây.';

  @override
  String healthSendAgainThere(String name) {
    return 'Trên $name: gửi lại các tệp.';
  }

  @override
  String summaryFolder(String folder) {
    return 'Vào $folder';
  }

  @override
  String get summaryOff => 'Tắt';

  @override
  String get summaryAlwaysReceives => 'Luôn nhận';

  @override
  String get summaryReceivingNow => 'Đang nhận';

  @override
  String get summaryReceivesOnAsk => 'Nhận khi bạn cho phép';

  @override
  String get summaryCannotReceive => 'Hiện không nhận được';

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
      other: '$seconds giây',
    );
    return '$_temp0';
  }

  @override
  String etaMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
    );
    return '$_temp0';
  }

  @override
  String etaHours(int hours, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours giờ',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
    );
    return '$_temp0 $_temp1';
  }

  @override
  String filesDropHere(String device) {
    return 'Thả tệp vào đây để gửi đến $device.';
  }

  @override
  String filesPickToSend(String device) {
    return 'Chọn ảnh và tệp để gửi đến $device.';
  }

  @override
  String get filesChoose => 'Chọn tệp…';

  @override
  String filesOffline(String device) {
    return '$device chưa kết nối. Bạn có thể gửi tệp khi thiết bị kết nối lại.';
  }

  @override
  String get filesRecent => 'Đã gửi và đã nhận';

  @override
  String filesNone(String device) {
    return 'Tệp bạn gửi đến $device và tệp thiết bị đó gửi cho bạn sẽ hiện ở đây.';
  }

  @override
  String get back => 'Quay lại';

  @override
  String progressWeak(String progress) {
    return 'Kết nối yếu · $progress';
  }

  @override
  String get actionTryAll => 'Thử lại tất cả';

  @override
  String failureFoldersUnsupported(String device) {
    return 'Ferret trên $device quá cũ để nhận thư mục. Hãy cập nhật, hoặc gửi các tệp.';
  }

  @override
  String get actionSendLoose => 'Gửi các tệp';

  @override
  String get filesChooseFolder => 'Chọn thư mục…';

  @override
  String get sendFolder => 'Gửi thư mục';

  @override
  String folderFilesDone(int done, int total) {
    return '$done trên $total tệp';
  }

  @override
  String folderProgressDone(String files, String size) {
    return '$files · $size';
  }

  @override
  String folderSkipped(int count) {
    return 'Đã bỏ qua $count liên kết hoặc tệp đặc biệt';
  }

  @override
  String get folderFilesApp => 'Tệp › Ferret';

  @override
  String get iphoneKeepOpen =>
      'Hãy giữ Ferret mở trên iPhone này trong lúc họ gửi.';
}
