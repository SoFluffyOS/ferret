// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'wake_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class WakeLocalizationsVi extends WakeLocalizations {
  WakeLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Wake-on-LAN';

  @override
  String get wake => 'Đánh thức';

  @override
  String get tryAgain => 'Thử lại';

  @override
  String get wakingButton => 'Đang đánh thức…';

  @override
  String waking(String name) {
    return 'Đang đánh thức $name… (tối đa một phút)';
  }

  @override
  String get didntWake => 'Không thức dậy';

  @override
  String get couldntSend => 'Không gửi được tín hiệu đánh thức';

  @override
  String get howToTurnOn => 'Cách bật Wake-on-LAN';

  @override
  String get healthReady => 'Có thể đánh thức khi đang ngủ';

  @override
  String get healthWiredUnknown => 'Có thể thử đánh thức qua cáp mạng';

  @override
  String healthWiredOff(String name) {
    return 'Wake-on-LAN đang tắt trên $name';
  }

  @override
  String get healthWifiOnly => 'Chỉ có Wi-Fi: có thể không thức dậy';

  @override
  String healthHelp(String name) {
    return 'Trên $name: Ferret → Cài đặt → Điều khiển → Wake-on-LAN chỉ cách bật.';
  }

  @override
  String get helpTitle => 'Wake-on-LAN';

  @override
  String get helpIntro =>
      'Wake-on-LAN bật một máy tính đang ngủ khi thiết bị khác gửi cho nó một “gói tin ma thuật” qua mạng. Ferret gửi gói tin đó khi bạn nhấn Đánh thức. Máy tính cần cho phép việc này trước, một lần.';

  @override
  String helpToldTitle(String name) {
    return 'Những gì $name cho Ferret biết';
  }

  @override
  String get helpThisComputer => 'Máy tính này';

  @override
  String get cardWiredOn => 'Cáp mạng · Wake-on-LAN đang bật';

  @override
  String get cardWiredOff => 'Cáp mạng · Wake-on-LAN đang tắt';

  @override
  String get cardWiredUnknown => 'Cáp mạng · không rõ Wake-on-LAN có bật không';

  @override
  String get cardWifi => 'Wi-Fi · ít máy tính thức dậy qua Wi-Fi';

  @override
  String get cardNone =>
      'Chưa có card mạng nào để đánh thức. Hãy mở Ferret trên máy đó một lần.';

  @override
  String get helpBestTitle => 'Điều kiện để hoạt động';

  @override
  String get helpBest =>
      'Cắm cáp mạng vào router, máy đang ngủ chứ không tắt hẳn, và một thiết bị khác của bạn ở cùng mạng. Qua Wi-Fi hầu hết máy tính không thức dậy: cáp mạng giúp chắc chắn hơn.';

  @override
  String get helpMacTitle => 'Mac';

  @override
  String get helpMac =>
      'Cài đặt hệ thống → Pin → Tùy chọn → Đánh thức để truy cập mạng (Mac để bàn: Cài đặt hệ thống → Năng lượng). Mac dùng Wi-Fi chỉ thức dậy qua Bonjour Sleep Proxy, như Apple TV hoặc HomePod cùng mạng.';

  @override
  String get helpWindowsTitle => 'Windows';

  @override
  String get helpWindows =>
      '1. Device Manager → Network adapters → card Ethernet của bạn → Properties.\n2. Power Management: bật “Allow this device to wake the computer” và “Only allow a magic packet to wake the computer”.\n3. Advanced: đặt “Wake on Magic Packet” thành Enabled.\n4. Để đánh thức khi đã tắt máy, hãy tắt Fast startup: Control Panel → Power Options → Choose what the power buttons do.';

  @override
  String get helpLinuxTitle => 'Linux';

  @override
  String get helpLinux =>
      'Bật cho card mạng: sudo ethtool -s enp3s0 wol g (dùng tên card của bạn trong “ip link”).\nGiữ sau khi khởi động lại: nmcli connection modify \"Wired connection 1\" 802-3-ethernet.wake-on-lan magic.';

  @override
  String get helpFirmwareTitle => 'BIOS hoặc UEFI (PC Windows và Linux)';

  @override
  String get helpFirmware =>
      'Nhấn F2, Del hoặc F12 khi PC khởi động. Bật “Wake on LAN”, “Power On by PCI-E” hoặc mục tương tự, và tắt “ErP” hoặc “Deep Sleep”, vì chúng ngắt điện card mạng.';

  @override
  String get helpIphoneTitle => 'Từ iPhone';

  @override
  String get helpIphone =>
      'iOS không cho ứng dụng phát gói tin ra toàn mạng, nên iPhone không tự gửi được gói tin ma thuật. Ferret nhờ một thiết bị khác của bạn đang bật, như Mac, PC hoặc ferret-cli trên máy chủ ở nhà, gửi giúp.';

  @override
  String settingsShare(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho thiết bị của tôi đánh thức $_temp0';
  }

  @override
  String settingsShareBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho các thiết bị đã ghép đôi, và chỉ chúng, biết địa chỉ card mạng (MAC) của $_temp0 để đánh thức nó.';
  }

  @override
  String get settingsRelay => 'Đánh thức máy tính giúp điện thoại của tôi';

  @override
  String settingsRelayBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Khi một điện thoại của bạn yêu cầu, $_temp0 gửi tín hiệu đánh thức tới máy tính khác của bạn trong mạng này.';
  }

  @override
  String get settingsReady => 'Sẵn sàng';

  @override
  String get settingsNotReady => 'Tắt';

  @override
  String get settingsWifiOnly => 'Chỉ Wi-Fi';
}
