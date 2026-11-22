// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'clipboard_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ClipboardLocalizationsVi extends ClipboardLocalizations {
  ClipboardLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Bảng nhớ tạm';

  @override
  String sentTo(String devices) {
    return 'Đã gửi đến $devices';
  }

  @override
  String get sentNowhere => 'Đã sao chép tại đây, chưa có thiết bị nào kết nối';

  @override
  String get sentWaiting => 'Đang chờ thiết bị kết nối';

  @override
  String sentWhenBack(String devices) {
    return 'Đã gửi đến $devices khi kết nối lại';
  }

  @override
  String get skippedSensitive => 'Không đồng bộ: được đánh dấu là riêng tư';

  @override
  String get skippedImagesOff => 'Không đồng bộ: hình ảnh đang tắt';

  @override
  String get skippedTooLarge => 'Không đồng bộ: quá lớn';

  @override
  String writeFailed(String device) {
    return 'Từ $device, chưa có trên bảng nhớ tạm này. Nhấn Sao chép.';
  }

  @override
  String activityCopiedOn(String device) {
    return 'Đã sao chép trên $device';
  }

  @override
  String get activityNotSent => 'Chưa gửi bảng nhớ tạm';

  @override
  String activityQuote(String text) {
    return '“$text”';
  }

  @override
  String get imageLabel => 'Hình ảnh';

  @override
  String get privateCleared => 'Mục riêng tư, đã xóa khỏi bộ nhớ';

  @override
  String get privateHidden => 'Mục riêng tư';

  @override
  String get copy => 'Sao chép';

  @override
  String get copied => 'Đã sao chép';

  @override
  String get sendClipboard => 'Gửi bảng nhớ tạm';

  @override
  String get offerBackgroundSend =>
      'Tự gửi những gì bạn sao chép, cả khi chạy trong nền.';

  @override
  String get offerTurnOn => 'Bật';

  @override
  String get offerTile =>
      'Gửi bảng nhớ tạm chỉ với một lần nhấn từ ô Ferret trong Cài đặt nhanh.';

  @override
  String get offerAddTile => 'Thêm ô';

  @override
  String get resultSent => 'Đã gửi.';

  @override
  String get resultNothingToSend =>
      'Bảng nhớ tạm đang trống, hoặc chứa nội dung không phải văn bản hay hình ảnh.';

  @override
  String get resultDuplicate => 'Đã gửi rồi.';

  @override
  String get resultSensitive =>
      'Chưa gửi: ứng dụng bạn sao chép từ đó đã đánh dấu nội dung là riêng tư. Bật Bao gồm mật khẩu trong Cài đặt → Bảng nhớ tạm để gửi các mục này.';

  @override
  String get resultImagesOff =>
      'Chưa gửi: hình ảnh đang tắt. Bật Hình ảnh trong Cài đặt → Bảng nhớ tạm để gửi.';

  @override
  String get resultTooLarge => 'Chưa gửi: vượt quá giới hạn kích thước.';

  @override
  String get resultNoDevices =>
      'Chưa có thiết bị nào kết nối. Mở Ferret trên thiết bị kia, cùng mạng Wi-Fi.';

  @override
  String get resultFailed =>
      'Không kết nối được với thiết bị của bạn. Hãy kiểm tra xem chúng có cùng mạng Wi-Fi không, rồi thử lại.';

  @override
  String get summarySyncs => 'Tự đồng bộ';

  @override
  String get summarySends => 'Tự gửi';

  @override
  String get summaryByHand => 'Gửi thủ công';

  @override
  String get healthSyncs => 'Tự đồng bộ';

  @override
  String get healthByHand => 'Gửi thủ công';

  @override
  String healthOnlyHereSends(String name) {
    return 'Tự gửi. $name gửi thủ công.';
  }

  @override
  String healthOnlyTheySend(String name) {
    return '$name tự gửi. Ở đây bạn gửi thủ công.';
  }

  @override
  String healthUnsupported(String name) {
    return 'Cần cập nhật Ferret trên $name';
  }

  @override
  String get settingsBackgroundSendLost =>
      'Đã ngừng gửi trong nền: Shizuku hoặc root không còn bật. Hãy thiết lập lại trong Cài đặt → Điều khiển.';

  @override
  String get settingsAutoSend => 'Tự động gửi';

  @override
  String get settingsAutoSendBody =>
      'Gửi những gì bạn sao chép tại đây đến các thiết bị đã kết nối.';

  @override
  String settingsAutoSendBodyManual(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'Máy tính bảng này',
        'other': 'Điện thoại này',
      },
    );
    return '$_temp0 chỉ cho phép với nội dung sao chép bên trong Ferret. Dùng Gửi bảng nhớ tạm cho phần còn lại.';
  }

  @override
  String get settingsBackgroundSend => 'Tự động gửi trong nền';

  @override
  String get settingsBackgroundSendBody =>
      'Gửi văn bản bạn sao chép trong bất kỳ ứng dụng nào, cả khi Ferret đã đóng. Dùng tính năng tăng cường của bạn (Shizuku hoặc root). Hình ảnh vẫn cần Gửi bảng nhớ tạm.';

  @override
  String get settingsWhyManual => 'Vì sao cần Gửi bảng nhớ tạm?';

  @override
  String get settingsWhyManualAndroid =>
      'Android không cho ứng dụng đọc bảng nhớ tạm trong nền. Hãy sao chép, rồi nhấn Gửi bảng nhớ tạm trong Ferret, trong thông báo của Ferret hoặc trong ô Cài đặt nhanh.';

  @override
  String get settingsWhyManualIos =>
      'iPhone chỉ cho ứng dụng đọc bảng nhớ tạm khi bạn yêu cầu. Hãy sao chép, rồi nhấn Gửi bảng nhớ tạm.';

  @override
  String get settingsBackgroundSendLocked =>
      'Cần Shizuku hoặc root. Hãy thiết lập một trong hai trong Cài đặt → Điều khiển.';

  @override
  String get settingsAutoReceive => 'Tự động nhận';

  @override
  String get settingsAutoReceiveBody =>
      'Đưa những gì thiết bị của bạn gửi thẳng vào bảng nhớ tạm này. Khi tắt, hãy nhấn Sao chép bên cạnh nội dung vừa đến.';

  @override
  String get settingsImages => 'Hình ảnh';

  @override
  String settingsImagesBody(int megabytes) {
    return 'Đồng bộ hình ảnh đã sao chép, tối đa $megabytes MB.';
  }

  @override
  String get settingsSensitive => 'Bao gồm mật khẩu';

  @override
  String settingsSensitiveBody(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
    );
    return 'Mặc định tắt: mật khẩu đã sao chép sẽ bị bỏ qua. Khi bật, chúng được đồng bộ và bị xóa sau $_temp0.';
  }

  @override
  String settingsHistory(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục trong lịch sử, chỉ lưu trong bộ nhớ.',
      zero: 'Lịch sử đang trống. Lịch sử chỉ nằm trong bộ nhớ, không bao giờ ghi ra đĩa.',
    );
    return '$_temp0';
  }

  @override
  String get settingsClearHistory => 'Xóa lịch sử';

  @override
  String get settingsWhyManualWayland =>
      'Trên Wayland, chỉ cửa sổ đang ở trên cùng mới biết khi có nội dung mới được sao chép. GNOME không có cách nào khác, nên Ferret sẽ gửi nội dung bạn đã sao chép khi cửa sổ của nó ở trên cùng trở lại, hoặc khi bạn chọn Gửi bảng nhớ tạm trên một thiết bị hay trong khay hệ thống. Trên KDE Plasma và Sway, hãy cài wl-clipboard để Ferret tự theo dõi.';

  @override
  String get settingsAutoSendBodyWayland =>
      'Trên môi trường desktop này, nội dung sao chép được gửi đi khi cửa sổ Ferret ở trên cùng. Dùng Gửi bảng nhớ tạm cho phần còn lại.';

  @override
  String get recentClips => 'Mục đã chép gần đây';

  @override
  String get recentClipsMenu => 'Mục đã chép gần đây…';

  @override
  String get recentClipsEmpty =>
      'Chưa sao chép gì. Những gì bạn sao chép ở đây hoặc trên các thiết bị của bạn sẽ hiện ở đây.';

  @override
  String get recentClipsNote =>
      '20 mục gần nhất, chỉ giữ trong bộ nhớ cho đến khi thoát Ferret. Mục riêng tư không bao giờ hiện ở đây.';

  @override
  String recentClipsKeys(String keys) {
    return 'Mở trang này từ bất kỳ ứng dụng nào bằng $keys.';
  }

  @override
  String recentFrom(String device) {
    return 'Từ $device';
  }

  @override
  String get recentCopiedHere => 'Đã sao chép tại đây';

  @override
  String get recentHidden =>
      'Bản xem trước từ thiết bị này bị ẩn ở đây. Vẫn sao chép được.';

  @override
  String get recentClipsDrag =>
      'Kéo một mục vào ứng dụng bất kỳ để thả vào đó.';
}
