// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'shell_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ShellLocalizationsVi extends ShellLocalizations {
  ShellLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get appName => 'Ferret';

  @override
  String get homeYourDevices => 'Thiết bị của bạn';

  @override
  String get homeNearby => 'Lân cận';

  @override
  String get homePairDevice => 'Thêm thiết bị';

  @override
  String get deviceConnected => 'Đã kết nối';

  @override
  String get deviceOffline => 'Chưa kết nối';

  @override
  String get deviceReconnecting => 'Đang kết nối lại…';

  @override
  String deviceStatusSpoken(String device, String status) {
    return '$device: $status';
  }

  @override
  String get deviceWeak => 'Đã kết nối · kết nối yếu';

  @override
  String get deviceNeedsAttention => 'Đã kết nối, cần chú ý';

  @override
  String get spokenOk => 'Ổn';

  @override
  String get spokenOff => 'Tắt';

  @override
  String get spokenWarning => 'Cần chú ý';

  @override
  String get spokenProblem => 'Có vấn đề';

  @override
  String get spokenChecking => 'Đang kiểm tra';

  @override
  String get deviceConnectsWhenOpen =>
      'Kết nối khi Ferret đang mở trên thiết bị đó';

  @override
  String get pairTitle => 'Thêm thiết bị';

  @override
  String get pairShowCode => 'Ghép đôi bằng mã QR';

  @override
  String get pairShowCodeShort => 'Dùng mã QR';

  @override
  String get pairEnterCode => 'Cách khác';

  @override
  String get pairIphoneBody =>
      'Máy tính sẽ hiện trong mục Lân cận khi Ferret đang mở trên cả hai. Không thấy? Trên máy tính, mở Ferret, nhấp + rồi chọn Ghép đôi bằng mã QR. Quét mã ở đây, hoặc bằng ứng dụng Camera của iPhone.';

  @override
  String get pairShowCodeBody =>
      'Trên điện thoại, mở Ferret và nhấn +, rồi chọn Ghép đôi bằng mã QR.';

  @override
  String get pairCopyLink => 'Sao chép liên kết';

  @override
  String get pairLinkCopied => 'Đã sao chép';

  @override
  String pairExpiresIn(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
    );
    return 'Hết hạn sau $_temp0';
  }

  @override
  String get pairNewCode => 'Mã mới';

  @override
  String get pairLinkLabel => 'Dán liên kết';

  @override
  String get pairLinkHint => 'Dán liên kết ferret://pair';

  @override
  String get pairLinkInvalid => 'Đây không phải liên kết ghép đôi của Ferret.';

  @override
  String get pairAddressLabel => 'Địa chỉ của thiết bị kia';

  @override
  String get pairAddressHint => 'VD: 192.168.1.20:47640';

  @override
  String get pairCompareTitle =>
      'Kiểm tra thiết bị kia có hiện đúng mã này, rồi nhấn Ghép đôi trên đó.';

  @override
  String get pairWaiting => 'Đang chờ thiết bị kia…';

  @override
  String pairSuccess(String device) {
    return 'Đã ghép đôi với $device';
  }

  @override
  String get pairFailedUnreachable =>
      'Không kết nối được với thiết bị đó. Cho cả hai dùng chung Wi-Fi rồi thử lại.';

  @override
  String get pairFailedUnreachableIphone =>
      'Không kết nối được với máy tính đó. Kiểm tra cả hai đang dùng chung Wi-Fi và Ferret được phép dùng mạng cục bộ trong Cài đặt.';

  @override
  String get pairFailedRejected => 'Thiết bị kia đã chọn Để sau.';

  @override
  String get pairFailedExpired =>
      'Mã đã hết hạn. Nhấp Mã mới trên máy tính rồi quét lại.';

  @override
  String get pairFailedBadProof =>
      'Mã không khớp nên chưa ghép đôi. Hãy thử lại, ở gần thiết bị kia.';

  @override
  String get pairFailedWrongDevice =>
      'Một thiết bị khác đã phản hồi. Đã dừng ghép đôi để giữ an toàn cho bạn.';

  @override
  String get pairFailedTimedOut => 'Thiết bị kia không phản hồi.';

  @override
  String pairFailedUpdateHere(String name) {
    return '$name có Ferret mới hơn. Hãy cập nhật Ferret ở đây rồi quét lại.';
  }

  @override
  String pairFailedUpdateThere(String name) {
    return '$name cần Ferret mới hơn. Hãy cập nhật ở đó rồi hiện lại mã.';
  }

  @override
  String get pairFailedProtocol => 'Ghép đôi bị dừng giữa chừng. Hãy thử lại.';

  @override
  String pairCodeSpoken(String digits) {
    return 'Mã: $digits';
  }

  @override
  String promptTitle(String device) {
    return 'Ghép đôi với $device?';
  }

  @override
  String promptBody(String device) {
    return 'Chỉ ghép đôi nếu $device hiện cùng mã này.';
  }

  @override
  String get promptAccept => 'Ghép đôi';

  @override
  String get promptReject => 'Để sau';

  @override
  String deviceIdLine(String id) {
    return 'ID thiết bị $id';
  }

  @override
  String get deviceActions => 'Thao tác';

  @override
  String get settingsTitle => 'Cài đặt';

  @override
  String get settingsThisDevice => 'Thiết bị này';

  @override
  String get settingsPrivacy => 'Quyền riêng tư';

  @override
  String get settingsPrivacyBody =>
      'Những gì bạn chia sẻ chỉ đến các thiết bị bạn đã ghép đôi, trực tiếp trong mạng của bạn, mã hóa đầu cuối. Không tài khoản, không đám mây, không thu thập dữ liệu.';

  @override
  String get settingsQuit => 'Thoát Ferret';

  @override
  String get settingsClose => 'Đóng Ferret';

  @override
  String get settingsCloseTip =>
      'Đóng màn hình này. Ferret vẫn chạy nền để các thiết bị luôn kết nối.';

  @override
  String get back => 'Quay lại';

  @override
  String get cancel => 'Hủy';

  @override
  String get menuOpen => 'Mở Ferret';

  @override
  String get menuOpenWindow => 'Mở cửa sổ Ferret';

  @override
  String get homeOpenWindow => 'Mở cửa sổ Ferret';

  @override
  String get settingsDock => 'Dock';

  @override
  String get settingsAlwaysInDock => 'Luôn hiện trong Dock';

  @override
  String get settingsAlwaysInDockBody =>
      'Khi tắt, Ferret chỉ nằm trong Dock lúc cửa sổ đang mở.';

  @override
  String get menuPair => 'Thêm thiết bị…';

  @override
  String get menuSettings => 'Cài đặt…';

  @override
  String get menuQuit => 'Thoát Ferret';

  @override
  String menubarTipConnectedTo(String device) {
    return 'Ferret · Đã kết nối với $device';
  }

  @override
  String menubarTipConnected(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị đã kết nối',
    );
    return 'Ferret · $_temp0';
  }

  @override
  String get menubarTipAlone => 'Ferret · Chưa kết nối thiết bị nào';

  @override
  String menubarTipSendingTo(String device) {
    return 'Ferret · Đang gửi đến $device';
  }

  @override
  String menubarTipReceivingFrom(String device) {
    return 'Ferret · Đang nhận từ $device';
  }

  @override
  String get menubarTipSending => 'Ferret · Đang gửi';

  @override
  String get menubarTipReceiving => 'Ferret · Đang nhận';

  @override
  String get menubarTipDone => 'Ferret · Xong';

  @override
  String menubarTipPair(String device) {
    return 'Ferret · $device muốn ghép đôi';
  }

  @override
  String menubarTipRequest(String device) {
    return 'Ferret · $device muốn gửi cho bạn';
  }

  @override
  String menubarTipWaiting(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count yêu cầu đang chờ bạn',
    );
    return 'Ferret · $_temp0';
  }

  @override
  String get menubarTipPaused => 'Ferret · Đã tạm dừng';

  @override
  String get welcomeTitle => 'Các thiết bị của bạn, phối hợp cùng nhau';

  @override
  String get welcomePrivacy =>
      'Không tài khoản. Không đám mây. Chỉ trong mạng của bạn.';

  @override
  String get welcomePlatforms => 'Android · iPhone · Mac · Windows · Linux';

  @override
  String get deviceLastSeenJustNow => 'Vừa mới thấy';

  @override
  String deviceLastSeenMinutes(int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes phút',
    );
    return 'Thấy lần cuối $_temp0 trước';
  }

  @override
  String deviceLastSeenHours(int hours) {
    String _temp0 = intl.Intl.pluralLogic(
      hours,
      locale: localeName,
      other: '$hours giờ',
    );
    return 'Thấy lần cuối $_temp0 trước';
  }

  @override
  String deviceLastSeenDays(int days) {
    String _temp0 = intl.Intl.pluralLogic(
      days,
      locale: localeName,
      other: '$days ngày',
    );
    return 'Thấy lần cuối $_temp0 trước';
  }

  @override
  String get resume => 'Tiếp tục chạy';

  @override
  String get pause => 'Tạm dừng';

  @override
  String get pauseOneHour => 'Tạm dừng đồng bộ 1 giờ';

  @override
  String get pauseUntilTomorrow => 'Tạm dừng đồng bộ đến ngày mai';

  @override
  String get pauseUntilResume => 'Tạm dừng đồng bộ đến khi tôi cho chạy tiếp';

  @override
  String get doctorTitle => 'Sửa kết nối';

  @override
  String doctorIntro(String device) {
    return 'Đang kiểm tra vì sao $device chưa kết nối.';
  }

  @override
  String doctorNetworkOk(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'Máy Mac này đang có Wi-Fi hoặc cáp mạng',
        'windows': 'PC này đang có Wi-Fi hoặc cáp mạng',
        'phone': 'Điện thoại này đang có Wi-Fi',
        'tablet': 'Máy tính bảng này đang có Wi-Fi',
        'other': 'Máy tính này đang có Wi-Fi hoặc cáp mạng',
      },
    );
    return '$_temp0';
  }

  @override
  String doctorNetworkProblem(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'Máy Mac này',
        'windows': 'PC này',
        'phone': 'Điện thoại này',
        'tablet': 'Máy tính bảng này',
        'other': 'Máy tính này',
      },
    );
    return '$_temp0 chưa có mạng. Hãy kết nối Wi-Fi hoặc Ethernet.';
  }

  @override
  String doctorMobileDataAny(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'Máy Mac này',
        'windows': 'PC này',
        'phone': 'Điện thoại này',
        'tablet': 'Máy tính bảng này',
        'other': 'Máy tính này',
      },
    );
    return '$_temp0 đang dùng dữ liệu di động, mà Ferret cần Wi-Fi để tìm thiết bị của bạn. Hãy vào cùng Wi-Fi với chúng.';
  }

  @override
  String doctorMobileData(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'Máy Mac này',
        'windows': 'PC này',
        'phone': 'Điện thoại này',
        'tablet': 'Máy tính bảng này',
        'other': 'Máy tính này',
      },
    );
    return '$_temp0 đang dùng dữ liệu di động, mà Ferret cần Wi-Fi để tìm $device. Hãy vào cùng Wi-Fi, hoặc kết nối $device qua VPN của bạn.';
  }

  @override
  String doctorMobileDataVpn(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'Máy Mac này',
        'windows': 'PC này',
        'phone': 'Điện thoại này',
        'tablet': 'Máy tính bảng này',
        'other': 'Máy tính này',
      },
    );
    return '$_temp0 đang dùng dữ liệu di động. Ferret sẽ thử kết nối $device qua VPN của bạn.';
  }

  @override
  String doctorVpn(String name) {
    return 'Đang bật VPN ($name). VPN có thể che các thiết bị trong Wi-Fi của bạn. Hãy cho phép truy cập mạng cục bộ trong ứng dụng VPN, hoặc tắt VPN. Trên máy tính công ty, hãy hỏi bộ phận IT.';
  }

  @override
  String doctorPort(String port) {
    return 'Ferret đang dùng cổng $port vì cổng thường dùng đã bị chiếm. Không sao cả.';
  }

  @override
  String doctorSameNetworkOk(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Lần trước, $device và $_temp0 dùng chung một Wi-Fi';
  }

  @override
  String doctorSameNetworkWarning(String device, String address, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Lần cuối, $device ở một mạng khác ($address). Cho $device và $_temp0 dùng chung Wi-Fi.';
  }

  @override
  String doctorReachableRunning(String device) {
    return 'Đang thử liên lạc với $device…';
  }

  @override
  String doctorReachableOk(String device) {
    return '$device đã phản hồi';
  }

  @override
  String doctorReachableProblem(String device) {
    return '$device không phản hồi.';
  }

  @override
  String get doctorAcceptedRunning => 'Đang kết nối…';

  @override
  String get doctorAcceptedOk => 'Đã kết nối. Mọi thứ đều ổn.';

  @override
  String doctorAcceptedProblem(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '$device có phản hồi nhưng không còn nhận ra $_temp0. Có thể thiết bị đã được đặt lại hoặc cài lại. Hãy ghép đôi lại.';
  }

  @override
  String get doctorFixTryAgain => 'Thử lại';

  @override
  String get doctorFixConnectByAddress => 'Kết nối bằng địa chỉ';

  @override
  String get doctorFixPairAgain => 'Ghép đôi lại';

  @override
  String get doctorFixCopy => 'Sao chép thông tin cho người giúp';

  @override
  String get connectTitle => 'Kết nối bằng địa chỉ';

  @override
  String get connectBody =>
      'Trên thiết bị kia, mở Ferret, vào Cài đặt rồi Nâng cao. Nhập địa chỉ hiện ở đó.';

  @override
  String get stayTitle => 'Giữ kết nối';

  @override
  String get stayBody =>
      'Android dừng các ứng dụng chạy nền để tiết kiệm pin. Các bước sau giúp Ferret luôn kết nối. Chỉ tốn khoảng 1% pin mỗi ngày.';

  @override
  String get stayNotifications =>
      'Cho phép thông báo của Ferret để Android cho nó tiếp tục chạy.';

  @override
  String get stayNotificationsFix => 'Cho phép';

  @override
  String get stayBattery =>
      'Android có thể dừng Ferret khi chạy nền. Hãy cho phép Ferret tiếp tục chạy.';

  @override
  String get stayBatteryFix => 'Sửa';

  @override
  String get stayRestricted =>
      'Mức dùng pin của Ferret đang là Bị hạn chế, nên Android dừng Ferret mỗi khi bạn rời ứng dụng.';

  @override
  String get stayRestrictedSteps =>
      'Mở Mức sử dụng pin của ứng dụng và chọn Không hạn chế.';

  @override
  String get stayRestrictedFix => 'Sửa';

  @override
  String get stayStepsXiaomi =>
      'Cài đặt → Ứng dụng → Quản lý ứng dụng → Ferret: bật Tự khởi chạy và đặt Tiết kiệm pin thành Không hạn chế.';

  @override
  String get stayStepsSamsung =>
      'Cài đặt → Pin → Giới hạn sử dụng trong nền → Ứng dụng không bao giờ ngủ: thêm Ferret.';

  @override
  String get stayStepsOneplus =>
      'Cài đặt → Ứng dụng → Ferret → Mức sử dụng pin: bật Cho phép hoạt động trong nền. Sau đó khóa Ferret trong màn hình ứng dụng gần đây.';

  @override
  String get stayStepsHuawei =>
      'Cài đặt → Pin → Khởi chạy ứng dụng → Ferret: tắt Quản lý tự động và giữ cả ba công tắc bật.';

  @override
  String get stayStepsOppo =>
      'Cài đặt → Ứng dụng → Ferret → Mức sử dụng pin: bật Cho phép hoạt động trong nền và Cho phép tự khởi chạy.';

  @override
  String get stayStepsVivo =>
      'Cài đặt → Pin → Quản lý tiêu thụ pin trong nền → Ferret: cho phép. Bật cả Tự khởi chạy cho Ferret.';

  @override
  String stayMaker(String maker) {
    return 'Điện thoại $maker của bạn còn có trình tiết kiệm pin riêng. Hãy cho phép Ferret ở đó.';
  }

  @override
  String get stayMakerFix => 'Mở cài đặt';

  @override
  String stayStops(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count lần',
    );
    return 'Hôm nay Android đã dừng Ferret $_temp0.';
  }

  @override
  String stayBootAsk(String device) {
    return 'Khởi động Ferret khi $device khởi động lại? Nếu không, Ferret chỉ kết nối lại khi bạn mở ứng dụng.';
  }

  @override
  String get stayBootYes => 'Có';

  @override
  String get stayBootNotNow => 'Để sau';

  @override
  String get settingsBackground => 'Chạy nền';

  @override
  String get settingsKeepRunning => 'Tiếp tục chạy nền';

  @override
  String get settingsKeepRunningBody =>
      'Giữ kết nối khi Ferret đã đóng. Hiện một thông báo im lặng.';

  @override
  String settingsStartOnBoot(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'tablet': 'máy tính bảng',
        'other': 'điện thoại',
      },
    );
    return 'Khởi động cùng $_temp0';
  }

  @override
  String dropTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Gửi $count tệp đến…',
      zero: 'Gửi tệp đến…',
    );
    return '$_temp0';
  }

  @override
  String get dropTileDrop => 'Thả để gửi';

  @override
  String get dropTilePick => 'Gửi đến đây';

  @override
  String get dropTileOffline => 'Ngoại tuyến';

  @override
  String get dropAllDevices => 'Tất cả thiết bị của tôi';

  @override
  String get dropNobody => 'Không có thiết bị nào để gửi';

  @override
  String get dropNobodyDetail => 'Hãy mở Ferret trên thiết bị kia trước.';

  @override
  String dropSendingTo(String name) {
    return 'Đang gửi đến $name';
  }

  @override
  String dropSentTo(String name) {
    return 'Đã gửi đến $name';
  }

  @override
  String dropFailedTo(String name) {
    return 'Không gửi được đến $name';
  }

  @override
  String get dropFailedDetail => 'Tệp chưa được gửi. Hãy thử lại sau giây lát.';

  @override
  String get dropAllDevicesName => 'tất cả thiết bị của tôi';

  @override
  String dropFolderCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thư mục',
    );
    return '$_temp0';
  }

  @override
  String dropFilesAndFolders(String files, String folders) {
    return '$files và $folders';
  }

  @override
  String dropFileCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tệp',
    );
    return '$_temp0';
  }

  @override
  String get dropTitleText => 'Gửi văn bản đến…';

  @override
  String get dropTitleLink => 'Mở liên kết trên…';

  @override
  String get dropKindText => 'Văn bản, vào bảng nhớ tạm của thiết bị';

  @override
  String get dropKindLink => 'Liên kết, mở trên thiết bị';

  @override
  String get dropTryAgain => 'Thử lại';

  @override
  String get dropClose => 'Đóng';

  @override
  String get dropCancel => 'Hủy';

  @override
  String dropSendTo(String name) {
    return 'Gửi đến $name';
  }

  @override
  String dropSendToAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị',
    );
    return 'Gửi đến cả $_temp0';
  }

  @override
  String dropToSendTo(String name) {
    return 'Thả để gửi đến $name';
  }

  @override
  String dropDeviceOffline(String name) {
    return '$name đang ngoại tuyến';
  }

  @override
  String get scanTitle => 'Quét mã';

  @override
  String get scanBody =>
      'Trên máy tính, mở Ferret và chọn Ghép đôi bằng mã QR. Sau đó hướng camera vào mã.';

  @override
  String get scanButton => 'Quét mã trên máy tính';

  @override
  String get scanButtonShort => 'Quét mã';

  @override
  String get scanNotFerret =>
      'Đây không phải mã của Ferret. Trên máy tính, mở Ferret và nhấp +, rồi chọn Ghép đôi bằng mã QR.';

  @override
  String get offersTitle => 'Làm được nhiều hơn';

  @override
  String get offersSubtitle =>
      'Các tính năng bổ sung bạn có thể bật. Đều không bắt buộc.';

  @override
  String get offersNotNow => 'Để sau';

  @override
  String get offersNotNowTooltip =>
      'Để sau. Mục Làm được nhiều hơn vẫn có trong Cài đặt.';

  @override
  String get offersAllOn =>
      'Mọi thứ ở đây đã bật. Tính năng mới sẽ hiện ở đây.';

  @override
  String get onboardNameLabel => 'Tên thiết bị';

  @override
  String get settingsRename => 'Đổi tên';

  @override
  String get settingsRenameTitle => 'Đặt tên cho thiết bị này';

  @override
  String thisDeviceShared(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'máy Mac này',
        'windows': 'máy tính này',
        'other': 'máy tính này',
      },
    );
    return 'Các tài khoản khác trên $_temp0 cũng dùng Ferret. Mỗi tài khoản có thiết bị riêng.';
  }

  @override
  String get thisDeviceOnlyMe => 'Chỉ mình tôi';

  @override
  String thisDeviceOnlyMeHint(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'máy Mac này',
        'windows': 'máy tính này',
        'other': 'máy tính này',
      },
    );
    return 'Chỉ mình tôi dùng $_temp0. Nội dung xem trước hiện lại, trừ thiết bị bạn đã tắt, và tên bỏ phần tài khoản. Nếu Ferret thấy một tài khoản khác ở đây, máy lại được tính là dùng chung.';
  }

  @override
  String thisDeviceOtherPort(String port, String usual) {
    return 'Đang dùng cổng $port: một tài khoản khác đang dùng cổng $usual.';
  }

  @override
  String get privateCoverBody => 'Mở Ferret để xem.';

  @override
  String privateCoverDetail(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'máy Mac này',
        'windows': 'máy tính này',
        'other': 'máy tính này',
      },
    );
    return 'Đã ẩn trên $_temp0';
  }

  @override
  String previewsTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'máy Mac này',
        'windows': 'máy tính này',
        'other': 'máy tính này',
      },
    );
    return 'Hiện nội dung xem trước trên $_temp0';
  }

  @override
  String previewsBody(String device) {
    return 'Thông báo, tin nhắn, người gọi và văn bản đã sao chép từ $device hiện trên màn hình này. Khi tắt, Ferret chỉ báo là có thứ vừa đến. Nội dung luôn ẩn khi màn hình bị khóa hoặc một tài khoản khác đang dùng máy.';
  }

  @override
  String previewsSharedDefault(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'máy Mac này',
        'windows': 'máy tính này',
        'other': 'máy tính này',
      },
    );
    return 'Mặc định tắt ở đây, vì các tài khoản khác trên $_temp0 cũng dùng Ferret.';
  }

  @override
  String settingsAddress(String address) {
    return 'Địa chỉ: $address';
  }

  @override
  String get settingsAddressHint =>
      'Nếu thiết bị khác không tìm thấy thiết bị này: trên thiết bị đó, mở Thêm thiết bị, chọn Cách khác rồi nhập địa chỉ này.';

  @override
  String get deviceWhyLong => 'Vì sao không kết nối được?';

  @override
  String get deviceWhyShort => 'Sửa kết nối';

  @override
  String deviceWhatWorks(String device) {
    return 'Những gì dùng được với $device';
  }

  @override
  String get deviceDetails => 'Chi tiết';

  @override
  String deviceForget(String device) {
    return 'Quên $device';
  }

  @override
  String get deviceForgetShort => 'Quên';

  @override
  String deviceForgetConfirmTitle(String device) {
    return 'Quên $device?';
  }

  @override
  String deviceForgetConfirmBody(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '$device và $_temp0 sẽ quên nhau. Bạn có thể ghép đôi lại bất cứ lúc nào.';
  }

  @override
  String get doctorTryAgainPrimary => 'Thử lại';

  @override
  String doctorNotAnsweringSteps(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Hãy thử:\n1. Trên $device, mở Ferret.\n2. Cho $device và $_temp0 dùng chung Wi-Fi.\n3. Wi-Fi khách và Wi-Fi văn phòng thường tách các thiết bị khỏi nhau. Hãy thử Wi-Fi ở nhà hoặc điểm phát sóng của điện thoại.';
  }

  @override
  String get nearbyLooking => 'Đang tìm thiết bị kia…';

  @override
  String get nearbyNone => 'Chưa tìm thấy thiết bị nào.';

  @override
  String get nearbyLookAgain => 'Tìm lại';

  @override
  String get nearbyPair => 'Ghép đôi';

  @override
  String nearbyPairWith(String name) {
    return 'Ghép đôi với $name';
  }

  @override
  String nearbyConnecting(String device) {
    return 'Đang kết nối với $device…';
  }

  @override
  String nearbyCheckCode(String device) {
    return 'Kiểm tra $device có hiện đúng mã này.';
  }

  @override
  String get nearbyTheyMatch => 'Mã khớp';

  @override
  String nearbyTapThere(String device) {
    return 'Trên $device, nhấn Ghép đôi.';
  }

  @override
  String nearbyWaiting(String device) {
    return 'Đang chờ $device…';
  }

  @override
  String get nearbyTryAgain => 'Thử lại';

  @override
  String nearbyNoAnswer(String device) {
    return '$device không phản hồi.';
  }

  @override
  String nearbyNotNow(String device) {
    return '$device đã chọn Để sau.';
  }

  @override
  String nearbyUnreachable(String device) {
    return 'Không kết nối được với $device. Cả hai có dùng chung Wi-Fi không?';
  }

  @override
  String get nearbyBlockedTitle => 'Ferret không thể tìm thiết bị của bạn';

  @override
  String get nearbyBlockedBody =>
      'Hệ thống cần bạn đồng ý. Cho phép Ferret trong Quyền riêng tư & Bảo mật, Mạng cục bộ.';

  @override
  String get nearbyOpenSettings => 'Mở Cài đặt';

  @override
  String get pairCantSeeSteps =>
      '1. Mở Ferret trên thiết bị kia.\n2. Cho cả hai dùng chung Wi-Fi.\n3. Vẫn chưa thấy? Kiểm tra mạng của tôi sẽ cho bạn biết lý do.';

  @override
  String promptAlsoOne(String first) {
    return 'Bạn cũng sẽ được kết nối với $first.';
  }

  @override
  String promptAlsoTwo(String first, String second) {
    return 'Bạn cũng sẽ được kết nối với $first và $second.';
  }

  @override
  String promptAlsoMore(String first, String second, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị khác',
    );
    return 'Bạn cũng sẽ được kết nối với $first, $second và $_temp0.';
  }

  @override
  String promptSecondsLeft(int seconds) {
    String _temp0 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: 'Còn $seconds giây',
    );
    return '$_temp0';
  }

  @override
  String promptNotice(String device) {
    return '$device muốn ghép đôi';
  }

  @override
  String get promptNoticeBody => 'Mở Ferret để so mã.';

  @override
  String groupJoinAsk(String asker, String device) {
    return '$asker muốn thêm $device vào các thiết bị của bạn';
  }

  @override
  String groupJoinAskDetail(String asker, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Thiết bị này sẽ được dùng những gì $asker được dùng ở đây. Chọn Để sau nếu không muốn thêm nó vào $_temp0.';
  }

  @override
  String get groupJoinAdd => 'Thêm';

  @override
  String groupJoinAddTooltip(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Thêm $device vào $_temp0';
  }

  @override
  String get groupJoinNotNow => 'Để sau';

  @override
  String groupJoinNotNowTooltip(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Không thêm $device vào $_temp0';
  }

  @override
  String groupRemoveAsk(String asker, String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '$asker muốn gỡ $device khỏi $_temp0';
  }

  @override
  String get groupRemoveAskDetail =>
      'Nó đã bị gỡ khỏi tất cả thiết bị của bạn ở đó. Chọn Giữ để nó vẫn được ghép đôi ở đây.';

  @override
  String get groupRemove => 'Gỡ';

  @override
  String groupRemoveTooltip(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Gỡ $device khỏi $_temp0';
  }

  @override
  String get groupKeep => 'Giữ';

  @override
  String groupKeepTooltip(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Giữ $device ghép đôi với $_temp0';
  }

  @override
  String get groupRequestNoticeBody => 'Mở Ferret để trả lời.';

  @override
  String groupRequestsNotice(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thay đổi về thiết bị của bạn cần bạn xử lý',
    );
    return '$_temp0';
  }

  @override
  String devicePairedThrough(String device) {
    return 'Ghép đôi qua $device';
  }

  @override
  String deviceForgetScopeBody(String device) {
    return '$device cũng đang kết nối với các thiết bị khác của bạn.';
  }

  @override
  String get deviceForgetEverywhere => 'Gỡ khỏi tất cả thiết bị của tôi';

  @override
  String get deviceForgetEverywhereShort => 'Gỡ mọi nơi';

  @override
  String deviceForgetHere(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Chỉ quên trên $_temp0';
  }

  @override
  String get deviceForgetHereShort => 'Chỉ quên ở đây';

  @override
  String get settingsSharePairings =>
      'Ghép đôi một lần cho tất cả thiết bị của tôi';

  @override
  String get settingsSharePairingsBody =>
      'Thiết bị bạn ghép đôi ở đây cũng được thêm vào các thiết bị khác của bạn. Khi một máy trong số đó thêm hoặc gỡ thiết bị, Ferret ở đây sẽ hỏi bạn trước.';

  @override
  String get settingsAlwaysVisible => 'Luôn hiển thị';

  @override
  String get settingsAlwaysVisibleBody =>
      'Hiện thiết bị này trên mọi mạng Wi-Fi. Khi tắt, nó chỉ hiện ở nơi đã gặp các thiết bị của bạn, hoặc khi bạn đang thêm thiết bị. Ở nơi khác nó chỉ lắng nghe, và các thiết bị của bạn vẫn tìm thấy nó.';

  @override
  String doctorIsolated(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Wi-Fi này tách các thiết bị khỏi nhau, nên $_temp0 không tới được $device. Wi-Fi quán cà phê, khách sạn và Wi-Fi khách thường như vậy. Hãy cho cả hai dùng Wi-Fi ở nhà hoặc điểm phát sóng của điện thoại.';
  }

  @override
  String get doctorIsolatedMaybe =>
      'Ferret chưa thấy thiết bị nào khác trên mạng này. Nếu thiết bị kia đang dùng chung Wi-Fi, có thể mạng này tách các thiết bị khỏi nhau, như Wi-Fi quán cà phê, khách sạn và Wi-Fi khách thường làm. Hãy cho cả hai dùng điểm phát sóng của điện thoại hoặc mạng ở nhà.';

  @override
  String doctorNothingWrong(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Mọi thứ trên $_temp0 đều ổn. Trên $device, hãy mở Ferret.';
  }

  @override
  String doctorNetworkIntro(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Đang kiểm tra mạng trên $_temp0.';
  }

  @override
  String doctorNetworkAllGood(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Mọi thứ trên $_temp0 đều ổn. Hãy mở Ferret trên thiết bị kia, dùng chung Wi-Fi.';
  }

  @override
  String get connectAction => 'Thử địa chỉ này';

  @override
  String get settingsGroupClipboard => 'Bảng nhớ tạm';

  @override
  String get settingsGroupFiles => 'Tệp';

  @override
  String get settingsGroupContinue => 'Tiếp tục & đa phương tiện';

  @override
  String get settingsGroupFromPhone => 'Từ điện thoại của bạn';

  @override
  String get settingsGroupToComputer => 'Đến máy tính của bạn';

  @override
  String get settingsGroupControl => 'Điều khiển';

  @override
  String get settingsGroupOtherApps => 'Ứng dụng khác';

  @override
  String get settingsOn => 'Bật';

  @override
  String get settingsOff => 'Tắt';

  @override
  String settingsCountOn(int on, int total) {
    return 'Đang bật $on/$total';
  }

  @override
  String settingsNamedOn(String names) {
    return 'Đang bật: $names';
  }

  @override
  String get settingsNeedsAttention => 'Cần chú ý';

  @override
  String get settingsAdvanced => 'Nâng cao';

  @override
  String get settingsLanguage => 'Ngôn ngữ';

  @override
  String get settingsLanguageSystem => 'Theo hệ thống';

  @override
  String settingsLanguageNote(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Menu, biểu tượng trên thanh menu và thông báo sẽ đổi vào lần tới Ferret khởi động.',
        'other': 'Menu, biểu tượng khay hệ thống và thông báo sẽ đổi vào lần tới Ferret khởi động.',
      },
    );
    return '$_temp0';
  }

  @override
  String get settingsAbout => 'Giới thiệu · Quyền riêng tư';

  @override
  String settingsVersion(String version) {
    return 'Ferret $version';
  }

  @override
  String get settingsLicense =>
      'Phần mềm tự do theo giấy phép GPL-3.0. Giao thức cũng mở, theo giấy phép MIT.';

  @override
  String get settingsSponsor => 'Tài trợ Ferret';

  @override
  String get settingsSponsorDetail =>
      'Ferret miễn phí. Nếu Ferret giúp bạn tiết kiệm thời gian, bạn có thể tài trợ trên GitHub.';

  @override
  String get settingsDeviceIdLabel => 'ID thiết bị';

  @override
  String get settingsAddressLabel => 'Địa chỉ';

  @override
  String get settingsCheckNetwork => 'Kiểm tra mạng của tôi';

  @override
  String get settingsNothingHere =>
      'Chưa có gì để cài đặt ở đây. Hãy ghép đôi một thiết bị trước.';

  @override
  String get settingsShortcutTitle => 'Mở Ferret từ bất cứ đâu';

  @override
  String get settingsClipsShortcutTitle => 'Mục đã chép gần đây, từ mọi nơi';

  @override
  String get settingsClipsShortcutBody =>
      'Nhấn tổ hợp phím này trong mọi ứng dụng để xem những gì bạn vừa chép, trên mọi thiết bị.';

  @override
  String get settingsShortcutBody =>
      'Nhấn các phím này trong bất kỳ ứng dụng nào để mở hoặc đóng menu của Ferret.';

  @override
  String get settingsShortcutOff => 'Tắt';

  @override
  String get settingsShortcutChange => 'Đổi';

  @override
  String get settingsShortcutTurnOff => 'Tắt';

  @override
  String get settingsShortcutTurnOn => 'Bật';

  @override
  String get settingsShortcutRecording => 'Nhấn tổ hợp phím mới. Esc để hủy.';

  @override
  String get settingsShortcutTaken =>
      'macOS không nhận tổ hợp phím này. Hãy thử phím khác.';

  @override
  String deviceMay(String device) {
    return '$device được phép';
  }

  @override
  String get deviceHow => 'Cách làm?';

  @override
  String get deviceFix => 'Sửa';

  @override
  String activityActionFor(String action, String subject) {
    return '$action: $subject';
  }

  @override
  String healthActionFor(String action, String feature) {
    return '$action $feature';
  }

  @override
  String devicePairedOn(String date) {
    return 'Đã ghép đôi vào $date';
  }

  @override
  String deviceNothingWorks(String device) {
    return 'Chưa có gì để hiện. Hãy giữ Ferret mở trên $device.';
  }

  @override
  String get addDontSee => 'Không thấy thiết bị?';

  @override
  String addShowsAs(String name) {
    return 'Hiển thị là $name';
  }

  @override
  String get qrScanEnough =>
      'Chỉ cần quét, bằng Ferret hoặc camera của điện thoại. Không phải so mã.';

  @override
  String get qrWaiting => 'Đang chờ điện thoại của bạn…';

  @override
  String get otherShowQr => 'Hiện mã QR';

  @override
  String get otherLinkTitle => 'Bằng liên kết';

  @override
  String get otherLinkBody =>
      'Sao chép liên kết của thiết bị này rồi mở trên thiết bị kia, hoặc dán liên kết của thiết bị kia vào đây.';

  @override
  String get otherAddressTitle => 'Bằng địa chỉ';

  @override
  String get otherAddressBody =>
      'Dành cho mạng che các thiết bị khỏi nhau. Địa chỉ nằm trong Cài đặt của Ferret, mục Nâng cao, trên thiết bị kia.';

  @override
  String get otherPairLink => 'Ghép bằng liên kết';

  @override
  String get otherPairAddress => 'Ghép bằng địa chỉ';

  @override
  String get homeMore => 'Khác';

  @override
  String get homeStatusPaused => 'Đã tạm dừng';

  @override
  String deviceAttention(String feature) {
    return 'Đã kết nối · $feature: cần chú ý';
  }

  @override
  String devicesOffline(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngoại tuyến',
    );
    return '$_temp0';
  }

  @override
  String get devicesShow => 'Hiện';

  @override
  String get devicesPin => 'Ghim lên đầu';

  @override
  String get devicesUnpin => 'Bỏ ghim';

  @override
  String get devicePinned => 'Đã ghim';

  @override
  String devicesStale(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thiết bị không thấy trong 30 ngày',
    );
    return '$_temp0';
  }

  @override
  String get devicesStaleReview => 'Gỡ…';

  @override
  String devicesStaleConfirm(String names, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Gỡ $names khỏi $_temp0?';
  }

  @override
  String get devicesStaleConfirmBody =>
      'Không thấy trong 30 ngày. Các thiết bị khác của bạn vẫn giữ chúng, và bạn có thể ghép đôi lại bất cứ lúc nào.';

  @override
  String get devicesStaleRemove => 'Gỡ';

  @override
  String get deviceRename => 'Đổi tên…';

  @override
  String deviceRenameTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Tên trên $_temp0';
  }

  @override
  String deviceRenameBody(String here, String device) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Chỉ $_temp0 dùng tên này. $device vẫn giữ tên riêng.';
  }

  @override
  String get deviceRenameSave => 'Lưu';

  @override
  String get deviceRenameReset => 'Dùng tên gốc';

  @override
  String deviceSameName(String name) {
    return 'Một thiết bị khác của bạn cũng tên là $name. Hãy đặt cho thiết bị này một tên dễ nhận ra.';
  }

  @override
  String deviceOwnName(String name) {
    return 'Tên gốc: $name';
  }

  @override
  String get activityFilterAll => 'Tất cả';

  @override
  String get sidebarFind => 'Tìm thiết bị';

  @override
  String sidebarNoMatch(String query) {
    return 'Không có thiết bị nào tên “$query”';
  }

  @override
  String dropOfflineCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngoại tuyến',
    );
    return '$_temp0';
  }

  @override
  String get emptyBody =>
      'Cài Ferret trên cả thiết bị kia rồi mở lên. Thiết bị sẽ hiện ở đây khi cả hai dùng chung Wi-Fi. Riêng iPhone thì ghép đôi bằng mã QR.';

  @override
  String get emptyBodyIphone =>
      'Cài Ferret trên cả máy tính rồi mở lên. Sau đó quét mã hiện ra.';

  @override
  String get emptyCantSee => 'Không thấy thiết bị?';

  @override
  String get welcomeNearbyBody =>
      'Nhấn Ghép đôi bên cạnh thiết bị kia. Chỉ cần làm một lần.';

  @override
  String get nearbyNotTheOne =>
      'Không phải thiết bị bạn cần? Hãy mở Ferret trên thiết bị kia.';

  @override
  String get activityTitle => 'Hoạt động';

  @override
  String get activitySeeAll => 'Xem tất cả';

  @override
  String get activityDismiss => 'Đóng';

  @override
  String get activityQuickLook => 'Xem nhanh';

  @override
  String get needsYouTitle => 'Cần bạn xử lý';

  @override
  String get activityEmpty =>
      'Chưa có gì. Hãy sao chép gì đó hoặc gửi một tệp.';

  @override
  String get activityNow => 'vừa xong';

  @override
  String activityMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count phút',
    );
    return '$_temp0';
  }

  @override
  String activityHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count giờ',
    );
    return '$_temp0';
  }

  @override
  String activityDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count ngày',
    );
    return '$_temp0';
  }

  @override
  String get footerDrag => 'Kéo tệp vào một thiết bị để gửi';

  @override
  String get footerKeepOpen =>
      'Giữ Ferret mở để đồng bộ. Nếu không, iOS sẽ tạm dừng nó.';

  @override
  String get footerNobody =>
      'Chưa kết nối. Mở Ferret trên thiết bị kia, dùng chung Wi-Fi.';

  @override
  String footerPausedUntil(String time) {
    return 'Tạm dừng đến $time';
  }

  @override
  String get footerPaused => 'Tạm dừng đến khi bạn cho chạy tiếp';

  @override
  String tipCopyHere(String device) {
    return 'Thử xem: sao chép gì đó ở đây, rồi dán trên $device.';
  }

  @override
  String tipCopyThere(String device) {
    return 'Thử xem: sao chép gì đó trên $device, rồi dán ở đây.';
  }

  @override
  String get tipDone => 'Vậy là xong.';

  @override
  String get tipDrag => 'Kéo tệp vào biểu tượng Ferret trên thanh menu để gửi.';

  @override
  String get tipDismiss => 'Đã hiểu';

  @override
  String get tipPaste =>
      'Ngán câu hỏi Cho phép dán? Cài đặt → Ferret → Dán từ ứng dụng khác → Cho phép';

  @override
  String get tipPasteOpen => 'Mở Cài đặt';

  @override
  String get doctorFirewall =>
      'Có thể Windows Firewall đang chặn Ferret.\n1. Nhấp Cho phép qua tường lửa, rồi chọn Có khi Windows hỏi.\n2. Thử lại.\nHoặc nhấp Mở Windows Firewall, chọn Thay đổi thiết đặt rồi đánh dấu Ferret.';

  @override
  String get doctorFixOpenFirewall => 'Mở Windows Firewall';

  @override
  String get sidebarHide => 'Ẩn thanh bên';

  @override
  String get sidebarShow => 'Hiện thanh bên';

  @override
  String get activityPaneHide => 'Ẩn Hoạt động';

  @override
  String get activityPaneShow => 'Hiện Hoạt động';

  @override
  String get sectionOverview => 'Tổng quan';

  @override
  String windowTitleSection(String device, String section) {
    return '$device — $section';
  }

  @override
  String get menuFile => 'Tệp';

  @override
  String get menuView => 'Xem';

  @override
  String get menuDevice => 'Thiết bị';

  @override
  String get menuWindow => 'Cửa sổ';

  @override
  String get menuSendFiles => 'Gửi tệp…';

  @override
  String get menuSendClipboard => 'Gửi bảng nhớ tạm';

  @override
  String get menuTakePhoto => 'Chụp ảnh';

  @override
  String menuTakePhotoWith(String device) {
    return 'Chụp ảnh bằng $device';
  }

  @override
  String get menuCloseWindow => 'Đóng cửa sổ';

  @override
  String get menuShowSidebar => 'Hiện thanh bên';

  @override
  String get menuHideSidebar => 'Ẩn thanh bên';

  @override
  String get menuBack => 'Quay lại';

  @override
  String get menuNextDevice => 'Thiết bị tiếp theo';

  @override
  String get menuPreviousDevice => 'Thiết bị trước';

  @override
  String get menuFixConnection => 'Sửa kết nối…';

  @override
  String get activityPaneNow => 'Hiện tại';

  @override
  String activityPaneRecent(String device) {
    return 'Gần đây với $device';
  }

  @override
  String activityPaneEmpty(String device) {
    return 'Những gì bạn gửi và nhận với $device sẽ hiện ở đây.';
  }

  @override
  String get menuShowActivityPane => 'Hiện khung Hoạt động';

  @override
  String get menuHideActivityPane => 'Ẩn khung Hoạt động';

  @override
  String get menuForgetDevice => 'Quên thiết bị này…';

  @override
  String get activityOpen => 'Mở';

  @override
  String sectionOffline(String device, String time) {
    return '$device đang ngoại tuyến. Cập nhật lần cuối $time.';
  }

  @override
  String sectionOfflineNoTime(String device) {
    return '$device đang ngoại tuyến. Đây là nội dung lần cuối.';
  }

  @override
  String doctorFirewallLinux(String firewall) {
    return '$firewall đang bật và sẽ chặn Ferret cho đến khi bạn cho phép.\n1. Nhấp Sao chép lệnh.\n2. Dán vào terminal rồi nhập mật khẩu.\n3. Thử lại.';
  }

  @override
  String get doctorFixCopyFirewallCommand => 'Sao chép lệnh';

  @override
  String get doctorFirewallAllowed =>
      'Windows Firewall cho phép Ferret trên mạng riêng tư. Vẫn không thấy? Đảm bảo mạng này được đặt là Riêng tư: Cài đặt → Mạng & Internet → Wi-Fi của bạn.';

  @override
  String get doctorFixAllowFirewall => 'Cho phép qua tường lửa';

  @override
  String get traySendClipboard => 'Gửi bảng nhớ tạm đến thiết bị của tôi';

  @override
  String get trayStillRunningTitle => 'Ferret vẫn đang chạy';

  @override
  String get trayStillRunningBody =>
      'Tìm nó trong khay hệ thống, cạnh đồng hồ. Thoát từ menu của nó.';

  @override
  String get noticeChannelTransfers => 'Truyền tệp';

  @override
  String get noticeChannelIncoming => 'Từ thiết bị của bạn';

  @override
  String get noticeChannelSuggestions => 'Gợi ý tiếp tục';

  @override
  String get noticeChannelFind => 'Tìm thiết bị';

  @override
  String get noticeChannelProblems => 'Sự cố kết nối';

  @override
  String get settingsStartAtLogin => 'Khởi động Ferret khi tôi đăng nhập';

  @override
  String settingsStartAtLoginBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Ferret mở trên thanh menu, để thiết bị của bạn kết nối sẵn trước khi cần.',
        'other': 'Ferret khởi động trong khay hệ thống, để các thiết bị kết nối sẵn trước khi bạn cần.',
      },
    );
    return '$_temp0';
  }

  @override
  String get menuHelp => 'Trợ giúp';

  @override
  String get menuKeyboardShortcuts => 'Phím tắt';

  @override
  String get menuCheckNetwork => 'Kiểm tra mạng của tôi…';

  @override
  String get menuSponsor => 'Tài trợ Ferret…';

  @override
  String get shortcutsTitle => 'Phím tắt';

  @override
  String get shortcutSections => 'Các mục của thiết bị đang chọn';

  @override
  String get shortcutSidebar => 'Hiện hoặc ẩn danh sách thiết bị';

  @override
  String get shortcutActivityPane => 'Hiện hoặc ẩn khung Hoạt động';

  @override
  String get shortcutsInWindow => 'Trong cửa sổ';

  @override
  String get shortcutsAnyApp => 'Từ mọi ứng dụng';

  @override
  String get shortcutRecentClips => 'Mục đã chép gần đây';

  @override
  String accessTitle(String device) {
    return 'Những gì $device được dùng';
  }

  @override
  String accessIntro(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '$device chỉ tiếp cận $_temp0 qua những mục đang bật ở đây, trực tiếp trong mạng của bạn. Tắt mục nào, mục đó dừng ngay trên cả hai thiết bị.';
  }

  @override
  String accessOffline(String device) {
    return '$device đang ngoại tuyến. Thay đổi của bạn có hiệu lực trước khi nó dùng lại được bất cứ thứ gì.';
  }

  @override
  String get accessSummaryAll => 'Đang bật tất cả';

  @override
  String get accessSummaryNone => 'Đang tắt tất cả';

  @override
  String accessSummarySome(int off, int total) {
    return 'Đang tắt $off/$total';
  }

  @override
  String get accessTurnAllOff => 'Tắt tất cả';

  @override
  String get accessTurnAllOn => 'Bật lại tất cả';

  @override
  String accessForgetHint(String device) {
    return 'Tắt tất cả vẫn giữ $device ở trạng thái ghép đôi. Để chặn hẳn kết nối, hãy quên thiết bị ở cuối trang của nó.';
  }

  @override
  String get accessClipboard => 'Những gì bạn sao chép, cả hai chiều';

  @override
  String get accessDrop => 'Tệp và liên kết bạn gửi, cả hai chiều';

  @override
  String get accessNotifications =>
      'Thông báo của điện thoại, cùng trả lời và thao tác bạn gửi lại';

  @override
  String get accessMessages =>
      'Tin nhắn và tên liên hệ của điện thoại, cùng tin nhắn bạn gửi từ máy tính';

  @override
  String get accessCalls => 'Ai đang gọi, cuộc gọi gần đây, nghe máy và gọi đi';

  @override
  String get accessHandoff =>
      'Trang hoặc nội dung bạn đang xem, để tiếp tục trên thiết bị kia';

  @override
  String get accessMedia =>
      'Nội dung đang phát, cùng phát, tạm dừng và chuyển bài từ thiết bị kia';

  @override
  String get accessMirroring =>
      'Xem màn hình điện thoại, mỗi lần đều phải được điện thoại đồng ý';

  @override
  String get accessRemoteInput =>
      'Di chuyển con trỏ và gõ phím, chỉ sau khi bạn cho phép';

  @override
  String get accessFind => 'Đổ chuông thiết bị để tìm';

  @override
  String get accessActions =>
      'Ngủ, khởi động lại, tắt máy, âm lượng và các thao tác của riêng bạn, chỉ sau khi bạn cho phép';

  @override
  String menubarTipControlled(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'máy Mac này',
        'windows': 'máy tính này',
        'other': 'máy tính này',
      },
    );
    return '$device đang điều khiển $_temp0';
  }

  @override
  String menubarTipScreenSeen(String device) {
    return '$device có thể thấy màn hình này';
  }

  @override
  String get deviceUpdateThere => 'Cần Ferret mới hơn';

  @override
  String get deviceUpdateHere => 'Cập nhật Ferret ở đây để kết nối';

  @override
  String updateThereTitle(String name) {
    return 'Cập nhật Ferret trên $name';
  }

  @override
  String updateThereBody(String name, String version, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '$name đang dùng Ferret cũ ($version) mà $_temp0 không còn kết nối được. Hãy cập nhật từ nơi bạn đã cài, rồi mở lên một lần. Hai thiết bị sẽ tự kết nối lại.';
  }

  @override
  String updateHereTitle(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Cập nhật Ferret trên $_temp0';
  }

  @override
  String updateHereBody(String name, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '$name đang dùng Ferret mới hơn mà $_temp0 chưa kết nối được. Hãy cập nhật Ferret ở đây, hai thiết bị sẽ tự kết nối lại.';
  }

  @override
  String get updateGet => 'Tải bản cập nhật';

  @override
  String replaceTitle(String name) {
    return 'Đây có phải $name mới của bạn?';
  }

  @override
  String replaceBody(String old) {
    return 'Từ đó đến nay không thấy $old. Nếu thay thế, thiết bị cũ sẽ bị gỡ khỏi mọi thiết bị của bạn, còn thiết bị này giữ nguyên tên, ghim và các quyền.';
  }

  @override
  String get replaceAction => 'Thay thiết bị cũ';

  @override
  String get replaceKeepBoth => 'Giữ cả hai';

  @override
  String whatsNewLine(String version) {
    return 'Đã cập nhật lên Ferret $version';
  }

  @override
  String get whatsNewAction => 'Có gì mới';

  @override
  String get settingsTipsAgain => 'Hiện lại mẹo';

  @override
  String get settingsTipsAgainDetail =>
      'Những gợi ý ngắn ở màn hình chính, chẳng hạn cách sao chép qua lại.';

  @override
  String get settingsTipsAgainDone => 'Mẹo đã trở lại, mỗi lần một mẹo.';

  @override
  String get settingsPrivacyPerDevice =>
      'Để chọn một thiết bị được dùng những gì, hãy mở thiết bị đó và xem mục Những gì thiết bị được dùng.';

  @override
  String get deviceAway => 'Đã kết nối · đang khóa';

  @override
  String doctorHotspot(String phone, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Không có Wi-Fi chung? Bật điểm phát sóng của $phone rồi kết nối $_temp0 vào đó. Ferret hoạt động qua điểm phát sóng, và dữ liệu giữa các thiết bị của bạn không dùng dữ liệu di động.';
  }

  @override
  String doctorHotspotAny(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'thiết bị kia',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Không có Wi-Fi chung? Bật điểm phát sóng của điện thoại rồi kết nối $_temp0 vào đó. Ferret hoạt động qua điểm phát sóng, và dữ liệu giữa các thiết bị của bạn không dùng dữ liệu di động.';
  }

  @override
  String doctorHotspotHere(String device) {
    return 'Không có Wi-Fi chung? Bật điểm phát sóng của điện thoại này rồi kết nối $device vào đó. Ferret hoạt động qua điểm phát sóng, và dữ liệu giữa các thiết bị của bạn không dùng dữ liệu di động.';
  }

  @override
  String webcamRow(String device) {
    return 'Dùng $device làm webcam';
  }

  @override
  String webcamTitle(String device) {
    return '$device làm webcam';
  }

  @override
  String get webcamIntro =>
      'Nhiều điện thoại Android chạy Android 14 trở lên tự làm webcam USB được. Không cần ứng dụng, không cần driver.';

  @override
  String webcamSteps(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return '1. Cắm $device vào $_temp0 bằng cáp USB.\n2. Trên $device, vuốt từ trên xuống và nhấn vào thông báo USB.\n3. Chọn Webcam.\n4. Trong ứng dụng gọi video, chọn điện thoại làm camera.';
  }

  @override
  String webcamMissing(String device) {
    return 'Không thấy Webcam trong danh sách? $device chưa có tính năng này. Điện thoại Pixel từ Pixel 6 trở đi đều có.';
  }

  @override
  String webcamOverWifi(String device) {
    return 'Không có cáp? Mục Dùng camera của $device gửi hình qua Wi-Fi, vào một cửa sổ Ferret. Ứng dụng gọi video chưa chọn được hình từ đó.';
  }

  @override
  String batteryLevel(String percent) {
    return 'Pin $percent';
  }

  @override
  String batteryCharging(String percent) {
    return 'Pin $percent, đang sạc';
  }

  @override
  String lowBatteryTitle(String device, int percent) {
    return '$device còn $percent%';
  }

  @override
  String get lowBatteryBody => 'Hãy sạc sớm để thiết bị vẫn kết nối.';

  @override
  String get settingsLowBattery => 'Báo pin yếu';

  @override
  String get settingsLowBatteryBody =>
      'Báo một lần khi một thiết bị của bạn còn 15%.';

  @override
  String get vpnRow => 'Kết nối khi ở xa';

  @override
  String vpnTitle(String device) {
    return 'Kết nối $device khi ở xa';
  }

  @override
  String vpnIntro(String device) {
    return 'Không cùng Wi-Fi? Nếu $device và thiết bị này cùng ở trong VPN của riêng bạn, như Tailscale, ZeroTier hoặc WireGuard, Ferret có thể kết nối qua đó. Không cần tài khoản Ferret, không có máy chủ Ferret: VPN là của bạn.';
  }

  @override
  String vpnSwitch(String device) {
    return 'Kết nối $device qua VPN của bạn';
  }

  @override
  String get vpnSwitchHint =>
      'Ferret luôn thử mạng cục bộ trước. Khi tắt, Ferret không bao giờ ra khỏi mạng đó.';

  @override
  String get vpnReachAt => 'Địa chỉ';

  @override
  String get vpnReachAtHint => '100.101.102.103 hoặc pixel.tail1234.ts.net';

  @override
  String get vpnSaveAddress => 'Lưu địa chỉ';

  @override
  String vpnAddresses(String device, String addresses) {
    return '$device đã chia sẻ địa chỉ VPN: $addresses. Địa chỉ ở trên là tùy chọn.';
  }

  @override
  String vpnNoAddresses(String device) {
    return '$device chưa chia sẻ địa chỉ VPN. Nó sẽ chia sẻ ở lần kết nối tới, nếu đang dùng VPN. Hoặc nhập địa chỉ ở trên.';
  }

  @override
  String get vpnSlow => 'Tệp lớn có thể chậm hơn so với khi ở nhà.';

  @override
  String vpnPrivacy(String device, String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'mac': 'máy Mac này',
        'windows': 'PC này',
        'phone': 'điện thoại này',
        'tablet': 'máy tính bảng này',
        'other': 'máy tính này',
      },
    );
    return 'Việc này hỏi $device địa chỉ VPN của nó. Địa chỉ của $_temp0 chỉ gửi tới thiết bị đã bật công tắc này cho nó.';
  }

  @override
  String get deviceReachedOverVpn => 'Đang kết nối qua VPN của bạn';

  @override
  String doctorVpnReachOn(String device) {
    return 'Ferret cũng thử kết nối $device qua VPN của bạn. Hãy chắc VPN đang bật trên cả hai thiết bị.';
  }

  @override
  String doctorVpnReachOff(String device) {
    return 'Đang ở xa? Nếu $device cũng ở trong VPN của bạn, Ferret có thể kết nối qua đó.';
  }

  @override
  String get doctorFixReachOverVpn => 'Kết nối qua VPN';

  @override
  String get iconDropChoose => 'Chọn thiết bị';

  @override
  String get iconDropShelf => 'Để lên kệ tạm';

  @override
  String get iconDropKept => 'Đã để lên kệ tạm';

  @override
  String iconDropSending(int count, String name) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đang gửi $count tệp đến $name',
      one: 'Đang gửi đến $name',
    );
    return '$_temp0';
  }

  @override
  String get iconDropUndo => 'Hoàn tác';

  @override
  String get localNetworkTitle => 'Tìm thiết bị của bạn';

  @override
  String get localNetworkBody =>
      'Ferret tìm và kết nối với các thiết bị của chính bạn trên Wi-Fi này. Android luôn hỏi trước khi cho ứng dụng làm vậy, nên Ferret cần bạn đồng ý. Không có gì rời khỏi mạng của bạn.';

  @override
  String get localNetworkAllow => 'Cho phép';

  @override
  String get localNetworkAllowTooltip =>
      'Cho Ferret kết nối các thiết bị của bạn trên Wi-Fi này';

  @override
  String get localNetworkBlocked =>
      'Android sẽ không hỏi lại. Trong Cài đặt, mở Quyền, rồi Thiết bị ở gần, và chọn Cho phép.';

  @override
  String get localNetworkOpenSettings => 'Mở Cài đặt';

  @override
  String get localNetworkOpenSettingsTooltip =>
      'Mở trang của Ferret trong Cài đặt Android';

  @override
  String get doctorLocalNetwork =>
      'Ferret chưa được phép dùng Wi-Fi này, nên không thể tìm hay kết nối thiết bị của bạn. Android hỏi trước khi bất kỳ ứng dụng nào làm vậy.';

  @override
  String get doctorLocalNetworkBlocked =>
      'Ferret không được phép dùng Wi-Fi này, và Android sẽ không hỏi lại. Trong Cài đặt, mở Quyền, rồi Thiết bị ở gần, và chọn Cho phép.';

  @override
  String get doctorLocalNetworkMac =>
      'macOS đang chặn Ferret trên mạng cục bộ, nên Ferret không tìm thấy hay kết nối được thiết bị của bạn. Mở Cài đặt hệ thống, rồi Quyền riêng tư & Bảo mật, rồi Mạng cục bộ, và bật Ferret.';

  @override
  String get doctorFixAllowLocalNetwork => 'Cho phép trên Wi-Fi này';

  @override
  String get localNetworkAskTitle => 'Tìm thiết bị của bạn trên Wi-Fi này';

  @override
  String get localNetworkAskBody =>
      'Ferret tìm các thiết bị của bạn trên Wi-Fi này. iOS sẽ hỏi một lần.';

  @override
  String get localNetworkAskDetail =>
      'Không có gì rời khỏi mạng của bạn, và Ferret chỉ tìm khi đang mở.';

  @override
  String get localNetworkAskContinue => 'Tiếp tục';

  @override
  String get localNetworkAskNotNow => 'Để sau';

  @override
  String get localNetworkDeniedTitle => 'Mạng cục bộ đang tắt cho Ferret';

  @override
  String get localNetworkDeniedBody =>
      'Nên Ferret không tìm thấy hay kết nối được thiết bị của bạn. Trong Cài đặt, mở Ferret và bật Mạng cục bộ.';

  @override
  String get doctorLocalNetworkIphone =>
      'Mạng cục bộ đang tắt cho Ferret, nên Ferret không tìm thấy hay kết nối được thiết bị của bạn. Trong Cài đặt, mở Ferret và bật Mạng cục bộ.';

  @override
  String doctorVpnRoute(String name, String device) {
    return 'VPN của bạn ($name) chuyển mọi thứ đi qua nó, kể cả những gì gửi cho $device ngay bên cạnh, nên Ferret không kết nối được. Trong ứng dụng VPN, hãy cho phép truy cập mạng cục bộ (thường gọi là Allow local LAN access). Trên máy tính công ty, hãy nhờ bộ phận IT.';
  }

  @override
  String get doctorFirewallRefused =>
      'Windows chưa thêm quy tắc tường lửa. Việc này cần quyền quản trị viên. Trên máy tính công ty, hãy nhờ bộ phận IT cho phép Ferret trên mạng riêng tư: TCP 47640 và 47642–47649, UDP 47641 và 5353.';

  @override
  String get doctorFirewallPublicNetwork =>
      'Windows coi mạng này là mạng công cộng, nên ẩn PC này khỏi các thiết bị khác của bạn. Ở quán cà phê thì vậy là tốt. Ở nhà hay ở chỗ làm:\n1. Nhấn Mở cài đặt mạng, rồi Thuộc tính.\n2. Chọn Mạng riêng tư.\n3. Thử lại.';

  @override
  String get doctorFirewallBlocked =>
      'Một quy tắc của Windows Firewall đang chặn Ferret. Windows thêm quy tắc này khi ai đó nhấn Hủy ở câu hỏi về quyền truy cập mạng.\n1. Nhấn Cho phép qua tường lửa, rồi Có khi Windows hỏi.\n2. Thử lại.';

  @override
  String get doctorFixOpenNetworkSettings => 'Mở cài đặt mạng';
}
