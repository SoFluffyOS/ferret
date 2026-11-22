// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'find_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class FindLocalizationsVi extends FindLocalizations {
  FindLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Tìm';

  @override
  String get ring => 'Đổ chuông';

  @override
  String get foundIt => 'Tìm thấy rồi';

  @override
  String get stop => 'Dừng';

  @override
  String get ringAgain => 'Đổ chuông lại';

  @override
  String get dismiss => 'Đóng';

  @override
  String get done => 'Xong';

  @override
  String get ringingTitle => 'Ferret đang đổ chuông';

  @override
  String ringingBody(String name) {
    return '$name đang tìm thiết bị này.';
  }

  @override
  String get ringingMuted => 'Thiết bị này đang ở chế độ im lặng nên chỉ rung.';

  @override
  String get ringingHere => 'Thiết bị này đang đổ chuông';

  @override
  String findDevice(String name) {
    return 'Tìm $name';
  }

  @override
  String outgoingRequesting(String name) {
    return 'Đang yêu cầu $name đổ chuông…';
  }

  @override
  String outgoingRinging(String name) {
    return 'Đang đổ chuông $name…';
  }

  @override
  String get outgoingRingingDetail =>
      'Chuông kêu tối đa 2 phút, hoặc đến khi có người nhấn Tìm thấy rồi.';

  @override
  String outgoingRingingMuted(String name) {
    return '$name đang ở chế độ im lặng nên chỉ rung. Trên $name: mở Ferret → Cài đặt → Điều khiển và bật Đổ chuông khi im lặng.';
  }

  @override
  String outgoingFound(String name) {
    return 'Đã tìm thấy $name.';
  }

  @override
  String outgoingTimedOut(String name) {
    return '$name đã tự ngừng đổ chuông.';
  }

  @override
  String outgoingStoppedHere(String name) {
    return 'Đã ngừng đổ chuông $name.';
  }

  @override
  String outgoingStoppedElsewhere(String name) {
    return 'Một thiết bị khác đã tắt chuông $name.';
  }

  @override
  String outgoingNoSound(String name) {
    return '$name không phát được âm thanh.';
  }

  @override
  String outgoingNoSoundDetail(String name) {
    return 'Trên $name: kiểm tra xem âm thanh có hoạt động không. Sau đó đổ chuông lại.';
  }

  @override
  String outgoingUnreachable(String name) {
    return '$name không trả lời.';
  }

  @override
  String outgoingUnreachableDetail(String name) {
    return 'Đảm bảo $name đang bật và cùng Wi-Fi, rồi đổ chuông lại.';
  }

  @override
  String outgoingNotSupported(String name) {
    return '$name chưa đổ chuông được.';
  }

  @override
  String outgoingNotSupportedDetail(String name) {
    return 'Cập nhật Ferret trên $name rồi đổ chuông lại.';
  }

  @override
  String outgoingLostConnection(String name) {
    return 'Mất kết nối với $name.';
  }

  @override
  String outgoingLostConnectionDetail(String name) {
    return '$name vẫn đổ chuông tối đa 2 phút, hoặc đến khi có người nhấn Tìm thấy rồi ở đó.';
  }

  @override
  String get settingsRingOnSilent => 'Đổ chuông khi im lặng';

  @override
  String get settingsRingOnSilentAndroid =>
      'Đổ chuông ở âm lượng tối đa, kể cả khi im lặng hoặc Không làm phiền. Sau đó âm lượng trở lại như cũ.';

  @override
  String get settingsRingOnSilentMac =>
      'Tăng âm lượng và bật tiếng trong lúc đổ chuông, rồi trả lại như cũ.';

  @override
  String get settingsFlashTorch => 'Nháy đèn pin';

  @override
  String get settingsFlashTorchBody =>
      'Nháy đèn pin trong lúc đổ chuông để bạn dễ thấy trong bóng tối.';

  @override
  String get settingsDndOn => 'Đổ chuông cả khi Không làm phiền.';

  @override
  String get settingsDndOff => 'Quyền truy cập Không làm phiền đang tắt';

  @override
  String settingsDndHowTo(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng',
        'other': 'điện thoại',
      },
    );
    return 'Nếu không có quyền này, $_temp0 vẫn đổ chuông khi im lặng nhưng không kêu khi Không làm phiền. Nhấn Cho phép ở Cài đặt, tìm Ferret trong danh sách và bật lên.';
  }

  @override
  String get settingsDndStillOff =>
      'Vẫn đang tắt. Tìm Ferret trong danh sách, bật lên rồi quay lại.';

  @override
  String get settingsAllow => 'Cho phép ở Cài đặt';

  @override
  String get settingsOpenFailed =>
      'Không mở được Cài đặt. Mở Cài đặt, rồi Thông báo, rồi Quyền truy cập Không làm phiền và bật Ferret.';

  @override
  String get settingsFullScreenOff =>
      'Màn hình đổ chuông không hiện được trên màn hình khóa';

  @override
  String get settingsFullScreenHowTo =>
      'Bạn vẫn nghe thấy chuông và nhận được thông báo. Cho phép thông báo toàn màn hình để thấy ngay nút Tìm thấy rồi.';

  @override
  String get settingsLimitIos =>
      'iPhone này chỉ đổ chuông, kể cả khi im lặng, trong lúc Ferret đang mở. iOS dừng ứng dụng ngay sau khi chúng rời màn hình.';

  @override
  String get settingsLimitDesktop =>
      'Đổ chuông ở âm lượng hiện tại. Hãy bật tiếng để nghe thấy.';

  @override
  String get settingsLimitNoPlayer =>
      'Không tìm thấy trình phát âm thanh nên máy tính này không đổ chuông được. Cài pw-play, paplay hoặc aplay.';

  @override
  String get settingsTestRing => 'Đổ chuông thử';

  @override
  String get settingsTestRingBody => 'Đổ chuông thiết bị này trong 5 giây.';

  @override
  String get summaryOnSilent => 'Đổ chuông khi im lặng';

  @override
  String get summaryQuietOnSilent => 'Không kêu khi im lặng';

  @override
  String get summaryQuietInDnd => 'Không kêu khi Không làm phiền';

  @override
  String get summaryCurrentVolume => 'Đổ chuông ở âm lượng hiện tại';

  @override
  String get summaryWhileOpen => 'Đổ chuông khi Ferret đang mở';

  @override
  String get summaryCantRing => 'Chưa đổ chuông được';

  @override
  String healthChecking(String name) {
    return 'Đang kiểm tra $name…';
  }

  @override
  String healthNeedsPermissionHelp(String name) {
    return 'Trên $name: mở Ferret → Cài đặt → Điều khiển và nhấn Cho phép ở Cài đặt trong mục Đổ chuông khi im lặng.';
  }

  @override
  String healthUnsupportedHelp(String name) {
    return 'Trên $name: cập nhật Ferret.';
  }

  @override
  String healthLoud(String name) {
    return 'Đổ chuông, kể cả khi im lặng';
  }

  @override
  String healthFollowsSilent(String name) {
    return 'Đổ chuông, không kêu khi im lặng';
  }

  @override
  String healthNeedsAppOpen(String name) {
    return 'Chỉ đổ chuông khi Ferret đang mở trên $name';
  }

  @override
  String healthNeedsPermission(String name) {
    return 'Không làm phiền khiến $name không kêu';
  }

  @override
  String healthNotAnswering(String name) {
    return '$name không trả lời lần đổ chuông trước';
  }

  @override
  String healthNoSound(String name) {
    return 'Lần trước $name không phát được âm thanh';
  }

  @override
  String healthUnsupported(String name) {
    return 'Cần cập nhật Ferret trên $name';
  }

  @override
  String ringToFind(String name) {
    return 'Đổ chuông $name để tìm';
  }
}
