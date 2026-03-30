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
  String get recitation => 'التلاوة';

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
  String get aboutSubtitle => 'إصدار التطبيق والدعم';

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
  String copiedToClipboard(String label) {
    return 'تم نسخ $label';
  }

  @override
  String appVersion(String version) {
    return 'الإصدار $version';
  }

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
  String get queued => 'في الانتظار';

  @override
  String get alreadyQueued => 'هذه السورة موجودة بالفعل في قائمة التنزيل.';

  @override
  String get retryDownload => 'إعادة محاولة التنزيل';

  @override
  String get deleteAudioLabel => 'حذف الصوت';

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
  String hizbThreeQuarter(int n) {
    return 'ثلاثة أرباع حزب $n';
  }
}
