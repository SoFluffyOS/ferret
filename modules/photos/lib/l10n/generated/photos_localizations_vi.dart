// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'photos_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class PhotosLocalizationsVi extends PhotosLocalizations {
  PhotosLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Ảnh';

  @override
  String get back => 'Quay lại';

  @override
  String get autoScreenshots => 'Ảnh chụp màn hình mới tự đến';

  @override
  String autoScreenshotsBody(String device) {
    return 'Mỗi ảnh chụp màn hình bạn chụp trên $device sẽ đến đây khi Ferret đang chạy trên cả hai.';
  }

  @override
  String get recent => 'Gần đây';

  @override
  String get select => 'Chọn';

  @override
  String get cancel => 'Huỷ';

  @override
  String saveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lưu $count ảnh',
    );
    return '$_temp0';
  }

  @override
  String get save => 'Lưu';

  @override
  String get saving => 'Đang lưu…';

  @override
  String get openSaved => 'Mở';

  @override
  String get revealSaved => 'Xem trong thư mục';

  @override
  String get revealSavedFinder => 'Xem trong Finder';

  @override
  String get saved => 'Đã lưu vào thư mục nhận.';

  @override
  String get saveFailed => 'Không lưu được. Hãy thử lại.';

  @override
  String limited(String device) {
    return '$device chỉ chia sẻ những ảnh bạn đã chọn.';
  }

  @override
  String get allowMore => 'Cho phép thêm ảnh';

  @override
  String loading(String device) {
    return 'Đang tải ảnh từ $device…';
  }

  @override
  String offline(String device) {
    return '$device đang ngoại tuyến. Ảnh sẽ hiện ở đây khi thiết bị quay lại.';
  }

  @override
  String unsupported(String device) {
    return '$device cần Ferret mới hơn để chia sẻ ảnh.';
  }

  @override
  String failed(String device) {
    return '$device không trả lời.';
  }

  @override
  String get tryAgain => 'Thử lại';

  @override
  String notAllowedTitle(String device) {
    return '$device chưa chia sẻ ảnh với máy này';
  }

  @override
  String notAllowedBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ảnh của bạn ở lại trên điện thoại cho đến khi bạn cho phép. Trên $device, mở $_temp0 trong Ferret và bật công tắc ảnh trong mục Những gì thiết bị được dùng.';
  }

  @override
  String noPermissionTitle(String device) {
    return 'Ferret trên $device chưa xem được ảnh';
  }

  @override
  String noPermissionBody(String device) {
    return 'Điện thoại chưa cấp quyền ảnh cho Ferret. Hãy cho phép trên $device.';
  }

  @override
  String askOnDevice(String device) {
    return 'Hỏi trên $device';
  }

  @override
  String get askShort => 'Xin quyền truy cập';

  @override
  String askedOnDevice(String device) {
    return 'Một thông báo đang chờ trên $device.';
  }

  @override
  String unavailableTitle(String device) {
    return 'Mở Ferret trên $device để xem ảnh';
  }

  @override
  String get unavailableBody =>
      'iPhone chỉ chia sẻ ảnh khi Ferret đang mở trên đó.';

  @override
  String empty(String device) {
    return 'Chưa có ảnh nào trên $device.';
  }

  @override
  String hidden(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy này',
      },
    );
    return 'Ảnh từ $device đang bị ẩn trên $_temp0.';
  }

  @override
  String kindPhoto(String date) {
    return 'Ảnh, $date';
  }

  @override
  String kindScreenshot(String date) {
    return 'Ảnh chụp màn hình, $date';
  }

  @override
  String kindVideo(String date) {
    return 'Video, $date';
  }

  @override
  String activitySaving(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đang lưu $count ảnh từ $device',
    );
    return '$_temp0';
  }

  @override
  String activitySaved(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã lưu $count ảnh từ $device',
    );
    return '$_temp0';
  }

  @override
  String activityScreenshot(String device) {
    return 'Ảnh chụp màn hình từ $device';
  }

  @override
  String activityFailed(String device) {
    return 'Không lưu được ảnh từ $device';
  }

  @override
  String get activityInFolder => 'Trong thư mục nhận';

  @override
  String failOffline(String device) {
    return '$device đã ngoại tuyến.';
  }

  @override
  String failNotAllowed(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy này',
      },
    );
    return '$device không chia sẻ ảnh với $_temp0.';
  }

  @override
  String failNoPermission(String device) {
    return 'Ferret trên $device không đọc được ảnh.';
  }

  @override
  String failMissing(String device) {
    return 'Những ảnh đó không còn trên $device.';
  }

  @override
  String get failOther => 'Việc gửi đã dừng. Hãy thử lại.';

  @override
  String permissionLabel(String device) {
    return 'Cho $device xem ảnh của bạn';
  }

  @override
  String permissionDetail(String device) {
    return 'Ảnh và ảnh chụp màn hình gần đây, khi Ferret đang chạy. $device có thể xem và lưu, không bao giờ xoá.';
  }

  @override
  String get permissionDetailLimited =>
      'Ferret chỉ thấy những ảnh bạn đã chọn. Đổi trong Cài đặt, Ảnh.';

  @override
  String get permissionDetailDenied =>
      'Quyền ảnh của Ferret đang tắt. Bật trong Cài đặt, Ảnh.';

  @override
  String noticeAskTitle(String device) {
    return '$device muốn xem ảnh của bạn';
  }

  @override
  String get noticeAskBody => 'Chạm để chọn những gì nó được xem.';

  @override
  String get settingsFull => 'Ferret xem được tất cả ảnh của bạn.';

  @override
  String get settingsLimited => 'Ferret chỉ thấy những ảnh bạn đã chọn.';

  @override
  String get settingsDenied => 'Quyền ảnh của Ferret đang tắt.';

  @override
  String get settingsNotAsked =>
      'Ferret sẽ xin quyền ảnh khi bạn chia sẻ ảnh với một máy tính.';

  @override
  String get settingsUnavailable => 'Hiện không đọc được ảnh.';

  @override
  String get allowPhotos => 'Cho phép ảnh';

  @override
  String get openSettings => 'Mở Cài đặt';

  @override
  String get settingsPerDevice =>
      'Chọn máy tính nào được xem ảnh trên trang của từng máy, trong mục Những gì thiết bị được dùng. Không gì bị xoá từ đây.';

  @override
  String settingsSharing(String devices) {
    return 'Đang chia sẻ với: $devices';
  }

  @override
  String get settingsSharingNone => 'Chưa chia sẻ với máy tính nào.';

  @override
  String get dragHint => 'Kéo ảnh vào ứng dụng bất kỳ để thả vào đó.';
}
