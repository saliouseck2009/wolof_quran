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
  String get tajweedColoring => 'Tajweed coloring';

  @override
  String get tajweedColoringDescription =>
      'Show colored tajweed rules in the Mushaf';

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
  String get aboutSubtitle => 'App version and legal information';

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
      'The app may open external links to third-party services. These services have their own privacy policies, and we do not control their data practices.';

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
  String get surahDownloadAlreadyInProgress =>
      'This surah is already being downloaded.';

  @override
  String get queued => 'Queued';

  @override
  String get alreadyQueued => 'This surah is already in the download queue.';

  @override
  String get retryDownload => 'Retry download';

  @override
  String get deleteAudioLabel => 'Delete audio';

  @override
  String get confirmDeleteSurahAudioTitle => 'Delete audio?';

  @override
  String confirmDeleteSurahAudioMessage(String surahName) {
    return 'Are you sure you want to delete the audio for $surahName? This action cannot be undone.';
  }

  @override
  String get delete => 'Delete';

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
  String get supportUnavailableOnIosTitle => 'Support is unavailable on iOS';

  @override
  String get supportUnavailableOnIosBody =>
      'To comply with App Store policies, this support section is currently disabled on iOS.';

  @override
  String get payWithWave => 'Wave';

  @override
  String get piSpiPayment => 'PI SPI';

  @override
  String get copyId => 'Copy ID';

  @override
  String get supportValue => 'Jazaakumullaahu khairan';

  @override
  String get playVerseRange => 'Play multiple verses';

  @override
  String get playUntilSurahEnd => 'Until the end';

  @override
  String get customVerseRange => 'Custom';

  @override
  String get rangeStartLabel => 'From';

  @override
  String get rangeEndLabel => 'To';

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count verses',
      one: '1 verse',
    );
    return '$_temp0';
  }

  @override
  String playVersesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Play $count verses',
      one: 'Play 1 verse',
    );
    return '$_temp0';
  }

  @override
  String verseRangeSubtitle(String reference) {
    return 'Continuous playback from $reference';
  }

  @override
  String addVersesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count verses',
      one: '+1 verse',
    );
    return '$_temp0';
  }

  @override
  String get surahEndChip => 'End of surah';

  @override
  String get chooseFirstVerse => 'Choose the first verse';

  @override
  String get chooseLastVerse => 'Choose the last verse';

  @override
  String get searchSurahOrNumber => 'Search a surah or a number';

  @override
  String verseCountShort(int count) {
    return '$count v.';
  }

  @override
  String get readingGoals => 'My goals';

  @override
  String get readingGoalsSubtitle => 'Plan your Khatm';

  @override
  String get newReadingGoal => 'New goal';

  @override
  String get editReadingGoal => 'Edit goal';

  @override
  String get readingGoalsOngoing => 'Ongoing';

  @override
  String get readingGoalsPlanned => 'Planned';

  @override
  String get readingGoalsFinished => 'Finished';

  @override
  String get noReadingGoalsTitle => 'No reading goal yet';

  @override
  String get noReadingGoalsDescription =>
      'Plan a Khatm at your own pace: pick a duration and the app tells you how many pages to read each day.';

  @override
  String get noReadingGoalsInSection => 'Nothing here for now';

  @override
  String get createReadingGoal => 'Create a goal';

  @override
  String get continueReading => 'Continue reading';

  @override
  String readingProgressLabel(int validated, int total) {
    return '$validated/$total pages';
  }

  @override
  String readingValidatedOf(int validated, int total) {
    return '$validated pages read out of $total';
  }

  @override
  String percentValue(int percent) {
    return '$percent%';
  }

  @override
  String readingTodayProgress(int read, int target) {
    return 'Today: $read/$target pages';
  }

  @override
  String get readingTodayDone => 'Today\'s goal reached ✓';

  @override
  String readingRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages left today',
      one: '1 page left today',
    );
    return '$_temp0';
  }

  @override
  String readingDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days left',
      one: '1 day left',
    );
    return '$_temp0';
  }

  @override
  String readingEndsOn(String date) {
    return 'Ends on $date';
  }

  @override
  String readingStartsOn(String date) {
    return 'Starts on $date';
  }

  @override
  String readingPaceAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages ahead',
      one: '1 page ahead',
    );
    return '$_temp0';
  }

  @override
  String readingPaceBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages behind',
      one: '1 page behind',
    );
    return '$_temp0';
  }

  @override
  String get readingPaceOnTrack => 'On track';

  @override
  String get readingStatusActive => 'Active';

  @override
  String get readingStatusPaused => 'Paused';

  @override
  String get readingStatusPlanned => 'Planned';

  @override
  String get readingStatusCompleted => 'Completed';

  @override
  String get readingStatusExpired => 'Expired';

  @override
  String get readingStatusAbandoned => 'Abandoned';

  @override
  String get readingGoalFollowed => 'Followed in the Mushaf';

  @override
  String get followGoal => 'Follow this goal';

  @override
  String get renameGoal => 'Rename';

  @override
  String get changeEndDate => 'Change end date';

  @override
  String get pauseGoal => 'Pause';

  @override
  String get resumeGoal => 'Resume';

  @override
  String get abandonGoal => 'Abandon';

  @override
  String get deleteGoal => 'Delete';

  @override
  String get duplicateGoal => 'New goal from this one';

  @override
  String get reactivateGoal => 'Reactivate';

  @override
  String get extendGoal => 'Extend';

  @override
  String get deleteGoalConfirmTitle => 'Delete this goal?';

  @override
  String get deleteGoalConfirmBody =>
      'Its progress and history will be lost. This cannot be undone.';

  @override
  String get abandonGoalConfirmTitle => 'Abandon this goal?';

  @override
  String get abandonGoalConfirmBody =>
      'Its progress is kept and you can reactivate it later.';

  @override
  String get confirm => 'Confirm';

  @override
  String get markPagesRead => 'Mark pages as read';

  @override
  String get untilPageMode => 'Up to a page';

  @override
  String get pageRangeMode => 'Page range';

  @override
  String get untilPageHint =>
      'Marks every unread page of the goal up to this page, in reading order.';

  @override
  String get fromPageLabel => 'From page';

  @override
  String get toPageLabel => 'To page';

  @override
  String get pageFieldLabel => 'Page';

  @override
  String pagesToMarkSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages will be marked as read',
      one: '1 page will be marked as read',
      zero: 'No new page to mark',
    );
    return '$_temp0';
  }

  @override
  String pagesAlreadyRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count already read',
      one: '1 already read',
    );
    return '$_temp0';
  }

  @override
  String get markAsRead => 'Mark as read';

  @override
  String pagesMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages marked as read',
      one: '1 page marked as read',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Undo';

  @override
  String invalidPage(int total) {
    return 'Enter a page between 1 and $total';
  }

  @override
  String get goalName => 'Goal name';

  @override
  String get goalNameHint => 'e.g. Khatm Ramadan';

  @override
  String defaultGoalName(int number) {
    return 'Khatm $number';
  }

  @override
  String get goalDuration => 'Duration';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      one: '1 day',
    );
    return '$_temp0';
  }

  @override
  String get customDuration => 'Custom';

  @override
  String get pickEndDate => 'End date';

  @override
  String get goalStartPoint => 'Starting point';

  @override
  String get startFromBeginning => 'Beginning of the Quran';

  @override
  String get startFromCurrentPage => 'Current page';

  @override
  String get startFromChosenPage => 'Chosen page';

  @override
  String get goalStartDate => 'Start date';

  @override
  String get today => 'Today';

  @override
  String get chooseDate => 'Choose a date';

  @override
  String get goalSummary => 'Summary';

  @override
  String get pagesToRead => 'Pages to read';

  @override
  String averagePerDay(String pages) {
    return 'About $pages pages per day';
  }

  @override
  String get goalCreate => 'Create the goal';

  @override
  String get goalSave => 'Save';

  @override
  String get nextStep => 'Next';

  @override
  String get homeReadingTitle => 'Reading in progress';

  @override
  String get homeReadingEmptyTitle => 'Plan your Quran reading';

  @override
  String get homeReadingEmptyBody =>
      'Set a goal and know each day how many pages to read.';

  @override
  String get seeAllGoals => 'All goals';

  @override
  String get chooseSurah => 'Choose a surah';

  @override
  String resumeAtPage(int page) {
    return 'Resume at page $page';
  }

  @override
  String goalDates(String start, String end) {
    return '$start → $end';
  }

  @override
  String completedOn(String date) {
    return 'Completed on $date';
  }

  @override
  String get freeReading => 'Free reading';

  @override
  String get freeReadingDescription =>
      'Browse the Mushaf without touching any goal.';

  @override
  String get readingActions => 'Reading';

  @override
  String get markThisPageRead => 'Mark this page as read';

  @override
  String get unmarkThisPage => 'Remove this page\'s validation';

  @override
  String get readUntilHere => 'I read until here';

  @override
  String readUntilHereConfirm(int from, int to, String goal) {
    return 'Mark pages $from to $to as read in “$goal”?';
  }

  @override
  String get readUntilHereNothing => 'Every page up to here is already read.';

  @override
  String get markSeveralPages => 'Mark several pages';

  @override
  String get viewProgress => 'View my progress';

  @override
  String get switchGoal => 'Switch goal';

  @override
  String get switchGoalSubtitle =>
      'Its last reading position will be restored.';

  @override
  String get switchToFreeReading => 'Switch to free reading';

  @override
  String get followAGoal => 'Follow a goal';

  @override
  String pageNotCounted(int page) {
    return 'Page $page not counted — read too briefly';
  }

  @override
  String pageMarkedRead(int page) {
    return 'Page $page marked as read';
  }

  @override
  String goalCompletedToast(String name) {
    return 'Alhamdulillah! “$name” is complete.';
  }

  @override
  String get readingTrackingSettings => 'Reading tracking';

  @override
  String get readingTrackingSubtitle =>
      'Automatic page validation in the Mushaf';

  @override
  String get autoTracking => 'Automatic reading tracking';

  @override
  String get autoTrackingDescription =>
      'A page counts as read in the followed goal after staying on it for the minimum time. You can always mark pages by hand.';

  @override
  String get autoTrackingThreshold => 'Minimum time per page';

  @override
  String secondsShort(int count) {
    return '$count s';
  }

  @override
  String get enabled => 'Enabled';

  @override
  String get disabled => 'Disabled';

  @override
  String todayShort(int read, int target) {
    return 'Today $read/$target';
  }

  @override
  String get todayDoneShort => 'Today\'s goal reached ✓';

  @override
  String get markReadShort => 'Mark as read';

  @override
  String continuousProgressLabel(int page) {
    return 'Continuous progress up to page $page';
  }

  @override
  String get readingNotStarted => 'No page read yet';

  @override
  String todayTarget(int count) {
    return 'Target: $count pages';
  }

  @override
  String todayRead(int count) {
    return 'Read: $count pages';
  }

  @override
  String recommendedPace(String pages) {
    return 'About $pages pages per day until the end';
  }

  @override
  String get pagesSectionTitle => 'Pages';

  @override
  String get legendRead => 'Read';

  @override
  String get legendUnread => 'Unread';

  @override
  String get legendSkipped => 'Skipped';

  @override
  String get missingPages => 'Missing pages';

  @override
  String get noMissingPages => 'No skipped page.';

  @override
  String pageRangeLabel(int from, int to) {
    return 'Pages $from–$to';
  }

  @override
  String get historyTitle => 'Reading history';

  @override
  String get noPagesThatDay => 'No page';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages',
      one: '1 page',
    );
    return '$_temp0';
  }

  @override
  String get journalTitle => 'Validations';

  @override
  String get noValidations => 'No validation yet.';

  @override
  String get validationSourceAuto => 'automatic';

  @override
  String get validationSourceManual => 'manual';

  @override
  String get actionPage => 'Page';

  @override
  String get actionRange => 'Page range';

  @override
  String get actionReadUntil => 'Read until here';

  @override
  String get actionJuz => 'Juz';

  @override
  String get actionHizb => 'Hizb';

  @override
  String get actionSurah => 'Surah';

  @override
  String get actionUnmark => 'Validation removed';

  @override
  String get markSection => 'Mark a Juz, Hizb or Surah';

  @override
  String get sectionJuz => 'Juz';

  @override
  String get sectionHizb => 'Hizb';

  @override
  String get sectionSurah => 'Surah';

  @override
  String sharedPagePrevious(int page) {
    return 'Page $page also holds the end of the previous section. Untick it if you did not read it entirely.';
  }

  @override
  String sharedPageNext(int page) {
    return 'Page $page also holds the start of the next section. Untick it if you did not read it entirely.';
  }

  @override
  String includePage(int page) {
    return 'Include page $page';
  }

  @override
  String sectionPagesSummary(String range, String count) {
    return '$range · $count';
  }

  @override
  String markSectionConfirm(String name) {
    return 'Mark $name as read';
  }

  @override
  String get statsTitle => 'My performance';

  @override
  String get statTotalPages => 'Pages read';

  @override
  String get statKhatmCompleted => 'Khatm completed';

  @override
  String get statCurrentStreak => 'Current streak';

  @override
  String get statBestStreak => 'Best streak';

  @override
  String get statAverage => 'Average per day (30 d)';

  @override
  String get statBestDay => 'Best day';

  @override
  String get statReadingTime => 'Active reading time';

  @override
  String periodDays(int count) {
    return '$count d';
  }

  @override
  String get chartTitle => 'Pages per day';

  @override
  String get byGoalTitle => 'By goal';

  @override
  String get completedKhatmTitle => 'Completed Khatm';

  @override
  String get noStatsYet =>
      'Read a few pages in a goal and your performance will appear here.';

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String minutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get encouragement => 'Keep going at your own pace.';
}
