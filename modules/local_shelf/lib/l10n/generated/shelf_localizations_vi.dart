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
      one: 'Kéo ra',
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
  String get clearTooltip => 'Gỡ mọi thứ khỏi kệ tạm';

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
      other: 'Gỡ cả $count mục khỏi kệ tạm. Tệp vẫn ở chỗ cũ.',
      one: 'Gỡ mục này khỏi kệ tạm. Tệp vẫn ở chỗ cũ.',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Hủy';

  @override
  String get remove => 'Gỡ';

  @override
  String removeTooltip(String name) {
    return 'Gỡ $name khỏi kệ tạm';
  }

  @override
  String get quickLook => 'Xem nhanh';

  @override
  String get showInFinder => 'Hiện trong Finder';

  @override
  String get copy => 'Sao chép';

  @override
  String get missing => 'Đã chuyển đi hoặc bị xóa';

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
      'Kéo bất cứ thứ gì ra ứng dụng khác, hoặc thả lên một thiết bị để gửi. Nhấn phím cách để xem trước.';

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
  String get keepCopies => 'Giữ bản sao';

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
      'Chỉ những gì bạn thả vào mới ở lại đây. Ferret không theo dõi bảng nhớ tạm cho kệ tạm.';

  @override
  String get copiesFor => 'Giữ trong';

  @override
  String get copiesForTooltip =>
      'Bản sao nằm trên kệ tạm bao lâu. Những gì bạn thả vào thì ở lại tới khi bạn gỡ đi.';

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
  String get summaryCopies => 'Giữ bản sao';

  @override
  String get summaryDropped => 'Chỉ những gì bạn thả';

  @override
  String get back => 'Quay lại';

  @override
  String get reachTitle => 'Khi bạn kéo';

  @override
  String get springOpen => 'Mở khi giữ chuột';

  @override
  String get springOpenBody =>
      'Kéo một thứ và giữ yên trên biểu tượng ở thanh menu, Ferret sẽ mở kèm kệ tạm sau độ trễ nạp lò xo của máy Mac.';

  @override
  String get boxOnDrag => 'Hộp khi kéo';

  @override
  String get boxOnDragBody =>
      'Một kệ tạm nhỏ trượt vào ở cạnh màn hình khi bạn kéo tệp hoặc ảnh. Giữ fn để bỏ qua một lần.';

  @override
  String get boxShows => 'Hiện khi';

  @override
  String get boxShowsTooltip =>
      'Khi nào hộp trượt vào: khi thao tác kéo tới gần cạnh màn hình, hoặc ngay khi bạn bắt đầu kéo.';

  @override
  String boxShowsShort(String when) {
    String _temp0 = intl.Intl.selectLogic(
      when,
      {
        'atEdge': 'Ở cạnh',
        'other': 'Ngay lập tức',
      },
    );
    return '$_temp0';
  }

  @override
  String boxShowsChoice(String when) {
    String _temp0 = intl.Intl.selectLogic(
      when,
      {
        'atEdge': 'Khi tôi kéo tới cạnh',
        'other': 'Ngay khi tôi kéo',
      },
    );
    return '$_temp0';
  }

  @override
  String get shake => 'Lắc để hiện';

  @override
  String get shakeBody =>
      'Lắc con trỏ khi đang kéo, kệ tạm sẽ hiện ngay bên cạnh.';

  @override
  String get sensitivity => 'Độ nhạy';

  @override
  String get sensitivityTooltip => 'Cần lắc nhiều hay ít. Cao là ít nhất.';

  @override
  String sensitivityChoice(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'low': 'Thấp',
        'normal': 'Vừa',
        'other': 'Cao',
      },
    );
    return '$_temp0';
  }

  @override
  String get shiftSummons => 'Giữ ⇧ thay vì lắc';

  @override
  String get shiftSummonsBody =>
      'Giữ ⇧ khi đang kéo để gọi kệ tạm mà không cần lắc.';

  @override
  String get ignoredTitle => 'Bỏ qua thao tác kéo từ';

  @override
  String get ignoredNone =>
      'Chưa có ứng dụng nào. Kéo từ mọi ứng dụng đều có thể gọi kệ tạm.';

  @override
  String get ignoredAdd => 'Thêm ứng dụng';

  @override
  String get ignoredAddTooltip =>
      'Chọn một ứng dụng đang mở mà thao tác kéo từ đó không bao giờ gọi kệ tạm.';

  @override
  String ignoredRemove(String app) {
    return 'Thôi bỏ qua $app';
  }

  @override
  String get iconDropTitle => 'Thả lên biểu tượng';

  @override
  String get iconDropTooltip =>
      'Điều gì xảy ra khi bạn thả lên biểu tượng ở thanh menu mà không chờ nó mở.';

  @override
  String iconDropShort(String mode) {
    String _temp0 = intl.Intl.selectLogic(
      mode,
      {
        'sendToLast': 'Thiết bị vừa dùng',
        'shelf': 'Kệ tạm',
        'other': 'Hỏi',
      },
    );
    return '$_temp0';
  }

  @override
  String iconDropChoice(String mode) {
    String _temp0 = intl.Intl.selectLogic(
      mode,
      {
        'sendToLast': 'Gửi đến thiết bị vừa dùng',
        'shelf': 'Để lên kệ tạm',
        'other': 'Luôn hỏi',
      },
    );
    return '$_temp0';
  }

  @override
  String iconDropBody(String mode) {
    String _temp0 = intl.Intl.selectLogic(
      mode,
      {
        'sendToLast': 'Tệp được gửi đến thiết bị duy nhất đang kết nối, hoặc thiết bị bạn vừa dùng, và bạn có 3 giây để hoàn tác. Văn bản và liên kết được để lên kệ tạm.',
        'shelf': 'Mọi thứ bạn thả đều ở lại máy Mac này, trên kệ tạm.',
        'other': 'Ferret mở ngay khi bạn kéo tới biểu tượng, để bạn chọn thiết bị hoặc kệ tạm.',
      },
    );
    return '$_temp0';
  }
}
