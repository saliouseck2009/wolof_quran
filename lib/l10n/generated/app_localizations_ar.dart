// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Arabic (`ar`).
class AppLocalizationsAr extends AppLocalizations {
  AppLocalizationsAr([String locale = 'ar']) : super(locale);

  @override
  String get appTitle => 'القرآن الولوف';

  @override
  String get welcome => 'مرحباً بكم في القرآن الولوف';

  @override
  String get quran => 'القرآن';

  @override
  String get mushaf => 'المصحف';

  @override
  String get surah => 'سورة';

  @override
  String get ayah => 'آية';

  @override
  String get play => 'تشغيل';

  @override
  String get pause => 'إيقاف مؤقت';

  @override
  String get stop => 'توقف';

  @override
  String get settings => 'الإعدادات';

  @override
  String get language => 'اللغة';

  @override
  String get theme => 'المظهر';

  @override
  String get tajweedColoring => 'ألوان التجويد';

  @override
  String get tajweedColoringDescription =>
      'إظهار قواعد التجويد بالألوان في المصحف';

  @override
  String get dark => 'داكن';

  @override
  String get light => 'فاتح';

  @override
  String get arabic => 'العربية';

  @override
  String get french => 'الفرنسية';

  @override
  String get english => 'الإنجليزية';

  @override
  String get wolof => 'الولوف';

  @override
  String get search => 'بحث';

  @override
  String get features => 'الميزات';

  @override
  String get searchInQuran => 'البحث في القرآن';

  @override
  String get favorites => 'المفضلة';

  @override
  String get bookmarks => 'العلامات المرجعية';

  @override
  String get recitation => 'استماع';

  @override
  String get translation => 'الترجمة';

  @override
  String get current => 'الحالي';

  @override
  String get system => 'النظام';

  @override
  String get version => 'الإصدار';

  @override
  String get support => 'الدعم';

  @override
  String get rateApp => 'قيّم التطبيق';

  @override
  String get getHelp => 'احصل على المساعدة';

  @override
  String get giveRating => 'أعط تقييمك';

  @override
  String get close => 'إغلاق';

  @override
  String get developedWithLove => 'طُور بـ ❤️ للمجتمع المسلم';

  @override
  String get surahs => 'السور';

  @override
  String get searchSurah => 'البحث عن سورة...';

  @override
  String get verses => 'آيات';

  @override
  String get revelation => 'النزول';

  @override
  String get meccan => 'مكية';

  @override
  String get medinan => 'مدنية';

  @override
  String get noSurahFound => 'لم توجد سورة';

  @override
  String get tryDifferentSearch => 'جرب مصطلح بحث مختلف';

  @override
  String get quranSettings => 'إعدادات القرآن';

  @override
  String get translationSettings => 'إعدادات الترجمة';

  @override
  String get selectTranslation => 'اختر الترجمة';

  @override
  String get currentTranslation => 'الترجمة الحالية';

  @override
  String get changeTranslation => 'تغيير الترجمة';

  @override
  String get translationDescription => 'اختر الترجمة المفضلة لآيات وسور القرآن';

  @override
  String translationUpdated(String language) {
    return 'تم تحديث الترجمة إلى $language';
  }

  @override
  String get cancel => 'إلغاء';

  @override
  String get searchQuran => 'بحث في القرآن';

  @override
  String get enterWordsToSearch => 'أدخل كلمات للبحث...';

  @override
  String get searchTheQuran => 'ابحث في القرآن';

  @override
  String get enterWordsToFindVerses => 'أدخل كلمات للعثور على آيات في القرآن';

  @override
  String get searchError => 'خطأ في البحث';

  @override
  String get noResultsFound => 'لم يتم العثور على نتائج';

  @override
  String get tryDifferentSearchTerms => 'جرّب مصطلحات بحث أخرى';

  @override
  String foundOccurrences(int occurrences, int verses) {
    return 'تم العثور على $occurrences نتيجة في $verses آية';
  }

  @override
  String get audioNotAvailable => 'الصوت غير متوفر. يرجى تحميل السورة أولاً.';

  @override
  String get checkInternetConnection =>
      'تحقق من اتصالك بالإنترنت وحاول مرة أخرى';

  @override
  String get connectionTimeout => 'انتهت مهلة الاتصال. يرجى المحاولة مرة أخرى';

  @override
  String get audioFileNotFound => 'لم يتم العثور على ملف الصوت على الخادم';

  @override
  String get accessDeniedToAudio => 'تم رفض الوصول إلى ملف الصوت';

  @override
  String get notEnoughStorage => 'مساحة التخزين غير كافية';

  @override
  String get downloadFailed => 'فشل التحميل. يرجى المحاولة مرة أخرى';

  @override
  String surahsDownloaded(int count) {
    return '$count/114 سورة محملة';
  }

  @override
  String get downloaded => 'محملة';

  @override
  String get notDownloaded => 'غير محملة';

  @override
  String get downloading => 'جاري التحميل...';

