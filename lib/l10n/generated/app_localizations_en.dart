// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Wolof Quran';

  @override
  String get welcome => 'Welcome to Wolof Quran';

  @override
  String get quran => 'Quran';

  @override
  String get mushaf => 'Mushaf';

  @override
  String get surah => 'Surah';

  @override
  String get ayah => 'Ayah';

  @override
  String get play => 'Play';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Stop';

  @override
  String get settings => 'Settings';

  @override
  String get language => 'Language';

  @override
  String get theme => 'Theme';

  @override
  String get dark => 'Dark';

  @override
  String get light => 'Light';

  @override
  String get arabic => 'Arabic';

  @override
  String get french => 'French';

  @override
  String get english => 'English';

  @override
  String get wolof => 'Wolof';

  @override
  String get search => 'Search';

  @override
  String get features => 'Features';

  @override
  String get searchInQuran => 'Search in Quran';

  @override
  String get favorites => 'Favorites';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get recitation => 'Listen';

  @override
  String get translation => 'Translation';

  @override
  String get current => 'Current';

  @override
  String get system => 'System';

  @override
  String get version => 'Version';

  @override
  String get support => 'Support';

  @override
  String get rateApp => 'Rate App';

  @override
  String get getHelp => 'Get help';

  @override
  String get giveRating => 'Give your rating';

  @override
  String get close => 'Close';

  @override
  String get developedWithLove => 'Developed with ❤️ for the Muslim community';

  @override
  String get surahs => 'Surahs';

  @override
  String get searchSurah => 'Search surah...';

  @override
  String get verses => 'verses';

  @override
  String get revelation => 'Revelation';

  @override
  String get meccan => 'Meccan';

  @override
  String get medinan => 'Medinan';

  @override
  String get noSurahFound => 'No surah found';

  @override
  String get tryDifferentSearch => 'Try a different search term';

  @override
  String get quranSettings => 'Quran Settings';

  @override
  String get translationSettings => 'Translation';

  @override
  String get selectTranslation => 'Select Translation';

  @override
  String get currentTranslation => 'Current Translation';

  @override
  String get changeTranslation => 'Change Translation';

  @override
  String get translationDescription =>
      'Choose your preferred translation for Quran verses and chapters';

  @override
  String translationUpdated(String language) {
    return 'Translation updated to $language';
  }

  @override
  String get cancel => 'Cancel';

  @override
  String get searchQuran => 'Search Quran';

  @override
  String get enterWordsToSearch => 'Enter words to search...';

  @override
  String get searchTheQuran => 'Search the Quran';

  @override
  String get enterWordsToFindVerses =>
      'Enter words to find verses in the Quran';

  @override
  String get searchError => 'Search Error';

  @override
  String get noResultsFound => 'No Results Found';

  @override
  String get tryDifferentSearchTerms => 'Try different search terms';

  @override
  String foundOccurrences(int occurrences, int verses) {
    return '$occurrences occurrence(s) in $verses verse(s)';
  }

  @override
  String get audioNotAvailable =>
      'Audio not available. Please download the surah first.';

  @override
  String get checkInternetConnection =>
      'Check your internet connection and try again';

  @override
  String get connectionTimeout => 'Connection timeout. Please try again';

  @override
  String get audioFileNotFound => 'Audio file not found on server';

  @override
  String get accessDeniedToAudio => 'Access denied to audio file';

  @override
  String get notEnoughStorage => 'Not enough storage space available';

  @override
  String get downloadFailed => 'Download failed. Please try again';

  @override
  String surahsDownloaded(int count) {
    return '$count/114 Surahs Downloaded';
  }

  @override
  String get downloaded => 'Downloaded';

  @override
  String get notDownloaded => 'Not downloaded';

  @override
  String get downloading => 'Downloading...';

  @override
  String downloadedSuccessfully(String surahName) {
    return '$surahName downloaded successfully';
  }

  @override
  String downloadFailedWithError(String error) {
    return 'Download failed: $error';
  }

  @override
  String get tryAgain => 'Try Again';

  @override
  String get dioStatus404 =>
      'Audio for this chapter is not yet available. Please try again later.';

  @override
  String errorCheckingDownloadStatus(String error) {
    return 'Error checking download status: $error';
  }

  @override
  String get checkFailed => 'Check failed';

  @override
  String get downloadToPlay => 'Download to play';

  @override
  String get downloadLabel => 'Download';

  @override
  String get continueDownload => 'Continue';

  @override
  String get mobileDataDownloadTitle => 'Download without Wi-Fi';

  @override
  String get mobileDataDownloadMessage =>
      'Wi-Fi is not available. Downloading with mobile data may consume your data plan. Do you want to continue?';

  @override
  String get audioNotYetAvailable =>
      'Audio for this surah is not yet available.';

  @override
  String get audioNotYetAvailableShort => 'Not yet available';

  @override
  String get audioNowAvailable => 'Now available';

  @override
  String get newAudioUpdatesTitle => 'New Audio Updates';

  @override
  String get noNewAudioUpdates => 'No new audio updates right now.';

  @override
  String newAudioBadge(int count) {
    return 'New ($count)';
  }

  @override
  String newAudioUpdatesCount(int count) {
    return '$count new surah(s) now available';
  }

  @override
  String get pauseSurah => 'Pause Surah';

  @override
  String get resumeSurah => 'Resume Surah';

  @override
  String get playSurah => 'Play Surah';

  @override
  String get arabicAndTranslation => 'Arabic & Translation';

  @override
  String get arabicOnly => 'Arabic Only';

  @override
  String get translationOnly => 'Translation Only';

  @override
  String get fontSettings => 'Font Settings';

  @override
  String get ayahFontSize => 'Ayah Font Size';

  @override
  String get fontSizeDescription => 'Adjust the size of Arabic text in verses';

  @override
  String get small => 'Small';

  @override
  String get large => 'Large';

  @override
  String get shareAyah => 'Share Ayah';

  @override
  String get customizeAndShare => 'Customize & Share';

  @override
  String get backgroundStyle => 'Background Style';

  @override
  String get displayStyle => 'Display Style';

  @override
  String get shareImage => 'Share Image';

  @override
  String get shareVideo => 'Share Video';

  @override
  String get shareCaptureFailed => 'Could not capture the image.';

  @override
  String get shareVideoGenerationFailed => 'Failed to generate video.';

  @override
  String get shareVideoUnavailableInScreenshotMode =>
      'Video sharing is unavailable in screenshot mode.';

  @override
  String get shareActionCancelled => 'Action cancelled.';

  @override
  String get shareSelectReciterForVideo =>
      'Please select a reciter to generate the video.';

  @override
  String get shareAudioUnavailableForSurah =>
      'Audio unavailable for this surah.';

  @override
  String get shareAudioNotDownloaded =>
      'Audio not downloaded for this reciter. Download the audios then try again.';

  @override
  String get shareAudioFileMissingAyah => 'Audio file not found for this ayah.';

  @override
  String get shareAudioFileMissingDevice => 'Audio file missing on the device.';

  @override
  String get shareDismissed => 'Share cancelled.';

  @override
  String get shareUnavailable => 'Sharing unavailable on this device.';

  @override
  String shareUnexpectedError(String error) {
    return 'Error: $error';
  }

  @override
  String shareDefaultText(String surahName, int verseNumber) {
    return 'Daily Inspiration - $surahName - Verse $verseNumber';
  }

  @override
  String get bookmarkAdded => 'Bookmark added';

  @override
  String get bookmarkRemoved => 'Bookmark removed';

  @override
  String get noBookmarksDescription =>
      'Bookmark your favorite verses to access them easily';

  @override
  String get clearAllBookmarks => 'Clear All';

  @override
  String get confirmClearBookmarks => 'Clear all bookmarks?';

  @override
  String get clearBookmarksMessage => 'This action cannot be undone.';

  @override
  String get clear => 'Clear';

  @override
  String get explorer => 'Explorer';

  @override
  String get errorLoadingBookmarks => 'Error loading bookmarks';

  @override
  String get noBookmarks => 'No Bookmarks';

  @override
  String get allBookmarksCleared => 'All bookmarks cleared';

  @override
  String get salamAlaikum => 'As-salamu alaykum';

  @override
  String get homeTagline => 'Discover the wisdom of verses in Wolof';

  @override
  String get dailyInspirationTitle => 'Daily Inspiration';

  @override
  String get loadingDailyInspiration => 'Loading daily inspiration...';

  @override
  String get holyQuran => 'The Holy Quran';

  @override
  String get tapForDailyVerse => 'Tap to get your daily verse from the Quran';

  @override
  String get tapAnywhereToStart => 'Tap anywhere to start';

  @override
  String get tapToReadArabicMore => 'Tap to read Arabic & more';

  @override
  String get openSurah => 'Open Surah';

  @override
  String get bookmark => 'Bookmark';

  @override
  String get bookmarked => 'Bookmarked';

  @override
  String get readSurahs => 'Read Surahs';

  @override
  String get readByPage => 'Read page by page';

  @override
  String get listenAudio => 'Listen Audio';

  @override
  String get findVerses => 'Find Verses';

  @override
  String get savedAyahs => 'Saved Ayahs';

  @override
  String get settingsDescription => 'Customize your reading experience';

  @override
  String get changeAppLanguage => 'Change the app language';

  @override
  String get chooseAppTheme => 'Choose the app theme';

  @override
  String get managePreferences => 'Manage preferences';

  @override
  String get about => 'About';

  @override
  String get aboutSubtitle => 'App version and support';

  @override
  String get aboutDescription =>
      'An app to read the Quran and listen to translation in Wolof.';

  @override
  String get aboutContentSourcesTitle => 'Content Sources';

  @override
  String get quranTextSourceTitle => 'Quran text source';

  @override
  String get audioManifestSourceTitle => 'Audio availability manifest';

  @override
  String get tafsirAudioSourceTitle => 'Tafsir audio source';

  @override
  String get tafsirAudioSourceDetails =>
      'Imam Assane Sarr (Senegal, Dakar, Mosque Saad Ibn Abi Waqqas, Unite 21)';

  @override
  String get aboutContactTitle => 'Contact';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get copyLabel => 'Copy';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get privacyPolicySubtitle => 'Your privacy matters';

  @override
  String get privacyPolicyValue => 'View';

  @override
  String get privacyPolicyPageTitle => 'Privacy Policy';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'Last updated: $date';
  }

  @override
  String get privacyPolicyIntro =>
      'Wolof Quran does not collect, store, or transmit any personal data. Your privacy is fully respected.';

  @override
  String get privacyPolicyLocalDataTitle => 'Data stored on your device';

  @override
  String get privacyPolicyLocalDataBody =>
      'All your data stays on your device and is never sent to any server:\n\n- Your preferences (language, theme, font size, selected reciter)\n- Downloaded audio files\n- Bookmarks and reading progress';

  @override
  String get privacyPolicyInternetTitle => 'Internet access';

  @override
  String get privacyPolicyInternetBody =>
      'The app uses an internet connection solely to:\n\n- Download Quran audio recitations\n- Check for app updates\n\nNo personal information is sent during these operations.';

  @override
  String get privacyPolicyPermissionsTitle => 'Permissions';

  @override
  String get privacyPolicyPermissionsBody =>
      'The app requests only the permissions strictly necessary for its features:\n\n- Internet: to download audio content\n- Audio playback: to play Quran recitations, including in the background';

  @override
  String get privacyPolicyThirdPartyTitle => 'External links';

  @override
  String get privacyPolicyThirdPartyBody =>
      'The support page contains links to external payment services (Wave, PI SPI). These services have their own privacy policies. We do not receive or store any payment information.';

  @override
  String get privacyPolicyChildrenTitle => 'Suitable for all ages';

  @override
  String get privacyPolicyChildrenBody =>
      'Since the app does not collect any personal data, it is safe for users of all ages, including children.';

  @override
  String get privacyPolicyContactTitle => 'Contact';

  @override
  String privacyPolicyContactBody(String email) {
    return 'For any question regarding this policy: $email';
  }

  @override
  String privacyPolicyPublisher(String name) {
    return 'Publisher: $name';
  }

  @override
  String get privacyPolicyAgeRating =>
      'This app is rated for all audiences (all ages).';

  @override
  String get privacyPolicyOnlineVersion => 'Full policy online';

  @override
  String get quranSettingsDescription =>
      'Customize your Quran reading experience';

  @override
  String get audioAndReciters => 'Audio & Tafsir Authors';

  @override
  String get manageRecitersAndDownloadAudio =>
      'Manage tafsir authors and download audio';

  @override
  String get viewAvailableReciters => 'View available tafsir authors';

  @override
  String get unknown => 'Unknown';

  @override
  String get availableReciters => 'Available Tafsir Authors';

  @override
  String get errorLoadingReciters => 'Error loading tafsir authors';

  @override
  String get retry => 'Retry';

  @override
  String get noRecitersAvailable => 'No tafsir authors available';

  @override
  String get checkBackLaterReciters =>
      'Check back later for available tafsir authors';

  @override
  String get selectReciter => 'Select Tafsir Author';

  @override
  String get browseAndSelectReciterHint =>
      'Tap card to browse • Tap select button to choose default';

  @override
  String get defaultReciter => 'Default Tafsir Author';

  @override
  String get available => 'Available';

  @override
  String selectedAsDefaultReciter(String name) {
    return 'Selected $name as default tafsir author';
  }

  @override
  String get audioDownloads => 'Audio Downloads';

  @override
  String get noReciterSelected => 'No tafsir author selected';

  @override
  String get change => 'Change';

  @override
  String ayahCountLabel(int count) {
    return '$count ayahs';
  }

  @override
  String surahAudioDeleted(String surahName) {
    return '$surahName audio removed';
  }

  @override
  String get downloadInProgress =>
      'Another download is already in progress. Please wait for it to finish.';

  @override
  String get queued => 'Queued';

  @override
  String get alreadyQueued => 'This surah is already in the download queue.';

  @override
  String get retryDownload => 'Retry download';

  @override
  String get deleteAudioLabel => 'Delete audio';

  @override
  String get downloadFailedShort => 'Download failed';

  @override
  String queuePositionLabel(int position) {
    return 'Queued (#$position)';
  }

  @override
  String get playbackModeOff => 'Playback mode: Off';

  @override
  String get playbackModeRepeatOne => 'Playback mode: Repeat one';

  @override
  String get playbackModeRepeatAll => 'Playback mode: Repeat all';

  @override
  String get playbackModeShuffle => 'Playback mode: Shuffle';

  @override
  String get selectSurah => 'Select a surah';

  @override
  String pageNumberLabel(int page) {
    return 'Page $page';
  }

  @override
  String get shareGeneratingVideo => 'Generating video...';

  @override
  String get sharePreparingContent => 'Preparing share content...';

  @override
  String get previousVerse => 'Previous verse';

  @override
  String get nextVerse => 'Next verse';

  @override
  String juzLabel(int juz) {
    return 'Juz $juz';
  }

  @override
  String hizbFull(int n) {
    return 'Hizb $n';
  }

  @override
  String hizbOneQuarter(int n) {
    return '1/4 Hizb $n';
  }

  @override
  String hizbHalf(int n) {
    return '1/2 Hizb $n';
  }

  @override
  String get nowPlaying => 'Now Playing';

  @override
  String get collapsePlayer => 'Collapse';

  @override
  String get previousSurah => 'Previous';

  @override
  String get nextSurah => 'Next';

  @override
  String get rewind10s => 'Rewind 10s';

  @override
  String get forward10s => 'Forward 10s';

  @override
  String hizbThreeQuarter(int n) {
    return '3/4 Hizb $n';
  }

  @override
  String get supportProject => 'Support the project';

  @override
  String get supportSubtitle => 'Help keep the app free and growing';

  @override
  String get supportPageTitle => 'Support Wolof Quran';

  @override
  String get payWithWave => 'Wave';

  @override
  String get piSpiPayment => 'PI SPI';

  @override
  String get copyId => 'Copy ID';

  @override
  String get supportValue => 'Jazaakumullaahu khairan';
}
