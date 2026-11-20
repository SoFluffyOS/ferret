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

  /// Hint in the empty shelf box at the bottom of the popover. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Drop here to keep it for later'**
  String get barEmpty;

  /// The shelf box while something is dragged over it.
  ///
  /// In en, this message translates to:
  /// **'Drop to keep it'**
  String get barDropOver;

  /// How many things are on the shelf.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item} other{{count} items}}'**
  String barCount(int count);

  /// The shelf box while private previews are off on this computer: only how many things are on it.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 item, hidden} other{{count} items, hidden}}'**
  String barHidden(int count);

  /// Tooltip of the small button in the shelf box's header: opens the shelf as a list, with Keep copies.
  ///
  /// In en, this message translates to:
  /// **'Open the list'**
  String get barOpen;

  /// Tooltip of the stack tile at the start of the shelf box.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Drag it out} other{Drag all {count} out}}'**
  String dragAll(int count);

  /// Label under the stack tile at the start of the shelf box: drags everything. Keep it very short.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{All {count}}}'**
  String allTile(int count);

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

  /// Menu entry: preview the item with macOS Quick Look. Apple's own name for it.
  ///
  /// In en, this message translates to:
  /// **'Quick Look'**
  String get quickLook;

  /// Menu entry: show the file in Finder, selected.
  ///
  /// In en, this message translates to:
  /// **'Show in Finder'**
  String get showInFinder;

  /// Menu entry: put the text or link on the clipboard.
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copy;

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
  /// **'Drop files, photos, text or links on the box at the bottom. It all stays on this computer.'**
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

  /// Heading in Settings → Shelf over the ways to reach the shelf while dragging something in another app.
  ///
  /// In en, this message translates to:
  /// **'While you drag'**
  String get reachTitle;

  /// Switch in Settings → Shelf: a drag resting on the menubar icon opens the popover with the shelf. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Open on hover'**
  String get springOpen;

  /// Under the Open on hover switch.
  ///
  /// In en, this message translates to:
  /// **'Rest a drag on the menubar icon and Ferret opens with the shelf, after your Mac\'s spring-loading delay.'**
  String get springOpenBody;

  /// Switch in Settings → Shelf: a small floating shelf slides in from the side of the screen while files are dragged. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Box on drag'**
  String get boxOnDrag;

  /// Under the Box on drag switch.
  ///
  /// In en, this message translates to:
  /// **'A small shelf slides in at the side of the screen while you drag files or photos. Hold fn to skip it once.'**
  String get boxOnDragBody;

  /// Row title in Settings → Shelf: when the floating shelf slides in.
  ///
  /// In en, this message translates to:
  /// **'Shows'**
  String get boxShows;

  /// Tooltip of the Shows menu.
  ///
  /// In en, this message translates to:
  /// **'When the box slides in: once your drag nears the side of the screen, or as soon as you start dragging.'**
  String get boxShowsTooltip;

  /// Label of the Shows menu button. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'{when, select, atEdge{At the edge} other{Right away}}'**
  String boxShowsShort(String when);

  /// Menu entries: when the floating shelf slides in.
  ///
  /// In en, this message translates to:
  /// **'{when, select, atEdge{When I drag to the edge} other{As soon as I drag}}'**
  String boxShowsChoice(String when);

  /// Switch in Settings → Shelf: shaking the pointer while dragging brings the floating shelf next to it. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Shake to show'**
  String get shake;

  /// Under the Shake to show switch.
  ///
  /// In en, this message translates to:
  /// **'Shake the pointer while dragging and the shelf shows up right next to it.'**
  String get shakeBody;

  /// Row title in Settings → Shelf: how hard the shake must be.
  ///
  /// In en, this message translates to:
  /// **'Sensitivity'**
  String get sensitivity;

  /// Tooltip of the Sensitivity menu.
  ///
  /// In en, this message translates to:
  /// **'How much shaking it takes. High needs the least.'**
  String get sensitivityTooltip;

  /// Shake sensitivity levels, in the menu and on its button.
  ///
  /// In en, this message translates to:
  /// **'{level, select, low{Low} normal{Normal} other{High}}'**
  String sensitivityChoice(String level);

  /// Switch in Settings → Shelf: holding Shift while dragging brings the floating shelf, for people who can't shake. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Hold ⇧ instead'**
  String get shiftSummons;

  /// Under the Hold ⇧ instead switch.
  ///
  /// In en, this message translates to:
  /// **'Hold ⇧ while dragging to bring the shelf without shaking.'**
  String get shiftSummonsBody;

  /// Heading over the apps whose drags never bring the floating shelf.
  ///
  /// In en, this message translates to:
  /// **'Ignore drags from'**
  String get ignoredTitle;

  /// In the ignored apps card while it is empty.
  ///
  /// In en, this message translates to:
  /// **'No apps. Drags from every app can bring the shelf.'**
  String get ignoredNone;

  /// Button that opens a menu of running apps to ignore. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'Add app'**
  String get ignoredAdd;

  /// Tooltip of the Add app button.
  ///
  /// In en, this message translates to:
  /// **'Pick an open app whose drags never bring the shelf.'**
  String get ignoredAddTooltip;

  /// Tooltip and screen reader label of the button that takes an app off the ignored list.
  ///
  /// In en, this message translates to:
  /// **'Stop ignoring {app}'**
  String ignoredRemove(String app);

  /// Row title in Settings → Shelf: what a quick drop on the menubar icon does.
  ///
  /// In en, this message translates to:
  /// **'Dropping on the icon'**
  String get iconDropTitle;

  /// Tooltip of the Dropping on the icon menu.
  ///
  /// In en, this message translates to:
  /// **'What happens when you let go on the menubar icon without waiting for it to open.'**
  String get iconDropTooltip;

  /// Label of the Dropping on the icon menu button. Keep it short.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, sendToLast{Last device} shelf{Shelf} other{Ask}}'**
  String iconDropShort(String mode);

  /// Menu entries: what a quick drop on the menubar icon does.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, sendToLast{Send to my last device} shelf{Put it on the shelf} other{Ask every time}}'**
  String iconDropChoice(String mode);

  /// Under the Dropping on the icon row, for the choice made.
  ///
  /// In en, this message translates to:
  /// **'{mode, select, sendToLast{Files go to your only connected device, or the one you used last, with 3 seconds to undo. Text and links go on the shelf.} shelf{Everything you drop stays on this Mac, on the shelf.} other{Ferret opens as soon as your drag reaches the icon, so you pick a device or the shelf.}}'**
  String iconDropBody(String mode);
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
