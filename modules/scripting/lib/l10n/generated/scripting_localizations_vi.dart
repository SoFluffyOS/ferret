// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'scripting_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ScriptingLocalizationsVi extends ScriptingLocalizations {
  ScriptingLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Tập lệnh';

  @override
  String noticeTitle(String title, String device) {
    return '$title · $device';
  }

  @override
  String noticeCover(String device) {
    return 'Thông báo từ một tập lệnh trên $device';
  }

  @override
  String permissionLabel(String device) {
    return 'Cho phép tập lệnh trên $device hiện thông báo ở đây';
  }

  @override
  String get permissionDetail =>
      'Dành cho ferret-cli notify. Tắt cho đến khi bạn bật.';

  @override
  String get settingsIntro =>
      'Tập lệnh trên máy tính này có thể theo dõi Ferret bằng ferret-cli watch, và phản hồi bằng hook: một tệp chạy được mang tên một sự kiện, như device.connected, trong thư mục bên dưới.';

  @override
  String get hooksFolder => 'Thư mục hook';

  @override
  String get hooksNone => 'Chưa có hook nào.';

  @override
  String hooksActive(String events) {
    return 'Hook đang chạy: $events';
  }

  @override
  String get hooksPrivacy =>
      'Hook không bao giờ nhận văn bản đã sao chép hay nội dung thông báo, và không nhận tên khi bản xem trước từ thiết bị đó đang tắt.';

  @override
  String get copyPath => 'Sao chép đường dẫn';

  @override
  String get checkAgain => 'Kiểm tra lại';
}
