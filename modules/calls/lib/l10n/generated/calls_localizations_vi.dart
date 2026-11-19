// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'calls_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class CallsLocalizationsVi extends CallsLocalizations {
  CallsLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Cuộc gọi';

  @override
  String get back => 'Quay lại';

  @override
  String get unknownCaller => 'Người gọi không xác định';

  @override
  String incomingOn(String device) {
    return 'Cuộc gọi đến trên $device';
  }

  @override
  String callingOn(String device) {
    return 'Đang gọi từ $device';
  }

  @override
  String onCallOn(String device) {
    return 'Đang trong cuộc gọi trên $device';
  }

  @override
  String onHoldOn(String device) {
    return 'Đang giữ máy trên $device';
  }

  @override
  String get answer => 'Trả lời';

  @override
  String get decline => 'Từ chối';

  @override
  String get hangUp => 'Kết thúc';

  @override
  String activityRinging(String caller, String device) {
    return '$caller đang gọi đến $device';
  }

  @override
  String activityOnCall(String caller) {
    return 'Đang gọi với $caller';
  }

  @override
  String activityDialing(String caller) {
    return 'Đang gọi $caller';
  }

  @override
  String activityOnHold(String caller) {
    return 'Đang giữ máy với $caller';
  }

  @override
  String get silence => 'Tắt chuông';

  @override
  String get silenced => 'Đã tắt chuông';

  @override
  String audioStays(String device) {
    return 'Hiện âm thanh vẫn ở trên $device. Hãy nói chuyện trên $device hoặc tai nghe của máy.';
  }

  @override
  String get outcomeNoCall => 'Cuộc gọi đó đã kết thúc.';

  @override
  String outcomeDisabled(String device) {
    return 'Cuộc gọi đang tắt trên $device. Trên $device: Ferret → Làm được nhiều hơn → Cuộc gọi.';
  }

  @override
  String outcomePermission(String device) {
    return '$device chưa cho phép việc này. Trên $device: Ferret → Cài đặt → Đến máy tính của bạn, rồi cho phép trong mục Cuộc gọi.';
  }

  @override
  String outcomeUnsupported(String device) {
    return 'Phiên bản Android của $device không hỗ trợ việc này.';
  }

  @override
  String get outcomeInvalidNumber => 'Có vẻ đó không phải là số điện thoại.';

  @override
  String outcomeFailed(String device) {
    return '$device không làm được việc đó. Hãy thử trên $device.';
  }

  @override
  String outcomeUnreachable(String device) {
    return '$device không phản hồi. Hãy kiểm tra xem máy đã kết nối chưa.';
  }

  @override
  String noticeIncomingBody(String device) {
    return 'Cuộc gọi đến · $device';
  }

  @override
  String privateCallCover(String device) {
    return 'Cuộc gọi trên $device';
  }

  @override
  String get noticeMissedTitle => 'Cuộc gọi nhỡ';

  @override
  String noticeMissedBody(String caller, String device) {
    return '$caller · $device';
  }

  @override
  String get callAction => 'Gọi…';

  @override
  String dialerTitle(String device) {
    return 'Gọi từ $device';
  }

  @override
  String get numberLabel => 'Số điện thoại';

  @override
  String get numberHint => '+1 555 0100';

  @override
  String get call => 'Gọi';

  @override
  String callStarted(String device) {
    return '$device đang gọi. Hiện âm thanh vẫn ở trên $device.';
  }

  @override
  String get dialSection => 'Cuộc gọi mới';

  @override
  String get recentCalls => 'Cuộc gọi gần đây';

  @override
  String get recentEmpty => 'Không có cuộc gọi gần đây.';

  @override
  String get recentLoading => 'Đang tải cuộc gọi gần đây…';

  @override
  String logUnreachable(String device) {
    return '$device không phản hồi. Hãy kiểm tra xem máy đã kết nối chưa.';
  }

  @override
  String logPermission(String device) {
    return '$device chưa cho Ferret đọc cuộc gọi gần đây. Trên $device: Ferret → Cài đặt → Đến máy tính của bạn, rồi cho phép Nhật ký cuộc gọi trong mục Cuộc gọi.';
  }

  @override
  String logDisabled(String device) {
    return 'Cuộc gọi đang tắt trên $device. Trên $device: Ferret → Làm được nhiều hơn → Cuộc gọi.';
  }

  @override
  String get retry => 'Thử lại';

  @override
  String get typeIncoming => 'Cuộc gọi đến';

  @override
  String get typeOutgoing => 'Cuộc gọi đi';

  @override
  String get typeMissed => 'Cuộc gọi nhỡ';

  @override
  String get typeRejected => 'Đã từ chối';

  @override
  String get privateNumber => 'Số riêng tư';

  @override
  String get explainer => 'Xem ai đang gọi và trả lời ngay trên máy tính.';

  @override
  String get explainerDetail =>
      'Android sẽ xin quyền Điện thoại, Nhật ký cuộc gọi và Danh bạ. Cuộc gọi chỉ được chuyển đến các thiết bị bạn đã ghép đôi. Hiện âm thanh vẫn ở trên điện thoại này.';

  @override
  String get turnOn => 'Bật';

  @override
  String get turnOff => 'Tắt';

  @override
  String get setUp => 'Thiết lập';

  @override
  String get fix => 'Sửa';

  @override
  String get phoneHomePaused =>
      'Cuộc gọi đang bật, nhưng Ferret chưa thấy được cuộc gọi của điện thoại này.';

  @override
  String get permissionOff => 'Ferret chưa thấy được cuộc gọi';

  @override
  String get permissionStillOff =>
      'Vẫn đang tắt. Android sẽ không hỏi lại, nên hãy cho phép trong cài đặt của ứng dụng.';

  @override
  String get permissionHowTo =>
      'Cho phép quyền Điện thoại để Ferret báo cho máy tính khi có cuộc gọi đến.';

  @override
  String get permissionHowToSettings =>
      'Trong cài đặt của ứng dụng, mở Quyền, chọn Điện thoại, rồi chọn Cho phép. Làm tương tự với Nhật ký cuộc gọi và Danh bạ.';

  @override
  String get allow => 'Cho phép truy cập';

  @override
  String get allowRest => 'Cho phép phần còn lại';

  @override
  String get openSettings => 'Mở cài đặt ứng dụng';

  @override
  String get openSettingsFailed =>
      'Không mở được Cài đặt. Hãy mở Cài đặt Android, chọn Ứng dụng, chọn Ferret, rồi chọn Quyền.';

  @override
  String get ready => 'Máy tính của bạn thấy được cuộc gọi của điện thoại này';

  @override
  String get capNumbers => 'Ai đang gọi và các cuộc gọi gần đây';

  @override
  String get capContacts => 'Tên và ảnh';

  @override
  String get capAnswer => 'Trả lời, từ chối và kết thúc';

  @override
  String get capDial => 'Gọi đi từ máy tính';

  @override
  String get audioOnPhone =>
      'Hiện âm thanh cuộc gọi vẫn ở trên điện thoại này.';

  @override
  String get showIncoming => 'Hiện cuộc gọi đến';

  @override
  String get showIncomingDetail =>
      'Một thông báo có nút Trả lời và Từ chối khi điện thoại đổ chuông.';

  @override
  String get settingsAudio =>
      'Hiện âm thanh cuộc gọi vẫn ở trên điện thoại. Ferret nhận cuộc gọi, còn bạn nói chuyện trên điện thoại hoặc tai nghe của máy.';

  @override
  String healthNoAnswer(String device) {
    return '$device không phản hồi';
  }

  @override
  String healthOff(String device) {
    return 'Đang tắt trên $device';
  }

  @override
  String get healthNeedsPermission =>
      'Android đã tắt quyền truy cập của Ferret';

  @override
  String healthLimited(String device) {
    return 'Chỉ hiện cuộc gọi. Trả lời trên $device';
  }

  @override
  String get healthOk => 'Trả lời và từ chối';

  @override
  String get healthChecking => 'Đang kiểm tra…';

  @override
  String healthOffHelp(String device) {
    return 'Trên $device: Ferret → Làm được nhiều hơn → Cuộc gọi.';
  }

  @override
  String healthNeedsPermissionHelp(String device) {
    return 'Trên $device: mở Ferret và nhấn Sửa.';
  }

  @override
  String get healthLocalOffHelp =>
      'Trên điện thoại này: Cài đặt → Đến máy tính của bạn → Cuộc gọi.';

  @override
  String healthLocalPushFailedHelp(String device) {
    return 'Trên $device: mở Ferret. Cuộc gọi tiếp theo sẽ hiện ở đó.';
  }

  @override
  String get settingsNeedsAccess => 'Cần cấp quyền';

  @override
  String settingsNeedsAccessOn(String device) {
    return 'Cần cấp quyền trên $device';
  }

  @override
  String get healthLocalOff => 'Đang tắt trên điện thoại này';

  @override
  String get healthLocalNeedsPermission =>
      'Android đã tắt quyền truy cập của Ferret';

  @override
  String healthLocalPushFailed(String device) {
    return 'Cuộc gọi gần nhất không đến được $device';
  }

  @override
  String healthLocalOk(String device) {
    return '$device thấy được cuộc gọi của điện thoại này';
  }
}
