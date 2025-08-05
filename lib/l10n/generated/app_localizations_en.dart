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
  String get searchInQuran => 'Search in Quran';

  @override
  String get favorites => 'Favorites';

  @override
  String get bookmarks => 'Bookmarks';

  @override
  String get recitation => 'Recitation';

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
    return 'Found $occurrences occurrence(s) in $verses verse(s)';
  }
}
