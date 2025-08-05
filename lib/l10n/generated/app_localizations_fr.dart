// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for French (`fr`).
class AppLocalizationsFr extends AppLocalizations {
  AppLocalizationsFr([String locale = 'fr']) : super(locale);

  @override
  String get appTitle => 'Coran Wolof';

  @override
  String get welcome => 'Bienvenue dans Coran Wolof';

  @override
  String get quran => 'Coran';

  @override
  String get surah => 'Sourate';

  @override
  String get ayah => 'Verset';

  @override
  String get play => 'Lire';

  @override
  String get pause => 'Pause';

  @override
  String get stop => 'Arrêter';

  @override
  String get settings => 'Paramètres';

  @override
  String get language => 'Langue';

  @override
  String get theme => 'Thème';

  @override
  String get dark => 'Sombre';

  @override
  String get light => 'Clair';

  @override
  String get arabic => 'Arabe';

  @override
  String get french => 'Français';

  @override
  String get english => 'Anglais';

  @override
  String get wolof => 'Wolof';

  @override
  String get search => 'Rechercher';

  @override
  String get searchInQuran => 'Rechercher dans le Coran';

  @override
  String get favorites => 'Favoris';

  @override
  String get bookmarks => 'Signets';

  @override
  String get recitation => 'Récitation';

  @override
  String get translation => 'Traduction';

  @override
  String get current => 'Actuel';

  @override
  String get system => 'Système';

  @override
  String get version => 'Version';

  @override
  String get support => 'Support';

  @override
  String get rateApp => 'Évaluer l\'app';

  @override
  String get getHelp => 'Obtenir de l\'aide';

  @override
  String get giveRating => 'Donnez votre avis';

  @override
  String get close => 'Fermer';

  @override
  String get developedWithLove =>
      'Développé avec ❤️ pour la communauté musulmane';

  @override
  String get surahs => 'Sourates';

  @override
  String get searchSurah => 'Rechercher une sourate...';

  @override
  String get verses => 'versets';

  @override
  String get revelation => 'Révélation';

  @override
  String get meccan => 'Mecquoise';

  @override
  String get medinan => 'Médinoise';

  @override
  String get noSurahFound => 'Aucune sourate trouvée';

  @override
  String get tryDifferentSearch => 'Essayez un autre terme de recherche';

  @override
  String get quranSettings => 'Paramètres du Coran';

  @override
  String get translationSettings => 'Traduction';

  @override
  String get selectTranslation => 'Sélectionner la traduction';

  @override
  String get currentTranslation => 'Traduction actuelle';

  @override
  String get changeTranslation => 'Changer la traduction';

  @override
  String get translationDescription =>
      'Choisissez votre traduction préférée pour les versets et chapitres du Coran';

  @override
  String translationUpdated(String language) {
    return 'Traduction mise à jour vers $language';
  }

  @override
  String get cancel => 'Annuler';

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
