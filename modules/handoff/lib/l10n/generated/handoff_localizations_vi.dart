// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'handoff_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class HandoffLocalizationsVi extends HandoffLocalizations {
  HandoffLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Tiếp tục';

  @override
  String get cardTitle => 'Tiếp tục';

  @override
  String continueFrom(String title, String device) {
    return 'Tiếp tục “$title” từ $device';
  }

  @override
  String get open => 'Mở';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String get cancel => 'Huỷ';

  @override
  String get openFailed =>
      'Thiết bị này không mở được mục đó. Có thể cần một ứng dụng chưa cài ở đây.';

  @override
  String get openDeferred => 'Mở Ferret để tiếp tục.';

  @override
  String get actionSendLink => 'Gửi liên kết…';

  @override
  String get actionSendCurrentPage => 'Gửi trang hiện tại';

  @override
  String sendLinkTitle(String device) {
    return 'Gửi đến $device';
  }

  @override
  String get sendLinkLabel => 'Liên kết hoặc văn bản';

  @override
  String get sendLinkHint => 'https://…';

  @override
  String get send => 'Gửi';

  @override
  String get sendEmpty => 'Không có gì để gửi. Hãy dán liên kết hoặc văn bản.';

  @override
  String sendOpened(String device) {
    return 'Đã mở trên $device';
  }

  @override
  String sendSuggested(String device) {
    return 'Trên $device: chạm vào thông báo để mở.';
  }

  @override
  String sendFailed(String device) {
    return '$device không mở được. Có thể cần một ứng dụng chưa cài trên đó.';
  }

  @override
  String sendUnreachable(String device) {
    return 'Không kết nối được với $device. Kiểm tra xem thiết bị đã bật và cùng mạng Wi-Fi chưa.';
  }

  @override
  String get currentPageNone =>
      'Không tìm thấy trang nào trong trình duyệt. Mở một trang trong Safari hoặc trình duyệt Chromium, rồi thử lại.';

  @override
  String get currentPageDenied =>
      'macOS đã chặn Ferret đọc trình duyệt. Hãy cho phép trong Cài đặt hệ thống, Quyền riêng tư & Bảo mật, Tự động hoá.';

  @override
  String get currentPageFailed =>
      'Không đọc được trang trong trình duyệt. Thử lại, hoặc gửi liên kết bằng “Gửi liên kết…”.';

  @override
  String get settingsPassive => 'Gợi ý việc tôi đang làm';

  @override
  String get settingsPassiveBody =>
      'Các thiết bị khác của bạn lặng lẽ gợi ý tiếp tục trang bạn đang xem. Gợi ý tự biến mất sau 5 phút.';

  @override
  String get settingsOpenAutomatically => 'Mở ngay liên kết được gửi đến';

  @override
  String get settingsOpenAutomaticallyBody =>
      'Khi tắt, những gì gửi đến đây sẽ chờ trong thông báo cho đến khi bạn mở.';

  @override
  String get settingsBrowserTab => 'Đọc trang hiện tại trong trình duyệt';

  @override
  String get settingsBrowserTabBody =>
      'Thêm “Gửi trang hiện tại”, và gợi ý trang bạn vừa rời đi. macOS hỏi một lần cho mỗi trình duyệt.';

  @override
  String get settingsAssistantTitle => 'Tiếp tục từ mọi ứng dụng';

  @override
  String get settingsAssistantBody =>
      'Đặt Ferret làm trợ lý kỹ thuật số, rồi nhấn giữ nút Home (hoặc vuốt lên từ góc dưới) ở bất kỳ màn hình nào để gửi sang thiết bị khác. Bật “Sử dụng văn bản từ màn hình” trong cùng trang cài đặt đó.';

  @override
  String get settingsAssistantOn => 'Ferret đang là trợ lý của bạn';

  @override
  String get settingsAssistantOff => 'Ferret chưa là trợ lý của bạn';

  @override
  String get settingsAssistantOpen => 'Mở cài đặt trợ lý';

  @override
  String get settingsShareHint =>
      'Bạn cũng có thể chia sẻ bất kỳ liên kết nào đến “Gửi bằng Ferret” rồi chọn “Mở trên…”.';

  @override
  String get summaryPassive => 'Gợi ý trang bạn đang xem';

  @override
  String get summarySendsOnly => 'Chỉ những gì bạn gửi';

  @override
  String get summaryBrowserOff => 'Tắt';

  @override
  String get summaryNoBrowser => 'Chưa có trình duyệt';

  @override
  String healthUnsupported(String name) {
    return 'Cần cập nhật Ferret trên $name';
  }

  @override
  String healthOpensRightAway(String name) {
    return 'Liên kết từ $name được mở ngay';
  }

  @override
  String healthWaits(String name) {
    return 'Liên kết từ $name chờ trong thông báo';
  }

  @override
  String healthLastSendFailed(String name) {
    return '$name chưa nhận được liên kết bạn gửi gần nhất';
  }

  @override
  String healthLastSendFailedHelp(String name) {
    return 'Trên $name: mở Ferret, rồi gửi lại liên kết.';
  }

  @override
  String noticeTitle(String title) {
    return 'Tiếp tục “$title”';
  }

  @override
  String noticeFrom(String device) {
    return 'Từ $device';
  }

  @override
  String noticeTextCopied(String device) {
    return 'Đã sao chép văn bản từ $device';
  }

  @override
  String noticeSent(String device) {
    return 'Đã gửi đến $device';
  }

  @override
  String noticeNotSent(String device) {
    return 'Không gửi được đến $device';
  }

  @override
  String get noticeNotSentBody =>
      'Kiểm tra xem thiết bị đã bật và cùng mạng Wi-Fi chưa, rồi chia sẻ lại.';

  @override
  String get noticeNothingToSend =>
      'Nội dung bạn chia sẻ không có gì để tiếp tục.';

  @override
  String get pickDeviceTitle => 'Tiếp tục trên';

  @override
  String get pickDeviceEmpty =>
      'Hiện chưa có thiết bị nào kết nối. Mở Ferret trên thiết bị kia, cùng mạng Wi-Fi.';

  @override
  String get back => 'Quay lại';

  @override
  String browserPairTitle(String browser) {
    return 'Cho phép $browser dùng Ferret?';
  }

  @override
  String browserPairBody(String code) {
    return 'Kiểm tra xem trình duyệt có hiển thị mã $code không. Sau đó trình duyệt có thể gửi thẻ đến thiết bị của bạn và mở các trang chúng gửi đến đây.';
  }

  @override
  String get browserPairAllow => 'Cho phép';

  @override
  String get browserPairDeny => 'Không cho phép';

  @override
  String noticeBrowserPairBody(String code) {
    return 'Mã $code. Mở Ferret để cho phép.';
  }

  @override
  String get settingsBrowserBridge => 'Tiện ích trình duyệt';

  @override
  String settingsBrowserBridgeBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho tiện ích Ferret trong Chrome, Edge, Brave hoặc Firefox gửi thẻ và mở trang từ thiết bị của bạn. Tiện ích chỉ kết nối trong $_temp0.';
  }

  @override
  String get browserBridgeListening =>
      'Để thêm trình duyệt khác, hãy ghép đôi từ trang cài đặt của tiện ích.';

  @override
  String get browserBridgeFailed =>
      'Ferret không khởi động được kết nối với trình duyệt. Có thể một bản Ferret khác đang chạy: thoát bản đó, rồi thử lại.';

  @override
  String get browserBridgeRetry => 'Thử lại';

  @override
  String get browserClientsEmpty =>
      'Chưa có trình duyệt. Cài tiện ích, mở phần cài đặt của tiện ích và chọn “Pair with Ferret”.';

  @override
  String get browserClientConnected => 'Đã kết nối';

  @override
  String get browserClientOffline => 'Chưa kết nối';

  @override
  String get browserClientRemove => 'Gỡ';

  @override
  String continueUntitledFrom(String device) {
    return 'Tiếp tục từ $device';
  }

  @override
  String get settingsHistory => 'Lịch sử';

  @override
  String get settingsHistoryBody =>
      'Những gì bạn đã tiếp tục giữa các thiết bị, lưu trên thiết bị này tối đa 30 ngày.';

  @override
  String get settingsHistoryClear => 'Xoá';
}
