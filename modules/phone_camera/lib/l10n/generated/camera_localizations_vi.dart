// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'camera_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class CameraLocalizationsVi extends CameraLocalizations {
  CameraLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Camera';

  @override
  String get takePhoto => 'Chụp ảnh';

  @override
  String get scanDocument => 'Quét tài liệu';

  @override
  String askPhotoTitle(String device) {
    return '$device muốn bạn chụp một tấm ảnh';
  }

  @override
  String askDocumentTitle(String device) {
    return '$device muốn bạn quét một tài liệu';
  }

  @override
  String get askBody => 'Không có gì được chụp cho đến khi bạn bấm nút chụp.';

  @override
  String get askCapturing => 'Camera đang mở.';

  @override
  String get askTakePhoto => 'Chụp ảnh';

  @override
  String get askScan => 'Quét';

  @override
  String get askNotNow => 'Để sau';

  @override
  String noticeBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Nhấn để trả lời trên $_temp0.';
  }

  @override
  String activityWaiting(String device) {
    return 'Đang chờ ảnh từ $device';
  }

  @override
  String activityWaitingScan(String device) {
    return 'Đang chờ bản quét từ $device';
  }

  @override
  String activityWaitingDetail(String device) {
    return 'Chụp trên $device.';
  }

  @override
  String activityReceiving(String device) {
    return 'Đang nhận ảnh từ $device';
  }

  @override
  String activityPhoto(String device) {
    return 'Ảnh từ $device';
  }

  @override
  String activityScan(String device) {
    return 'Bản quét từ $device';
  }

  @override
  String get activityOnClipboard => 'Trong bảng nhớ tạm';

  @override
  String get activityInFolder => 'Trong thư mục nhận';

  @override
  String get copy => 'Sao chép';

  @override
  String get cancel => 'Hủy';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String endDeclined(String device) {
    return '$device đã chọn Để sau';
  }

  @override
  String endCancelled(String device) {
    return 'Không có ảnh nào được chụp trên $device';
  }

  @override
  String endUnsupported(String device) {
    return '$device không chụp được loại này';
  }

  @override
  String get endUnsupportedDetail =>
      'Máy không có camera mà Ferret mở được, hoặc không có trình quét tài liệu.';

  @override
  String endNoPermission(String device) {
    return 'Không có quyền dùng camera trên $device';
  }

  @override
  String get endNoPermissionDetail =>
      'Cho phép Ferret dùng camera trong phần cài đặt của điện thoại.';

  @override
  String endBusy(String device) {
    return 'Camera trên $device đang mở';
  }

  @override
  String endOffline(String device) {
    return '$device chưa kết nối';
  }

  @override
  String endFailed(String device) {
    return 'Ảnh từ $device chưa đến';
  }

  @override
  String endExpired(String device) {
    return 'Không ai chụp ảnh trên $device';
  }
}
