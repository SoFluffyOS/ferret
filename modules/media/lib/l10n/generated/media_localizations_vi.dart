// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'media_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MediaLocalizationsVi extends MediaLocalizations {
  MediaLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Đa phương tiện';

  @override
  String nowPlayingOn(String device) {
    return 'Đang phát trên $device';
  }

  @override
  String pausedOn(String device) {
    return 'Đã tạm dừng trên $device';
  }

  @override
  String playerOn(String app, String device) {
    return '$app trên $device';
  }

  @override
  String get settingsPauseOnCall => 'Tạm dừng khi có cuộc gọi';

  @override
  String get settingsPauseOnCallBody =>
      'Tạm dừng nội dung đang phát trên thiết bị này khi có cuộc gọi đến hoặc đang gọi, rồi phát lại sau đó.';

  @override
  String get play => 'Phát';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get next => 'Tiếp theo';

  @override
  String get previous => 'Trước đó';

  @override
  String get continueHere => 'Tiếp tục tại đây';

  @override
  String get continueOpening => 'Đang mở…';

  @override
  String get continueFromStart => 'Mở từ đầu';

  @override
  String continueNoLink(String app) {
    return 'Không mở được ở đây. $app không chia sẻ liên kết đến nội dung này.';
  }

  @override
  String continueOpenFailed(String device) {
    return 'Không có ứng dụng nào ở đây mở được. Nội dung vẫn phát trên $device.';
  }

  @override
  String playerGone(String device) {
    return 'Trình phát đó đã đóng trên $device.';
  }

  @override
  String deviceUnreachable(String device) {
    return '$device không trả lời. Trên $device: mở Ferret rồi thử lại.';
  }

  @override
  String deviceNotSharing(String device) {
    return '$device đã ngừng chia sẻ đa phương tiện. Trên $device: Cài đặt → Tiếp tục & đa phương tiện → Chia sẻ đa phương tiện của tôi.';
  }

  @override
  String get commandUnsupported => 'Trình phát này không làm được việc đó.';

  @override
  String commandFailed(String device) {
    return 'Trình phát trên $device không phản hồi. Hãy thử lại.';
  }

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get settingsShare => 'Chia sẻ đa phương tiện của tôi';

  @override
  String get settingsShareBody =>
      'Các thiết bị khác của bạn thấy nội dung đang phát ở đây và có thể điều khiển.';

  @override
  String get settingsShowRemote => 'Hiện đa phương tiện từ thiết bị khác';

  @override
  String get settingsShowRemoteBody =>
      'Nội dung đang phát trên các thiết bị khác của bạn, kèm nút điều khiển và Tiếp tục tại đây.';

  @override
  String get summaryShowsAndShares => 'Hiện và chia sẻ nội dung đang phát';

  @override
  String get summaryShows => 'Hiện nội dung thiết bị của bạn đang phát';

  @override
  String get summaryShares => 'Chia sẻ nội dung đang phát ở đây';

  @override
  String get summaryOff => 'Tắt';

  @override
  String healthUnsupported(String name) {
    return 'Cần cập nhật Ferret trên $name';
  }

  @override
  String get healthShowsTheirs => 'Chia sẻ nội dung đang phát.';

  @override
  String get healthNothingPlaying => 'Hiện không phát gì';

  @override
  String healthSharesMine(String name, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'Mac này',
        'android': 'điện thoại này',
        'ios': 'iPhone này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$name thấy nội dung đang phát trên $_temp0.';
  }

  @override
  String healthShowsAndShares(String name, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'Mac này',
        'android': 'điện thoại này',
        'ios': 'iPhone này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Chia sẻ nội dung đang phát. $name thấy nội dung đang phát trên $_temp0.';
  }

  @override
  String healthLostAccess(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'Mac này',
        'android': 'điện thoại này',
        'ios': 'iPhone này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ferret không thấy được nội dung đang phát trên $_temp0';
  }

  @override
  String healthOffHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'Mac này',
        'android': 'điện thoại này',
        'ios': 'iPhone này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Đang tắt trên $_temp0';
  }

  @override
  String healthNotShared(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macos': 'Mac này',
        'android': 'điện thoại này',
        'ios': 'iPhone này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Không chia sẻ từ $_temp0';
  }

  @override
  String get healthShowHelp =>
      'Cài đặt → Tiếp tục & đa phương tiện → Hiện đa phương tiện từ thiết bị khác';

  @override
  String get healthShareHelp =>
      'Cài đặt → Tiếp tục & đa phương tiện → Chia sẻ đa phương tiện của tôi';

  @override
  String get accessAndroid =>
      'Ferret cần Quyền truy cập thông báo để thấy nội dung đang phát trên điện thoại này. Ferret chỉ đọc các nút điều khiển đa phương tiện.';

  @override
  String get accessMacos =>
      'macOS sẽ hỏi một lần để cho Ferret điều khiển Music và Spotify.';

  @override
  String get accessDenied =>
      'Ferret chưa điều khiển được Music hay Spotify. Cho phép trong Cài đặt hệ thống, Quyền riêng tư & Bảo mật, Tự động hóa.';

  @override
  String get accessAllow => 'Cho phép truy cập';

  @override
  String get accessOpenSettings => 'Mở cài đặt';

  @override
  String get accessCheckAgain => 'Kiểm tra lại';

  @override
  String get limitMacos =>
      'Trên Mac, Ferret thấy Music và Spotify. macOS không cho ứng dụng thấy các trình phát khác.';

  @override
  String get limitIos =>
      'iPhone không cho ứng dụng thấy nội dung ứng dụng khác đang phát. Bạn vẫn xem và điều khiển được đa phương tiện trên các thiết bị khác của mình.';

  @override
  String get limitWindows =>
      'Ferret thấy các trình phát hiện trong phần điều khiển đa phương tiện của Windows. Âm lượng vẫn do PC này điều khiển.';

  @override
  String get limitLinux =>
      'Ferret thấy các trình phát hỗ trợ MPRIS, tức là hầu hết trình phát trên Linux.';

  @override
  String get back => 'Quay lại';
}
