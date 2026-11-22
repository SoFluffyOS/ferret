// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'updates_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class UpdatesLocalizationsVi extends UpdatesLocalizations {
  UpdatesLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Cập nhật';

  @override
  String get checkSwitch => 'Kiểm tra cập nhật';

  @override
  String get checkSwitchBody =>
      'Mỗi ngày một lần, Ferret hỏi GitHub phiên bản mới nhất. Nó không gửi gì về bạn hay thiết bị của bạn.';

  @override
  String get betaSwitch => 'Nhận cả bản beta';

  @override
  String get betaSwitchBody =>
      'Dùng thử tính năng mới trước mọi người. Bản beta có thể còn lỗi.';

  @override
  String get checkNow => 'Kiểm tra ngay';

  @override
  String get checkNowTooltip =>
      'Hỏi GitHub phiên bản Ferret mới nhất ngay bây giờ';

  @override
  String get checking => 'Đang kiểm tra…';

  @override
  String upToDate(String version) {
    return 'Ferret $version là phiên bản mới nhất.';
  }

  @override
  String get checkFailed =>
      'Không kết nối được GitHub. Hãy thử lại sau. Trên mạng công ty, proxy hoặc tường lửa có thể đang chặn.';

  @override
  String statusOff(String version) {
    return 'Ferret không kiểm tra cập nhật. Bạn đang dùng $version.';
  }

  @override
  String ready(String version) {
    return 'Ferret $version đã sẵn sàng';
  }

  @override
  String readyOut(String version) {
    return 'Đã có Ferret $version';
  }

  @override
  String youHave(String version) {
    return 'Bạn đang dùng $version';
  }

  @override
  String get packageManager =>
      'Hãy cập nhật bằng trình quản lý gói hoặc kho ứng dụng.';

  @override
  String get manualInstall => 'Hãy tải về từ trang web để cài đặt.';

  @override
  String get install => 'Cài đặt';

  @override
  String installTooltip(String version) {
    return 'Tải về, kiểm tra và cài Ferret $version, rồi khởi động lại';
  }

  @override
  String get whatsNew => 'Có gì mới';

  @override
  String whatsNewTitle(String version) {
    return 'Có gì mới trong Ferret $version';
  }

  @override
  String get noNotes => 'Phiên bản này không có ghi chú.';

  @override
  String get later => 'Để sau';

  @override
  String get close => 'Đóng';

  @override
  String get downloadPage => 'Trang tải về';

  @override
  String get downloadPageTooltip => 'Mở trang tải Ferret trong trình duyệt';

  @override
  String downloading(int percent) {
    return 'Đang tải… $percent%';
  }

  @override
  String get downloadingNoSize => 'Đang tải…';

  @override
  String get verifying => 'Đang kiểm tra bản tải về…';

  @override
  String get installing => 'Đang cài đặt…';

  @override
  String get restarting => 'Ferret sẽ khởi động lại ngay.';

  @override
  String get cancel => 'Hủy';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get notInstalled => 'Chưa cài bản cập nhật';

  @override
  String get downloadFailed =>
      'Chưa tải xong. Hãy kiểm tra kết nối rồi thử lại.';

  @override
  String get noFile => 'Bản phát hành này chưa có tệp cho hệ thống này.';

  @override
  String get checksumMissing =>
      'Bản phát hành này không có mã kiểm tra cho tệp, nên Ferret không kiểm tra được. Chưa cài gì cả.';

  @override
  String get checksumMismatch =>
      'Bản tải về không khớp mã kiểm tra trên GitHub, có thể đã hỏng hoặc bị thay đổi. Chưa cài gì cả.';

  @override
  String get notSigned => 'Bản tải về không có chữ ký hợp lệ. Chưa cài gì cả.';

  @override
  String get wrongPublisher =>
      'Bản tải về không được ký bởi nhà phát triển Ferret. Chưa cài gì cả.';

  @override
  String get notNotarized =>
      'Apple chưa kiểm tra bản tải về này (chưa được công chứng). Chưa cài gì cả.';

  @override
  String get unsignedHere =>
      'Bản Ferret này chưa được ký, nên không biết ai tạo ra bản cập nhật. Hãy cài từ trang tải về.';

  @override
  String get installFailed =>
      'Ferret không cài được bản cập nhật. Hãy cài từ trang tải về.';

  @override
  String get permissionTitle => 'Cho phép Ferret cài bản cập nhật';

  @override
  String get permissionBody =>
      'Android hỏi một lần. Ferret chỉ cài bản cập nhật của chính nó, đã kiểm tra trước.';

  @override
  String get openSettings => 'Mở cài đặt';

  @override
  String get openSettingsTooltip =>
      'Mở mục Cài ứng dụng không rõ nguồn gốc của Android cho Ferret';

  @override
  String get confirmOnPhone =>
      'Hãy xác nhận cập nhật trong hộp thoại của Android.';

  @override
  String get showPrompt => 'Hiện lại';

  @override
  String get showPromptTooltip => 'Hiện lại hộp thoại cài đặt của Android';

  @override
  String get dragTitle => 'Kéo Ferret vào Applications';

  @override
  String get dragBody =>
      'Ferret không tự thay thế được trong thư mục đó khi không có quyền quản trị, nên bản cập nhật đã kiểm tra được mở trong Finder.';
}
