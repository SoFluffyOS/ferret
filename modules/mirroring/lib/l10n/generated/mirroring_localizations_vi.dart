// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'mirroring_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MirroringLocalizationsVi extends MirroringLocalizations {
  MirroringLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Màn hình';

  @override
  String get showScreen => 'Xem màn hình';

  @override
  String windowTitle(String device) {
    return '$device — Màn hình';
  }

  @override
  String inWindowTitle(String device) {
    return 'Màn hình của $device đang ở cửa sổ riêng';
  }

  @override
  String get bringToFront => 'Đưa lên trước';

  @override
  String launcherTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Xem màn hình của $device trên $_temp0';
  }

  @override
  String launcherBody(String device) {
    return '$device sẽ hỏi bạn mỗi lần, trừ khi đang cắm cáp mà bạn đã cho phép.';
  }

  @override
  String get stop => 'Dừng';

  @override
  String get cancel => 'Huỷ';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get back => 'Quay lại';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String get fullScreen => 'Toàn màn hình';

  @override
  String get exitFullScreen => 'Thoát toàn màn hình';

  @override
  String requestingTitle(String device) {
    return 'Đang hỏi $device…';
  }

  @override
  String waitingTitle(String device) {
    return 'Trả lời trên $device';
  }

  @override
  String waitingBody(String device) {
    return 'Trên $device, chọn chia sẻ toàn bộ màn hình rồi nhấn Bắt đầu.';
  }

  @override
  String startingTitle(String device) {
    return '$device đã đồng ý';
  }

  @override
  String get startingBody => 'Đang chờ hình ảnh đầu tiên…';

  @override
  String screenOffTitle(String device) {
    return 'Màn hình của $device đang tắt';
  }

  @override
  String screenOffBody(String device) {
    return 'Đánh thức $device để xem tiếp.';
  }

  @override
  String endDeniedTitle(String device) {
    return '$device đã từ chối';
  }

  @override
  String endDeniedBody(String device) {
    return 'Có người đã nhấn Huỷ trên $device.';
  }

  @override
  String endTimedOutTitle(String device) {
    return 'Không ai trả lời trên $device';
  }

  @override
  String endTimedOutBody(String device) {
    return 'Câu hỏi hiện trên $device trong một phút. Đánh thức $device rồi hỏi lại.';
  }

  @override
  String endBusyTitle(String device) {
    return '$device đang chia sẻ màn hình rồi';
  }

  @override
  String get endBusyBody =>
      'Điện thoại chỉ chia sẻ màn hình với một thiết bị mỗi lần. Hãy dừng thiết bị kia trước.';

  @override
  String endUnsupportedTitle(String device) {
    return '$device không thể chia sẻ màn hình';
  }

  @override
  String get endUnsupportedBody =>
      'Xem màn hình cần một điện thoại Android có Ferret.';

  @override
  String endTurnedOffTitle(String device) {
    return 'Chia sẻ màn hình đang tắt trên $device';
  }

  @override
  String endTurnedOffBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $device: mở Ferret → Cài đặt → Đến máy tính của bạn và bật “Cho máy tính của tôi hỏi xem màn hình này”. Sau đó mở $_temp0 ở đó và kiểm tra xem nó có được phép hỏi không.';
  }

  @override
  String endCannotAskTitle(String device) {
    return '$device không hiện được câu hỏi';
  }

  @override
  String endCannotAskBody(String device) {
    return 'Trên $device: mở Ferret hoặc cho phép thông báo của Ferret. Sau đó hỏi lại.';
  }

  @override
  String endVersionTitle(String device) {
    return '$device cần Ferret mới hơn';
  }

  @override
  String endVersionBody(String device) {
    return 'Cập nhật Ferret trên $device rồi thử lại.';
  }

  @override
  String endNoCodecTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device không gửi được hình ảnh mà $_temp0 hiển thị được';
  }

  @override
  String endNoCodecBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cập nhật Ferret trên $device và trên $_temp0 rồi thử lại.';
  }

  @override
  String endNotConnectedTitle(String device) {
    return '$device chưa kết nối';
  }

  @override
  String endNotConnectedBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $device: mở Ferret. Đã cùng Wi-Fi với $_temp0 chưa?';
  }

  @override
  String endNoAnswerTitle(String device) {
    return '$device không trả lời';
  }

  @override
  String endNoAnswerBody(String device) {
    return 'Trên $device: mở Ferret. Sau đó thử lại.';
  }

  @override
  String endStoppedOnPhoneTitle(String device) {
    return 'Đã dừng trên $device';
  }

  @override
  String endStoppedOnPhoneBody(String device) {
    return 'Có người đã nhấn Dừng trên $device.';
  }

  @override
  String endSystemEndedTitle(String device) {
    return '$device đã ngừng chia sẻ';
  }

  @override
  String endSystemEndedBody(String device) {
    return 'Android ngừng chia sẻ khi $device khoá màn hình hoặc khi có người dừng từ thanh trạng thái. Mở khoá $device rồi xem lại.';
  }

  @override
  String endLostConnectionTitle(String device) {
    return 'Mất kết nối với $device';
  }

  @override
  String endLostConnectionBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Kiểm tra xem $device có đang bật và cùng Wi-Fi với $_temp0 không.';
  }

  @override
  String get endFailedTitle => 'Hình ảnh đã dừng';

  @override
  String endFailedBody(String device) {
    return '$device không chụp được màn hình của nó.';
  }

  @override
  String get endDecoderFailedTitle =>
      'Máy tính này không hiển thị được hình ảnh';

  @override
  String endDecoderFailedBody(String device) {
    return 'Video từ $device không phát được ở đây.';
  }

  @override
  String statusPicture(String codec, int width, int height, int fps) {
    return '$codec · $width×$height · $fps fps';
  }

  @override
  String statusLatency(int milliseconds) {
    return '$milliseconds ms';
  }

  @override
  String statusBitrate(String megabits) {
    return '$megabits Mbps';
  }

  @override
  String statusDropped(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'rớt $count khung',
    );
    return '$_temp0';
  }

  @override
  String get codecH264 => 'H.264';

  @override
  String get codecJpeg => 'JPEG';

  @override
  String viewingTitle(String device) {
    return 'Đang xem màn hình của $device';
  }

  @override
  String sharingTitle(String device) {
    return 'Đang chia sẻ màn hình với $device';
  }

  @override
  String sharingBody(String time) {
    return 'Mọi thứ trên màn hình này đều hiện ở bên đó. Từ $time.';
  }

  @override
  String askingTitle(String device) {
    return '$device muốn xem màn hình này';
  }

  @override
  String get askingBody =>
      'Trả lời lời nhắc của Android. Nếu không thấy, hãy nhấn vào thông báo từ Ferret.';

  @override
  String auditShared(String device, String duration, String time) {
    return '$device đã xem màn hình điện thoại này trong $duration lúc $time';
  }

  @override
  String auditViewed(String device, String duration, String time) {
    return 'Bạn đã xem màn hình của $device trong $duration lúc $time';
  }

  @override
  String durationSeconds(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds giây',
    );
    return '$_temp0';
  }

  @override
  String durationMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
    );
    return '$_temp0';
  }

  @override
  String durationHours(int hours, int minutes) {
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
  String get noticeAskBody => 'Nhấn để trả lời';

  @override
  String get noticeAskChannel => 'Yêu cầu chia sẻ màn hình';

  @override
  String get noticeSharingBody => 'Mọi thứ trên màn hình này đều hiện ở bên đó';

  @override
  String get noticeSharingChannel => 'Chia sẻ màn hình';

  @override
  String get settingsAllow => 'Cho máy tính của tôi hỏi xem màn hình này';

  @override
  String get settingsAllowBody =>
      'Android sẽ hỏi bạn mỗi lần. Không có gì được chia sẻ trước khi bạn đồng ý.';

  @override
  String sharingTitleSound(String device) {
    return 'Đang chia sẻ màn hình và âm thanh với $device';
  }

  @override
  String sharingBodySound(String time) {
    return 'Mọi thứ trên màn hình này đều hiện ở đó, kèm âm thanh. Từ $time.';
  }

  @override
  String get noticeSharingBodySound =>
      'Mọi thứ trên màn hình này đều hiện ở đó, kèm âm thanh';

  @override
  String get settingsSendSound => 'Gửi cả âm thanh';

  @override
  String get settingsSendSoundBody =>
      'Máy tính đang xem màn hình này cũng nghe được những gì điện thoại phát: nhạc, video, trò chơi. Chỉ khi đang chia sẻ màn hình, và không bao giờ dùng micrô. Một số ứng dụng chặn việc này nên sẽ im lặng.';

  @override
  String get settingsSendSoundPermission =>
      'Android gọi quyền này là \"ghi âm\" và xếp nó vào mục Micrô. Ferret chỉ ghi lại những gì điện thoại phát ra.';

  @override
  String get settingsSendSoundDenied =>
      'Android chưa cho phép. Để đổi, hãy mở Ferret trong phần cài đặt ứng dụng của Android, rồi Quyền → Micrô.';

  @override
  String get settingsSendSoundUnsupported =>
      'Gửi âm thanh cần Android 10 trở lên.';

  @override
  String get settingsUnsupported =>
      'Điện thoại này không chụp được màn hình của nó';

  @override
  String get settingsHistoryTitle => 'Lịch sử';

  @override
  String get settingsHistoryEmptyShared => 'Chưa ai xem màn hình này.';

  @override
  String get clearHistory => 'Xoá lịch sử';

  @override
  String get settingsPerDevice =>
      'Để chặn một máy tính hỏi, hãy mở máy đó từ Trang chủ.';

  @override
  String get summaryOff => 'Tắt';

  @override
  String get summaryAsks => 'Hỏi mỗi lần';

  @override
  String get summaryCantCapture => 'Không chụp được';

  @override
  String get permissionAsk => 'Hỏi xem màn hình điện thoại này';

  @override
  String get permissionAskOff =>
      'Màn hình đang tắt với mọi máy tính. Bật trong Cài đặt → Đến máy tính của bạn.';

  @override
  String healthAsks(String device) {
    return 'Hỏi trên $device mỗi lần';
  }

  @override
  String get healthTryAgainHelp => 'Chọn Xem màn hình để thử lại.';

  @override
  String get healthShareOff => 'Đang tắt trên điện thoại này';

  @override
  String get healthShareOffHelp =>
      'Mở Cài đặt → Đến máy tính của bạn và bật “Cho máy tính của tôi hỏi xem màn hình này”.';

  @override
  String healthShareBlocked(String device) {
    return 'Đang tắt với $device';
  }

  @override
  String healthShareBlockedHelp(String device) {
    return 'Bật “Hỏi xem màn hình điện thoại này” cho $device ở phía dưới trang này.';
  }

  @override
  String get healthSharing => 'Đang xem màn hình điện thoại này';

  @override
  String get healthShareAsks => 'Hỏi bạn mỗi lần';

  @override
  String get healthViewing => 'Đang hiện màn hình của nó ở đây';

  @override
  String healthTurnedOff(String device) {
    return 'Đang tắt trên $device';
  }

  @override
  String healthUnsupported(String device) {
    return '$device không thể chia sẻ màn hình';
  }

  @override
  String healthCannotAsk(String device) {
    return '$device không hiện được câu hỏi';
  }

  @override
  String healthFailed(String device) {
    return '$device không chụp được màn hình của nó';
  }

  @override
  String get healthDecoderFailed => 'Máy tính này không hiển thị được hình ảnh';

  @override
  String get experimental => 'Thử nghiệm';

  @override
  String get targetCable => 'Cáp';

  @override
  String get targetWireless => 'Gỡ lỗi qua Wi-Fi';

  @override
  String setupInstallToolBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cài bộ platform tools của Android (có sẵn adb) trên $_temp0. Trang này sẽ tự chuyển tiếp.';
  }

  @override
  String get setupDownloadToolTitle => 'Tải công cụ hỗ trợ của Android';

  @override
  String get setupDownloadToolBody =>
      'Ferret tải bộ platform tools của Android từ Google, khoảng 16 MB, chỉ một lần.';

  @override
  String get download => 'Tải về';

  @override
  String get downloading => 'Đang tải về…';

  @override
  String setupDownloadFailed(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Chưa tải xong. Kiểm tra kết nối internet của $_temp0 rồi thử lại.';
  }

  @override
  String get setupStartToolTitle => 'Khởi động công cụ hỗ trợ của Android';

  @override
  String setupStartToolBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ferret không được phép khởi động adb trên $_temp0. Mở Android Studio hoặc chạy adb start-server trong Terminal. Trang này sẽ tự chuyển tiếp.';
  }

  @override
  String setupPermissionTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ferret cần bạn cho phép trên $_temp0';
  }

  @override
  String setupPermissionBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép Ferret trong mục Mạng cục bộ ở cài đặt quyền riêng tư của $_temp0.';
  }

  @override
  String get buttonBack => 'Quay lại';

  @override
  String get buttonHome => 'Màn hình chính';

  @override
  String get buttonRecents => 'Gần đây';

  @override
  String get receiverAirplayTitle => 'Xem màn hình iPhone và iPad ở đây';

  @override
  String get receiverAirplayBody =>
      'Máy tính này xuất hiện trong mục Phản chiếu màn hình ở Trung tâm điều khiển của iPhone. Bạn luôn được hỏi trước khi có gì hiện lên.';

  @override
  String get receiverOtherTitle => 'Cho thiết bị khác gửi màn hình đến đây';

  @override
  String get receiverOtherBody => 'Bạn luôn được hỏi trước khi có gì hiện lên.';

  @override
  String allowTitle(String device) {
    return '$device muốn hiện màn hình của nó ở đây';
  }

  @override
  String get allow => 'Hiển thị';

  @override
  String get dontAllow => 'Không cho phép';

  @override
  String get close => 'Đóng';

  @override
  String get showAgain => 'Xem lại';

  @override
  String get askAgain => 'Hỏi lại';

  @override
  String askAgainIn(String time) {
    return 'Bạn có thể hỏi lại sau $time.';
  }

  @override
  String get how => 'Cách làm';

  @override
  String get why => 'Tại sao?';

  @override
  String get wake => 'Đánh thức';

  @override
  String get notMine => 'Không phải của tôi';

  @override
  String get showIt => 'Hiển thị';

  @override
  String startingCableTitle(String device) {
    return 'Đang hiện $device…';
  }

  @override
  String waitingNothing(String device) {
    return 'Không thấy gì trên $device? Mở thông báo từ Ferret.';
  }

  @override
  String get waitingWhy =>
      'Android hỏi mỗi lần. Ferret không thể bỏ qua bước này, và cũng không muốn.';

  @override
  String timeLeft(String time) {
    return 'Còn $time';
  }

  @override
  String reconnectingTitle(String device) {
    return 'Đang kết nối lại với $device…';
  }

  @override
  String lostTitle(String device) {
    return 'Mất kết nối với $device';
  }

  @override
  String lostBody(String device) {
    return 'Sẽ tự tiếp tục khi $device quay lại.';
  }

  @override
  String lostCableBody(String device) {
    return 'Cắm lại $device. Hình ảnh sẽ tự tiếp tục.';
  }

  @override
  String notConnectedWaits(String device) {
    return 'Sẽ tự bắt đầu khi $device kết nối.';
  }

  @override
  String get orDivider => 'hoặc';

  @override
  String plugInTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cắm $device vào $_temp0';
  }

  @override
  String get plugInBody => 'Bạn còn có thể nhấp và gõ trên đó.';

  @override
  String get buttonRotate => 'Xoay';

  @override
  String get buttonKeyboard => 'Bàn phím';

  @override
  String get buttonScreenshot => 'Chụp màn hình';

  @override
  String screenshotSaved(String folder) {
    return 'Đã lưu vào $folder';
  }

  @override
  String get screenshotFailed => 'Không lưu được ảnh chụp màn hình.';

  @override
  String get showInFinder => 'Hiển thị trong Finder';

  @override
  String get showInFolder => 'Hiển thị trong thư mục';

  @override
  String get buttonNotifications => 'Bảng thông báo';

  @override
  String get buttonVolumeUp => 'Tăng âm lượng';

  @override
  String get buttonVolumeDown => 'Giảm âm lượng';

  @override
  String get buttonPower => 'Nguồn';

  @override
  String get more => 'Thêm';

  @override
  String tooltipWithKey(String name, String key) {
    return '$name ($key)';
  }

  @override
  String get keyRightClick => 'nhấp chuột phải';

  @override
  String get keyMiddleClick => 'nhấp chuột giữa';

  @override
  String get viewOnly => 'Chỉ xem';

  @override
  String viewOnlyBody(String device) {
    return '$device chỉ chia sẻ hình ảnh, không chia sẻ quyền điều khiển. Để nhấp và gõ, hãy cắm cáp.';
  }

  @override
  String get viewOnlyAirplayBody =>
      'iPhone hoặc iPad chỉ chia sẻ hình ảnh, không chia sẻ quyền điều khiển.';

  @override
  String get controlWithCable => 'Điều khiển bằng cáp';

  @override
  String get viewOnlyToast => 'Chỉ xem.';

  @override
  String get keepToolbar => 'Luôn hiện thanh công cụ';

  @override
  String get soundTitle => 'Âm thanh';

  @override
  String get soundDetailHere => 'Tại đây';

  @override
  String get soundDetailThere => 'Trên điện thoại';

  @override
  String get soundDetailNone => 'Không';

  @override
  String soundHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $_temp0';
  }

  @override
  String soundThere(String device) {
    return 'Trên $device';
  }

  @override
  String get soundVolume => 'Âm lượng';

  @override
  String soundMovesNote(String device) {
    return '$device sẽ im lặng khi âm thanh của nó phát ở đây. Đổi cài đặt này sẽ khởi động lại hình ảnh.';
  }

  @override
  String soundCopiesNote(String device) {
    return '$device vẫn tiếp tục phát: hãy giảm âm lượng trên đó để chỉ nghe ở đây. Các ứng dụng chặn ghi lại, như một số ứng dụng video, sẽ im lặng.';
  }

  @override
  String soundNextTime(String device) {
    return '$device cần đồng ý lại, nên âm thanh sẽ bắt đầu từ lần sau.';
  }

  @override
  String soundNotAllowed(String device) {
    return '$device chưa gửi âm thanh. Trên điện thoại, mở Ferret, rồi Cài đặt → Màn hình, và bật Gửi cả âm thanh.';
  }

  @override
  String soundUnsupportedCable(String device) {
    return '$device không gửi được âm thanh. Việc này cần Android 11 trở lên và màn hình đã mở khóa khi bắt đầu hiển thị.';
  }

  @override
  String soundUnsupportedWifi(String device) {
    return '$device không gửi được âm thanh. Việc này cần Android 10 trở lên và Ferret phiên bản mới nhất trên đó.';
  }

  @override
  String soundFailed(String device) {
    return '$device không ghi lại được âm thanh. Hãy dừng, rồi hiển thị màn hình lại.';
  }

  @override
  String get soundNoOutput =>
      'Máy tính này không phát được âm thanh. Hãy kiểm tra đầu ra âm thanh.';

  @override
  String get soundAirplay =>
      'Âm thanh qua AirPlay chưa có. Âm thanh vẫn phát trên iPhone.';

  @override
  String get soundWaiting => 'Đang chờ âm thanh…';

  @override
  String get qualityGood => 'Tốt';

  @override
  String get qualitySlow => 'Chậm';

  @override
  String get qualityPoor => 'Kém';

  @override
  String get pictureTitle => 'Hình ảnh';

  @override
  String pictureTooltip(String quality) {
    return 'Hình ảnh: $quality';
  }

  @override
  String get presetAuto => 'Tự động';

  @override
  String get presetAutoBody => 'Ferret tự điều chỉnh';

  @override
  String get presetSharp => 'Sắc nét';

  @override
  String get presetSharpBody => 'Kích thước đầy đủ';

  @override
  String get presetFast => 'Nhanh';

  @override
  String get presetFastBody => 'Nhỏ hơn, mượt';

  @override
  String get presetRestarts => 'Thay đổi sẽ khởi động lại hình ảnh.';

  @override
  String presetNextTime(String device) {
    return '$device phải đồng ý lại khi thay đổi, nên sẽ áp dụng từ lần sau.';
  }

  @override
  String get presetAirplay => 'iPhone tự chọn chất lượng.';

  @override
  String basicPicture(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Hiện tại $_temp0 chỉ có hình ảnh cơ bản (khoảng 10 khung mỗi giây).';
  }

  @override
  String get details => 'Chi tiết';

  @override
  String get wayWifi => 'Wi-Fi';

  @override
  String get wayCable => 'Cáp';

  @override
  String get wayAirplay => 'AirPlay';

  @override
  String get noticeViaCable => 'Đang chuyển sang hiện qua cáp.';

  @override
  String noticeCableNoAsk(String device) {
    return 'Khi dùng cáp, $device không hỏi mỗi lần. Chỉ làm vậy với điện thoại của chính bạn.';
  }

  @override
  String noticeSlow(String device) {
    return 'Kết nối với $device đang chậm.';
  }

  @override
  String noticeSlowHelp(String device) {
    return 'Kết nối với $device đang chậm. Lại gần Wi-Fi hơn hoặc cắm cáp.';
  }

  @override
  String get useFast => 'Dùng Nhanh';

  @override
  String get textFieldHint => 'Gõ hoặc dán rồi nhấn Enter';

  @override
  String get send => 'Gửi';

  @override
  String replaceTitle(String current, String next) {
    return 'Dừng xem $current và xem $next?';
  }

  @override
  String replaceConfirm(String device) {
    return 'Xem $device';
  }

  @override
  String leaveTitle(String device) {
    return 'Dừng xem $device?';
  }

  @override
  String get leaveBody => 'Rời trang này sẽ dừng chia sẻ trên cả hai thiết bị.';

  @override
  String get keepShowing => 'Xem tiếp';

  @override
  String setupTitle(String device) {
    return 'Xem $device bằng cáp';
  }

  @override
  String get setupSubtitle => 'Không cần cài ứng dụng trên điện thoại.';

  @override
  String stepPlug(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cắm điện thoại vào $_temp0';
  }

  @override
  String get stepDebugging => 'Bật Gỡ lỗi qua USB';

  @override
  String get stepDebuggingOn => 'Trên điện thoại:';

  @override
  String get stepDebugging1 => 'Cài đặt → Giới thiệu về điện thoại';

  @override
  String get stepDebugging2 => 'Nhấn Số bản dựng 7 lần';

  @override
  String get stepDebugging3 =>
      'Cài đặt → Hệ thống → Tùy chọn cho nhà phát triển → Gỡ lỗi qua USB';

  @override
  String get brandsToggle => 'Samsung, Xiaomi, hãng khác';

  @override
  String get brandsBody =>
      'Samsung: Số bản dựng nằm trong Thông tin điện thoại → Thông tin phần mềm.\nXiaomi: nhấn vào Phiên bản OS thay cho Số bản dựng, và bật thêm Gỡ lỗi USB (Cài đặt bảo mật), nếu không sẽ không nhấp được.\nĐiện thoại khác: tìm Số bản dựng trong Cài đặt.';

  @override
  String get stepAllow => 'Nhấn Cho phép trên điện thoại';

  @override
  String stepAllowNamed(String device) {
    return 'Trên $device: nhấn Cho phép. Đánh dấu Luôn cho phép từ máy tính này.';
  }

  @override
  String get setupWaiting => 'Đang chờ điện thoại…';

  @override
  String get setupCables => 'Nhiều loại cáp chỉ sạc được. Hãy thử cáp khác.';

  @override
  String setupPrivacy(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Sau khi cho phép, $_temp0 có thể xem và điều khiển điện thoại mà không cần hỏi. Chỉ làm vậy với điện thoại của chính bạn.';
  }

  @override
  String get setupUnsupported =>
      'Máy tính này không thể xem điện thoại qua cáp.';

  @override
  String airplayOn(String device) {
    return 'Trên $device:';
  }

  @override
  String get airplayStep1 =>
      'Mở Trung tâm điều khiển (vuốt xuống từ góc trên bên phải)';

  @override
  String get airplayStep2 => 'Nhấn Phản chiếu màn hình';

  @override
  String airplayStep3(String computer) {
    return 'Chọn “$computer”';
  }

  @override
  String airplayListeningLeft(String time) {
    return 'Đang chờ… $time';
  }

  @override
  String setupStepNumbered(int number, String step) {
    return '$number. $step';
  }

  @override
  String get airplayNote =>
      'Chỉ xem. Không có âm thanh. Thử nghiệm: một bản cập nhật iOS có thể làm hỏng tính năng này.';

  @override
  String get airplayMacTitle => 'Mac đã có sẵn tính năng này';

  @override
  String airplayMacBody(String device) {
    return 'Trên $device, chọn Mac này trong Phản chiếu màn hình, hoặc dùng Phản chiếu iPhone.';
  }

  @override
  String get useFerretAnyway => 'Vẫn dùng Ferret';

  @override
  String airplayConnecting(String device) {
    return '$device đang kết nối';
  }

  @override
  String get airplayConnectingBody =>
      'Đây là tên mà thiết bị tự đặt. Chỉ đồng ý nếu đó là thiết bị của bạn.';

  @override
  String airplayTimedOutTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Không ai chọn $_temp0';
  }

  @override
  String get airplayTimedOutBody => 'Ferret đã chờ hai phút rồi dừng.';

  @override
  String get listenAgain => 'Chờ lại';

  @override
  String viewingDetail(String time, String way) {
    return 'Từ $time · $way';
  }

  @override
  String viewingAsking(String device) {
    return 'Đang hỏi $device…';
  }

  @override
  String get lookForCableTitle => 'Tìm điện thoại cắm cáp';

  @override
  String get lookForCableBody =>
      'Hiện mọi điện thoại Android đang cắm cáp và đã bật Gỡ lỗi qua USB.';

  @override
  String get summaryCable => 'Tìm thiết bị cắm cáp';

  @override
  String sharingReconnecting(String device) {
    return '$device bị ngắt. Đang chờ một lát để nó kết nối lại.';
  }

  @override
  String get endStoppedHereTitle => 'Đã dừng';

  @override
  String endStoppedHereBody(String device) {
    return '$device không còn chia sẻ màn hình.';
  }

  @override
  String get allowNoticeBody => 'Chỉ đồng ý nếu đó là thiết bị của bạn.';

  @override
  String get controlAsk => 'Điều khiển';

  @override
  String get controlAsking => 'Đang hỏi…';

  @override
  String noticeControlAsking(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $device, chạm Một lần hoặc Luôn luôn để $_temp0 có thể nhấp và gõ ở đó.';
  }

  @override
  String noticeControlAllowed(String device) {
    return 'Bây giờ bạn có thể nhấp và gõ trên $device.';
  }

  @override
  String noticeControlDenied(String device) {
    return '$device đã từ chối điều khiển. Bạn vẫn có thể xem.';
  }

  @override
  String noticeControlTimedOut(String device) {
    return 'Không ai trả lời trên $device. Nhấp Điều khiển để hỏi lại.';
  }

  @override
  String noticeControlStopped(String device) {
    return '$device đã dừng điều khiển. Bạn vẫn có thể xem.';
  }

  @override
  String viewOnlySetupBody(String device) {
    return 'Để nhấp và gõ qua Wi-Fi, hãy bật Điều khiển Ferret trên $device: mở Ferret ở đó, rồi Cài đặt → Đến máy tính của bạn.';
  }

  @override
  String controlAskTitle(String computer, String phone) {
    return 'Cho $computer điều khiển $phone khi đang hiển thị màn hình?';
  }

  @override
  String controlAskCardTitle(String computer, String phone) {
    return 'Cho $computer điều khiển $phone?';
  }

  @override
  String controlAskBody(String computer) {
    return 'Khi đang hiển thị màn hình này, $computer có thể chạm, vuốt và gõ ở đây, cho đến khi bạn dừng lại.';
  }

  @override
  String get controlAlways => 'Luôn luôn';

  @override
  String get controlOnce => 'Một lần';

  @override
  String get controlNo => 'Không';

  @override
  String controlledTitle(String computer) {
    return 'Đang được điều khiển bởi $computer';
  }

  @override
  String get controlledBody =>
      'Máy tính đó có thể chạm và gõ ở đây khi đang hiển thị màn hình này.';

  @override
  String get controlStop => 'Dừng điều khiển';

  @override
  String get controlStopSharing => 'Dừng chia sẻ màn hình';

  @override
  String get noticeControlChannel => 'Điều khiển từ máy tính';

  @override
  String get settingsControlTitle => 'Điều khiển từ máy tính';

  @override
  String get settingsControlPowerUps =>
      'Máy tính đang hiển thị màn hình này có thể chạm và gõ ở đây, thông qua Tăng cường. Nó sẽ hỏi bạn trước.';

  @override
  String get settingsControlService =>
      'Điều khiển Ferret đang bật. Máy tính đang hiển thị màn hình này có thể chạm và gõ ở đây sau khi hỏi bạn.';

  @override
  String get settingsControlOff =>
      'Để máy tính đang hiển thị màn hình này chạm và gõ ở đây, hãy bật Điều khiển Ferret trong phần cài đặt Hỗ trợ tiếp cận của Android.';

  @override
  String get settingsControlTurnOn => 'Bật Điều khiển Ferret…';

  @override
  String get settingsControlOpen => 'Cài đặt Hỗ trợ tiếp cận';

  @override
  String settingsControlAlwaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count máy tính điều khiển điện thoại này mà không cần hỏi.',
    );
    return '$_temp0';
  }

  @override
  String get settingsControlAskAgain => 'Hỏi mỗi lần';

  @override
  String get controlDisclosureTitle => 'Bật Điều khiển Ferret?';

  @override
  String get controlDisclosureBody =>
      'Điều khiển Ferret là một dịch vụ hỗ trợ tiếp cận của Android. Khi bật, máy tính bạn đã ghép đôi có thể chạm, vuốt, nhấn Quay lại và Màn hình chính, và gõ trên điện thoại này.\n\nNó chỉ hoạt động khi bạn đang hiển thị màn hình này cho máy tính đó và đã đồng ý cho điều khiển. Một thông báo luôn hiện suốt thời gian đó, kèm nút Dừng.\n\nĐể gõ, nó đọc ô văn bản bạn đang gõ vào. Nó không đọc gì khác, không lưu gì, và không gửi gì đi đâu.';

  @override
  String get controlDisclosureSteps =>
      'Tiếp theo, trong Hỗ trợ tiếp cận, chạm Điều khiển Ferret và bật nó lên.';

  @override
  String get controlDisclosureOpen => 'Mở cài đặt';

  @override
  String get notNow => 'Để sau';

  @override
  String useCamera(String device) {
    return 'Dùng camera của $device';
  }

  @override
  String cameraWindowTitle(String device) {
    return '$device — Camera';
  }

  @override
  String get cameraSavePicture => 'Lưu ảnh';

  @override
  String get cameraSwitch => 'Đổi camera';

  @override
  String get cameraUseAgain => 'Dùng lại';

  @override
  String get cameraPictureNote =>
      '720p, 30 khung hình mỗi giây, như một webcam.';

  @override
  String cameraWaitingBody(String device) {
    return 'Trên $device, nhấn Một lần hoặc Luôn luôn để bật camera.';
  }

  @override
  String cameraWaitingNothing(String device) {
    return 'Không thấy gì trên $device? Mở Ferret trên đó.';
  }

  @override
  String cameraDeniedBody(String device) {
    return 'Có người đã nhấn Không trên $device.';
  }

  @override
  String cameraBusyTitle(String device) {
    return '$device đang bận';
  }

  @override
  String get cameraBusyBody =>
      'Màn hình hoặc camera của nó đang bật cho một thiết bị. Hãy dừng thiết bị đó trước.';

  @override
  String cameraUnsupportedTitle(String device) {
    return '$device không thể chia sẻ camera';
  }

  @override
  String get cameraUnsupportedBody =>
      'Dùng camera của điện thoại cần một điện thoại Android có Ferret mới nhất.';

  @override
  String cameraTurnedOffTitle(String device) {
    return 'Camera đang tắt trên $device';
  }

  @override
  String cameraTurnedOffBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $device: mở Ferret → Cài đặt → Đến máy tính của bạn và bật “Cho máy tính của tôi hỏi dùng camera này”. Sau đó mở $_temp0 ở đó và kiểm tra xem nó có được phép hỏi không.';
  }

  @override
  String cameraCannotStartTitle(String device) {
    return '$device không bật được camera';
  }

  @override
  String cameraCannotStartBody(String device) {
    return 'Trên $device: mở Ferret và cho phép dùng camera. Sau đó hỏi lại.';
  }

  @override
  String cameraStoppedHereBody(String device) {
    return 'Camera của $device đã tắt.';
  }

  @override
  String cameraSystemEndedTitle(String device) {
    return '$device đã tắt camera';
  }

  @override
  String cameraSystemEndedBody(String device) {
    return 'Android đã đóng camera, hoặc một ứng dụng khác đang dùng nó. Hãy dùng lại khi $device sẵn sàng.';
  }

  @override
  String cameraFailedBody(String device) {
    return '$device không khởi động được camera.';
  }

  @override
  String cameraViewingTitle(String device) {
    return 'Đang dùng camera của $device';
  }

  @override
  String cameraAuditViewed(String device, String duration, String time) {
    return 'Bạn đã dùng camera của $device trong $duration lúc $time';
  }

  @override
  String cameraAuditShared(String device, String duration, String time) {
    return '$device đã dùng camera của điện thoại này trong $duration lúc $time';
  }

  @override
  String cameraLeaveTitle(String device) {
    return 'Dừng dùng camera của $device?';
  }

  @override
  String get cameraLeaveBody => 'Rời trang này sẽ tắt camera.';

  @override
  String get cameraKeep => 'Cứ để bật';

  @override
  String cameraAskTitle(String computer) {
    return '$computer muốn dùng camera của bạn';
  }

  @override
  String get cameraAskBody =>
      'Nó sẽ thấy qua camera và nghe qua micro, cho đến khi bạn dừng lại.';

  @override
  String cameraOnTitle(String computer) {
    return 'Camera đang bật cho $computer';
  }

  @override
  String cameraOnBody(String time) {
    return 'Nó đang thấy và nghe qua điện thoại này. Từ $time.';
  }

  @override
  String cameraOnBodySilent(String time) {
    return 'Nó đang thấy qua camera của điện thoại này. Micro đang tắt. Từ $time.';
  }

  @override
  String get noticeCameraBody => 'Nó đang thấy và nghe qua điện thoại này';

  @override
  String get noticeCameraBodySilent =>
      'Nó đang thấy qua camera của điện thoại này';

  @override
  String get noticeCameraChannel => 'Camera cho máy tính';

  @override
  String get settingsCameraTitle => 'Camera cho máy tính';

  @override
  String get settingsCameraAllow => 'Cho máy tính của tôi hỏi dùng camera này';

  @override
  String get settingsCameraAllowBody =>
      'Bạn trả lời Một lần, Luôn luôn hoặc Không. Một thông báo có nút Dừng luôn hiện khi camera đang bật.';

  @override
  String settingsCameraAlwaysCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count máy tính dùng camera này mà không cần hỏi.',
    );
    return '$_temp0';
  }

  @override
  String get permissionCameraAsk => 'Hỏi dùng camera của điện thoại này';

  @override
  String get permissionCameraAskOff =>
      'Camera đang tắt với mọi máy tính. Bật trong Cài đặt → Đến máy tính của bạn.';

  @override
  String get cameraTitle => 'Camera';
}
