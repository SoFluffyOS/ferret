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
  String consentTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho $device điều khiển $_temp0?';
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
  String controlledBy(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device đang điều khiển $_temp0';
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
  String activeNoticeBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Chạm Dừng điều khiển để lấy lại $_temp0.';
  }

  @override
  String permissionTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device chưa thể điều khiển $_temp0';
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
  String auditLine(String device, int minutes, String time, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: 'trong $minutes phút',
      zero: 'chưa đến 1 phút',
    );
    return '$device đã điều khiển $_temp0 $_temp1 lúc $time';
  }

  @override
  String settingsEnabled(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho thiết bị của tôi điều khiển $_temp0';
  }

  @override
  String get settingsEnabledBody =>
      'Điện thoại trở thành bàn di chuột và bàn phím của máy, hoặc một máy tính khác cho mượn bàn phím và chuột của nó. Mỗi thiết bị đều hỏi bạn trước.';

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
  String statusFailedBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ferret chưa biết mình có được điều khiển $_temp0 hay không. Hãy kiểm tra lại.';
  }

  @override
  String get checkAgain => 'Kiểm tra lại';

  @override
  String settingsPerDevice(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Để một điện thoại hoặc máy tính điều khiển $_temp0 mà không cần hỏi, mở thiết bị đó từ Trang chủ.';
  }

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
  String get settingsHistoryTitle => 'Ai đã điều khiển';

  @override
  String settingsHistoryEmpty(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Chưa có thiết bị nào điều khiển $_temp0.';
  }

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
  String healthTurnedOffHelp(String device, String host) {
    String _temp0 = intl.Intl.selectLogic(
      host,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $device: mở Ferret → Cài đặt → Điều khiển rồi bật Cho thiết bị của tôi điều khiển $_temp0.';
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
  String healthHostOffHelp(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Mở Cài đặt → Điều khiển rồi bật Cho thiết bị của tôi điều khiển $_temp0.';
  }

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

  @override
  String screenConsentTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho $device dùng $_temp0 bằng bàn phím và chuột của nó?';
  }

  @override
  String screenConsentBody(String device) {
    return 'Khi bạn chuyển sang từ $device, bàn phím và chuột của nó sẽ di chuyển con trỏ, nhấp và gõ phím ở đây cho đến khi bạn dừng lại. Bạn luôn thấy rõ trong suốt thời gian đó.';
  }

  @override
  String get settingsScreenTitle => 'Một bộ bàn phím và chuột';

  @override
  String get shortcutScreenNext => 'Bàn phím và chuột sang máy tính kế tiếp';

  @override
  String shortcutScreenHome(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Bàn phím và chuột về lại $_temp0';
  }

  @override
  String settingsScreenSwitch(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'của Mac này',
        'windows': 'của PC này',
        'other': 'của máy tính này',
      },
    );
    return 'Dùng bàn phím và chuột $_temp0 trên các máy tính khác của tôi';
  }

  @override
  String get settingsScreenSwitchBody =>
      '⌃⌥→ chuyển chúng sang máy tính kế tiếp đang kết nối, ⌃⌥⎋ đưa chúng về lại. Mỗi máy tính sẽ hỏi ở lần đầu.';

  @override
  String settingsScreenNext(String names) {
    return 'Đang bật. ⌃⌥→ chuyển sang $names.';
  }

  @override
  String get settingsScreenNoTarget =>
      'Đang bật. Chưa có máy tính nào để chuyển sang: mở Ferret trên máy tính kia.';

  @override
  String get settingsScreenAccess => 'Cần quyền Giám sát đầu vào và Trợ năng';

  @override
  String settingsScreenAccessBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'của Mac này',
        'windows': 'của PC này',
        'other': 'của máy tính này',
      },
    );
    return 'Để Ferret giữ phím và con trỏ $_temp0 khi chúng đang ở máy tính khác. Nếu dòng này vẫn còn sau khi bạn đã cho phép cả hai, hãy thoát rồi mở lại Ferret.';
  }

  @override
  String get settingsScreenKeysTaken =>
      'Một ứng dụng khác đang dùng ⌃⌥→ hoặc ⌃⌥⎋, nên Ferret không nhận được.';

  @override
  String get healthScreenKeys => '⌃⌥→ sang máy tính kế tiếp, ⌃⌥⎋ về lại đây';

  @override
  String healthScreenKeysHelp(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '⌃⌥→ trên $_temp0 chuyển bàn phím và chuột của nó sang máy tính kế tiếp đang kết nối, theo thứ tự tên. Nhấn tiếp cho đến khi tới $device. ⌃⌥⎋ đưa chúng về. $device sẽ hỏi ở lần đầu.';
  }

  @override
  String healthScreenOffHelp(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'của Mac này',
        'windows': 'của PC này',
        'other': 'của máy tính này',
      },
    );
    return 'Mở Cài đặt → Điều khiển và bật Dùng bàn phím và chuột $_temp0 trên các máy tính khác của tôi.';
  }

  @override
  String activityScreenAway(String device) {
    return 'Bàn phím và chuột đang ở $device';
  }

  @override
  String get activityScreenAwayDetail => '⌃⌥⎋ để đưa về';

  @override
  String activityScreenAsking(String device) {
    return 'Đang chờ $device cho phép bàn phím và chuột của bạn';
  }

  @override
  String get screenBringBack => 'Đưa về';

  @override
  String get screenNoComputer => 'Không có máy tính nào để chuyển sang';

  @override
  String get screenNoComputerBody =>
      'Hãy kết nối một máy Mac, PC hoặc Linux có Ferret trước.';

  @override
  String get screenNeedsAccess => 'Ferret cần hai quyền';

  @override
  String get screenNeedsAccessBody =>
      'Cho phép Giám sát đầu vào và Trợ năng trong Cài đặt hệ thống → Quyền riêng tư & Bảo mật, rồi nhấn lại ⌃⌥→.';

  @override
  String get screenSecureInput => 'Một ô mật khẩu đang mở';

  @override
  String screenSecureInputBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Nhập xong hoặc đóng nó, rồi nhấn lại ⌃⌥→. Khi ô này đang mở, macOS ẩn thao tác gõ phím khỏi Ferret, nên phím của bạn ở lại $_temp0.';
  }

  @override
  String screenSecureInputApp(String app) {
    return '$app đang giữ phím của bạn';
  }

  @override
  String screenSecureInputAppBody(String app) {
    return 'Thoát $app hoặc đóng ô mật khẩu của nó, rồi nhấn lại ⌃⌥→. Ứng dụng này đã bật chế độ nhập bảo mật của macOS, nên Ferret không thấy phím bạn gõ.';
  }

  @override
  String screenCaptureFailed(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'của Mac này',
        'windows': 'của PC này',
        'other': 'của máy tính này',
      },
    );
    return 'Không giữ được bàn phím và chuột $_temp0';
  }

  @override
  String screenBackHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Bàn phím và chuột của bạn đã về lại $_temp0.';
  }

  @override
  String screenDenied(String device) {
    return '$device không nhận bàn phím và chuột của bạn';
  }

  @override
  String screenLost(String device) {
    return 'Mất kết nối với $device';
  }

  @override
  String screenStopped(String device) {
    return '$device đã dừng';
  }
}
