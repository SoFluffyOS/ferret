// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'actions_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ActionsLocalizationsVi extends ActionsLocalizations {
  ActionsLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Thao tác trên máy tính';

  @override
  String get dismiss => 'Đóng';

  @override
  String get cancel => 'Huỷ';

  @override
  String get allowOnce => 'Cho phép một lần';

  @override
  String get allowAlways => 'Luôn cho phép';

  @override
  String get dontAllow => 'Không cho phép';

  @override
  String get actionSleep => 'Ngủ';

  @override
  String get actionRestart => 'Khởi động lại';

  @override
  String get actionShutDown => 'Tắt máy';

  @override
  String get actionMute => 'Tắt hoặc bật tiếng';

  @override
  String get actionVolumeUp => 'Tăng âm lượng';

  @override
  String get actionVolumeDown => 'Giảm âm lượng';

  @override
  String get actionVolume => 'Âm lượng';

  @override
  String consentSleep(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép $device đưa $_temp0 vào chế độ ngủ?';
  }

  @override
  String consentRestart(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép $device khởi động lại $_temp0?';
  }

  @override
  String consentShutDown(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép $device tắt $_temp0?';
  }

  @override
  String consentSound(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép $device đổi âm lượng của $_temp0?';
  }

  @override
  String consentCustom(String device, String name, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép $device chạy “$name” trên $_temp0?';
  }

  @override
  String consentBody(String device) {
    return 'Chọn Luôn cho phép thì lần sau $device làm việc này mà không cần hỏi. Bạn có thể thu lại quyền đó trên trang của thiết bị.';
  }

  @override
  String get consentCountsDown =>
      'Bạn có 10 giây để huỷ trước khi việc đó diễn ra.';

  @override
  String get consentCommandLabel => 'Nó chạy đúng lệnh này:';

  @override
  String consentCommandNotice(String command) {
    return 'Chạy: $command';
  }

  @override
  String countdownRestart(String computer, int seconds) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds giây',
    );
    return 'Sẽ khởi động lại $_temp0 sau $_temp1';
  }

  @override
  String countdownShutDown(String computer, int seconds) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    String _temp1 = intl.Intl.pluralLogic(
      seconds,
      locale: localeName,
      other: '$seconds giây',
    );
    return 'Sẽ tắt $_temp0 sau $_temp1';
  }

  @override
  String countdownBody(String device) {
    return '$device đã yêu cầu. Hãy lưu công việc của bạn, hoặc huỷ.';
  }

  @override
  String countdownNoticeRestart(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device đang khởi động lại $_temp0';
  }

  @override
  String countdownNoticeShutDown(String device, String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return '$device đang tắt $_temp0';
  }

  @override
  String get countdownNoticeBody =>
      'Việc này diễn ra sau 10 giây. Bấm Huỷ để dừng lại.';

  @override
  String recordTitle(String action, String device) {
    return '$action, do $device yêu cầu';
  }

  @override
  String get recordDone => 'Xong';

  @override
  String get recordDenied => 'Bạn đã từ chối.';

  @override
  String get recordNotAnswered => 'Không ai trả lời ở đây.';

  @override
  String get recordCancelled => 'Đã huỷ ở đây.';

  @override
  String get recordFailed => 'Không thực hiện được.';

  @override
  String recordExitCode(int code) {
    return 'Kết thúc với mã $code.';
  }

  @override
  String recordTimedOut(int seconds) {
    return 'Đã dừng: chạy lâu hơn $seconds giây.';
  }

  @override
  String get recordNotStarted =>
      'Không khởi chạy được. Hãy kiểm tra lệnh trong Cài đặt.';

  @override
  String groupTitle(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'Máy tính này',
      },
    );
    return '$_temp0';
  }

  @override
  String groupHint(String device) {
    return 'Lần đầu, $device sẽ hỏi trên màn hình của nó.';
  }

  @override
  String get groupYourActions => 'Thao tác của bạn';

  @override
  String get restartEllipsis => 'Khởi động lại…';

  @override
  String get shutDownEllipsis => 'Tắt máy…';

  @override
  String confirmRestartTitle(String device) {
    return 'Khởi động lại $device?';
  }

  @override
  String confirmRestartBody(String device) {
    return 'Máy đếm ngược 10 giây trước, và ai đang ở $device cũng có thể huỷ. Ferret kết nối lại khi máy khởi động xong.';
  }

  @override
  String confirmShutDownTitle(String device) {
    return 'Tắt $device?';
  }

  @override
  String confirmShutDownBody(String device) {
    return 'Máy đếm ngược 10 giây trước, và ai đang ở $device cũng có thể huỷ. Khi máy đã tắt, Ferret không thể kết nối cho đến khi có người bật lại.';
  }

  @override
  String outAsking(String device, String action) {
    return 'Đang yêu cầu $device: $action…';
  }

  @override
  String outAskingDetail(String device) {
    return 'Nếu máy hỏi, hãy trả lời trên $device.';
  }

  @override
  String outCountingDown(String device) {
    return '$device đếm ngược 10 giây trước.';
  }

  @override
  String outSleep(String device) {
    return '$device đang chuyển sang chế độ ngủ';
  }

  @override
  String outRestart(String device) {
    return '$device đang khởi động lại';
  }

  @override
  String outShutDown(String device) {
    return '$device đang tắt';
  }

  @override
  String outCustom(String device, String name) {
    return '$device đã chạy “$name”';
  }

  @override
  String outDenied(String device) {
    return '$device đã từ chối';
  }

  @override
  String outNotAnswered(String device) {
    return 'Không ai trả lời trên $device';
  }

  @override
  String get outNotAnsweredDetail =>
      'Câu hỏi hiện trên màn hình của máy trong một phút. Hãy thử lại khi có người ở đó.';

  @override
  String outBusy(String device) {
    return '$device đang bận với một yêu cầu khác';
  }

  @override
  String outTurnedOff(String device) {
    return 'Thao tác đang tắt trên $device';
  }

  @override
  String get outTurnedOffDetail => 'Bật trên máy đó: Cài đặt → Điều khiển.';

  @override
  String outUnknown(String device) {
    return '$device không còn thao tác đó';
  }

  @override
  String outFailed(String device) {
    return 'Không thực hiện được trên $device';
  }

  @override
  String outFailedCode(String name, int code) {
    return '“$name” kết thúc với mã $code trên máy đó.';
  }

  @override
  String outCancelled(String device) {
    return 'Đã bị huỷ trên $device';
  }

  @override
  String outTimedOut(String name, String device) {
    return '“$name” chạy quá lâu trên $device';
  }

  @override
  String get outTimedOutDetail => 'Lệnh đã bị dừng trên máy đó.';

  @override
  String settingsEnabled(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Cho phép thiết bị của bạn chạy thao tác trên $_temp0';
  }

  @override
  String get settingsEnabledBody =>
      'Ngủ, khởi động lại, tắt máy, âm lượng và các thao tác của riêng bạn. Mỗi thiết bị sẽ hỏi ở đây trong lần đầu.';

  @override
  String get settingsPerDevice =>
      'Những gì một thiết bị được làm mà không cần hỏi nằm trên trang của thiết bị đó.';

  @override
  String get yourActionsTitle => 'Thao tác của bạn';

  @override
  String get yourActionsEmpty =>
      'Một lệnh, một tập lệnh hay một phím tắt của bạn, kèm một cái tên. Thiết bị của bạn chỉ thấy cái tên đó.';

  @override
  String get addAction => 'Thêm thao tác';

  @override
  String get editAction => 'Sửa';

  @override
  String get editNewTitle => 'Thao tác mới';

  @override
  String get editTitle => 'Sửa thao tác';

  @override
  String get editName => 'Tên';

  @override
  String get editNameHint => 'Chúc ngủ ngon';

  @override
  String get editCommand => 'Lệnh, tập lệnh hoặc phím tắt';

  @override
  String editCommandHelp(int seconds) {
    return 'Lệnh chạy dưới tên bạn, không qua shell: không có dấu | hay &&. Hãy đặt chúng trong một tập lệnh rồi nhập đường dẫn. Lệnh bị dừng sau $seconds giây.';
  }

  @override
  String get editCommandChanged =>
      'Lệnh mới sẽ khiến mọi thiết bị phải hỏi lại.';

  @override
  String get save => 'Lưu';

  @override
  String get remove => 'Xoá';

  @override
  String get historyTitle => 'Lịch sử';

  @override
  String get historyEmpty => 'Chưa có gì được chạy.';

  @override
  String get clearHistory => 'Xoá lịch sử';

  @override
  String get summaryOff => 'Tắt';

  @override
  String get summaryOn => 'Hỏi trước';

  @override
  String summaryOwn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thao tác của bạn',
    );
    return '$_temp0';
  }

  @override
  String permissionSleep(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Đưa $_temp0 vào chế độ ngủ mà không cần hỏi';
  }

  @override
  String permissionRestart(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Khởi động lại $_temp0 mà không cần hỏi';
  }

  @override
  String permissionShutDown(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Tắt $_temp0 mà không cần hỏi';
  }

  @override
  String permissionSound(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Đổi âm lượng của $_temp0 mà không cần hỏi';
  }

  @override
  String permissionCustom(String name) {
    return 'Chạy “$name” mà không cần hỏi';
  }

  @override
  String healthOffers(int count, String device) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count thao tác',
    );
    return '$_temp0. $device sẽ hỏi trong lần đầu.';
  }

  @override
  String healthRemoteOff(String device) {
    return 'Thao tác đang tắt trên $device';
  }

  @override
  String healthRemoteOffHelp(String device) {
    return 'Trên $device, mở Cài đặt → Điều khiển rồi bật Thao tác trên máy tính.';
  }

  @override
  String get healthHostAsks => 'Hỏi bạn ở đây trong lần đầu';

  @override
  String healthHostOff(String computer) {
    String _temp0 = intl.Intl.selectLogic(
      computer,
      {
        'mac': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Thao tác đang tắt trên $_temp0';
  }

  @override
  String get healthHostOffHelp =>
      'Bật Thao tác trên máy tính trong Cài đặt → Điều khiển.';
}
