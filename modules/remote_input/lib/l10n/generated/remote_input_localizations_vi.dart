// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'remote_input_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class RemoteInputLocalizationsVi extends RemoteInputLocalizations {
  RemoteInputLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Điều khiển';

  @override
  String get useAsTouchpad => 'Điều khiển';

  @override
  String get back => 'Quay lại';

  @override
  String consentTitle(String device) {
    return 'Cho $device điều khiển máy tính này?';
  }

  @override
  String consentBody(String device) {
    return '$device có thể di chuyển con trỏ, nhấp và gõ phím ở đây cho đến khi bạn dừng lại. Bạn luôn thấy rõ trong suốt thời gian đó.';
  }

  @override
  String get allowOnce => 'Cho phép một lần';

  @override
  String get allowAlways => 'Luôn cho phép';

  @override
  String get dontAllow => 'Không cho phép';

  @override
  String controlledBy(String device) {
    return '$device đang điều khiển máy tính này';
  }

  @override
  String controlledSince(String time) {
    return 'Từ $time. Thiết bị có thể di chuyển con trỏ và gõ phím.';
  }

  @override
  String get stop => 'Dừng điều khiển';

  @override
  String activityControlling(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device đang điều khiển $_temp0';
  }

  @override
  String get activityStop => 'Dừng';

  @override
  String activityControlled(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device đã điều khiển $_temp0';
  }

  @override
  String activityControlledFor(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'Trong $minutes phút',
      zero: 'Chưa đến 1 phút',
    );
    return '$_temp0';
  }

  @override
  String get activeNoticeBody =>
      'Chạm Dừng điều khiển để lấy lại máy tính này.';

  @override
  String permissionTitle(String device) {
    return '$device chưa thể điều khiển máy tính này';
  }

  @override
  String permissionBody(String device) {
    return 'Cho phép Ferret trong cài đặt Trợ năng, rồi thử lại trên $device.';
  }

  @override
  String get openSettings => 'Mở Cài đặt';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String auditLine(String device, int minutes, String time) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'trong $minutes phút',
      zero: 'chưa đến 1 phút',
    );
    return '$device đã điều khiển máy tính này $_temp0 lúc $time';
  }

  @override
  String get settingsEnabled =>
      'Cho điện thoại của tôi điều khiển máy tính này';

  @override
  String get settingsEnabledBody =>
      'Điện thoại trở thành bàn di chuột và bàn phím của máy. Mỗi điện thoại đều hỏi bạn trước.';

  @override
  String get statusReadyQuartz => 'Đang bật. Dùng quyền Trợ năng.';

  @override
  String get statusReadySendInput =>
      'Đang bật. Không điều khiển được ứng dụng chạy với quyền quản trị viên.';

  @override
  String get statusReadyUinput => 'Đang bật. Dùng thiết bị nhập ảo.';

  @override
  String get statusReadyXdotool =>
      'Đang bật. Dùng xdotool, chỉ hoạt động trên X11.';

  @override
  String get statusReadyYdotool => 'Đang bật. Dùng ydotool.';

  @override
  String get statusNeedsPermission => 'Quyền Trợ năng đang tắt';

  @override
  String get statusNeedsPermissionBody =>
      'macOS hỏi trước khi cho ứng dụng di chuyển con trỏ hoặc gõ phím. Bật Ferret trong danh sách, rồi quay lại đây.';

  @override
  String get allowAccess => 'Cấp quyền truy cập';

  @override
  String get statusNoLinuxBackend => 'Chưa thể điều khiển máy tính này';

  @override
  String get statusNoLinuxBackendBody =>
      'Ferret cần quyền ghi vào /dev/uinput, hoặc xdotool (X11) hay ydotool (Wayland). Cài một trong số đó bằng trình quản lý gói, rồi kiểm tra lại.';

  @override
  String get statusYdotoolNotRunning =>
      'Đã cài ydotool, nhưng dịch vụ của nó chưa chạy';

  @override
  String get statusYdotoolNotRunningBody =>
      'Khởi động dịch vụ ydotoold, rồi kiểm tra lại.';

  @override
  String get statusFailed => 'Chưa kiểm tra';

  @override
  String get statusFailedBody =>
      'Ferret chưa biết mình có được điều khiển máy tính này hay không. Hãy kiểm tra lại.';

  @override
  String get checkAgain => 'Kiểm tra lại';

  @override
  String get settingsPerDevice =>
      'Để một điện thoại điều khiển máy tính này mà không cần hỏi, mở điện thoại đó từ Trang chủ.';

  @override
  String get settingsHostTitle => 'Con trỏ và bàn phím';

  @override
  String get settingsTouchpadTitle => 'Bàn di chuột';

  @override
  String get summaryOn => 'Bật';

  @override
  String get summaryOff => 'Tắt';

  @override
  String get summaryNeedsAccess => 'Cần cấp quyền';

  @override
  String get summaryUnavailable => 'Chưa dùng được';

  @override
  String permissionAlways(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Điều khiển $_temp0 mà không cần hỏi';
  }

  @override
  String get permissionAlwaysDetail =>
      'Bạn vẫn luôn thấy rõ, kèm nút Dừng điều khiển.';

  @override
  String get permissionAlwaysOff =>
      'Điều khiển đang tắt. Bật trong Cài đặt → Điều khiển.';

  @override
  String get settingsHistoryTitle => 'Lịch sử';

  @override
  String get settingsHistoryEmpty =>
      'Chưa có thiết bị nào điều khiển máy tính này.';

  @override
  String get clearHistory => 'Xoá lịch sử';

  @override
  String get settingsSpeed => 'Tốc độ bàn di chuột';

  @override
  String get settingsSpeedBody =>
      'Con trỏ đi xa bao nhiêu với cùng một quãng vuốt ngón tay.';

  @override
  String get settingsNaturalScroll => 'Cuộn tự nhiên';

  @override
  String get settingsNaturalScrollBody =>
      'Vuốt hai ngón tay lên để cuộn xuống, giống trên màn hình điện thoại.';

  @override
  String requesting(String device) {
    return 'Đang hỏi $device…';
  }

  @override
  String waitingTitle(String device) {
    return 'Đang chờ $device';
  }

  @override
  String waitingBody(String device) {
    return 'Trên $device: nhấp Cho phép một lần. Chọn Luôn cho phép để lần sau không hỏi nữa.';
  }

  @override
  String get cancel => 'Huỷ';

  @override
  String get touchpadHint =>
      'Một ngón để di chuyển. Chạm để nhấp, giữ để nhấp chuột phải. Hai ngón để cuộn. Chạm rồi trượt để kéo.';

  @override
  String get leftButton => 'Nhấp chuột trái';

  @override
  String get rightButton => 'Nhấp chuột phải';

  @override
  String get keyboardHint => 'Gõ ở đây';

  @override
  String get showKeyboard => 'Bàn phím';

  @override
  String get hideKeyboard => 'Ẩn bàn phím';

  @override
  String get keyEscape => 'Esc';

  @override
  String get keyTab => 'Tab';

  @override
  String get keyEnter => 'Enter';

  @override
  String get keyBackspace => 'Backspace';

  @override
  String get keyLeft => 'Trái';

  @override
  String get keyRight => 'Phải';

  @override
  String get keyUp => 'Lên';

  @override
  String get keyDown => 'Xuống';

  @override
  String get mediaPrevious => 'Bài trước';

  @override
  String get mediaPlayPause => 'Phát hoặc tạm dừng';

  @override
  String get mediaNext => 'Bài tiếp';

  @override
  String get volumeDown => 'Giảm âm lượng';

  @override
  String get volumeMute => 'Tắt tiếng';

  @override
  String get volumeUp => 'Tăng âm lượng';

  @override
  String get modShift => 'Shift';

  @override
  String get modControl => 'Ctrl';

  @override
  String get modAlt => 'Alt';

  @override
  String get modAltMac => 'Option';

  @override
  String get modMeta => 'Win';

  @override
  String get modMetaMac => 'Cmd';

  @override
  String get modMetaLinux => 'Super';

  @override
  String deniedDenied(String device) {
    return '$device đã từ chối.';
  }

  @override
  String deniedTimeout(String device) {
    return 'Không ai phản hồi trên $device.';
  }

  @override
  String deniedBusy(String device) {
    return 'Một thiết bị khác đang điều khiển $device.';
  }

  @override
  String deniedNeedsPermission(String device) {
    return '$device cần quyền Trợ năng trước. Trên $device: mở Ferret và cấp quyền.';
  }

  @override
  String deniedUnsupported(String device) {
    return 'Chưa thể điều khiển $device. Trên $device: mở Ferret → Cài đặt → Điều khiển để xem lý do.';
  }

  @override
  String deniedTurnedOff(String device) {
    return 'Điều khiển đang tắt trên $device. Trên $device: mở Ferret → Cài đặt → Điều khiển rồi bật lên.';
  }

  @override
  String deniedVersion(String device) {
    return '$device đang chạy Ferret bản cũ. Cập nhật Ferret trên $device, rồi thử lại.';
  }

  @override
  String stoppedOnHost(String device) {
    return 'Có người đã dừng điều khiển trên $device.';
  }

  @override
  String get stoppedIdle => 'Đã dừng vì lâu không có thao tác.';

  @override
  String stoppedRevoked(String device) {
    return '$device không còn cho điện thoại này điều khiển.';
  }

  @override
  String stoppedFailed(String device) {
    return '$device không còn di chuyển con trỏ hay gõ phím được nữa. Trên $device: kiểm tra quyền Trợ năng.';
  }

  @override
  String lostConnection(String device) {
    return 'Mất kết nối với $device.';
  }

  @override
  String unreachable(String device) {
    return '$device không phản hồi. Trên $device: mở Ferret.';
  }

  @override
  String get tryAgain => 'Thử lại';

  @override
  String controllingTitle(String device) {
    return 'Đang điều khiển $device';
  }

  @override
  String get controllingBody => 'Điện thoại này là bàn di chuột của máy.';

  @override
  String get openTouchpad => 'Mở bàn di chuột';

  @override
  String healthAsksFirst(String device) {
    return 'Hỏi trên $device trước';
  }

  @override
  String healthAlways(String device) {
    return 'Được phép trên $device mà không cần hỏi';
  }

  @override
  String healthControlling(String device) {
    return 'Đang điều khiển $device';
  }

  @override
  String healthNeedsPermissionHelp(String device) {
    return 'Trên $device: mở Ferret → Cài đặt → Điều khiển rồi nhấp Cấp quyền truy cập.';
  }

  @override
  String healthUnsupportedHelp(String device) {
    return 'Trên $device: mở Ferret → Cài đặt → Điều khiển để xem còn thiếu gì.';
  }

  @override
  String healthTurnedOffHelp(String device) {
    return 'Trên $device: mở Ferret → Cài đặt → Điều khiển rồi bật Cho điện thoại của tôi điều khiển máy tính này.';
  }

  @override
  String healthVersion(String device) {
    return 'Cần cập nhật Ferret trên $device';
  }

  @override
  String healthVersionHelp(String device) {
    return 'Trên $device: cập nhật Ferret.';
  }

  @override
  String healthNotAnswering(String device) {
    return 'Lần trước $device không phản hồi';
  }

  @override
  String healthNotAnsweringHelp(String device) {
    return 'Trên $device: mở Ferret.';
  }

  @override
  String healthHostAsks(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Hỏi trước khi điều khiển $_temp0';
  }

  @override
  String healthHostAlways(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Được điều khiển $_temp0 mà không cần hỏi';
  }

  @override
  String healthHostControlling(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Đang điều khiển $_temp0';
  }

  @override
  String healthHostOff(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Đang tắt trên $_temp0';
  }

  @override
  String get healthHostOffHelp =>
      'Mở Cài đặt → Điều khiển rồi bật Cho điện thoại của tôi điều khiển máy tính này.';

  @override
  String healthHostNeedsAccess(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cần quyền Trợ năng trên $_temp0';
  }

  @override
  String get healthHostNeedsAccessHelp =>
      'Mở Cài đặt → Điều khiển rồi nhấp Cấp quyền truy cập.';

  @override
  String get healthHostUnavailable => 'Chưa thể điều khiển';

  @override
  String get healthHostUnavailableHelp =>
      'Mở Cài đặt → Điều khiển để xem còn thiếu gì.';

  @override
  String healthNeedsPermission(String device) {
    return 'Cần quyền Trợ năng trên $device';
  }

  @override
  String healthUnsupported(String device) {
    return 'Không thể điều khiển $device';
  }

  @override
  String healthTurnedOff(String device) {
    return 'Đang tắt trên $device';
  }

  @override
  String lockConsentTitle(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép $device khoá $_temp0?';
  }

  @override
  String lockConsentBody(String device) {
    return '$device muốn khoá màn hình ngay. Chọn Luôn cho phép thì lần sau sẽ khoá ngay.';
  }

  @override
  String lockDevice(String device) {
    return 'Khoá $device';
  }

  @override
  String lockAsking(String device) {
    return 'Đang khoá $device…';
  }

  @override
  String lockAskingDetail(String device) {
    return 'Nếu được hỏi, hãy trả lời trên $device.';
  }

  @override
  String lockLocked(String device) {
    return 'Đã khoá $device';
  }

  @override
  String lockDenied(String device) {
    return '$device không cho khoá';
  }

  @override
  String lockTimedOut(String device) {
    return '$device không trả lời';
  }

  @override
  String get lockTimedOutDetail =>
      'Không ai đồng ý trên máy đó kịp lúc, hoặc máy đã ngoại tuyến.';

  @override
  String lockBusy(String device) {
    return '$device đang hỏi về một thiết bị khác';
  }

  @override
  String lockTurnedOff(String device) {
    return 'Điều khiển đang tắt trên $device';
  }

  @override
  String get lockTurnedOffDetail =>
      'Bật lại trên máy đó trong Cài đặt → Điều khiển.';

  @override
  String lockFailed(String device) {
    return '$device không khoá được';
  }

  @override
  String permissionLock(String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Khoá $_temp0 mà không cần hỏi';
  }

  @override
  String get permissionLockDetail => 'Khoá từ điện thoại, không cần hỏi ở đây.';

  @override
  String presentOn(String device) {
    return 'Trình chiếu trên $device';
  }

  @override
  String get presentTitle => 'Trình chiếu';

  @override
  String get presentNext => 'Tiếp';

  @override
  String get presentPrevious => 'Trước';

  @override
  String get presentBlackScreen => 'Màn hình đen';

  @override
  String get presentShowSlides => 'Hiện trang chiếu';

  @override
  String get presentTimerHint => 'Đồng hồ bắt đầu từ trang chiếu đầu tiên';

  @override
  String get presentRestartTimer => 'Chạm vào thời gian để đếm lại';

  @override
  String get presentWorksWith =>
      'Dùng được với PowerPoint, Keynote, Google Slides và PDF ở chế độ toàn màn hình, như một bút trình chiếu.';
}
