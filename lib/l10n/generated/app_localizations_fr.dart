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
  String get searchQuran => 'Rechercher dans le Coran';

  @override
  String get enterWordsToSearch => 'Saisissez des mots à rechercher...';

  @override
  String get searchTheQuran => 'Recherchez dans le Coran';

  @override
  String get enterWordsToFindVerses =>
      'Saisissez des mots pour trouver des versets dans le Coran';

  @override
  String get searchError => 'Erreur de recherche';

  @override
  String get noResultsFound => 'Aucun résultat trouvé';

  @override
  String get tryDifferentSearchTerms => 'Essayez d\'autres termes de recherche';

  @override
  String foundOccurrences(int occurrences, int verses) {
    return '$occurrences occurrence(s) trouvée(s) dans $verses verset(s)';
  }

  @override
  String get audioNotAvailable =>
      'Audio non disponible. Veuillez d\'abord télécharger la sourate.';

  @override
  String get checkInternetConnection =>
      'Vérifiez votre connexion Internet et réessayez';

  @override
  String get connectionTimeout =>
      'Délai de connexion dépassé. Veuillez réessayer';

  @override
  String get audioFileNotFound => 'Fichier audio introuvable sur le serveur';

  @override
  String get accessDeniedToAudio => 'Accès refusé au fichier audio';

  @override
  String get notEnoughStorage => 'Espace de stockage insuffisant';

  @override
  String get downloadFailed => 'Échec du téléchargement. Veuillez réessayer';

  @override
  String surahsDownloaded(int count) {
    return '$count/114 Sourates téléchargées';
  }

  @override
  String get downloaded => 'Téléchargée';

  @override
  String get notDownloaded => 'Non téléchargée';

  @override
  String get downloading => 'Téléchargement...';

  @override
  String downloadedSuccessfully(String surahName) {
    return '$surahName téléchargée avec succès';
  }

  @override
  String downloadFailedWithError(String error) {
    return 'Échec du téléchargement : $error';
  }

  @override
  String get tryAgain => 'Réessayer';

  @override
  String get dioStatus404 =>
      'L’audio de ce chapitre n’est pas encore disponible. Merci de réessayer plus tard';

  @override
  String errorCheckingDownloadStatus(String error) {
    return 'Erreur lors de la vérification du statut de téléchargement : $error';
  }

  @override
  String get checkFailed => 'Vérification échouée';

  @override
  String get downloadToPlay => 'Télécharger pour lire';

  @override
  String get pauseSurah => 'Mettre en pause la Sourate';

  @override
  String get resumeSurah => 'Reprendre la Sourate';

  @override
  String get playSurah => 'Lire la Sourate';

  @override
  String get arabicAndTranslation => 'Arabe et Traduction';

  @override
  String get arabicOnly => 'Arabe Seulement';

  @override
  String get translationOnly => 'Traduction Seulement';

  @override
  String get fontSettings => 'Paramètres de Police';

  @override
  String get ayahFontSize => 'Taille de Police des Versets';

  @override
  String get fontSizeDescription =>
      'Ajuster la taille du texte arabe dans les versets';

  @override
  String get small => 'Petit';

  @override
  String get large => 'Grand';

  @override
  String get shareAyah => 'Partager le Verset';

  @override
  String get customizeAndShare => 'Personnaliser et Partager';

  @override
  String get backgroundStyle => 'Style d\'Arrière-plan';

  @override
  String get displayStyle => 'Style d\'Affichage';

  @override
  String get shareImage => 'Partager l\'Image';

  @override
  String get bookmarkAdded => 'Marque-page ajouté';

  @override
  String get bookmarkRemoved => 'Marque-page supprimé';

  @override
  String get noBookmarksDescription =>
      'Marquez vos versets préférés pour y accéder facilement';

  @override
  String get clearAllBookmarks => 'Tout effacer';

  @override
  String get confirmClearBookmarks => 'Effacer tous les marque-pages ?';

  @override
  String get clearBookmarksMessage => 'Cette action ne peut pas être annulée.';

  @override
  String get clear => 'Effacer';

  @override
  String get salamAlaikum => 'As-salam alaykum';

  @override
  String get dailyInspirationTitle => 'Inspiration quotidienne';

  @override
  String get loadingDailyInspiration =>
      'Chargement de l\'inspiration quotidienne...';

  @override
  String get holyQuran => 'Le Noble Coran';

  @override
  String get tapForDailyVerse =>
      'Appuyez pour obtenir votre verset du jour du Coran';

  @override
  String get tapAnywhereToStart => 'Touchez n\'importe où pour commencer';

  @override
  String get tapToReadArabicMore => 'Appuyez pour lire l\'arabe et plus';

  @override
  String get openSurah => 'Ouvrir la sourate';

  @override
  String get bookmark => 'Marquer';

  @override
  String get bookmarked => 'Marqué';

  @override
  String get readSurahs => 'Lire les sourates';

  @override
  String get listenAudio => 'Écouter l\'audio';

  @override
  String get findVerses => 'Trouver des versets';

  @override
  String get savedAyahs => 'Versets enregistrés';

  @override
  String get settingsDescription => 'Personnalisez votre expérience de lecture';

  @override
  String get changeAppLanguage => 'Changer la langue de l\'application';

  @override
  String get chooseAppTheme => 'Choisir le thème de l\'application';

  @override
  String get managePreferences => 'Gérer les préférences';

  @override
  String get about => 'À propos';

  @override
  String get aboutSubtitle => 'Version de l\'application et support';

  @override
  String get aboutDescription =>
      'Une application pour lire le Coran et écouter les récitations en langue wolof.';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get quranSettingsDescription => 'Personnalisez votre lecture du Coran';

  @override
  String get audioAndReciters => 'Audio et récitateur(s)';

  @override
  String get manageRecitersAndDownloadAudio =>
      'Gérer les récitateur(s) et télécharger l\'audio';

  @override
  String get viewAvailableReciters => 'Voir les récitateur(s) disponibles';

  @override
  String get unknown => 'Inconnu';

  @override
  String get availableReciters => 'Récitateur(s) disponibles';

  @override
  String get errorLoadingReciters =>
      'Erreur lors du chargement des récitateur(s)';

  @override
  String get retry => 'Réessayer';

  @override
  String get noRecitersAvailable => 'Aucun récitateur disponible';

  @override
  String get checkBackLaterReciters =>
      'Revenez plus tard pour voir les récitateur(s) disponibles';

  @override
  String get selectReciter => 'Sélectionner un récitateur';

  @override
  String get browseAndSelectReciterHint =>
      'Touchez la carte pour parcourir • Touchez le bouton pour définir par défaut';

  @override
  String get defaultReciter => 'Récitateur par défaut';

  @override
  String get available => 'Disponible';

  @override
  String selectedAsDefaultReciter(String name) {
    return '$name sélectionné comme récitateur par défaut';
  }

  @override
  String get audioDownloads => 'Téléchargements audio';

  @override
  String get noReciterSelected => 'Aucun récitateur sélectionné';

  @override
  String get change => 'Changer';

  @override
  String ayahCountLabel(int count) {
    return '$count verset(s)';
  }
}