  @override
  String downloadedSuccessfully(String surahName) {
    return 'تم تحميل $surahName بنجاح';
  }

  @override
  String downloadFailedWithError(String error) {
    return 'فشل التحميل: $error';
  }

  @override
  String get tryAgain => 'حاول مرة أخرى';

  @override
  String get dioStatus404 =>
      'الصوت لهذا الفصل غير متوفر بعد. يرجى المحاولة مرة أخرى لاحقًا.';

  @override
  String errorCheckingDownloadStatus(String error) {
    return 'خطأ في فحص حالة التحميل: $error';
  }

  @override
  String get checkFailed => 'فشل الفحص';

  @override
  String get downloadToPlay => 'تحميل للتشغيل';

  @override
  String get downloadLabel => 'تحميل';

  @override
  String get continueDownload => 'متابعة';

  @override
  String get mobileDataDownloadTitle => 'تحميل بدون Wi‑Fi';

  @override
  String get mobileDataDownloadMessage =>
      'شبكة Wi‑Fi غير متوفرة. قد يؤدي التحميل عبر بيانات الهاتف إلى استهلاك باقتك. هل تريد المتابعة؟';

  @override
  String get audioNotYetAvailable => 'صوت هذه السورة غير متاح بعد.';

  @override
  String get audioNotYetAvailableShort => 'غير متاح بعد';

  @override
  String get audioNowAvailable => 'متاح الآن';

  @override
  String get newAudioUpdatesTitle => 'تحديثات صوتية جديدة';

  @override
  String get noNewAudioUpdates => 'لا توجد تحديثات صوتية جديدة حالياً.';

  @override
  String newAudioBadge(int count) {
    return 'جديد ($count)';
  }

  @override
  String newAudioUpdatesCount(int count) {
    return '$count سورة صوتية جديدة متاحة الآن';
  }

  @override
  String get pauseSurah => 'إيقاف مؤقت للسورة';

  @override
  String get resumeSurah => 'استئناف السورة';

  @override
  String get playSurah => 'تشغيل السورة';

  @override
  String get arabicAndTranslation => 'العربية والترجمة';

  @override
  String get arabicOnly => 'العربية فقط';

  @override
  String get translationOnly => 'الترجمة فقط';

  @override
  String get fontSettings => 'إعدادات الخط';

  @override
  String get ayahFontSize => 'حجم خط الآيات';

  @override
  String get fontSizeDescription => 'تعديل حجم النص العربي في الآيات';

  @override
  String get small => 'صغير';

  @override
  String get large => 'كبير';

  @override
  String get shareAyah => 'مشاركة الآية';

  @override
  String get customizeAndShare => 'تخصيص ومشاركة';

  @override
  String get backgroundStyle => 'نمط الخلفية';

  @override
  String get displayStyle => 'نمط العرض';

  @override
  String get shareImage => 'مشاركة الصورة';

  @override
  String get shareVideo => 'مشاركة فيديو';

  @override
  String get shareCaptureFailed => 'تعذّر التقاط الصورة.';

  @override
  String get shareVideoGenerationFailed => 'فشل إنشاء الفيديو.';

  @override
  String get shareVideoUnavailableInScreenshotMode =>
      'مشاركة الفيديو غير متاحة في وضع لقطات الشاشة.';

  @override
  String get shareActionCancelled => 'تم إلغاء العملية.';

  @override
  String get shareSelectReciterForVideo => 'يرجى اختيار قارئ لإنشاء الفيديو.';

  @override
  String get shareAudioUnavailableForSurah => 'الصوت غير متوفر لهذه السورة.';

  @override
  String get shareAudioNotDownloaded =>
      'الصوت غير محمّل لهذا القارئ. حمّل الملفات ثم أعد المحاولة.';

  @override
  String get shareAudioFileMissingAyah => 'ملف الصوت غير موجود لهذه الآية.';

  @override
  String get shareAudioFileMissingDevice => 'ملف الصوت غير موجود على الجهاز.';

  @override
  String get shareDismissed => 'تم إلغاء المشاركة.';

  @override
  String get shareUnavailable => 'المشاركة غير متاحة على هذا الجهاز.';

  @override
  String shareUnexpectedError(String error) {
    return 'خطأ: $error';
  }

  @override
  String shareDefaultText(String surahName, int verseNumber) {
    return 'الإلهام اليومي - $surahName - الآية $verseNumber';
  }

  @override
  String get bookmarkAdded => 'تم إضافة الإشارة المرجعية';

  @override
  String get bookmarkRemoved => 'تم حذف الإشارة المرجعية';

  @override
  String get noBookmarksDescription =>
      'ضع إشارة مرجعية على آياتك المفضلة للوصول إليها بسهولة';

  @override
  String get clearAllBookmarks => 'مسح الكل';

  @override
  String get confirmClearBookmarks => 'مسح جميع الإشارات المرجعية؟';

  @override
  String get clearBookmarksMessage => 'لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get clear => 'مسح';

