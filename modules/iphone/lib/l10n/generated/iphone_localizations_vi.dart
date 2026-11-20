// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'iphone_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class IphoneLocalizationsVi extends IphoneLocalizations {
  IphoneLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'iPhone';

  @override
  String nowPlayingOn(String device) {
    return 'Đang phát trên $device';
  }

  @override
  String pausedOn(String device) {
    return 'Đã tạm dừng trên $device';
  }

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get next => 'Tiếp';

  @override
  String get previous => 'Trước';

  @override
  String get volumeUp => 'Tăng âm lượng';

  @override
  String get volumeDown => 'Giảm âm lượng';

  @override
  String commandFailed(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device không phản hồi. Hãy để máy gần $_temp0 rồi thử lại.';
  }

  @override
  String get problemBluetoothOffTitle => 'Bluetooth đang tắt';

  @override
  String problemBluetoothOffBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Bật Bluetooth trên $_temp0 để nhận thông báo và nội dung đang phát của iPhone tại đây.';
  }

  @override
  String get problemUnauthorizedTitle => 'Ferret không dùng được Bluetooth';

  @override
  String problemUnauthorizedBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép Ferret dùng Bluetooth trong cài đặt quyền riêng tư của $_temp0, rồi thử lại.';
  }

  @override
  String get problemNoDeviceTitle => 'Chọn iPhone của bạn';

  @override
  String problemNoDeviceBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ghép đôi iPhone với $_temp0, rồi chọn nó trong Ferret.';
  }

  @override
  String problemNotSharedTitle(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device chưa chia sẻ với $_temp0';
  }

  @override
  String problemNotSharedBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Trên $device: Cài đặt → Bluetooth, nhấn ⓘ bên cạnh $_temp0, rồi bật Chia sẻ thông báo hệ thống. Không thấy trong danh sách? Hãy ghép đôi lại.';
  }

  @override
  String get yourIphone => 'iPhone';

  @override
  String get openBluetoothSettings => 'Cài đặt Bluetooth';

  @override
  String get openFailed =>
      'Không mở được cài đặt Bluetooth. Hãy mở từ cài đặt hệ thống.';

  @override
  String get setUp => 'Thiết lập';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get settingsEnable => 'Kết nối iPhone';

  @override
  String get settingsEnableBody =>
      'Hiện thông báo và nội dung đang phát của iPhone qua Bluetooth. Không cần cài gì trên iPhone.';

  @override
  String get worksTitle => 'Những gì dùng được với iPhone';

  @override
  String get worksBody =>
      'Thông báo ngay khi đến, kèm Xoá, Trả lời và Từ chối. Phát, tạm dừng, chuyển bài và âm lượng cho bất cứ nội dung nào iPhone đang phát.';

  @override
  String get limitsTitle => 'Chưa có';

  @override
  String limitsBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Đọc và gửi tin nhắn (SMS và iMessage) và nghe gọi trên $_temp0. Apple chỉ cho tệp, bảng nhớ tạm và Handoff hoạt động giữa các thiết bị của hãng.';
  }

  @override
  String get macNoteTitle => 'Thử nghiệm trên Mac';

  @override
  String get macNote =>
      'Chỉ hoạt động khi chính macOS đang kết nối với iPhone qua Bluetooth, và macOS có thể giữ thông báo của iPhone cho riêng mình.';

  @override
  String get statusUnsupported =>
      'Máy tính này không có Bluetooth LE, thứ cần để kết nối với iPhone.';

  @override
  String get statusNotConfigured =>
      'Bản dựng Ferret này không được phép dùng Bluetooth.';

  @override
  String statusConnecting(String device) {
    return 'Đang kết nối với $device…';
  }

  @override
  String statusConnected(String device) {
    return 'Đã kết nối với $device';
  }

  @override
  String statusOutOfReach(String device) {
    return '$device đang ngoài tầm. Ferret sẽ kết nối lại khi máy quay lại.';
  }

  @override
  String statusFailed(String device) {
    return 'Không liên lạc được với $device. Sẽ thử lại sau giây lát.';
  }

  @override
  String summaryUnavailable(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Không dùng được trên $_temp0';
  }

  @override
  String summaryOutOfReach(String device) {
    return '$device đang ngoài tầm';
  }

  @override
  String summaryNotShared(String device) {
    return '$device chưa chia sẻ';
  }

  @override
  String notificationsNotShared(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device chưa chia sẻ thông báo. Trên $device: Cài đặt → Bluetooth, nhấn ⓘ bên cạnh $_temp0, rồi bật Chia sẻ thông báo hệ thống.';
  }

  @override
  String mediaNotShared(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device chưa chia sẻ nội dung đang phát với $_temp0.';
  }

  @override
  String get setupTitle => 'Ghép đôi iPhone';

  @override
  String get setupStepUnlock =>
      'Trên iPhone: mở khoá và mở Cài đặt → Bluetooth. Giữ nguyên màn hình đó.';

  @override
  String get setupStepPairWindows =>
      'Trên PC này, mở cài đặt Bluetooth, chọn Thêm thiết bị → Bluetooth rồi chọn iPhone. Xác nhận mã trên cả hai máy.';

  @override
  String get setupStepPairMac =>
      'Giữ iPhone đã đăng nhập và ở gần Mac này với Bluetooth đang bật, để macOS kết nối với nó.';

  @override
  String get setupStepPairLinux =>
      'Máy tính này giờ hiện trên iPhone trong mục Thiết bị khác. Nhấn vào đó, rồi xác nhận mã trên cả hai máy.';

  @override
  String setupStepAllow(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Khi iPhone hỏi, hãy cho phép hiện thông báo trên $_temp0.';
  }

  @override
  String get setupStepChoose => 'Chọn iPhone bên dưới.';

  @override
  String get devicesTitle => 'Thiết bị đã ghép đôi';

  @override
  String get devicesEmpty => 'Chưa tìm thấy iPhone nào đã ghép đôi.';

  @override
  String get devicesRefresh => 'Tìm lại';

  @override
  String get deviceUse => 'Dùng';

  @override
  String get deviceConnected => 'Đã kết nối';

  @override
  String get deviceUnnamed => 'Thiết bị chưa đặt tên';

  @override
  String get forget => 'Dùng iPhone khác';

  @override
  String get settingsNotifications => 'Hiện thông báo';

  @override
  String get settingsNotificationsBody =>
      'Chỉ thông báo mới. Những gì đã có sẵn trên iPhone vẫn ở lại đó.';

  @override
  String get settingsMedia => 'Điều khiển đa phương tiện';

  @override
  String get settingsMediaBody =>
      'Một thẻ hiện nội dung iPhone đang phát, kèm các nút điều khiển.';

  @override
  String get settingsHidePreviews => 'Ẩn nội dung thông báo';

  @override
  String get settingsHidePreviewsBody =>
      'Chỉ hiện tên ứng dụng, dành cho lúc người khác có thể nhìn thấy màn hình của bạn.';

  @override
  String noticeTitle(String app, String title) {
    return '$app: $title';
  }

  @override
  String get noticeHidden => 'Thông báo mới';

  @override
  String get noticeFromIphone => 'iPhone';

  @override
  String get actionClear => 'Xoá';

  @override
  String get actionAnswer => 'Trả lời';

  @override
  String get actionDecline => 'Từ chối';

  @override
  String get actionCallBack => 'Gọi lại';

  @override
  String get actionAccept => 'Chấp nhận';

  @override
  String actionFailedTitle(String device) {
    return '$device không phản hồi';
  }

  @override
  String actionFailedBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Thao tác đó không đến được $device. Hãy để máy gần $_temp0 rồi thử lại.';
  }
}
