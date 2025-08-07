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
    return 'Found $occurrences occurrence(s) in $verses verse(s)';
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
  String errorCheckingDownloadStatus(String error) {
    return 'خطأ في فحص حالة التحميل: $error';
  }

  @override
  String get checkFailed => 'فشل الفحص';

  @override
  String get downloadToPlay => 'تحميل للتشغيل';

  @override
  String get pauseSurah => 'إيقاف مؤقت للسورة';

  @override
  String get resumeSurah => 'استئناف السورة';

  @override
  String get playSurah => 'تشغيل السورة';
}
