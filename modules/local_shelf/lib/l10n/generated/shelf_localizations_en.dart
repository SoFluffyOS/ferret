// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'shelf_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class ShelfLocalizationsEn extends ShelfLocalizations {
  ShelfLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get title => 'Shelf';

  @override
  String get barEmpty => 'Drop here to keep it for later';

  @override
  String get barDropOver => 'Drop to keep it';

  @override
  String barCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items',
      one: '1 item',
    );
    return '$_temp0';
  }

  @override
  String barHidden(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count items, hidden',
      one: '1 item, hidden',
    );
    return '$_temp0';
  }

  @override
  String get barOpen => 'Open the shelf';

  @override
  String dragAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Drag all $count out, or click to open',
      one: 'Drag it out, or click to open',
    );
    return '$_temp0';
  }

  @override
  String get clear => 'Clear';

  @override
  String get clearTooltip => 'Take everything off the shelf';

  @override
  String clearConfirm(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Clear $count',
    );
    return '$_temp0';
  }

  @override
  String clearConfirmTooltip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Take all $count off the shelf. Files stay where they are.',
      one: 'Take it off the shelf. The file stays where it is.',
    );
    return '$_temp0';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get remove => 'Remove';

  @override
  String removeTooltip(String name) {
    return 'Take $name off the shelf';
  }

  @override
  String get missing => 'Moved or deleted';

  @override
  String get kindFile => 'File';

  @override
  String get kindFolder => 'Folder';

  @override
  String get kindImage => 'Picture';

  @override
  String get kindText => 'Text';

  @override
  String get kindLink => 'Link';

  @override
  String get copiedHere => 'Copied';

  @override
  String get droppedHere => 'Dropped';

  @override
  String fromDevice(String name) {
    return 'From $name';
  }

  @override
  String get hiddenItem => 'Hidden';

  @override
  String get empty => 'Nothing on the shelf yet';

  @override
  String get emptyNote =>
      'Drop files, photos, text or links on the bar at the bottom. What you copy shows up here too. It all stays on this computer.';

  @override
  String get hiddenNote =>
      'Hidden while private previews are off on this computer.';

  @override
  String get dragNote =>
      'Drag anything out to another app, or onto a device to send it. Space shows a preview.';

  @override
  String selectedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count selected',
    );
    return '$_temp0';
  }

  @override
  String get back => 'Back';
}
