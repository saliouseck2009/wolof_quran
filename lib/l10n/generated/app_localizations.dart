import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
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
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

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
    Locale('fr'),
    Locale('ar'),
    Locale('en'),
  ];

  /// The title of the application
  ///
  /// In en, this message translates to:
  /// **'Wolof Quran'**
  String get appTitle;

  /// Welcome message on home page
  ///
  /// In en, this message translates to:
  /// **'Welcome to Wolof Quran'**
  String get welcome;

  /// Quran text
  ///
  /// In en, this message translates to:
  /// **'Quran'**
  String get quran;

  /// Surah text
  ///
  /// In en, this message translates to:
  /// **'Surah'**
  String get surah;

  /// Ayah/Verse text
  ///
  /// In en, this message translates to:
  /// **'Ayah'**
  String get ayah;

  /// Play button text
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get play;

  /// Pause button text
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pause;

  /// Stop button text
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// Settings page title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// Language setting
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// Theme setting
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// Dark theme
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get dark;

  /// Light theme
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get light;

  /// Arabic language
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// French language
  ///
  /// In en, this message translates to:
  /// **'French'**
  String get french;

  /// English language
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Wolof language
  ///
  /// In en, this message translates to:
  /// **'Wolof'**
  String get wolof;

  /// Search text
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get search;

  /// Search in Quran placeholder
  ///
  /// In en, this message translates to:
  /// **'Search in Quran'**
  String get searchInQuran;

  /// Favorites text
  ///
  /// In en, this message translates to:
  /// **'Favorites'**
  String get favorites;

  /// Bookmarks text
  ///
  /// In en, this message translates to:
  /// **'Bookmarks'**
  String get bookmarks;

  /// Recitation text
  ///
  /// In en, this message translates to:
  /// **'Recitation'**
  String get recitation;

  /// Translation text
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translation;

  /// Current selection indicator
  ///
  /// In en, this message translates to:
  /// **'Current'**
  String get current;

  /// System theme option
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get system;

  /// Version text
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get version;

  /// Support text
  ///
  /// In en, this message translates to:
  /// **'Support'**
  String get support;

  /// Rate app text
  ///
  /// In en, this message translates to:
  /// **'Rate App'**
  String get rateApp;

  /// Get help subtitle
  ///
  /// In en, this message translates to:
  /// **'Get help'**
  String get getHelp;

  /// Give rating subtitle
  ///
  /// In en, this message translates to:
  /// **'Give your rating'**
  String get giveRating;

  /// Close button text
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// About app description
  ///
  /// In en, this message translates to:
  /// **'Developed with ❤️ for the Muslim community'**
  String get developedWithLove;

  /// Surahs page title
  ///
  /// In en, this message translates to:
  /// **'Surahs'**
  String get surahs;

  /// Search surah placeholder
  ///
  /// In en, this message translates to:
  /// **'Search surah...'**
  String get searchSurah;

  /// Verses count text
  ///
  /// In en, this message translates to:
  /// **'verses'**
  String get verses;

  /// Revelation type
  ///
  /// In en, this message translates to:
  /// **'Revelation'**
  String get revelation;

  /// Meccan revelation type
  ///
  /// In en, this message translates to:
  /// **'Meccan'**
  String get meccan;

  /// Medinan revelation type
  ///
  /// In en, this message translates to:
  /// **'Medinan'**
  String get medinan;

  /// No search results message
  ///
  /// In en, this message translates to:
  /// **'No surah found'**
  String get noSurahFound;

  /// No search results subtitle
  ///
  /// In en, this message translates to:
  /// **'Try a different search term'**
  String get tryDifferentSearch;

  /// Quran Settings page title
  ///
  /// In en, this message translates to:
  /// **'Quran Settings'**
  String get quranSettings;

  /// Translation settings section title
  ///
  /// In en, this message translates to:
  /// **'Translation'**
  String get translationSettings;

  /// Translation selection modal title
  ///
  /// In en, this message translates to:
  /// **'Select Translation'**
  String get selectTranslation;

  /// Current translation label
  ///
  /// In en, this message translates to:
  /// **'Current Translation'**
  String get currentTranslation;

  /// Change translation button text
  ///
  /// In en, this message translates to:
  /// **'Change Translation'**
  String get changeTranslation;

  /// Translation settings description
  ///
  /// In en, this message translates to:
  /// **'Choose your preferred translation for Quran verses and chapters'**
  String get translationDescription;

  /// Translation update confirmation message
  ///
  /// In en, this message translates to:
  /// **'Translation updated to {language}'**
  String translationUpdated(String language);

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Search page title
  ///
  /// In en, this message translates to:
  /// **'Search Quran'**
  String get searchQuran;

  /// Search input placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter words to search...'**
  String get enterWordsToSearch;

  /// Initial search state title
  ///
  /// In en, this message translates to:
  /// **'Search the Quran'**
  String get searchTheQuran;

  /// Initial search state subtitle
  ///
  /// In en, this message translates to:
  /// **'Enter words to find verses in the Quran'**
  String get enterWordsToFindVerses;

  /// Search error title
  ///
  /// In en, this message translates to:
  /// **'Search Error'**
  String get searchError;

  /// No search results title
  ///
  /// In en, this message translates to:
  /// **'No Results Found'**
  String get noResultsFound;

  /// No search results subtitle
  ///
  /// In en, this message translates to:
  /// **'Try different search terms'**
  String get tryDifferentSearchTerms;

  /// Search results count
  ///
  /// In en, this message translates to:
  /// **'Found {occurrences} occurrence(s) in {verses} verse(s)'**
  String foundOccurrences(int occurrences, int verses);

  /// Message shown when audio is not downloaded
  ///
  /// In en, this message translates to:
  /// **'Audio not available. Please download the surah first.'**
  String get audioNotAvailable;

  /// Error message for connection issues
  ///
  /// In en, this message translates to:
  /// **'Check your internet connection and try again'**
  String get checkInternetConnection;

  /// Error message for timeout issues
  ///
  /// In en, this message translates to:
  /// **'Connection timeout. Please try again'**
  String get connectionTimeout;

  /// Error message when audio file is not found
  ///
  /// In en, this message translates to:
  /// **'Audio file not found on server'**
  String get audioFileNotFound;

  /// Error message for access denied
  ///
  /// In en, this message translates to:
  /// **'Access denied to audio file'**
  String get accessDeniedToAudio;

  /// Error message for insufficient storage
  ///
  /// In en, this message translates to:
  /// **'Not enough storage space available'**
  String get notEnoughStorage;

  /// Generic download failure message
  ///
  /// In en, this message translates to:
  /// **'Download failed. Please try again'**
  String get downloadFailed;

  /// Status text showing downloaded surahs count
  ///
  /// In en, this message translates to:
  /// **'{count}/114 Surahs Downloaded'**
  String surahsDownloaded(int count);

  /// Status text for downloaded content
  ///
  /// In en, this message translates to:
  /// **'Downloaded'**
  String get downloaded;

  /// Status text for not downloaded content
  ///
  /// In en, this message translates to:
  /// **'Not downloaded'**
  String get notDownloaded;

  /// Status text during download
  ///
  /// In en, this message translates to:
  /// **'Downloading...'**
  String get downloading;

  /// Success message after download completion
  ///
  /// In en, this message translates to:
  /// **'{surahName} downloaded successfully'**
  String downloadedSuccessfully(String surahName);

  /// Download failure message with specific error
  ///
  /// In en, this message translates to:
  /// **'Download failed: {error}'**
  String downloadFailedWithError(String error);

  /// Button text to retry an action
  ///
  /// In en, this message translates to:
  /// **'Try Again'**
  String get tryAgain;

  /// Error message when checking download status fails
  ///
  /// In en, this message translates to:
  /// **'Error checking download status: {error}'**
  String errorCheckingDownloadStatus(String error);

  /// Generic check failure message
  ///
  /// In en, this message translates to:
  /// **'Check failed'**
  String get checkFailed;

  /// Button text to download content before playing
  ///
  /// In en, this message translates to:
  /// **'Download to play'**
  String get downloadToPlay;

  /// Button text to pause surah playback
  ///
  /// In en, this message translates to:
  /// **'Pause Surah'**
  String get pauseSurah;

  /// Button text to resume surah playback
  ///
  /// In en, this message translates to:
  /// **'Resume Surah'**
  String get resumeSurah;

  /// Button text to play surah
  ///
  /// In en, this message translates to:
  /// **'Play Surah'**
  String get playSurah;

  /// Display mode showing both Arabic and translation
  ///
  /// In en, this message translates to:
  /// **'Arabic & Translation'**
  String get arabicAndTranslation;

  /// Display mode showing only Arabic text
  ///
  /// In en, this message translates to:
  /// **'Arabic Only'**
  String get arabicOnly;

  /// Display mode showing only translation
  ///
  /// In en, this message translates to:
  /// **'Translation Only'**
  String get translationOnly;

  /// Font settings section title
  ///
  /// In en, this message translates to:
  /// **'Font Settings'**
  String get fontSettings;

  /// Setting for ayah font size
  ///
  /// In en, this message translates to:
  /// **'Ayah Font Size'**
  String get ayahFontSize;

  /// Description for font size setting
  ///
  /// In en, this message translates to:
  /// **'Adjust the size of Arabic text in verses'**
  String get fontSizeDescription;

  /// Small font size label
  ///
  /// In en, this message translates to:
  /// **'Small'**
  String get small;

  /// Large font size label
  ///
  /// In en, this message translates to:
  /// **'Large'**
  String get large;

  /// Share ayah button text
  ///
  /// In en, this message translates to:
  /// **'Share Ayah'**
  String get shareAyah;

  /// Modal title for customizing ayah before sharing
  ///
  /// In en, this message translates to:
  /// **'Customize & Share'**
  String get customizeAndShare;

  /// Background color selection section title
  ///
  /// In en, this message translates to:
  /// **'Background Style'**
  String get backgroundStyle;

  /// Display mode selection section title
  ///
  /// In en, this message translates to:
  /// **'Display Style'**
  String get displayStyle;

  /// Final share button text
  ///
  /// In en, this message translates to:
  /// **'Share Image'**
  String get shareImage;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
