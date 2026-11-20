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
  String get barOpen => 'Mở kệ tạm';

  @override
  String dragAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Kéo cả $count mục ra, hoặc bấm để mở',
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
      'Thả tệp, ảnh, chữ hay liên kết lên thanh ở dưới cùng. Những gì bạn sao chép cũng hiện ở đây. Mọi thứ chỉ nằm trên máy tính này.';

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
  String get back => 'Quay lại';
}
