// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'power_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class PowerLocalizationsVi extends PowerLocalizations {
  PowerLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Tăng cường';

  @override
  String get back => 'Quay lại';

  @override
  String get settingsUnsupported =>
      'Tăng cường là các khả năng bổ sung cho điện thoại Android. Ở đây không có gì cần thiết lập.';

  @override
  String get settingsSummaryStandard =>
      'Ferret chạy như một ứng dụng thông thường. Với Shizuku hoặc root, Ferret còn có thể gửi bảng nhớ tạm trong nền.';

  @override
  String get settingsSummaryShizuku =>
      'Shizuku đang bật. Ferret có thể gửi bảng nhớ tạm trong nền.';

  @override
  String get settingsSummaryRoot =>
      'Root đang bật. Ferret có thể gửi bảng nhớ tạm trong nền, cả sau khi khởi động lại.';

  @override
  String get settingsOpen => 'Mở Tăng cường';

  @override
  String get settingsShortStandard => 'Tắt';

  @override
  String get settingsShortShizuku => 'Shizuku đang bật';

  @override
  String get settingsShortRoot => 'Root đang bật';

  @override
  String get ladderTitle => 'Những gì điện thoại này cho phép Ferret làm';

  @override
  String get rungBasic => 'Cơ bản';

  @override
  String get rungNotifications => '+ Thông báo';

  @override
  String get rungMessagesAndCalls => '+ Tin nhắn và cuộc gọi';

  @override
  String get rungShizuku => '+ Shizuku';

  @override
  String get rungRoot => '+ Root';

  @override
  String get rungOn => 'Đang bật';

  @override
  String get rungOff => 'Chưa bật';

  @override
  String get perkFiles => 'Gửi và nhận tệp';

  @override
  String get perkClipboardTap => 'Gửi bảng nhớ tạm chỉ với một lần nhấn';

  @override
  String get perkHandoff => 'Tiếp tục một trang trên thiết bị khác';

  @override
  String get perkMedia => 'Điều khiển nội dung đang phát';

  @override
  String get perkFind => 'Đổ chuông thiết bị bị thất lạc';

  @override
  String get perkNotifications =>
      'Xem thông báo của điện thoại này trên các thiết bị khác của bạn';

  @override
  String get perkReplies => 'Trả lời và bỏ qua thông báo ngay từ đó';

  @override
  String get perkMessages => 'Đọc và trả lời tin nhắn từ máy tính';

  @override
  String get perkCalls => 'Xem ai đang gọi, rồi trả lời hoặc từ chối';

  @override
  String get perkClipboardBackground =>
      'Tự gửi những gì bạn sao chép, cả khi chạy trong nền';

  @override
  String get perkOneTapSetup =>
      'Bật quyền truy cập thông báo và chạy trong nền chỉ với một lần nhấn';

  @override
  String get perkSameAsShizuku => 'Mọi thứ Shizuku mang lại';

  @override
  String get perkSurvivesRestart =>
      'Vẫn hoạt động sau khi điện thoại khởi động lại';

  @override
  String get notificationsOpenSettings => 'Mở quyền truy cập thông báo';

  @override
  String get notificationsTurnOnNow => 'Bật ngay';

  @override
  String get notificationsRestricted =>
      'Nếu Android báo cài đặt bị hạn chế, hãy mở Thông tin ứng dụng, nhấn dấu ba chấm và chọn Cho phép chế độ cài đặt bị hạn chế. Sau đó thử lại.';

  @override
  String get appInfo => 'Thông tin ứng dụng';

  @override
  String get messagesHint =>
      'Ferret sẽ xin các quyền này khi bạn bật Tin nhắn hoặc Cuộc gọi. Lỡ từ chối? Hãy đổi lại trong Thông tin ứng dụng.';

  @override
  String get shizukuTitle => 'Thiết lập Shizuku';

  @override
  String get shizukuIntro =>
      'Shizuku là một ứng dụng miễn phí, mã nguồn mở. Nó cho phép Ferret làm vài việc Android chỉ dành cho hệ thống mà không cần root điện thoại.';

  @override
  String get stepInstallTitle => '1. Cài đặt Shizuku';

  @override
  String get stepInstallBody =>
      'Tải từ trang web của Shizuku. Ứng dụng cũng có trên F-Droid.';

  @override
  String get stepInstallButton => 'Tải Shizuku';

  @override
  String get stepStartTitle => '2. Khởi động Shizuku';

  @override
  String get stepStartBody =>
      'Mở Shizuku và làm theo các bước Khởi động của ứng dụng, rồi quay lại đây. Ferret sẽ kiểm tra lại khi bạn quay lại.';

  @override
  String get stepStartButton => 'Mở Shizuku';

  @override
  String get stepAllowTitle => '3. Cho phép Ferret';

  @override
  String get stepAllowBody =>
      'Shizuku sẽ hỏi có cho Ferret sử dụng không. Hãy chọn Luôn cho phép.';

  @override
  String get stepAllowButton => 'Cho phép Ferret';

  @override
  String get shizukuOn => 'Shizuku đang bật.';

  @override
  String get shizukuOnBody =>
      'Tiếp theo: bật Tự động gửi trong nền trong Cài đặt → Bảng nhớ tạm. Shizuku sẽ dừng khi điện thoại khởi động lại; hãy khởi động lại nó từ ứng dụng Shizuku.';

  @override
  String get stopUsingShizuku => 'Ngừng dùng Shizuku';

  @override
  String get noticeShizukuRefused =>
      'Shizuku đã từ chối. Mở Shizuku, cho phép Ferret trong danh sách ứng dụng, rồi thử lại.';

  @override
  String get noticeShizukuNotOpened =>
      'Không mở được Shizuku. Hãy kiểm tra xem ứng dụng đã được cài chưa.';

  @override
  String get noticeLinkFailed =>
      'Không mở được trình duyệt. Hãy tìm Shizuku trên F-Droid hoặc GitHub.';

  @override
  String get noticeGrantFailed =>
      'Android không nhận thay đổi này. Hãy thử lại, hoặc bật trong Cài đặt của điện thoại này.';

  @override
  String get noticeRootRefused =>
      'Quyền root đã bị từ chối. Hãy cho phép Ferret trong trình quản lý root, rồi thử lại.';

  @override
  String get noticeSettingsNotOpened =>
      'Không mở được Cài đặt của điện thoại này. Hãy mở Cài đặt, chọn Ứng dụng, rồi chọn Ferret.';

  @override
  String get batteryTitle => 'Giữ Ferret chạy trong nền';

  @override
  String get batteryBody =>
      'Ngăn Android cho Ferret ngủ, để các thiết bị của bạn luôn kết nối.';

  @override
  String get batteryOn => 'Ferret được phép chạy trong nền.';

  @override
  String get turnOn => 'Bật';

  @override
  String get rootTitle => 'Root';

  @override
  String get rootNotFound =>
      'Điện thoại này chưa root, và cũng không cần: Shizuku mang lại các tính năng tương tự.';

  @override
  String get rootFound => 'Đã tìm thấy root trên điện thoại này.';

  @override
  String rootFoundWith(String manager) {
    return 'Đã tìm thấy root trên điện thoại này ($manager).';
  }

  @override
  String get rootWarning =>
      'Root cho ứng dụng toàn quyền kiểm soát điện thoại của bạn. Chỉ bật khi bạn tự root điện thoại. Ferret chỉ dùng root cho những việc liệt kê ở trên, không gì khác, và chỉ khi mục này đang bật.';

  @override
  String get useRoot => 'Dùng root';

  @override
  String get rootPromptHint => 'Trình quản lý root sẽ yêu cầu bạn xác nhận.';

  @override
  String get rootOn => 'Root đang bật.';

  @override
  String get stopUsingRoot => 'Ngừng dùng root';

  @override
  String get cardStartShizuku =>
      'Khởi động Shizuku và Ferret sẽ tự gửi những gì bạn sao chép.';

  @override
  String get cardAllowShizuku =>
      'Cho phép Shizuku và Ferret sẽ tự gửi những gì bạn sao chép.';

  @override
  String get cardShizukuStopped =>
      'Shizuku đã dừng nên việc gửi bảng nhớ tạm trong nền đang tạm dừng. Shizuku dừng mỗi khi điện thoại khởi động lại. Hãy khởi động lại nó.';

  @override
  String get cardShizukuRevoked =>
      'Shizuku không còn cho phép Ferret nên việc gửi bảng nhớ tạm trong nền đang tạm dừng.';

  @override
  String get cardUseRoot =>
      'Dùng root và Ferret sẽ tự gửi những gì bạn sao chép.';

  @override
  String get cardRootLost =>
      'Quyền root đã bị thu hồi nên việc gửi bảng nhớ tạm trong nền đang tạm dừng.';

  @override
  String get cardSetUp => 'Mở Tăng cường';

  @override
  String get cardAskAgain => 'Hỏi lại';
}