  @override
  String get explorer => 'استكشاف';

  @override
  String get errorLoadingBookmarks => 'خطأ في تحميل العلامات المرجعية';

  @override
  String get noBookmarks => 'لا توجد علامات مرجعية';

  @override
  String get allBookmarksCleared => 'تم مسح جميع العلامات المرجعية';

  @override
  String get salamAlaikum => 'السلام عليكم';

  @override
  String get homeTagline => 'اكتشف حكمة الآيات بلغة الولوف';

  @override
  String get dailyInspirationTitle => 'إلهام يومي';

  @override
  String get loadingDailyInspiration => 'جاري تحميل الإلهام اليومي...';

  @override
  String get holyQuran => 'القرآن الكريم';

  @override
  String get tapForDailyVerse => 'اضغط للحصول على آيتك اليومية من القرآن';

  @override
  String get tapAnywhereToStart => 'اضغط في أي مكان للبدء';

  @override
  String get tapToReadArabicMore => 'اضغط لقراءة العربية والمزيد';

  @override
  String get openSurah => 'افتح السورة';

  @override
  String get bookmark => 'إضافة إشارة مرجعية';

  @override
  String get bookmarked => 'مضاف إلى الإشارات المرجعية';

  @override
  String get readSurahs => 'قراءة السور';

  @override
  String get readByPage => 'قراءة صفحة بصفحة';

  @override
  String get listenAudio => 'استمع إلى الصوت';

  @override
  String get findVerses => 'ابحث عن الآيات';

  @override
  String get savedAyahs => 'الآيات المحفوظة';

  @override
  String get settingsDescription => 'خصص تجربة القراءة الخاصة بك';

  @override
  String get changeAppLanguage => 'تغيير لغة التطبيق';

  @override
  String get chooseAppTheme => 'اختيار مظهر التطبيق';

  @override
  String get managePreferences => 'إدارة التفضيلات';

  @override
  String get about => 'حول التطبيق';

  @override
  String get aboutSubtitle => 'إصدار التطبيق والمعلومات القانونية';

  @override
  String get aboutDescription =>
      'تطبيق لقراءة القرآن والاستماع إلى التلاوات باللغة الولوف.';

  @override
  String get aboutContentSourcesTitle => 'مصادر المحتوى';

  @override
  String get quranTextSourceTitle => 'مصدر نص القرآن';

  @override
  String get audioManifestSourceTitle => 'ملف توفر الصوت';

  @override
  String get tafsirAudioSourceTitle => 'مصدر صوت التفسير';

  @override
  String get tafsirAudioSourceDetails =>
      'الإمام أسان صار (السنغال، داكار، مسجد سعد بن أبي وقاص، الوحدة 21)';

  @override
  String get aboutContactTitle => 'التواصل';

  @override
  String get contactEmailLabel => 'البريد الإلكتروني';

  @override
  String get copyLabel => 'نسخ';

  @override
  String get copiedToClipboard => 'تم النسخ';

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

  @override
  String get privacyPolicy => 'سياسة الخصوصية';

  @override
  String get privacyPolicySubtitle => 'خصوصيتك تهمنا';

  @override
  String get privacyPolicyValue => 'عرض';

