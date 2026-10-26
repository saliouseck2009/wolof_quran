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
  String get mushaf => 'Mushaf';

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
  String get tajweedColoring => 'Coloration tajwid';

  @override
  String get tajweedColoringDescription =>
      'Afficher les règles de tajwid en couleur dans le Mushaf';

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
  String get features => 'Fonctionnalités';

  @override
  String get searchInQuran => 'Rechercher dans le Coran';

  @override
  String get favorites => 'Favoris';

  @override
  String get bookmarks => 'Signets';

  @override
  String get recitation => 'Lecteur audio';

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
    return '$occurrences occurrence(s) dans $verses verset(s)';
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
  String get downloadLabel => 'Télécharger';

  @override
  String get continueDownload => 'Continuer';

  @override
  String get mobileDataDownloadTitle => 'Télécharger sans Wi-Fi';

  @override
  String get mobileDataDownloadMessage =>
      'Le Wi-Fi n\'est pas disponible. Télécharger avec les données mobiles peut consommer votre forfait. Voulez-vous continuer ?';

  @override
  String get audioNotYetAvailable =>
      'L\'audio de cette sourate n\'est pas encore disponible.';

  @override
  String get audioNotYetAvailableShort => 'Bientôt';

  @override
  String get audioNowAvailable => 'Disponible maintenant';

  @override
  String get newAudioUpdatesTitle => 'Nouveaux audios';

  @override
  String get noNewAudioUpdates =>
      'Aucune nouvelle disponibilité audio pour le moment.';

  @override
  String newAudioBadge(int count) {
    return 'Nouveau ($count)';
  }

  @override
  String newAudioUpdatesCount(int count) {
    return '$count nouvelle(s) sourate(s) audio disponible(s)';
  }

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
  String get shareVideo => 'Partager la Vidéo';

  @override
  String get shareCaptureFailed => 'Impossible de capturer l’image.';

  @override
  String get shareVideoGenerationFailed => 'Échec de la génération vidéo.';

  @override
  String get shareVideoUnavailableInScreenshotMode =>
      'Le partage vidéo est indisponible en mode captures d’écran.';

  @override
  String get shareActionCancelled => 'Action annulée.';

  @override
  String get shareSelectReciterForVideo =>
      'Veuillez sélectionner un récitateur pour générer la vidéo.';

  @override
  String get shareAudioUnavailableForSurah =>
      'Audio non disponible pour cette sourate.';

  @override
  String get shareAudioNotDownloaded =>
      'Audio non téléchargé pour ce récitateur. Téléchargez les audios puis réessayez.';

  @override
  String get shareAudioFileMissingAyah =>
      'Fichier audio introuvable pour cet ayah.';

  @override
  String get shareAudioFileMissingDevice =>
      'Fichier audio manquant sur l’appareil.';

  @override
  String get shareDismissed => 'Partage annulé.';

  @override
  String get shareUnavailable => 'Partage indisponible sur cet appareil.';

  @override
  String shareUnexpectedError(String error) {
    return 'Erreur : $error';
  }

  @override
  String shareDefaultText(String surahName, int verseNumber) {
    return 'Inspiration quotidienne - $surahName - Verset $verseNumber';
  }

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
  String get explorer => 'Explorer';

  @override
  String get errorLoadingBookmarks => 'Erreur lors du chargement des signets';

  @override
  String get noBookmarks => 'Aucun signet';

  @override
  String get allBookmarksCleared => 'Tous les signets ont été supprimés';

  @override
  String get salamAlaikum => 'As-salam alaykum';

  @override
  String get homeTagline => 'Découvrez la sagesse des versets en wolof';

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
  String get readByPage => 'Lire page par page';

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
  String get aboutSubtitle =>
      'Version de l\'application et informations légales';

  @override
  String get aboutDescription =>
      'Une application pour lire le Coran et écouter la traduction en langue wolof.';

  @override
  String get aboutContentSourcesTitle => 'Sources du contenu';

  @override
  String get quranTextSourceTitle => 'Source du texte coranique';

  @override
  String get audioManifestSourceTitle => 'Manifeste de disponibilité audio';

  @override
  String get tafsirAudioSourceTitle => 'Source de l\'audio tafsir';

  @override
  String get tafsirAudioSourceDetails =>
      'Imam Assane Sarr (Sénégal, Dakar, Mosquée Saad Ibn Abi Waqqas, Unité 21)';

  @override
  String get aboutContactTitle => 'Contact';

  @override
  String get contactEmailLabel => 'Email';

  @override
  String get copyLabel => 'Copier';

  @override
  String get copiedToClipboard => 'Copie dans le presse-papiers';

  @override
  String appVersion(String version) {
    return 'Version $version';
  }

  @override
  String get privacyPolicy => 'Politique de confidentialité';

  @override
  String get privacyPolicySubtitle => 'Votre vie privée compte';

  @override
  String get privacyPolicyValue => 'Consulter';

  @override
  String get privacyPolicyPageTitle => 'Politique de confidentialité';

  @override
  String privacyPolicyLastUpdated(String date) {
    return 'Dernière mise à jour : $date';
  }

  @override
  String get privacyPolicyIntro =>
      'Coran Wolof ne collecte, ne stocke et ne transmet aucune donnée personnelle. Votre vie privée est entièrement respectée.';

  @override
  String get privacyPolicyLocalDataTitle =>
      'Données stockées sur votre appareil';

  @override
  String get privacyPolicyLocalDataBody =>
      'Toutes vos données restent sur votre appareil et ne sont jamais envoyées à un serveur :\n\n- Vos préférences (langue, thème, taille de police, récitateur choisi)\n- Les fichiers audio téléchargés\n- Les signets et la progression de lecture';

  @override
  String get privacyPolicyInternetTitle => 'Accès Internet';

  @override
  String get privacyPolicyInternetBody =>
      'L\'application utilise une connexion Internet uniquement pour :\n\n- Télécharger les récitations audio du Coran\n- Vérifier les mises à jour de l\'application\n\nAucune information personnelle n\'est envoyée lors de ces opérations.';

  @override
  String get privacyPolicyPermissionsTitle => 'Permissions';

  @override
  String get privacyPolicyPermissionsBody =>
      'L\'application ne demande que les permissions strictement nécessaires :\n\n- Internet : pour télécharger le contenu audio\n- Lecture audio : pour jouer les récitations du Coran, y compris en arrière-plan';

  @override
  String get privacyPolicyThirdPartyTitle => 'Liens externes';

  @override
  String get privacyPolicyThirdPartyBody =>
      'L\'application peut ouvrir des liens externes vers des services tiers. Ces services ont leurs propres politiques de confidentialité, et nous ne contrôlons pas leurs pratiques de données.';

  @override
  String get privacyPolicyChildrenTitle => 'Adapté à tous les âges';

  @override
  String get privacyPolicyChildrenBody =>
      'Puisque l\'application ne collecte aucune donnée personnelle, elle est sûre pour les utilisateurs de tous âges, y compris les enfants.';

  @override
  String get privacyPolicyContactTitle => 'Contact';

  @override
  String privacyPolicyContactBody(String email) {
    return 'Pour toute question concernant cette politique : $email';
  }

  @override
  String privacyPolicyPublisher(String name) {
    return 'Éditeur : $name';
  }

  @override
  String get privacyPolicyAgeRating =>
      'Cette application est destinée à tous les publics (tout âge).';

  @override
  String get privacyPolicyOnlineVersion => 'Politique complète en ligne';

  @override
  String get quranSettingsDescription => 'Personnalisez votre lecture du Coran';

  @override
  String get audioAndReciters => 'Audio et auteur(s) de tafsir';

  @override
  String get manageRecitersAndDownloadAudio =>
      'Gérer les auteur(s) de tafsir et télécharger l\'audio';

  @override
  String get viewAvailableReciters =>
      'Voir les auteur(s) de tafsir disponibles';

  @override
  String get unknown => 'Inconnu';

  @override
  String get availableReciters => 'Auteur(s) de tafsir disponibles';

  @override
  String get errorLoadingReciters =>
      'Erreur lors du chargement des auteur(s) de tafsir';

  @override
  String get retry => 'Réessayer';

  @override
  String get noRecitersAvailable => 'Aucun auteur de tafsir disponible';

  @override
  String get checkBackLaterReciters =>
      'Revenez plus tard pour voir les auteur(s) de tafsir disponibles';

  @override
  String get selectReciter => 'Sélectionner un auteur de tafsir';

  @override
  String get browseAndSelectReciterHint =>
      'Touchez la carte pour parcourir • Touchez le bouton pour définir par défaut';

  @override
  String get defaultReciter => 'Auteur de tafsir par défaut';

  @override
  String get available => 'Disponible';

  @override
  String selectedAsDefaultReciter(String name) {
    return '$name sélectionné comme auteur de tafsir par défaut';
  }

  @override
  String get audioDownloads => 'Téléchargements audio';

  @override
  String get noReciterSelected => 'Aucun auteur de tafsir sélectionné';

  @override
  String get change => 'Changer';

  @override
  String ayahCountLabel(int count) {
    return '$count verset(s)';
  }

  @override
  String surahAudioDeleted(String surahName) {
    return 'Audio de $surahName supprimé';
  }

  @override
  String get downloadInProgress =>
      'Un téléchargement est déjà en cours. Veuillez attendre la fin avant d\'en lancer un autre.';

  @override
  String get surahDownloadAlreadyInProgress =>
      'Le téléchargement de cette sourate est déjà en cours.';

  @override
  String get queued => 'En file';

  @override
  String get alreadyQueued =>
      'Cette sourate est déjà dans la file de téléchargement.';

  @override
  String get retryDownload => 'Relancer le téléchargement';

  @override
  String get deleteAudioLabel => 'Supprimer l\'audio';

  @override
  String get confirmDeleteSurahAudioTitle => 'Supprimer l\'audio ?';

  @override
  String confirmDeleteSurahAudioMessage(String surahName) {
    return 'Êtes-vous sûr de vouloir supprimer l\'audio de $surahName ? Cette action est irréversible.';
  }

  @override
  String get delete => 'Supprimer';

  @override
  String get downloadFailedShort => 'Téléchargement échoué';

  @override
  String queuePositionLabel(int position) {
    return 'En file (#$position)';
  }

  @override
  String get playbackModeOff => 'Mode de lecture : arrêt en fin de piste';

  @override
  String get playbackModeRepeatOne => 'Mode de lecture : répéter la piste';

  @override
  String get playbackModeRepeatAll => 'Mode de lecture : répéter la file';

  @override
  String get playbackModeShuffle => 'Mode de lecture : aléatoire';

  @override
  String get selectSurah => 'Sélectionner une sourate';

  @override
  String pageNumberLabel(int page) {
    return 'Page $page';
  }

  @override
  String get shareGeneratingVideo => 'Génération de la vidéo en cours...';

  @override
  String get sharePreparingContent => 'Préparation du partage...';

  @override
  String get previousVerse => 'Verset précédent';

  @override
  String get nextVerse => 'Verset suivant';

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
  String get nowPlaying => 'En cours de lecture';

  @override
  String get collapsePlayer => 'Réduire';

  @override
  String get previousSurah => 'Précédent';

  @override
  String get nextSurah => 'Suivant';

  @override
  String get rewind10s => 'Reculer 10s';

  @override
  String get forward10s => 'Avancer 10s';

  @override
  String hizbThreeQuarter(int n) {
    return '3/4 Hizb $n';
  }

  @override
  String get supportProject => 'Soutenir le projet';

  @override
  String get supportSubtitle => 'Contribuez au maintien de l\'application';

  @override
  String get supportPageTitle => 'Soutenir Coran Wolof';

  @override
  String get supportUnavailableOnIosTitle =>
      'Le soutien est indisponible sur iOS';

  @override
  String get supportUnavailableOnIosBody =>
      'Pour respecter les règles de l\'App Store, cette section de soutien est actuellement désactivée sur iOS.';

  @override
  String get payWithWave => 'Wave';

  @override
  String get piSpiPayment => 'PI SPI';

  @override
  String get copyId => 'Copier l\'identifiant';

  @override
  String get supportValue => 'Jazaakumullaahu khairan';

  @override
  String get playVerseRange => 'Lire plusieurs versets';

  @override
  String get playUntilSurahEnd => 'Jusqu\'à la fin';

  @override
  String get customVerseRange => 'Personnalisée';

  @override
  String get rangeStartLabel => 'De';

  @override
  String get rangeEndLabel => 'À';

  @override
  String versesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count versets',
      one: '1 verset',
    );
    return '$_temp0';
  }

  @override
  String playVersesCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Lire $count versets',
      one: 'Lire 1 verset',
    );
    return '$_temp0';
  }

  @override
  String verseRangeSubtitle(String reference) {
    return 'Lecture continue à partir de $reference';
  }

  @override
  String addVersesChip(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '+$count versets',
      one: '+1 verset',
    );
    return '$_temp0';
  }

  @override
  String get surahEndChip => 'Fin de la sourate';

  @override
  String get chooseFirstVerse => 'Choisir le premier verset';

  @override
  String get chooseLastVerse => 'Choisir le dernier verset';

  @override
  String get searchSurahOrNumber => 'Rechercher une sourate ou un numéro';

  @override
  String verseCountShort(int count) {
    return '$count v.';
  }

  @override
  String get readingGoals => 'Mes objectifs';

  @override
  String get readingGoalsSubtitle => 'Planifiez votre Khatm';

  @override
  String get newReadingGoal => 'Nouvel objectif';

  @override
  String get editReadingGoal => 'Modifier l\'objectif';

  @override
  String get readingGoalsOngoing => 'En cours';

  @override
  String get readingGoalsPlanned => 'Planifiés';

  @override
  String get readingGoalsFinished => 'Terminés';

  @override
  String get noReadingGoalsTitle => 'Aucun objectif de lecture';

  @override
  String get noReadingGoalsDescription =>
      'Planifiez un Khatm à votre rythme : choisissez une durée et l\'application vous indique combien de pages lire chaque jour.';

  @override
  String get noReadingGoalsInSection => 'Rien ici pour le moment';

  @override
  String get createReadingGoal => 'Créer un objectif';

  @override
  String get continueReading => 'Continuer la lecture';

  @override
  String readingProgressLabel(int validated, int total) {
    return '$validated/$total pages';
  }

  @override
  String readingValidatedOf(int validated, int total) {
    return '$validated pages lues sur $total';
  }

  @override
  String percentValue(int percent) {
    return '$percent %';
  }

  @override
  String readingTodayProgress(int read, int target) {
    return 'Aujourd\'hui : $read/$target pages';
  }

  @override
  String get readingTodayDone => 'Objectif du jour atteint ✓';

  @override
  String readingRemainingToday(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Il reste $count pages à lire aujourd\'hui',
      one: 'Il reste 1 page à lire aujourd\'hui',
    );
    return '$_temp0';
  }

  @override
  String readingDaysLeft(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours restants',
      one: '1 jour restant',
    );
    return '$_temp0';
  }

  @override
  String readingEndsOn(String date) {
    return 'Fin le $date';
  }

  @override
  String readingStartsOn(String date) {
    return 'Début le $date';
  }

  @override
  String readingPaceAhead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages d\'avance',
      one: '1 page d\'avance',
    );
    return '$_temp0';
  }

  @override
  String readingPaceBehind(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages de retard',
      one: '1 page de retard',
    );
    return '$_temp0';
  }

  @override
  String get readingPaceOnTrack => 'Dans les temps';

  @override
  String get readingStatusActive => 'Actif';

  @override
  String get readingStatusPaused => 'En pause';

  @override
  String get readingStatusPlanned => 'Planifié';

  @override
  String get readingStatusCompleted => 'Terminé';

  @override
  String get readingStatusExpired => 'Expiré';

  @override
  String get readingStatusAbandoned => 'Abandonné';

  @override
  String get readingGoalFollowed => 'Suivi dans le Mushaf';

  @override
  String get followGoal => 'Suivre cet objectif';

  @override
  String get renameGoal => 'Renommer';

  @override
  String get changeEndDate => 'Modifier la date de fin';

  @override
  String get pauseGoal => 'Mettre en pause';

  @override
  String get resumeGoal => 'Reprendre';

  @override
  String get abandonGoal => 'Abandonner';

  @override
  String get deleteGoal => 'Supprimer';

  @override
  String get duplicateGoal => 'Nouvel objectif à partir de celui-ci';

  @override
  String get reactivateGoal => 'Réactiver';

  @override
  String get extendGoal => 'Prolonger';

  @override
  String get deleteGoalConfirmTitle => 'Supprimer cet objectif ?';

  @override
  String get deleteGoalConfirmBody =>
      'Sa progression et son historique seront perdus. Cette action est irréversible.';

  @override
  String get abandonGoalConfirmTitle => 'Abandonner cet objectif ?';

  @override
  String get abandonGoalConfirmBody =>
      'Sa progression est conservée et vous pourrez le réactiver plus tard.';

  @override
  String get confirm => 'Confirmer';

  @override
  String get markPagesRead => 'Marquer des pages comme lues';

  @override
  String get untilPageMode => 'Jusqu\'à une page';

  @override
  String get pageRangeMode => 'Plage de pages';

  @override
  String get untilPageHint =>
      'Marque toutes les pages non lues de l\'objectif jusqu\'à cette page, dans l\'ordre de lecture.';

  @override
  String get fromPageLabel => 'De la page';

  @override
  String get toPageLabel => 'À la page';

  @override
  String get pageFieldLabel => 'Page';

  @override
  String pagesToMarkSummary(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages seront marquées comme lues',
      one: '1 page sera marquée comme lue',
      zero: 'Aucune nouvelle page à marquer',
    );
    return '$_temp0';
  }

  @override
  String pagesAlreadyRead(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count déjà lues',
      one: '1 déjà lue',
    );
    return '$_temp0';
  }

  @override
  String get markAsRead => 'Marquer comme lues';

  @override
  String pagesMarked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count pages marquées comme lues',
      one: '1 page marquée comme lue',
    );
    return '$_temp0';
  }

  @override
  String get undo => 'Annuler';

  @override
  String invalidPage(int total) {
    return 'Saisissez une page entre 1 et $total';
  }

  @override
  String get goalName => 'Nom de l\'objectif';

  @override
  String get goalNameHint => 'ex. Khatm Ramadan';

  @override
  String defaultGoalName(int number) {
    return 'Khatm $number';
  }

  @override
  String get goalDuration => 'Durée';

  @override
  String durationDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count jours',
      one: '1 jour',
    );
    return '$_temp0';
  }

  @override
  String get customDuration => 'Personnalisée';

  @override
  String get pickEndDate => 'Date de fin';

  @override
  String get goalStartPoint => 'Point de départ';

  @override
  String get startFromBeginning => 'Début du Coran';

  @override
  String get startFromCurrentPage => 'Page actuelle';

  @override
  String get startFromChosenPage => 'Page choisie';

  @override
  String get goalStartDate => 'Date de début';

  @override
  String get today => 'Aujourd\'hui';

  @override
  String get chooseDate => 'Choisir une date';

  @override
  String get goalSummary => 'Récapitulatif';

  @override
  String get pagesToRead => 'Pages à lire';

  @override
  String averagePerDay(String pages) {
    return 'Environ $pages pages par jour';
  }

  @override
  String get goalCreate => 'Créer l\'objectif';

  @override
  String get goalSave => 'Enregistrer';

  @override
  String get nextStep => 'Suivant';

  @override
  String get homeReadingTitle => 'Lecture en cours';

  @override
  String get homeReadingEmptyTitle => 'Planifiez votre lecture du Coran';

  @override
  String get homeReadingEmptyBody =>
      'Fixez un objectif et sachez chaque jour combien de pages lire.';

  @override
  String get seeAllGoals => 'Tous les objectifs';

  @override
  String get chooseSurah => 'Choisir une sourate';

  @override
  String resumeAtPage(int page) {
    return 'Reprendre à la page $page';
  }

  @override
  String goalDates(String start, String end) {
    return '$start → $end';
  }

  @override
  String completedOn(String date) {
    return 'Terminé le $date';
  }

  @override
  String get freeReading => 'Lecture libre';

  @override
  String get freeReadingDescription =>
      'Parcourez le Mushaf sans toucher à aucun objectif.';

  @override
  String get readingActions => 'Lecture';

  @override
  String get markThisPageRead => 'Marquer cette page comme lue';

  @override
  String get unmarkThisPage => 'Retirer la validation de cette page';

  @override
  String get readUntilHere => 'J\'ai lu jusqu\'ici';

  @override
  String readUntilHereConfirm(int from, int to, String goal) {
    return 'Marquer les pages $from à $to comme lues dans « $goal » ?';
  }

  @override
  String get readUntilHereNothing =>
      'Toutes les pages jusqu\'ici sont déjà lues.';

  @override
  String get markSeveralPages => 'Marquer plusieurs pages';

  @override
  String get viewProgress => 'Voir ma progression';

  @override
  String get switchGoal => 'Changer d\'objectif';

  @override
  String get switchGoalSubtitle =>
      'Sa dernière position de lecture sera restaurée.';

  @override
  String get switchToFreeReading => 'Passer en lecture libre';

  @override
  String get followAGoal => 'Suivre un objectif';

  @override
  String pageNotCounted(int page) {
    return 'Page $page non comptabilisée — lecture trop courte';
  }

  @override
  String pageMarkedRead(int page) {
    return 'Page $page marquée comme lue';
  }

  @override
  String goalCompletedToast(String name) {
    return 'Alhamdulillah ! « $name » est terminé.';
  }

  @override
  String get readingTrackingSettings => 'Suivi de lecture';

  @override
  String get readingTrackingSubtitle =>
      'Validation automatique des pages dans le Mushaf';

  @override
  String get autoTracking => 'Suivi automatique de lecture';

  @override
  String get autoTrackingDescription =>
      'Une page est comptée comme lue dans l\'objectif suivi après un temps minimum d\'affichage. Vous pouvez toujours marquer les pages à la main.';

  @override
  String get autoTrackingThreshold => 'Temps minimum par page';

  @override
  String secondsShort(int count) {
    return '$count s';
  }

  @override
  String get enabled => 'Activé';

  @override
  String get disabled => 'Désactivé';

  @override
  String todayShort(int read, int target) {
    return 'Aujourd\'hui $read/$target';
  }

  @override
  String get todayDoneShort => 'Objectif du jour atteint ✓';

  @override
  String get markReadShort => 'Marquer comme lue';

  @override
  String continuousProgressLabel(int page) {
    return 'Progression continue jusqu\'à la page $page';
  }

  @override
  String get readingNotStarted => 'Aucune page lue pour le moment';

  @override
  String todayTarget(int count) {
    return 'Objectif : $count pages';
  }

  @override
  String todayRead(int count) {
    return 'Lues : $count pages';
  }

  @override
  String recommendedPace(String pages) {
    return 'Environ $pages pages par jour jusqu\'à la fin';
  }

  @override
  String get pagesSectionTitle => 'Pages';

  @override
  String get legendRead => 'Lue';

  @override
  String get legendUnread => 'Non lue';

  @override
  String get legendSkipped => 'Sautée';

  @override
  String get missingPages => 'Pages manquantes';

  @override
  String get noMissingPages => 'Aucune page sautée.';

  @override
  String pageRangeLabel(int from, int to) {
    return 'Pages $from–$to';
  }

  @override
  String get historyTitle => 'Historique de lecture';

  @override
  String get noPagesThatDay => 'Aucune page';

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
  String get noValidations => 'Aucune validation pour le moment.';

  @override
  String get validationSourceAuto => 'automatique';

  @override
  String get validationSourceManual => 'manuelle';

  @override
  String get actionPage => 'Page';

  @override
  String get actionRange => 'Plage de pages';

  @override
  String get actionReadUntil => 'Lu jusqu\'ici';

  @override
  String get actionJuz => 'Juz';

  @override
  String get actionHizb => 'Hizb';

  @override
  String get actionSurah => 'Sourate';

  @override
  String get actionUnmark => 'Validation retirée';

  @override
  String get markSection => 'Marquer un Juz, un Hizb ou une Sourate';

  @override
  String get sectionJuz => 'Juz';

  @override
  String get sectionHizb => 'Hizb';

  @override
  String get sectionSurah => 'Sourate';

  @override
  String sharedPagePrevious(int page) {
    return 'La page $page contient aussi la fin de la section précédente. Décochez-la si vous ne l\'avez pas lue entièrement.';
  }

  @override
  String sharedPageNext(int page) {
    return 'La page $page contient aussi le début de la section suivante. Décochez-la si vous ne l\'avez pas lue entièrement.';
  }

  @override
  String includePage(int page) {
    return 'Inclure la page $page';
  }

  @override
  String sectionPagesSummary(String range, String count) {
    return '$range · $count';
  }

  @override
  String markSectionConfirm(String name) {
    return 'Marquer $name comme lu';
  }

  @override
  String get statsTitle => 'Mes performances';

  @override
  String get statTotalPages => 'Pages lues';

  @override
  String get statKhatmCompleted => 'Khatm terminés';

  @override
  String get statCurrentStreak => 'Série en cours';

  @override
  String get statBestStreak => 'Meilleure série';

  @override
  String get statAverage => 'Moyenne par jour (30 j)';

  @override
  String get statBestDay => 'Meilleur jour';

  @override
  String get statReadingTime => 'Temps de lecture actif';

  @override
  String periodDays(int count) {
    return '$count j';
  }

  @override
  String get chartTitle => 'Pages par jour';

  @override
  String get byGoalTitle => 'Par objectif';

  @override
  String get completedKhatmTitle => 'Khatm terminés';

  @override
  String get noStatsYet =>
      'Lisez quelques pages dans un objectif et vos performances apparaîtront ici.';

  @override
  String hoursMinutes(int hours, int minutes) {
    return '$hours h $minutes min';
  }

  @override
  String minutesOnly(int minutes) {
    return '$minutes min';
  }

  @override
  String get encouragement => 'Continuez à votre rythme.';
}
