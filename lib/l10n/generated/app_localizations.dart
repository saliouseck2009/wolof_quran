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

  /// Mushaf reader title
  ///
  /// In en, this message translates to:
  /// **'Mushaf'**
  String get mushaf;

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

  /// Label for tajweed coloring toggle in mushaf settings
  ///
  /// In en, this message translates to:
  /// **'Tajweed coloring'**
  String get tajweedColoring;

  /// Subtitle for tajweed coloring toggle in mushaf settings
  ///
  /// In en, this message translates to:
  /// **'Show colored tajweed rules in the Mushaf'**
  String get tajweedColoringDescription;

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

  /// Home quick actions section title
  ///
  /// In en, this message translates to:
  /// **'Features'**
  String get features;

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
  /// **'Listen'**
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
  /// **'{occurrences} occurrence(s) in {verses} verse(s)'**
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

  /// Specific error message returned when Dio throws on status code 404
  ///
  /// In en, this message translates to:
  /// **'Audio for this chapter is not yet available. Please try again later.'**
  String get dioStatus404;

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

  /// Short download button label
  ///
  /// In en, this message translates to:
  /// **'Download'**
  String get downloadLabel;

  /// Continue button label for mobile data warning
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueDownload;

  /// Title for mobile data warning before downloading
  ///
  /// In en, this message translates to:
  /// **'Download without Wi-Fi'**
  String get mobileDataDownloadTitle;

  /// Message shown when user starts a download without Wi-Fi
  ///
  /// In en, this message translates to:
  /// **'Wi-Fi is not available. Downloading with mobile data may consume your data plan. Do you want to continue?'**
  String get mobileDataDownloadMessage;

  /// Shown when a surah is not present in the remote manifest yet
  ///
  /// In en, this message translates to:
  /// **'Audio for this surah is not yet available.'**
  String get audioNotYetAvailable;

  /// Compact label for unavailable audio
  ///
  /// In en, this message translates to:
  /// **'Not yet available'**
  String get audioNotYetAvailableShort;

  /// Short helper text for newly available audio
  ///
  /// In en, this message translates to:
  /// **'Now available'**
  String get audioNowAvailable;

  /// Title for page listing new audio updates
  ///
  /// In en, this message translates to:
  /// **'New Audio Updates'**
  String get newAudioUpdatesTitle;

  /// Empty state for new audio updates page
  ///
  /// In en, this message translates to:
  /// **'No new audio updates right now.'**
  String get noNewAudioUpdates;

  /// Badge showing unread new audio count
  ///
  /// In en, this message translates to:
  /// **'New ({count})'**
  String newAudioBadge(int count);

  /// Summary text of newly available surahs count
  ///
  /// In en, this message translates to:
  /// **'{count} new surah(s) now available'**
  String newAudioUpdatesCount(int count);

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

  /// Share video button text
  ///
  /// In en, this message translates to:
  /// **'Share Video'**
  String get shareVideo;

  /// Error shown when screenshot capture fails
  ///
  /// In en, this message translates to:
  /// **'Could not capture the image.'**
  String get shareCaptureFailed;

  /// Error shown when video creation fails
  ///
  /// In en, this message translates to:
  /// **'Failed to generate video.'**
  String get shareVideoGenerationFailed;

  /// Message shown when video sharing is disabled for simulator screenshot mode
  ///
  /// In en, this message translates to:
  /// **'Video sharing is unavailable in screenshot mode.'**
  String get shareVideoUnavailableInScreenshotMode;

  /// Message shown when user cancels a share action
  ///
  /// In en, this message translates to:
  /// **'Action cancelled.'**
  String get shareActionCancelled;

  /// Prompt to select a reciter before creating a video
  ///
  /// In en, this message translates to:
  /// **'Please select a reciter to generate the video.'**
  String get shareSelectReciterForVideo;

  /// Message when audio isn't available for the surah
  ///
  /// In en, this message translates to:
  /// **'Audio unavailable for this surah.'**
  String get shareAudioUnavailableForSurah;

  /// Message when audio for the reciter is missing
  ///
  /// In en, this message translates to:
  /// **'Audio not downloaded for this reciter. Download the audios then try again.'**
  String get shareAudioNotDownloaded;

  /// Message when specific ayah audio file is missing
  ///
  /// In en, this message translates to:
  /// **'Audio file not found for this ayah.'**
  String get shareAudioFileMissingAyah;

  /// Message when expected audio file doesn't exist on device
  ///
  /// In en, this message translates to:
  /// **'Audio file missing on the device.'**
  String get shareAudioFileMissingDevice;

  /// Message when share sheet is dismissed
  ///
  /// In en, this message translates to:
  /// **'Share cancelled.'**
  String get shareDismissed;

  /// Message when sharing is not supported
  ///
  /// In en, this message translates to:
  /// **'Sharing unavailable on this device.'**
  String get shareUnavailable;

  /// Unexpected error while sharing
  ///
  /// In en, this message translates to:
  /// **'Error: {error}'**
  String shareUnexpectedError(String error);

  /// Default text shared alongside exported ayah
  ///
  /// In en, this message translates to:
  /// **'Daily Inspiration - {surahName} - Verse {verseNumber}'**
  String shareDefaultText(String surahName, int verseNumber);

  /// Confirmation message when bookmark is added
  ///
  /// In en, this message translates to:
  /// **'Bookmark added'**
  String get bookmarkAdded;

  /// Confirmation message when bookmark is removed
  ///
  /// In en, this message translates to:
  /// **'Bookmark removed'**
  String get bookmarkRemoved;

  /// Description for empty bookmarks state
  ///
  /// In en, this message translates to:
  /// **'Bookmark your favorite verses to access them easily'**
  String get noBookmarksDescription;

  /// Button to clear all bookmarks
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAllBookmarks;

  /// Confirmation dialog title for clearing bookmarks
  ///
  /// In en, this message translates to:
  /// **'Clear all bookmarks?'**
  String get confirmClearBookmarks;

  /// Warning message for clearing bookmarks
  ///
  /// In en, this message translates to:
  /// **'This action cannot be undone.'**
  String get clearBookmarksMessage;

  /// Clear button text
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Title for the explorer/search page
  ///
  /// In en, this message translates to:
  /// **'Explorer'**
  String get explorer;

  /// Error message when bookmarks fail to load
  ///
  /// In en, this message translates to:
  /// **'Error loading bookmarks'**
  String get errorLoadingBookmarks;

  /// Title for empty bookmarks state
  ///
  /// In en, this message translates to:
  /// **'No Bookmarks'**
  String get noBookmarks;

  /// Success message when all bookmarks are cleared
  ///
  /// In en, this message translates to:
  /// **'All bookmarks cleared'**
  String get allBookmarksCleared;

  /// Greeting shown on home header
  ///
  /// In en, this message translates to:
  /// **'As-salamu alaykum'**
  String get salamAlaikum;

  /// Home page tagline describing the app
  ///
  /// In en, this message translates to:
  /// **'Discover the wisdom of verses in Wolof'**
  String get homeTagline;

  /// Title for daily inspiration card
  ///
  /// In en, this message translates to:
  /// **'Daily Inspiration'**
  String get dailyInspirationTitle;

  /// Loading message for daily inspiration section
  ///
  /// In en, this message translates to:
  /// **'Loading daily inspiration...'**
  String get loadingDailyInspiration;

  /// Arabic title label for Quran
  ///
  /// In en, this message translates to:
  /// **'The Holy Quran'**
  String get holyQuran;

  /// Subtitle encouraging user to get daily verse
  ///
  /// In en, this message translates to:
  /// **'Tap to get your daily verse from the Quran'**
  String get tapForDailyVerse;

  /// Hint to start daily inspiration
  ///
  /// In en, this message translates to:
  /// **'Tap anywhere to start'**
  String get tapAnywhereToStart;

  /// Hint to expand daily inspiration for Arabic text
  ///
  /// In en, this message translates to:
  /// **'Tap to read Arabic & more'**
  String get tapToReadArabicMore;

  /// Button to open surah detail
  ///
  /// In en, this message translates to:
  /// **'Open Surah'**
  String get openSurah;

  /// Bookmark button label
  ///
  /// In en, this message translates to:
  /// **'Bookmark'**
  String get bookmark;

  /// State indicating ayah is bookmarked
  ///
  /// In en, this message translates to:
  /// **'Bookmarked'**
  String get bookmarked;

  /// Subtitle for surah list action
  ///
  /// In en, this message translates to:
  /// **'Read Surahs'**
  String get readSurahs;

  /// Subtitle for mushaf home action
  ///
  /// In en, this message translates to:
  /// **'Read page by page'**
  String get readByPage;

  /// Subtitle for audio recitation action
  ///
  /// In en, this message translates to:
  /// **'Listen Audio'**
  String get listenAudio;

  /// Subtitle for search action
  ///
  /// In en, this message translates to:
  /// **'Find Verses'**
  String get findVerses;

  /// Subtitle for bookmarks action
  ///
  /// In en, this message translates to:
  /// **'Saved Ayahs'**
  String get savedAyahs;

  /// Header subtitle on settings page
  ///
  /// In en, this message translates to:
  /// **'Customize your reading experience'**
  String get settingsDescription;

  /// Subtitle for language setting
  ///
  /// In en, this message translates to:
  /// **'Change the app language'**
  String get changeAppLanguage;

  /// Subtitle for theme setting
  ///
  /// In en, this message translates to:
  /// **'Choose the app theme'**
  String get chooseAppTheme;

  /// Value text for Quran settings menu item
  ///
  /// In en, this message translates to:
  /// **'Manage preferences'**
  String get managePreferences;

  /// About menu title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// About menu subtitle
  ///
  /// In en, this message translates to:
  /// **'App version and legal information'**
  String get aboutSubtitle;

  /// About dialog description
  ///
  /// In en, this message translates to:
  /// **'An app to read the Quran and listen to translation in Wolof.'**
  String get aboutDescription;

  /// Section title for content attribution sources
  ///
  /// In en, this message translates to:
  /// **'Content Sources'**
  String get aboutContentSourcesTitle;

  /// Label for Quran text source URL
  ///
  /// In en, this message translates to:
  /// **'Quran text source'**
  String get quranTextSourceTitle;

  /// Label for remote audio availability manifest source
  ///
  /// In en, this message translates to:
  /// **'Audio availability manifest'**
  String get audioManifestSourceTitle;

  /// Label for tafsir audio attribution
  ///
  /// In en, this message translates to:
  /// **'Tafsir audio source'**
  String get tafsirAudioSourceTitle;

  /// Attribution details for tafsir audio source
  ///
  /// In en, this message translates to:
  /// **'Imam Assane Sarr (Senegal, Dakar, Mosque Saad Ibn Abi Waqqas, Unite 21)'**
  String get tafsirAudioSourceDetails;

  /// Section title for contact information
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get aboutContactTitle;

  /// Label for contact email row
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get contactEmailLabel;

  /// Tooltip/label for copy action
  ///
  /// In en, this message translates to:
  /// **'Copy'**
  String get copyLabel;

  /// Snackbar message when text is copied
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// App version label with number
  ///
  /// In en, this message translates to:
  /// **'Version {version}'**
  String appVersion(String version);

  /// Settings menu title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Settings menu subtitle
  ///
  /// In en, this message translates to:
  /// **'Your privacy matters'**
  String get privacyPolicySubtitle;

  /// Value label
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get privacyPolicyValue;

  /// Page title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicyPageTitle;

  /// Last updated label
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String privacyPolicyLastUpdated(String date);

  /// Intro text
  ///
  /// In en, this message translates to:
  /// **'Wolof Quran does not collect, store, or transmit any personal data. Your privacy is fully respected.'**
  String get privacyPolicyIntro;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Data stored on your device'**
  String get privacyPolicyLocalDataTitle;

  /// Section body
  ///
  /// In en, this message translates to:
  /// **'All your data stays on your device and is never sent to any server:\n\n- Your preferences (language, theme, font size, selected reciter)\n- Downloaded audio files\n- Bookmarks and reading progress'**
  String get privacyPolicyLocalDataBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Internet access'**
  String get privacyPolicyInternetTitle;

  /// Section body
  ///
  /// In en, this message translates to:
  /// **'The app uses an internet connection solely to:\n\n- Download Quran audio recitations\n- Check for app updates\n\nNo personal information is sent during these operations.'**
  String get privacyPolicyInternetBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Permissions'**
  String get privacyPolicyPermissionsTitle;

  /// Section body
  ///
  /// In en, this message translates to:
  /// **'The app requests only the permissions strictly necessary for its features:\n\n- Internet: to download audio content\n- Audio playback: to play Quran recitations, including in the background'**
  String get privacyPolicyPermissionsBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'External links'**
  String get privacyPolicyThirdPartyTitle;

  /// Section body
  ///
  /// In en, this message translates to:
  /// **'The app may open external links to third-party services. These services have their own privacy policies, and we do not control their data practices.'**
  String get privacyPolicyThirdPartyBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Suitable for all ages'**
  String get privacyPolicyChildrenTitle;

  /// Section body
  ///
  /// In en, this message translates to:
  /// **'Since the app does not collect any personal data, it is safe for users of all ages, including children.'**
  String get privacyPolicyChildrenBody;

  /// Section title
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get privacyPolicyContactTitle;

  /// Section body
  ///
  /// In en, this message translates to:
  /// **'For any question regarding this policy: {email}'**
  String privacyPolicyContactBody(String email);

  /// Publisher legal name
  ///
  /// In en, this message translates to:
  /// **'Publisher: {name}'**
  String privacyPolicyPublisher(String name);

  /// Age rating statement
  ///
  /// In en, this message translates to:
  /// **'This app is rated for all audiences (all ages).'**
  String get privacyPolicyAgeRating;

  /// Link label for online privacy policy
  ///
  /// In en, this message translates to:
  /// **'Full policy online'**
  String get privacyPolicyOnlineVersion;

  /// Header subtitle on Quran settings page
  ///
  /// In en, this message translates to:
  /// **'Customize your Quran reading experience'**
  String get quranSettingsDescription;

  /// Menu title for audio and tafsir authors
  ///
  /// In en, this message translates to:
  /// **'Audio & Tafsir Authors'**
  String get audioAndReciters;

  /// Subtitle for audio and tafsir authors menu item
  ///
  /// In en, this message translates to:
  /// **'Manage tafsir authors and download audio'**
  String get manageRecitersAndDownloadAudio;

  /// Value text for audio and tafsir authors item
  ///
  /// In en, this message translates to:
  /// **'View available tafsir authors'**
  String get viewAvailableReciters;

  /// Fallback text when value is unknown
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Title for tafsir author list page
  ///
  /// In en, this message translates to:
  /// **'Available Tafsir Authors'**
  String get availableReciters;

  /// Headline for tafsir author loading error
  ///
  /// In en, this message translates to:
  /// **'Error loading tafsir authors'**
  String get errorLoadingReciters;

  /// Retry button label
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// Headline when no tafsir authors found
  ///
  /// In en, this message translates to:
  /// **'No tafsir authors available'**
  String get noRecitersAvailable;

  /// Subtitle when no tafsir authors available
  ///
  /// In en, this message translates to:
  /// **'Check back later for available tafsir authors'**
  String get checkBackLaterReciters;

  /// Action to select a tafsir author
  ///
  /// In en, this message translates to:
  /// **'Select Tafsir Author'**
  String get selectReciter;

  /// Hint text for tafsir author selection
  ///
  /// In en, this message translates to:
  /// **'Tap card to browse • Tap select button to choose default'**
  String get browseAndSelectReciterHint;

  /// Badge for currently selected tafsir author
  ///
  /// In en, this message translates to:
  /// **'Default Tafsir Author'**
  String get defaultReciter;

  /// Badge for available reciter
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get available;

  /// Snackbar when user selects a tafsir author
  ///
  /// In en, this message translates to:
  /// **'Selected {name} as default tafsir author'**
  String selectedAsDefaultReciter(String name);

  /// Title for surah audio downloads page
  ///
  /// In en, this message translates to:
  /// **'Audio Downloads'**
  String get audioDownloads;

  /// Message when no tafsir author chosen
  ///
  /// In en, this message translates to:
  /// **'No tafsir author selected'**
  String get noReciterSelected;

  /// Generic change button label
  ///
  /// In en, this message translates to:
  /// **'Change'**
  String get change;

  /// Label showing ayah count per surah
  ///
  /// In en, this message translates to:
  /// **'{count} ayahs'**
  String ayahCountLabel(int count);

  /// Confirmation after deleting downloaded surah audio
  ///
  /// In en, this message translates to:
  /// **'{surahName} audio removed'**
  String surahAudioDeleted(String surahName);

  /// Shown when user tries to start a second download while one is active
  ///
  /// In en, this message translates to:
  /// **'Another download is already in progress. Please wait for it to finish.'**
  String get downloadInProgress;

  /// Shown when user tries to download the same surah while its download is in progress
  ///
  /// In en, this message translates to:
  /// **'This surah is already being downloaded.'**
  String get surahDownloadAlreadyInProgress;

  /// Label shown when a surah download is queued
  ///
  /// In en, this message translates to:
  /// **'Queued'**
  String get queued;

  /// Snackbar shown when user tries to queue an already queued surah
  ///
  /// In en, this message translates to:
  /// **'This surah is already in the download queue.'**
  String get alreadyQueued;

  /// Tooltip or action label to retry a failed download
  ///
  /// In en, this message translates to:
  /// **'Retry download'**
  String get retryDownload;

  /// Tooltip or action label to delete a downloaded surah audio
  ///
  /// In en, this message translates to:
  /// **'Delete audio'**
  String get deleteAudioLabel;

  /// Title of the confirmation dialog when deleting a surah audio
  ///
  /// In en, this message translates to:
  /// **'Delete audio?'**
  String get confirmDeleteSurahAudioTitle;

  /// Body of the confirmation dialog when deleting a surah audio
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to delete the audio for {surahName}? This action cannot be undone.'**
  String confirmDeleteSurahAudioMessage(String surahName);

  /// Label for the delete confirm button
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// Short generic message for failed queued download
  ///
  /// In en, this message translates to:
  /// **'Download failed'**
  String get downloadFailedShort;

  /// Tooltip with queue position for a pending surah download
  ///
  /// In en, this message translates to:
  /// **'Queued (#{position})'**
  String queuePositionLabel(int position);

  /// Tooltip for playback mode button when looping is disabled
  ///
  /// In en, this message translates to:
  /// **'Playback mode: Off'**
  String get playbackModeOff;

  /// Tooltip for playback mode button when repeating the current track
  ///
  /// In en, this message translates to:
  /// **'Playback mode: Repeat one'**
  String get playbackModeRepeatOne;

  /// Tooltip for playback mode button when repeating the queue
  ///
  /// In en, this message translates to:
  /// **'Playback mode: Repeat all'**
  String get playbackModeRepeatAll;

  /// Tooltip for playback mode button when shuffle is active
  ///
  /// In en, this message translates to:
  /// **'Playback mode: Shuffle'**
  String get playbackModeShuffle;

  /// Title for mushaf surah picker
  ///
  /// In en, this message translates to:
  /// **'Select a surah'**
  String get selectSurah;

  /// Mushaf page number label
  ///
  /// In en, this message translates to:
  /// **'Page {page}'**
  String pageNumberLabel(int page);

  /// Loading text while a share video is being generated
  ///
  /// In en, this message translates to:
  /// **'Generating video...'**
  String get shareGeneratingVideo;

  /// Loading text while share content is being prepared
  ///
  /// In en, this message translates to:
  /// **'Preparing share content...'**
  String get sharePreparingContent;

  /// Tooltip for the previous verse navigation button
  ///
  /// In en, this message translates to:
  /// **'Previous verse'**
  String get previousVerse;

  /// Tooltip for the next verse navigation button
  ///
  /// In en, this message translates to:
  /// **'Next verse'**
  String get nextVerse;

  /// Juz number label shown in the mushaf app bar
  ///
  /// In en, this message translates to:
  /// **'Juz {juz}'**
  String juzLabel(int juz);

  /// Full hizb label shown in the mushaf bottom bar
  ///
  /// In en, this message translates to:
  /// **'Hizb {n}'**
  String hizbFull(int n);

  /// Quarter hizb label shown in the mushaf bottom bar
  ///
  /// In en, this message translates to:
  /// **'1/4 Hizb {n}'**
  String hizbOneQuarter(int n);

  /// Half hizb label shown in the mushaf bottom bar
  ///
  /// In en, this message translates to:
  /// **'1/2 Hizb {n}'**
  String hizbHalf(int n);

  /// No description provided for @nowPlaying.
  ///
  /// In en, this message translates to:
  /// **'Now Playing'**
  String get nowPlaying;

  /// No description provided for @collapsePlayer.
  ///
  /// In en, this message translates to:
  /// **'Collapse'**
  String get collapsePlayer;

  /// No description provided for @previousSurah.
  ///
  /// In en, this message translates to:
  /// **'Previous'**
  String get previousSurah;

  /// No description provided for @nextSurah.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get nextSurah;

  /// No description provided for @rewind10s.
  ///
  /// In en, this message translates to:
  /// **'Rewind 10s'**
  String get rewind10s;

  /// No description provided for @forward10s.
  ///
  /// In en, this message translates to:
  /// **'Forward 10s'**
  String get forward10s;

  /// Three-quarter hizb label shown in the mushaf bottom bar
  ///
  /// In en, this message translates to:
  /// **'3/4 Hizb {n}'**
  String hizbThreeQuarter(int n);

  /// Settings menu item title for support page
  ///
  /// In en, this message translates to:
  /// **'Support the project'**
  String get supportProject;

  /// Settings menu item subtitle for support page
  ///
  /// In en, this message translates to:
  /// **'Help keep the app free and growing'**
  String get supportSubtitle;

  /// Title of the support/donation page
  ///
  /// In en, this message translates to:
  /// **'Support Wolof Quran'**
  String get supportPageTitle;

  /// Title shown on iOS when external donation methods are disabled
  ///
  /// In en, this message translates to:
  /// **'Support is unavailable on iOS'**
  String get supportUnavailableOnIosTitle;

  /// Body text shown on iOS when support page is disabled
  ///
  /// In en, this message translates to:
  /// **'To comply with App Store policies, this support section is currently disabled on iOS.'**
  String get supportUnavailableOnIosBody;

  /// Title for Wave payment section
  ///
  /// In en, this message translates to:
  /// **'Wave'**
  String get payWithWave;

  /// Title for PI SPI payment section
  ///
  /// In en, this message translates to:
  /// **'PI SPI'**
  String get piSpiPayment;

  /// Button label to copy PI SPI identifier
  ///
  /// In en, this message translates to:
  /// **'Copy ID'**
  String get copyId;

  /// Short value text shown on the support settings card
  ///
  /// In en, this message translates to:
  /// **'Jazaakumullaahu khairan'**
  String get supportValue;
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
