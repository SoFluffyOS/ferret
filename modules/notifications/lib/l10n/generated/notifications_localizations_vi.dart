// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'notifications_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class NotificationsLocalizationsVi extends NotificationsLocalizations {
  NotificationsLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Thông báo';

  @override
  String explainer(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Hiện thông báo của $_temp0 trên máy tính. Mọi ứng dụng đều được chuyển sang, và bạn có thể tắt tiếng những ứng dụng không muốn nhận.';
  }

  @override
  String offerDescription(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Xem thông báo của $_temp0 trên máy tính.';
  }

  @override
  String get explainerDetail =>
      'Chỉ thông báo mới. Không có gì rời khỏi mạng của bạn.';

  @override
  String get turnOn => 'Bật';

  @override
  String get turnOff => 'Tắt chuyển thông báo';

  @override
  String get accessOn => 'Quyền truy cập thông báo đang bật';

  @override
  String get accessOff => 'Quyền truy cập thông báo đang tắt';

  @override
  String get accessStillOff =>
      'Vẫn đang tắt. Bật Ferret trên màn hình Quyền truy cập thông báo rồi quay lại.';

  @override
  String get accessHowTo =>
      'Ở màn hình tiếp theo, bật Ferret rồi quay lại đây.';

  @override
  String get openAccessSettings => 'Mở quyền truy cập thông báo';

  @override
  String get openAccessShort => 'Mở cài đặt';

  @override
  String get openSettingsFailed =>
      'Không mở được Cài đặt. Hãy tự mở Cài đặt → Thông báo → Quyền truy cập thông báo.';

  @override
  String get restrictedTitle => 'Android đã chặn cài đặt này';

  @override
  String get restrictedBody =>
      'Android chặn cài đặt này với ứng dụng cài từ ngoài cửa hàng ứng dụng. Chỉ cần cho phép một lần:';

  @override
  String get restrictedStepOne => 'Mở Thông tin ứng dụng.';

  @override
  String get restrictedStepTwo =>
      'Nhấn ⋮ ở góc trên, rồi chọn Cho phép chế độ cài đặt bị hạn chế.';

  @override
  String get restrictedStepThree =>
      'Quay lại và mở quyền truy cập thông báo lần nữa.';

  @override
  String get openAppInfo => 'Thông tin ứng dụng';

  @override
  String get skipWhileUsing => 'Tạm dừng khi tôi đang dùng điện thoại';

  @override
  String get skipWhileUsingDetail =>
      'Khi màn hình đang bật và đã mở khoá, bạn đã thấy thông báo ngay trên điện thoại.';

  @override
  String get chooseApps => 'Chọn ứng dụng';

  @override
  String get appsAll => 'Mọi ứng dụng';

  @override
  String appsAllExcept(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Mọi ứng dụng, trừ $count',
      zero: 'Mọi ứng dụng',
    );
    return '$_temp0';
  }

  @override
  String appsOnly(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ứng dụng',
      zero: 'Chưa chọn ứng dụng nào',
    );
    return '$_temp0';
  }

  @override
  String get filterAll => 'Mọi ứng dụng';

  @override
  String get filterAllDetail => 'Thông báo của mọi ứng dụng đều đến máy tính.';

  @override
  String get filterAllExcept => 'Mọi ứng dụng, trừ…';

  @override
  String get filterAllExceptDetail => 'Tắt tiếng vài ứng dụng ồn ào.';

  @override
  String get filterOnly => 'Chỉ những ứng dụng này…';

  @override
  String get filterOnlyDetail => 'Chọn vài ứng dụng bạn muốn nhận.';

  @override
  String get filterBuiltIn =>
      'Thông báo của chính Ferret, điều khiển nhạc và các thông báo im lặng hoặc đang diễn ra luôn ở lại trên điện thoại.';

  @override
  String get appPickerMuteHint =>
      'Tắt những ứng dụng bạn không muốn thấy trên máy tính.';

  @override
  String get appPickerOnlyHint =>
      'Bật những ứng dụng bạn muốn thấy trên máy tính.';

  @override
  String get appPickerApps => 'Ứng dụng, gần đây nhất trước';

  @override
  String get selectAll => 'Chọn tất cả';

  @override
  String get selectNone => 'Bỏ chọn tất cả';

  @override
  String get appPickerTitle => 'Chọn ứng dụng';

  @override
  String get appPickerSearch => 'Tìm ứng dụng';

  @override
  String get appPickerLoading => 'Đang lấy danh sách ứng dụng…';

  @override
  String get appPickerEmpty => 'Không có ứng dụng nào khớp.';

  @override
  String appPickerFailed(String device) {
    return 'Không lấy được danh sách ứng dụng từ $device. Hãy đảm bảo thiết bị đã kết nối.';
  }

  @override
  String appPickerSaveFailed(String device) {
    return 'Không lưu được thay đổi đó trên $device.';
  }

  @override
  String thisPhone(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return '$_temp0';
  }

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get back => 'Quay lại';

  @override
  String get noPhone =>
      'Kết nối điện thoại Android để xem thông báo của máy tại đây.';

  @override
  String phoneMirroring(String apps) {
    return 'Bật · $apps';
  }

  @override
  String phoneMirroringOff(String device) {
    return 'Đang tắt trên $device';
  }

  @override
  String get phoneAccessOff => 'Android đã tắt quyền truy cập của Ferret';

  @override
  String get phoneChecking => 'Đang kiểm tra…';

  @override
  String phoneUnreachable(String device) {
    return '$device không phản hồi';
  }

  @override
  String get homeEmpty =>
      'Chưa có thông báo. Thông báo mới từ điện thoại sẽ hiện ở đây.';

  @override
  String homeEmptyFrom(String device) {
    return 'Chưa có thông báo. Thông báo mới từ $device sẽ hiện ở đây.';
  }

  @override
  String get clearAll => 'Xoá tất cả';

  @override
  String get reply => 'Trả lời';

  @override
  String get dismiss => 'Bỏ qua';

  @override
  String get offline => 'ngoại tuyến';

  @override
  String whileAway(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thông báo khi bạn vắng mặt',
    );
    return '$_temp0';
  }

  @override
  String whileAwayFrom(int count, String apps) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thông báo khi bạn vắng mặt',
    );
    return '$_temp0, từ $apps';
  }

  @override
  String get replyFailedTitle => 'Chưa gửi được câu trả lời';

  @override
  String replyFailedBody(String device) {
    return '$device đang ngoại tuyến hoặc thông báo không còn nữa. Hãy trả lời trên $device.';
  }

  @override
  String get setUp => 'Thiết lập';

  @override
  String get fix => 'Sửa';

  @override
  String phoneHomePaused(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Quyền truy cập thông báo đang tắt trên $_temp0 nên máy tính không nhận được thông báo.';
  }

  @override
  String homeTurnOn(String device) {
    return 'Bật Thông báo trên $device để xem thông báo của máy tại đây.';
  }

  @override
  String homeOffline(String device) {
    return '$device đang ngoại tuyến. Thông báo sẽ hiện ở đây khi máy kết nối lại.';
  }

  @override
  String homeAccessOff(String device) {
    return 'Android đã tắt quyền truy cập của Ferret trên $device. Trên $device: mở Ferret và nhấn Sửa.';
  }

  @override
  String homeUnreachable(String device) {
    return '$device không phản hồi. Trên $device: mở Ferret.';
  }

  @override
  String howTitle(String device) {
    return 'Bật Thông báo trên $device';
  }

  @override
  String howBody(String device) {
    return 'Trên $device: Ferret → Làm được nhiều hơn → Thông báo. Ferret sẽ xin quyền truy cập thông báo, sau đó thông báo của mọi ứng dụng sẽ hiện ở đây.';
  }

  @override
  String get how => 'Cách làm?';

  @override
  String get ok => 'Đã hiểu';

  @override
  String get settingsNeedsAccess => 'Cần cấp quyền';

  @override
  String settingsNeedsAccessOn(String device) {
    return 'Cần cấp quyền trên $device';
  }

  @override
  String get settingsPerPhone =>
      'Mọi ứng dụng đều được chuyển sang, trừ khi bạn thay đổi. Để tắt tiếng ứng dụng hoặc ngừng hiện thông báo của một điện thoại ở đây, hãy mở điện thoại đó từ Trang chủ.';

  @override
  String get permissionShow => 'Hiện thông báo của máy tại đây';

  @override
  String get permissionHold => 'Giữ lại khi máy đang được dùng';

  @override
  String get actionChooseApps => 'Chọn ứng dụng gửi thông báo';

  @override
  String get actionChooseAppsShort => 'Chọn ứng dụng';

  @override
  String get healthHiddenHere => 'Đã tắt tại đây';

  @override
  String get healthHiddenHelp =>
      'Bật \"Hiện thông báo của máy tại đây\" bên dưới.';

  @override
  String healthAccessHelp(String device) {
    return 'Trên $device: mở Ferret và nhấn Sửa.';
  }

  @override
  String healthOffThisPhone(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Đang tắt trên $_temp0';
  }

  @override
  String healthOffThisPhoneHelp(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Trên $_temp0: Cài đặt → Đến máy tính của bạn → Thông báo.';
  }

  @override
  String activityOne(String app, String title) {
    return '$app: $title';
  }

  @override
  String activityCount(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thông báo từ $device',
    );
    return '$_temp0';
  }

  @override
  String privateCover(String device) {
    return 'Thông báo mới từ $device';
  }

  @override
  String get hideCodes => 'Ẩn mã một lần';

  @override
  String hideCodesDetail(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng này',
        'other': 'điện thoại này',
      },
    );
    return 'Mã đăng nhập, ngân hàng và giao hàng ở lại trên $_temp0. Máy tính chỉ hiện tên ứng dụng và \"Đã ẩn mã\".';
  }

  @override
  String get codeHidden => 'Đã ẩn mã. Hãy mở trên điện thoại.';
}
