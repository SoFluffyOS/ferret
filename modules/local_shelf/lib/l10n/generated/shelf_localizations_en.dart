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
  String get barOpen => 'Open the list';

  @override
  String dragAll(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Drag all $count out',
      one: 'Drag it out',
    );
    return '$_temp0';
  }

  @override
  String allTile(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'All $count',
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
  String get quickLook => 'Quick Look';

  @override
  String get showInFinder => 'Show in Finder';

  @override
  String get copy => 'Copy';

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
      'Drop files, photos, text or links on the box at the bottom. It all stays on this computer.';

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
  String get keepCopies => 'Keep copies';

  @override
  String keepCopiesBody(String keep) {
    String _temp0 = intl.Intl.selectLogic(
      keep,
      {
        'untilQuit': 'What you copy here or on your other devices goes on the shelf too, until you quit Ferret. Passwords never do.',
        'day': 'What you copy here or on your other devices goes on the shelf too, for a day. Passwords never do.',
        'other': 'What you copy here or on your other devices goes on the shelf too, for 7 days. Passwords never do.',
      },
    );
    return '$_temp0';
  }

  @override
  String get keepCopiesOffBody =>
      'Only what you drop stays here. Ferret doesn\'t watch your clipboard for the shelf.';

  @override
  String get copiesFor => 'Keep them';

  @override
  String get copiesForTooltip =>
      'How long copies stay on the shelf. What you drop stays until you take it off.';

  @override
  String copiesForShort(String keep) {
    String _temp0 = intl.Intl.selectLogic(
      keep,
      {
        'untilQuit': 'Until quit',
        'day': '1 day',
        'other': '7 days',
      },
    );
    return '$_temp0';
  }

  @override
  String copiesForChoice(String keep) {
    String _temp0 = intl.Intl.selectLogic(
      keep,
      {
        'untilQuit': 'Until you quit Ferret',
        'day': 'For a day',
        'other': 'For 7 days',
      },
    );
    return '$_temp0';
  }

  @override
  String get summaryCopies => 'Keeps copies';

  @override
  String get summaryDropped => 'Only what you drop';

  @override
  String get back => 'Back';

  @override
  String get reachTitle => 'While you drag';

  @override
  String get springOpen => 'Open on hover';

  @override
  String get springOpenBody =>
      'Rest a drag on the menubar icon and Ferret opens with the shelf, after your Mac\'s spring-loading delay.';

  @override
  String get boxOnDrag => 'Box on drag';

  @override
  String get boxOnDragBody =>
      'A small shelf slides in at the side of the screen while you drag files or photos. Hold fn to skip it once.';

  @override
  String get boxShows => 'Shows';

  @override
  String get boxShowsTooltip =>
      'When the box slides in: once your drag nears the side of the screen, or as soon as you start dragging.';

  @override
  String boxShowsShort(String when) {
    String _temp0 = intl.Intl.selectLogic(
      when,
      {
        'atEdge': 'At the edge',
        'other': 'Right away',
      },
    );
    return '$_temp0';
  }

  @override
  String boxShowsChoice(String when) {
    String _temp0 = intl.Intl.selectLogic(
      when,
      {
        'atEdge': 'When I drag to the edge',
        'other': 'As soon as I drag',
      },
    );
    return '$_temp0';
  }

  @override
  String get shake => 'Shake to show';

  @override
  String get shakeBody =>
      'Shake the pointer while dragging and the shelf shows up right next to it.';

  @override
  String get sensitivity => 'Sensitivity';

  @override
  String get sensitivityTooltip =>
      'How much shaking it takes. High needs the least.';

  @override
  String sensitivityChoice(String level) {
    String _temp0 = intl.Intl.selectLogic(
      level,
      {
        'low': 'Low',
        'normal': 'Normal',
        'other': 'High',
      },
    );
    return '$_temp0';
  }

  @override
  String get shiftSummons => 'Hold ⇧ instead';

  @override
  String get shiftSummonsBody =>
      'Hold ⇧ while dragging to bring the shelf without shaking.';

  @override
  String get ignoredTitle => 'Ignore drags from';

  @override
  String get ignoredNone =>
      'No apps. Drags from every app can bring the shelf.';

  @override
  String get ignoredAdd => 'Add app';

  @override
  String get ignoredAddTooltip =>
      'Pick an open app whose drags never bring the shelf.';

  @override
  String ignoredRemove(String app) {
    return 'Stop ignoring $app';
  }

  @override
  String get iconDropTitle => 'Dropping on the icon';

  @override
  String get iconDropTooltip =>
      'What happens when you let go on the menubar icon without waiting for it to open.';

  @override
  String iconDropShort(String mode) {
    String _temp0 = intl.Intl.selectLogic(
      mode,
      {
        'sendToLast': 'Last device',
        'shelf': 'Shelf',
        'other': 'Ask',
      },
    );
    return '$_temp0';
  }

  @override
  String iconDropChoice(String mode) {
    String _temp0 = intl.Intl.selectLogic(
      mode,
      {
        'sendToLast': 'Send to my last device',
        'shelf': 'Put it on the shelf',
        'other': 'Ask every time',
      },
    );
    return '$_temp0';
  }

  @override
  String iconDropBody(String mode) {
    String _temp0 = intl.Intl.selectLogic(
      mode,
      {
        'sendToLast': 'Files go to your only connected device, or the one you used last, with 3 seconds to undo. Text and links go on the shelf.',
        'shelf': 'Everything you drop stays on this Mac, on the shelf.',
        'other': 'Ferret opens as soon as your drag reaches the icon, so you pick a device or the shelf.',
      },
    );
    return '$_temp0';
  }
}
