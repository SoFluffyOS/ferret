import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'shelf_localizations_en.dart';
import 'shelf_localizations_vi.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of ShelfLocalizations
/// returned by `ShelfLocalizations.of(context)`.
///
/// Applications need to include `ShelfLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/shelf_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: ShelfLocalizations.localizationsDelegates,
///   supportedLocales: ShelfLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the ShelfLocalizations.supportedLocales
/// property.
abstract class ShelfLocalizations {
  ShelfLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static ShelfLocalizations of(BuildContext context) {
    return Localizations.of<ShelfLocalizations>(context, ShelfLocalizations)!;
  }

  static const LocalizationsDelegate<ShelfLocalizations> delegate =
      _ShelfLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('vi'),
  ];

  /// Name of the place at the bottom of the menubar popover where dropped and copied things are kept for later.
  ///
  /// In en, this message translates to:
  /// **'Shelf'**
  String get title;

  /// Hint on the empty shelf bar at the bottom of the popover. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Drop here to keep it for later'**
  String get barEmpty;

  /// The shelf bar while something is dragged over it.
  ///
  /// In en, this message translates to:
  /// **'Drop to keep it'**
  String get barDropOver;

  /// How many things are on the shelf.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String barCount(int count);

  /// The shelf bar while private previews are off on this computer: only how many things are on it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item, hidden} other{{count} items, hidden}}'**
  String barHidden(int count);

  /// Tooltip of the shelf bar: clicking it opens the shelf.
  ///
  /// In en, this message translates to:
  /// **'Open the shelf'**
  String get barOpen;

  /// Tooltip of the stack at the left of the shelf bar.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Drag it out, or click to open} other{Drag all {count} out, or click to open}}'**
  String dragAll(int count);

  /// Button: takes everything off the shelf. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// No description provided for @clearTooltip.
  ///
  /// In en, this message translates to:
  /// **'Take everything off the shelf'**
  String get clearTooltip;

  /// The Clear button asking once more before many things go. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{Clear {count}}}'**
  String clearConfirm(int count);

  /// No description provided for @clearConfirmTooltip.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Take it off the shelf. The file stays where it is.} other{Take all {count} off the shelf. Files stay where they are.}}'**
  String clearConfirmTooltip(int count);

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Button on one shelf item: takes it off the shelf. The file itself stays.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @removeTooltip.
  ///
  /// In en, this message translates to:
  /// **'Take {name} off the shelf'**
  String removeTooltip(String name);

  /// A file on the shelf that isn't where it was anymore.
  ///
  /// In en, this message translates to:
  /// **'Moved or deleted'**
  String get missing;

  /// No description provided for @kindFile.
  ///
  /// In en, this message translates to:
  /// **'File'**
  String get kindFile;

  /// No description provided for @kindFolder.
  ///
  /// In en, this message translates to:
  /// **'Folder'**
  String get kindFolder;

  /// No description provided for @kindImage.
  ///
  /// In en, this message translates to:
  /// **'Picture'**
  String get kindImage;

  /// No description provided for @kindText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get kindText;

  /// No description provided for @kindLink.
  ///
  /// In en, this message translates to:
  /// **'Link'**
  String get kindLink;

  /// Where a shelf item came from: copied on this computer.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copiedHere;

  /// Where a shelf item came from: dragged onto the shelf.
  ///
  /// In en, this message translates to:
  /// **'Dropped'**
  String get droppedHere;

  /// No description provided for @fromDevice.
  ///
  /// In en, this message translates to:
  /// **'From {name}'**
  String fromDevice(String name);

  /// Title of a shelf item whose contents are hidden because previews are off.
  ///
  /// In en, this message translates to:
  /// **'Hidden'**
  String get hiddenItem;

  /// No description provided for @empty.
  ///
  /// In en, this message translates to:
  /// **'Nothing on the shelf yet'**
  String get empty;

  /// No description provided for @emptyNote.
  ///
  /// In en, this message translates to:
  /// **'Drop files, photos, text or links on the bar at the bottom. It all stays on this computer.'**
  String get emptyNote;

  /// No description provided for @hiddenNote.
  ///
  /// In en, this message translates to:
  /// **'Hidden while private previews are off on this computer.'**
  String get hiddenNote;

  /// No description provided for @dragNote.
  ///
  /// In en, this message translates to:
  /// **'Drag anything out to another app, or onto a device to send it. Space shows a preview.'**
  String get dragNote;

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{{count} selected}}'**
  String selectedCount(int count);

  /// Switch: also put what is copied to the clipboard on the shelf. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Keep copies'**
  String get keepCopies;

  /// Under the Keep copies switch while it is on: how long copies stay.
  ///
  /// In en, this message translates to:
  /// **'{keep, select, untilQuit{What you copy here or on your other devices goes on the shelf too, until you quit Ferret. Passwords never do.} day{What you copy here or on your other devices goes on the shelf too, for a day. Passwords never do.} other{What you copy here or on your other devices goes on the shelf too, for 7 days. Passwords never do.}}'**
  String keepCopiesBody(String keep);

  /// Under the Keep copies switch while it is off.
  ///
  /// In en, this message translates to:
  /// **'Only what you drop stays here. Ferret doesn\'t watch your clipboard for the shelf.'**
  String get keepCopiesOffBody;

  /// Row title: how long copies stay on the shelf.
  ///
  /// In en, this message translates to:
  /// **'Keep them'**
  String get copiesFor;

  /// No description provided for @copiesForTooltip.
  ///
  /// In en, this message translates to:
  /// **'How long copies stay on the shelf. What you drop stays until you take it off.'**
  String get copiesForTooltip;

  /// Button label with the chosen time. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'{keep, select, untilQuit{Until quit} day{1 day} other{7 days}}'**
  String copiesForShort(String keep);

  /// Menu entries: how long copies stay on the shelf.
  ///
  /// In en, this message translates to:
  /// **'{keep, select, untilQuit{Until you quit Ferret} day{For a day} other{For 7 days}}'**
  String copiesForChoice(String keep);

  /// Settings row value: the shelf keeps what is copied.
  ///
  /// In en, this message translates to:
  /// **'Keeps copies'**
  String get summaryCopies;

  /// Settings row value: the shelf keeps only what is dropped on it.
  ///
  /// In en, this message translates to:
  /// **'Only what you drop'**
  String get summaryDropped;

  /// No description provided for @back.
  ///
  /// In en, this message translates to:
  /// **'Back'**
  String get back;
}

class _ShelfLocalizationsDelegate
    extends LocalizationsDelegate<ShelfLocalizations> {
  const _ShelfLocalizationsDelegate();

  @override
  Future<ShelfLocalizations> load(Locale locale) {
    return SynchronousFuture<ShelfLocalizations>(
      lookupShelfLocalizations(locale),
    );
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'vi'].contains(locale.languageCode);

  @override
  bool shouldReload(_ShelfLocalizationsDelegate old) => false;
}

ShelfLocalizations lookupShelfLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return ShelfLocalizationsEn();
    case 'vi':
      return ShelfLocalizationsVi();
  }

  throw FlutterError(
    'ShelfLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
