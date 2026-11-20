// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'shelf_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Vietnamese (`vi`).
class ShelfLocalizationsVi extends ShelfLocalizations {
  ShelfLocalizationsVi([String locale = 'vi']) : super(locale);

  @override
  String get title => 'Kệ tạm';

  @override
  String get barEmpty => 'Thả vào đây để giữ lại';

  @override
  String get barDropOver => 'Thả để giữ lại';

  @override
  String barCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục',
    );
    return '$_temp0';
  }

  @override
  String barHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count mục, đang ẩn',
    );
    return '$_temp0';
  }

  @override
  String get barOpen => 'Mở danh sách';

  @override
  String dragAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kéo cả $count mục ra',
    );
    return '$_temp0';
  }

  @override
  String allTile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Cả $count',
    );
    return '$_temp0';
  }

  @override
  String get clear => 'Dọn';

  @override
  String get clearTooltip => 'Bỏ mọi thứ khỏi kệ tạm';

  @override
  String clearConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Dọn $count',
    );
    return '$_temp0';
  }

  @override
  String clearConfirmTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Bỏ cả $count mục khỏi kệ tạm. Tệp vẫn ở chỗ cũ.',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Huỷ';

  @override
  String get remove => 'Bỏ';

  @override
  String removeTooltip(String name) {
    return 'Bỏ $name khỏi kệ tạm';
  }

  @override
  String get quickLook => 'Xem nhanh';

  @override
  String get showInFinder => 'Hiện trong Finder';

  @override
  String get copy => 'Sao chép';

  @override
  String get missing => 'Đã chuyển đi hoặc bị xoá';

  @override
  String get kindFile => 'Tệp';

  @override
  String get kindFolder => 'Thư mục';

  @override
  String get kindImage => 'Ảnh';

  @override
  String get kindText => 'Văn bản';

  @override
  String get kindLink => 'Liên kết';

  @override
  String get copiedHere => 'Đã sao chép';

  @override
  String get droppedHere => 'Đã thả vào';

  @override
  String fromDevice(String name) {
    return 'Từ $name';
  }

  @override
  String get hiddenItem => 'Đang ẩn';

  @override
  String get empty => 'Kệ tạm chưa có gì';

  @override
  String get emptyNote =>
      'Thả tệp, ảnh, chữ hay liên kết vào hộp ở dưới cùng. Mọi thứ chỉ nằm trên máy tính này.';

  @override
  String get hiddenNote =>
      'Đang ẩn vì xem trước riêng tư đang tắt trên máy tính này.';

  @override
  String get dragNote =>
      'Kéo bất cứ thứ gì ra ứng dụng khác, hoặc thả lên một thiết bị để gửi. Phím cách để xem trước.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Đã chọn $count',
    );
    return '$_temp0';
  }

  @override
  String get keepCopies => 'Giữ bản sao chép';

  @override
  String keepCopiesBody(String keep) {
    String _temp0 = intl.Intl.selectLogic(
      keep,
      {
        'untilQuit': 'Những gì bạn sao chép ở đây hay trên thiết bị khác cũng lên kệ tạm, cho tới khi bạn thoát Ferret. Mật khẩu thì không bao giờ.',
        'day': 'Những gì bạn sao chép ở đây hay trên thiết bị khác cũng lên kệ tạm, trong một ngày. Mật khẩu thì không bao giờ.',
        'other': 'Những gì bạn sao chép ở đây hay trên thiết bị khác cũng lên kệ tạm, trong 7 ngày. Mật khẩu thì không bao giờ.',
      },
    );
    return '$_temp0';
  }

  @override
  String get keepCopiesOffBody =>
      'Chỉ những gì bạn thả vào mới ở lại đây. Ferret không theo dõi bộ nhớ tạm cho kệ tạm.';

  @override
  String get copiesFor => 'Giữ trong';

  @override
  String get copiesForTooltip =>
      'Bản sao chép nằm trên kệ tạm bao lâu. Những gì bạn thả vào thì ở lại tới khi bạn bỏ đi.';

  @override
  String copiesForShort(String keep) {
    String _temp0 = intl.Intl.selectLogic(
      keep,
      {
        'untilQuit': 'Tới khi thoát',
        'day': '1 ngày',
        'other': '7 ngày',
      },
    );
    return '$_temp0';
  }

  @override
  String copiesForChoice(String keep) {
    String _temp0 = intl.Intl.selectLogic(
      keep,
      {
        'untilQuit': 'Tới khi bạn thoát Ferret',
        'day': 'Một ngày',
        'other': '7 ngày',
      },
    );
    return '$_temp0';
  }

  @override
  String get summaryCopies => 'Giữ bản sao chép';

  @override
  String get summaryDropped => 'Chỉ những gì bạn thả';

  @override
  String get back => 'Quay lại';
}
