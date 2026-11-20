// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'messages_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class MessagesLocalizationsVi extends MessagesLocalizations {
  MessagesLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Tin nhắn';

  @override
  String cardTitle(String phone) {
    return 'Tin nhắn · $phone';
  }

  @override
  String get back => 'Quay lại';

  @override
  String get explainer => 'Đọc và trả lời tin nhắn ngay trên máy tính.';

  @override
  String get explainerDetail =>
      'Ferret đọc tin nhắn trên điện thoại này và chỉ hiện chúng trên máy tính của riêng bạn. Không có gì rời khỏi mạng của bạn. Danh bạ giúp cuộc trò chuyện có tên và ảnh.';

  @override
  String get rcsNote =>
      'Ứng dụng khác không đọc được các cuộc trò chuyện trong Google Messages (RCS, loại có dấu chấm đang nhập). Chúng vẫn đến máy tính dưới dạng thông báo, và bạn có thể trả lời tại đó.';

  @override
  String get turnOn => 'Bật';

  @override
  String get turnOff => 'Tắt';

  @override
  String get noTelephony =>
      'Thiết bị này không gửi hay nhận được tin nhắn nên không có gì để chia sẻ.';

  @override
  String get accessOff => 'Quyền SMS đang tắt';

  @override
  String get accessStillOff =>
      'Vẫn đang tắt. Hãy cho phép SMS để Ferret đọc được tin nhắn.';

  @override
  String get accessHowTo =>
      'Ferret cần quyền SMS để đọc và gửi tin nhắn, và Danh bạ để hiện tên.';

  @override
  String get allowAccess => 'Cho phép truy cập';

  @override
  String get accessBlocked =>
      'Android sẽ không hỏi lại. Mở cài đặt của Ferret, nhấn Quyền, rồi cho phép SMS và Danh bạ.';

  @override
  String get openAppSettings => 'Mở cài đặt';

  @override
  String get openSettingsFailed =>
      'Không mở được Cài đặt. Hãy tự mở Cài đặt Android → Ứng dụng → Ferret → Quyền.';

  @override
  String get accessOn => 'Máy tính của bạn có thể đọc và trả lời tin nhắn';

  @override
  String get contactsOff =>
      'Danh bạ đang tắt nên cuộc trò chuyện hiện số thay vì tên.';

  @override
  String get sendOff =>
      'Tính năng gửi đang tắt nên câu trả lời từ máy tính sẽ không được gửi đi.';

  @override
  String get offerDescription => 'Đọc và trả lời tin nhắn ngay trên máy tính.';

  @override
  String get phoneCardNeedsAccess =>
      'Tin nhắn đang bật, nhưng Ferret chưa đọc được tin nhắn của điện thoại này.';

  @override
  String get fix => 'Sửa';

  @override
  String get setUp => 'Thiết lập';

  @override
  String unreadCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin nhắn chưa đọc',
      zero: 'Không có tin nhắn chưa đọc',
    );
    return '$_temp0';
  }

  @override
  String get open => 'Mở';

  @override
  String get conversationsEmpty => 'Chưa có cuộc trò chuyện nào.';

  @override
  String statusOffline(String name) {
    return '$name đang ngoại tuyến. Bạn có thể đọc tin nhắn đã lưu và trả lời khi máy kết nối lại.';
  }

  @override
  String statusChecking(String name) {
    return 'Đang kết nối với $name…';
  }

  @override
  String statusOff(String name) {
    return 'Tin nhắn đang tắt trên $name. Trên $name: Ferret → Làm được nhiều hơn → Tin nhắn.';
  }

  @override
  String statusNoAccess(String name) {
    return 'Ferret trên $name chưa đọc được tin nhắn. Trên $name: mở Ferret và cho phép SMS.';
  }

  @override
  String statusUnreachable(String name) {
    return '$name không phản hồi. Trên $name: mở Ferret rồi thử lại.';
  }

  @override
  String get healthOk => 'Tin nhắn và trả lời';

  @override
  String healthOff(String name) {
    return 'Đang tắt trên $name';
  }

  @override
  String get healthNoAccess => 'Android đã tắt quyền truy cập của Ferret';

  @override
  String get healthChecking => 'Đang kiểm tra…';

  @override
  String healthOffHelp(String name) {
    return 'Trên $name: Ferret → Làm được nhiều hơn → Tin nhắn.';
  }

  @override
  String healthNoAccessHelp(String name) {
    return 'Trên $name: mở Ferret và cho phép SMS.';
  }

  @override
  String get healthOffThisPhone => 'Đang tắt trên điện thoại này';

  @override
  String get healthOffThisPhoneHelp =>
      'Trên điện thoại này: Cài đặt → Đến máy tính của bạn → Tin nhắn.';

  @override
  String get settingsNeedsAccess => 'Cần cấp quyền';

  @override
  String settingsNeedsAccessOn(String name) {
    return 'Cần cấp quyền trên $name';
  }

  @override
  String healthUnreachable(String name) {
    return '$name không phản hồi';
  }

  @override
  String get retry => 'Thử lại';

  @override
  String get syncing => 'Đang đồng bộ các cuộc trò chuyện gần đây…';

  @override
  String get loadingOlder => 'Đang tải tin nhắn cũ hơn…';

  @override
  String loadFailed(String name) {
    return 'Không tải được tin nhắn từ $name.';
  }

  @override
  String get pickConversation => 'Chọn một cuộc trò chuyện';

  @override
  String get composerHint => 'Tin nhắn văn bản';

  @override
  String get send => 'Gửi';

  @override
  String composerOffline(String name) {
    return 'Trả lời khi $name kết nối lại.';
  }

  @override
  String composerGroup(String name) {
    return 'Tin nhắn nhóm cần MMS, mà chỉ ứng dụng nhắn tin của $name mới gửi được. Hãy trả lời trên $name.';
  }

  @override
  String composerNoSend(String name) {
    return 'Tính năng gửi đang tắt trên $name. Trên $name: mở Ferret và cho phép SMS để trả lời từ đây.';
  }

  @override
  String get sending => 'Đang gửi…';

  @override
  String notSentBecause(String reason) {
    return 'Chưa gửi được. $reason';
  }

  @override
  String outcomeOffline(String name) {
    return '$name chưa kết nối.';
  }

  @override
  String outcomeNoAccess(String name) {
    return 'Ferret chưa được phép gửi tin nhắn trên $name. Trên $name: mở Ferret và cho phép SMS.';
  }

  @override
  String get outcomeNoRecipient => 'Cuộc trò chuyện này không có người nhận.';

  @override
  String outcomeGroup(String name) {
    return 'Tin nhắn nhóm chỉ gửi được từ $name.';
  }

  @override
  String outcomeNoService(String name) {
    return '$name không có sóng.';
  }

  @override
  String outcomeTimeout(String name) {
    return '$name không xác nhận kịp. Hãy kiểm tra cuộc trò chuyện trên $name trước khi gửi lại.';
  }

  @override
  String outcomeFailed(String name) {
    return '$name không gửi được. Hãy gửi lại, hoặc gửi từ $name.';
  }

  @override
  String get retrySend => 'Gửi lại';

  @override
  String get discard => 'Bỏ';

  @override
  String get kindFailed => 'Chưa gửi được';

  @override
  String get kindQueued => 'Đang chờ gửi';

  @override
  String get kindOutbox => 'Đang gửi…';

  @override
  String get photo => 'Ảnh';

  @override
  String get video => 'Video';

  @override
  String get audio => 'Âm thanh';

  @override
  String get contactCard => 'Liên hệ';

  @override
  String get attachment => 'Tệp đính kèm';

  @override
  String attachmentFrom(String name) {
    return '$name: Tệp đính kèm';
  }

  @override
  String latestFrom(String name, String text) {
    return '$name: $text';
  }

  @override
  String get today => 'Hôm nay';

  @override
  String get yesterday => 'Hôm qua';

  @override
  String get you => 'Bạn';

  @override
  String imageFailed(String name) {
    return 'Không tải được ảnh từ $name.';
  }

  @override
  String get rcsComputerNote =>
      'Cuộc trò chuyện RCS không hiện ở đây. Chúng đến cùng thông báo của điện thoại, và bạn có thể trả lời tại đó.';

  @override
  String get replyAction => 'Trả lời';

  @override
  String activityTitle(String sender, String device) {
    return '$sender · $device';
  }

  @override
  String privateCover(String device) {
    return 'Tin nhắn mới trên $device';
  }

  @override
  String get markReadAction => 'Đánh dấu đã đọc';

  @override
  String get replyFailedTitle => 'Chưa gửi được câu trả lời';

  @override
  String noticeTitleCount(String name, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count tin mới',
    );
    return '$name · $_temp0';
  }

  @override
  String noticeGroupBody(String sender, String text) {
    return '$sender: $text';
  }

  @override
  String get notifySetting => 'Hiện tin nhắn mới dưới dạng thông báo';

  @override
  String get notifyDetail =>
      'Kèm nút Trả lời, trừ khi cuộc trò chuyện đang mở sẵn ở đây.';

  @override
  String get forgetHistory => 'Xoá tin đã lưu';

  @override
  String forgetDetail(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Ferret lưu các tin nhắn gần đây trên $_temp0 để vẫn xem được khi điện thoại ngoại tuyến.';
  }

  @override
  String get forgetConfirmTitle => 'Xoá tin nhắn đã lưu?';

  @override
  String forgetConfirmBody(String here) {
    String _temp0 = intl.Intl.selectLogic(
      here,
      {
        'macOS': 'Mac này',
        'windows': 'PC này',
        'other': 'máy tính này',
      },
    );
    return 'Thao tác này xoá các tin nhắn đã lưu trên $_temp0. Điện thoại của bạn vẫn giữ nguyên tất cả.';
  }

  @override
  String get forgetConfirm => 'Xoá';

  @override
  String get cancel => 'Huỷ';
}
