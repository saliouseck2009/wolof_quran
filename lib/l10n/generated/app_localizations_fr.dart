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
  String get aboutSubtitle => 'Version de l\'application et support';

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
      'La page de soutien contient des liens vers des services de paiement externes (Wave, PI SPI). Ces services ont leurs propres politiques de confidentialité. Nous ne recevons ni ne stockons aucune information de paiement.';

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
  String get queued => 'En file';

  @override
  String get alreadyQueued =>
      'Cette sourate est déjà dans la file de téléchargement.';

  @override
  String get retryDownload => 'Relancer le téléchargement';

  @override
  String get deleteAudioLabel => 'Supprimer l\'audio';

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
  String get payWithWave => 'Wave';

  @override
  String get piSpiPayment => 'PI SPI';

  @override
  String get copyId => 'Copier l\'identifiant';

  @override
  String get supportValue => 'Jazaakumullaahu khairan';
}