  @override
  String get privacyPolicyPageTitle => 'سياسة الخصوصية';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'آخر تحديث: $date';
  }

  @override
  String get privacyPolicyIntro =>
      'تطبيق القرآن بالولوف لا يجمع ولا يخزن ولا ينقل أي بيانات شخصية. خصوصيتك محترمة بالكامل.';

  @override
  String get privacyPolicyLocalDataTitle => 'البيانات المخزنة على جهازك';

  @override
  String get privacyPolicyLocalDataBody =>
      'جميع بياناتك تبقى على جهازك ولا تُرسل أبداً إلى أي خادم:\n\n- تفضيلاتك (اللغة، المظهر، حجم الخط، القارئ المختار)\n- ملفات الصوت المحملة\n- العلامات المرجعية وتقدم القراءة';

  @override
  String get privacyPolicyInternetTitle => 'الاتصال بالإنترنت';

  @override
  String get privacyPolicyInternetBody =>
      'يستخدم التطبيق الاتصال بالإنترنت فقط من أجل:\n\n- تحميل تلاوات القرآن الصوتية\n- التحقق من تحديثات التطبيق\n\nلا يتم إرسال أي معلومات شخصية أثناء هذه العمليات.';

  @override
  String get privacyPolicyPermissionsTitle => 'الأذونات';

  @override
  String get privacyPolicyPermissionsBody =>
      'لا يطلب التطبيق سوى الأذونات الضرورية لعمله:\n\n- الإنترنت: لتحميل المحتوى الصوتي\n- تشغيل الصوت: لقراءة تلاوات القرآن، بما في ذلك في الخلفية';

  @override
  String get privacyPolicyThirdPartyTitle => 'الروابط الخارجية';

  @override
  String get privacyPolicyThirdPartyBody =>
      'قد يفتح التطبيق روابط خارجية إلى خدمات طرف ثالث. لهذه الخدمات سياسات خصوصية خاصة بها، ونحن لا نتحكم في ممارسات بياناتها.';

  @override
  String get privacyPolicyChildrenTitle => 'مناسب لجميع الأعمار';

  @override
  String get privacyPolicyChildrenBody =>
      'بما أن التطبيق لا يجمع أي بيانات شخصية، فهو آمن للمستخدمين من جميع الأعمار، بما في ذلك الأطفال.';

  @override
  String get privacyPolicyContactTitle => 'التواصل';

  @override
  String privacyPolicyContactBody(String email) {
    return 'لأي سؤال متعلق بهذه السياسة: $email';
  }

  @override
  String privacyPolicyPublisher(String name) {
    return 'الناشر: $name';
  }

  @override
  String get privacyPolicyAgeRating =>
      'هذا التطبيق مخصص لجميع الفئات العمرية (كل الأعمار).';

  @override
  String get privacyPolicyOnlineVersion => 'السياسة الكاملة عبر الإنترنت';

  @override
  String get quranSettingsDescription => 'خصص تجربة قراءة القرآن لديك';

  @override
  String get audioAndReciters => 'الصوت ومؤلفو التفسير';

  @override
  String get manageRecitersAndDownloadAudio =>
      'إدارة مؤلفي التفسير وتنزيل الصوت';

  @override
  String get viewAvailableReciters => 'عرض مؤلفي التفسير المتاحين';

  @override
  String get unknown => 'غير معروف';

  @override
  String get availableReciters => 'مؤلفو التفسير المتاحون';

  @override
  String get errorLoadingReciters => 'خطأ في تحميل مؤلفي التفسير';

  @override
  String get retry => 'إعادة المحاولة';

  @override
  String get noRecitersAvailable => 'لا يوجد مؤلفو تفسير متاحون';

  @override
  String get checkBackLaterReciters =>
      'عد لاحقاً للاطلاع على مؤلفي التفسير المتاحين';

  @override
  String get selectReciter => 'اختر مؤلف تفسير';

  @override
  String get browseAndSelectReciterHint =>
      'اضغط على البطاقة للاستعراض • اضغط على الزر للتعيين كافتراضي';

  @override
  String get defaultReciter => 'مؤلف التفسير الافتراضي';

  @override
  String get available => 'متاح';

  @override
  String selectedAsDefaultReciter(String name) {
    return 'تم اختيار $name كمؤلف تفسير افتراضي';
  }

  @override
  String get audioDownloads => 'تنزيلات الصوت';

  @override
  String get noReciterSelected => 'لم يتم اختيار مؤلف تفسير';

  @override
  String get change => 'تغيير';

  @override
  String ayahCountLabel(int count) {
    return '$count آية';
  }

  @override
  String surahAudioDeleted(String surahName) {
    return 'تم حذف صوت سورة $surahName';
  }

  @override
  String get downloadInProgress =>
      'هناك تنزيل جارٍ بالفعل. يرجى الانتظار حتى ينتهي قبل بدء آخر.';

  @override
  String get surahDownloadAlreadyInProgress => 'تنزيل هذه السورة جارٍ بالفعل.';

  @override
  String get queued => 'في الانتظار';

  @override
  String get alreadyQueued => 'هذه السورة موجودة بالفعل في قائمة التنزيل.';

  @override
  String get retryDownload => 'إعادة محاولة التنزيل';

  @override
  String get deleteAudioLabel => 'حذف الصوت';

  @override
  String get confirmDeleteSurahAudioTitle => 'حذف الصوت؟';

  @override
  String confirmDeleteSurahAudioMessage(String surahName) {
    return 'هل أنت متأكد من رغبتك في حذف صوت سورة $surahName؟ لا يمكن التراجع عن هذا الإجراء.';
  }

  @override
  String get delete => 'حذف';

  @override
  String get downloadFailedShort => 'فشل التنزيل';

  @override
  String queuePositionLabel(int position) {
    return 'في الانتظار (#$position)';
  }

  @override
  String get playbackModeOff => 'وضع التشغيل: إيقاف عند النهاية';

  @override
  String get playbackModeRepeatOne => 'وضع التشغيل: تكرار المقطع الحالي';

  @override
  String get playbackModeRepeatAll => 'وضع التشغيل: تكرار القائمة';

  @override
  String get playbackModeShuffle => 'وضع التشغيل: عشوائي';

  @override
  String get selectSurah => 'اختر سورة';

  @override
  String pageNumberLabel(int page) {
    return 'الصفحة $page';
  }

  @override
  String get shareGeneratingVideo => 'جارٍ إنشاء الفيديو...';

  @override
  String get sharePreparingContent => 'جارٍ تحضير محتوى المشاركة...';

  @override
  String get previousVerse => 'الآية السابقة';

  @override
  String get nextVerse => 'الآية التالية';

  @override
  String juzLabel(int juz) {
    return 'الجزء $juz';
  }

  @override
  String hizbFull(int n) {
    return 'حزب $n';
  }

  @override
  String hizbOneQuarter(int n) {
    return 'ربع حزب $n';
  }

  @override
  String hizbHalf(int n) {
    return 'نصف حزب $n';
  }

  @override
  String get nowPlaying => 'قيد التشغيل';

  @override
  String get collapsePlayer => 'تصغير';

  @override
  String get previousSurah => 'السابق';

  @override
  String get nextSurah => 'التالي';

  @override
  String get rewind10s => '10 ثوانٍ للخلف';

  @override
  String get forward10s => '10 ثوانٍ للأمام';

  @override
  String hizbThreeQuarter(int n) {
    return 'ثلاثة أرباع حزب $n';
  }

  @override
  String get supportProject => 'دعم المشروع';

  @override
  String get supportSubtitle => 'ساهم في استمرارية التطبيق';

  @override
  String get supportPageTitle => 'دعم القرآن بالولوف';

  @override
  String get supportUnavailableOnIosTitle => 'الدعم غير متاح على iOS';

  @override
  String get supportUnavailableOnIosBody =>
      'للالتزام بسياسات App Store، تم تعطيل قسم الدعم هذا حالياً على iOS.';

  @override
  String get payWithWave => 'Wave';

  @override
  String get piSpiPayment => 'PI SPI';

  @override
  String get copyId => 'نسخ المعرّف';

  @override
  String get supportValue => 'جزاكم الله خيرًا';

  @override
  String get playVerseRange => 'تشغيل عدة آيات';

  @override
  String get playUntilSurahEnd => 'حتى النهاية';

  @override
  String get customVerseRange => 'مخصص';

  @override
  String get rangeStartLabel => 'من';

  @override
  String get rangeEndLabel => 'إلى';

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count آية',
      few: '$count آيات',
      two: 'آيتان',
      one: 'آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String playVersesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'تشغيل $count آية',
      few: 'تشغيل $count آيات',
      two: 'تشغيل آيتين',
      one: 'تشغيل آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String verseRangeSubtitle(String reference) {
    return 'تشغيل متواصل بدءًا من $reference';
  }

  @override
  String addVersesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count آية',
      few: '+$count آيات',
      two: '+آيتان',
      one: '+آية واحدة',
    );
    return '$_temp0';
  }

  @override
  String get surahEndChip => 'نهاية السورة';

  @override
  String get chooseFirstVerse => 'اختر الآية الأولى';

  @override
  String get chooseLastVerse => 'اختر الآية الأخيرة';

  @override
  String get searchSurahOrNumber => 'ابحث عن سورة أو رقم';

  @override
  String verseCountShort(int count) {
    return '$count آية';
  }

  @override
  String get readingGoals => 'أهدافي';

  @override
  String get readingGoalsSubtitle => 'خطّط لختمتك';

  @override
  String get newReadingGoal => 'هدف جديد';

  @override
  String get editReadingGoal => 'تعديل الهدف';

  @override
  String get readingGoalsOngoing => 'جارية';

  @override
  String get readingGoalsPlanned => 'مخطّطة';

  @override
  String get readingGoalsFinished => 'منتهية';

  @override
  String get noReadingGoalsTitle => 'لا يوجد هدف قراءة بعد';

  @override
  String get noReadingGoalsDescription =>
      'خطّط لختمة على وتيرتك: اختر مدة ويخبرك التطبيق بعدد الصفحات التي تقرؤها كل يوم.';

  @override
  String get noReadingGoalsInSection => 'لا شيء هنا حاليًا';

  @override
  String get createReadingGoal => 'إنشاء هدف';

  @override
  String get continueReading => 'متابعة القراءة';

  @override
  String readingProgressLabel(int validated, int total) {
    return '$validated/$total صفحة';
  }

  @override
  String readingValidatedOf(int validated, int total) {
    return '$validated صفحة مقروءة من $total';
  }

  @override
  String percentValue(int percent) {
    return '$percent٪';
  }

  @override
  String readingTodayProgress(int read, int target) {
    return 'اليوم: $read/$target صفحة';
  }

  @override
  String get readingTodayDone => 'تحقّق هدف اليوم ✓';

  @override
  String readingRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count صفحة لليوم',
      few: 'بقيت $count صفحات لليوم',
      two: 'بقيت صفحتان لليوم',
      one: 'بقيت صفحة واحدة لليوم',
    );
    return '$_temp0';
  }

  @override
  String readingDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا متبقيًا',
      few: '$count أيام متبقية',
      two: 'يومان متبقيان',
      one: 'يوم واحد متبقٍ',
    );
    return '$_temp0';
  }

  @override
  String readingEndsOn(String date) {
    return 'ينتهي في $date';
  }

  @override
  String readingStartsOn(String date) {
    return 'يبدأ في $date';
  }

  @override
  String readingPaceAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متقدم بـ $count صفحة',
      few: 'متقدم بـ $count صفحات',
      two: 'متقدم بصفحتين',
      one: 'متقدم بصفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String readingPaceBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'متأخر بـ $count صفحة',
      few: 'متأخر بـ $count صفحات',
      two: 'متأخر بصفحتين',
      one: 'متأخر بصفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get readingPaceOnTrack => 'في الموعد';

  @override
  String get readingStatusActive => 'نشط';

  @override
  String get readingStatusPaused => 'متوقف مؤقتًا';

  @override
  String get readingStatusPlanned => 'مخطّط';

  @override
  String get readingStatusCompleted => 'مكتمل';

  @override
  String get readingStatusExpired => 'منتهي الصلاحية';

  @override
  String get readingStatusAbandoned => 'متروك';

  @override
  String get readingGoalFollowed => 'متابَع في المصحف';

  @override
  String get followGoal => 'متابعة هذا الهدف';

  @override
  String get renameGoal => 'إعادة التسمية';

  @override
  String get changeEndDate => 'تغيير تاريخ الانتهاء';

  @override
  String get pauseGoal => 'إيقاف مؤقت';

  @override
  String get resumeGoal => 'استئناف';

  @override
  String get abandonGoal => 'ترك الهدف';

  @override
  String get deleteGoal => 'حذف';

  @override
  String get duplicateGoal => 'تكرار الهدف';

  @override
  String get reactivateGoal => 'إعادة التفعيل';

  @override
  String get extendGoal => 'تمديد';

  @override
  String get deleteGoalConfirmTitle => 'حذف هذا الهدف؟';

  @override
  String get deleteGoalConfirmBody =>
      'سيُفقد تقدمه وسجله. لا يمكن التراجع عن هذا الإجراء.';

  @override
  String get abandonGoalConfirmTitle => 'ترك هذا الهدف؟';

  @override
  String get abandonGoalConfirmBody =>
      'يُحفظ تقدمه ويمكنك إعادة تفعيله لاحقًا.';

  @override
  String get confirm => 'تأكيد';

  @override
  String get markPagesRead => 'تحديد صفحات كمقروءة';

  @override
  String get untilPageMode => 'حتى صفحة';

  @override
  String get pageRangeMode => 'نطاق صفحات';

  @override
  String get untilPageHint =>
      'يحدد كل الصفحات غير المقروءة في الهدف حتى هذه الصفحة، بترتيب القراءة.';

  @override
  String get fromPageLabel => 'من الصفحة';

  @override
  String get toPageLabel => 'إلى الصفحة';

  @override
  String get pageFieldLabel => 'الصفحة';

  @override
  String pagesToMarkSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ستُحدد $count صفحة كمقروءة',
      few: 'ستُحدد $count صفحات كمقروءة',
      two: 'ستُحدد صفحتان كمقروءتين',
      one: 'ستُحدد صفحة واحدة كمقروءة',
      zero: 'لا توجد صفحة جديدة للتحديد',
    );
    return '$_temp0';
  }

  @override
  String pagesAlreadyRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count مقروءة سابقًا',
      few: '$count مقروءة سابقًا',
      two: 'اثنتان مقروءتان سابقًا',
      one: 'واحدة مقروءة سابقًا',
    );
    return '$_temp0';
  }

  @override
  String get markAsRead => 'تحديد كمقروءة';

  @override
  String pagesMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'حُددت $count صفحة كمقروءة',
      few: 'حُددت $count صفحات كمقروءة',
      two: 'حُددت صفحتان كمقروءتين',
      one: 'حُددت صفحة واحدة كمقروءة',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'تراجع';

  @override
  String invalidPage(int total) {
    return 'أدخل صفحة بين 1 و $total';
  }

  @override
  String get goalName => 'اسم الهدف';

  @override
  String get goalNameHint => 'مثال: ختمة رمضان';

  @override
  String defaultGoalName(int number) {
    return 'ختمة $number';
  }

  @override
  String get goalDuration => 'المدة';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count يومًا',
      few: '$count أيام',
      two: 'يومان',
      one: 'يوم واحد',
    );
    return '$_temp0';
  }

  @override
  String get customDuration => 'مخصصة';

  @override
  String get pickEndDate => 'تاريخ الانتهاء';

  @override
  String get goalStartPoint => 'نقطة البداية';

  @override
  String get startFromBeginning => 'بداية القرآن';

  @override
  String get startFromCurrentPage => 'الصفحة الحالية';

  @override
  String get startFromChosenPage => 'صفحة مختارة';

  @override
  String get goalStartDate => 'تاريخ البدء';

  @override
  String get today => 'اليوم';

  @override
  String get chooseDate => 'اختيار تاريخ';

  @override
  String get goalSummary => 'الملخص';

  @override
  String get pagesToRead => 'الصفحات المطلوب قراءتها';

  @override
  String averagePerDay(String pages) {
    return 'حوالي $pages صفحة في اليوم';
  }

  @override
  String get goalCreate => 'إنشاء الهدف';

  @override
  String get goalSave => 'حفظ';

  @override
  String get nextStep => 'التالي';

  @override
  String get homeReadingTitle => 'قراءة جارية';

  @override
  String get homeReadingEmptyTitle => 'خطّط لقراءتك للقرآن';

  @override
  String get homeReadingEmptyBody =>
      'حدد هدفًا واعرف كل يوم عدد الصفحات التي تقرؤها.';

  @override
  String get seeAllGoals => 'كل الأهداف';

  @override
  String get chooseSurah => 'اختيار سورة';

  @override
  String resumeAtPage(int page) {
    return 'المتابعة من الصفحة $page';
  }

  @override
  String goalDates(String start, String end) {
    return '$start ← $end';
  }

  @override
  String completedOn(String date) {
    return 'اكتمل في $date';
  }

  @override
  String get freeReading => 'قراءة حرة';

  @override
  String get freeReadingDescription => 'تصفّح المصحف دون التأثير على أي هدف.';

  @override
  String get readingActions => 'القراءة';

  @override
  String get markThisPageRead => 'تحديد هذه الصفحة كمقروءة';

  @override
  String get unmarkThisPage => 'إلغاء تحديد هذه الصفحة';

  @override
  String get readUntilHere => 'قرأت حتى هنا';

  @override
  String readUntilHereConfirm(int from, int to, String goal) {
    return 'تحديد الصفحات من $from إلى $to كمقروءة في «$goal»؟';
  }

  @override
  String get readUntilHereNothing => 'كل الصفحات حتى هنا مقروءة بالفعل.';

  @override
  String get markSeveralPages => 'تحديد عدة صفحات';

  @override
  String get viewProgress => 'عرض تقدمي';

  @override
  String get switchGoal => 'تغيير الهدف';

  @override
  String get switchGoalSubtitle => 'ستُستعاد آخر موضع قراءة له.';

  @override
  String get switchToFreeReading => 'الانتقال إلى القراءة الحرة';

  @override
  String get followAGoal => 'متابعة هدف';

  @override
  String pageNotCounted(int page) {
    return 'لم تُحتسب الصفحة $page — قراءة قصيرة جدًا';
  }

  @override
  String pageMarkedRead(int page) {
    return 'حُددت الصفحة $page كمقروءة';
  }

  @override
  String goalCompletedToast(String name) {
    return 'الحمد لله! اكتمل «$name».';
  }

  @override
  String get readingTrackingSettings => 'تتبع القراءة';

  @override
  String get readingTrackingSubtitle => 'التحقق التلقائي من الصفحات في المصحف';

  @override
  String get autoTracking => 'تتبع القراءة التلقائي';

  @override
  String get autoTrackingDescription =>
      'تُحتسب الصفحة مقروءة في الهدف المتابَع بعد عرضها لمدة دنيا. يمكنك دائمًا تحديد الصفحات يدويًا.';

  @override
  String get autoTrackingThreshold => 'الحد الأدنى للوقت لكل صفحة';

  @override
  String secondsShort(int count) {
    return '$count ث';
  }

  @override
  String get enabled => 'مفعّل';

  @override
  String get disabled => 'معطّل';

  @override
  String todayShort(int read, int target) {
    return 'اليوم $read/$target';
  }

  @override
  String get todayDoneShort => 'تحقّق هدف اليوم ✓';

  @override
  String get markReadShort => 'تحديد كمقروءة';

  @override
  String continuousProgressLabel(int page) {
    return 'تقدم متواصل حتى الصفحة $page';
  }

  @override
  String get readingNotStarted => 'لم تُقرأ أي صفحة بعد';

  @override
  String todayTarget(int count) {
    return 'الهدف: $count صفحة';
  }

  @override
  String todayRead(int count) {
    return 'المقروء: $count صفحة';
  }

  @override
  String recommendedPace(String pages) {
    return 'حوالي $pages صفحة في اليوم حتى النهاية';
  }

  @override
  String get pagesSectionTitle => 'الصفحات';

  @override
  String get legendRead => 'مقروءة';

  @override
  String get legendUnread => 'غير مقروءة';

  @override
  String get legendSkipped => 'متخطاة';

  @override
  String get missingPages => 'الصفحات الناقصة';

  @override
  String get noMissingPages => 'لا توجد صفحة متخطاة.';

  @override
  String pageRangeLabel(int from, int to) {
    return 'الصفحات $from–$to';
  }

  @override
  String get historyTitle => 'سجل القراءة';

  @override
  String get noPagesThatDay => 'لا صفحات';

  @override
  String pagesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count صفحة',
      few: '$count صفحات',
      two: 'صفحتان',
      one: 'صفحة واحدة',
    );
    return '$_temp0';
  }

  @override
  String get journalTitle => 'عمليات التحقق';

  @override
  String get noValidations => 'لا يوجد تحقق بعد.';

  @override
  String get validationSourceAuto => 'تلقائي';

  @override
  String get validationSourceManual => 'يدوي';

  @override
  String get actionPage => 'صفحة';

  @override
  String get actionRange => 'نطاق صفحات';

  @override
  String get actionReadUntil => 'قرأت حتى هنا';

  @override
  String get actionJuz => 'جزء';

  @override
  String get actionHizb => 'حزب';

  @override
  String get actionSurah => 'سورة';

  @override
  String get actionUnmark => 'أُلغي التحديد';

  @override
  String get markSection => 'تحديد جزء / حزب / سورة';

  @override
  String get sectionJuz => 'جزء';

  @override
  String get sectionHizb => 'حزب';

  @override
  String get sectionSurah => 'سورة';

  @override
  String sharedPagePrevious(int page) {
    return 'الصفحة $page تحتوي أيضًا على نهاية القسم السابق. ألغِ تحديدها إن لم تقرأها كاملة.';
  }

  @override
  String sharedPageNext(int page) {
    return 'الصفحة $page تحتوي أيضًا على بداية القسم التالي. ألغِ تحديدها إن لم تقرأها كاملة.';
  }

  @override
  String includePage(int page) {
    return 'تضمين الصفحة $page';
  }

  @override
  String sectionPagesSummary(String range, String count) {
    return '$range · $count';
  }

  @override
  String markSectionConfirm(String name) {
    return 'تحديد $name كمقروء';
  }

  @override
  String get statsTitle => 'أدائي';

  @override
  String get statTotalPages => 'الصفحات المقروءة';

  @override
  String get statKhatmCompleted => 'الختمات المكتملة';

  @override
  String get statCurrentStreak => 'السلسلة الحالية';

  @override
  String get statBestStreak => 'أفضل سلسلة';

  @override
  String get statAverage => 'المعدل اليومي (30 يومًا)';

  @override
  String get statBestDay => 'أفضل يوم';

  @override
  String get statReadingTime => 'وقت القراءة الفعلي';

  @override
  String periodDays(int count) {
    return '$count ي';
  }

  @override
  String get chartTitle => 'الصفحات في اليوم';

  @override
  String get byGoalTitle => 'حسب الهدف';

  @override
  String get completedKhatmTitle => 'الختمات المكتملة';

  @override
  String get noStatsYet => 'اقرأ بعض الصفحات في هدف وسيظهر أداؤك هنا.';

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours س $minutes د';
  }

  @override
  String minutesOnly(int minutes) {
    return '$minutes د';
  }

  @override
  String get encouragement => 'واصل على وتيرتك.';

  @override
  String get reminderDaily => 'تذكير يومي';

  @override
  String get reminderTime => 'وقت التذكير';

  @override
  String get reminderSheetHint =>
      'يُرسل تذكير في هذا الوقت ما لم يتحقق هدف اليوم.';

  @override
  String get setReminder => 'تذكير';

  @override
  String get remindersGlobal => 'تذكيرات القراءة';

  @override
  String get remindersGlobalDescription =>
      'السماح بالتذكيرات للأهداف التي تطلبها. لا يُرسل شيء بعد تحقق هدف اليوم.';

  @override
  String get reminderPermissionDenied =>
      'الإشعارات معطّلة للتطبيق. فعّلها في إعدادات الهاتف لتلقي التذكيرات.';

  @override
  String get reminderTitle => 'قراءتك لليوم';

  @override
  String reminderBodySingle(int count, String goal) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'بقيت $count صفحة لـ «$goal».',
      few: 'بقيت $count صفحات لـ «$goal».',
      two: 'بقيت صفحتان لـ «$goal».',
      one: 'بقيت صفحة واحدة لـ «$goal».',
    );
    return '$_temp0';
  }

  @override
  String reminderBodyMulti(int count) {
    return '$count أهداف بانتظار قراءتك.';
  }

  @override
  String get goalCompletedTitle => 'الحمد لله!';

  @override
  String get goalCompletedBody => 'لقد أتممت ختمتك للقرآن الكريم.';

  @override
  String actualDuration(String days) {
    return 'المدة الفعلية: $days';
  }

  @override
  String get startNewKhatm => 'ختمة جديدة';

  @override
  String get viewHistory => 'عرض السجل';

  @override
  String get readingGoalsHintTitle => 'تابع قراءتك';

  @override
  String get readingGoalsHintBody =>
      'أنشئ هدفًا لتعرف كل يوم عدد الصفحات التي تقرؤها، وتحقق من تقدمك مباشرة في المصحف.';

  @override
  String get later => 'لاحقًا';

  @override
  String get markPagesShort => 'تحديد صفحات';

  @override
  String get markSectionShort => 'تحديد قسم';

  @override
  String statBestDayOn(String date) {
    return 'أفضل يوم · $date';
  }

  @override
  String readUntilHereConfirmSingle(int page, String goal) {
    return 'تحديد الصفحة $page كمقروءة في «$goal»؟';
  }
}
