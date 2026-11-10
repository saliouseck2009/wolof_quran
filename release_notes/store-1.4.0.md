# Coran Wolof — fiche de publication 1.4.0 (App Store + Google Play)

Ce document contient tout ce qu'il faut saisir dans **App Store Connect** et dans la
**Google Play Console** pour publier la version 1.4.0. Il est écrit pour être confié à un
agent IA qui remplit les formulaires.

## 0. Consignes pour l'agent

- Copier les textes des blocs `text` **tels quels**, sans les reformuler ni les traduire.
- Chaque bloc indique sa limite de caractères ; toutes les limites ont été vérifiées.
- Ne remplir que les langues qui existent déjà dans la fiche du store. Si une seule langue
  existe, utiliser le français.
- Les champs marqués **« inchangé »** ne doivent pas être modifiés.
- Les champs marqués **« à confirmer »** ne sont pas visibles publiquement : garder la
  valeur déjà saisie si elle existe, sinon utiliser la proposition.
- Enregistrer les brouillons, puis **s'arrêter avant** « Soumettre pour vérification »
  (Apple) et « Lancer le déploiement en production » (Google) : le propriétaire valide
  ces deux actions lui-même.
- Ne saisir aucun mot de passe ni coordonnée bancaire ; la connexion aux consoles est
  faite par le propriétaire.

## 1. Identité de l'application

| Élément | Valeur |
|---|---|
| Nom sur les stores | Coran Wolof |
| Nom affiché sous l'icône | Wolof Quran |
| Version à publier | **1.4.0** |
| Numéro de build iOS / versionCode Android | **13** |
| Version actuellement en ligne | 1.3.0 (build 10) |
| Bundle ID iOS | `com.saliouseck.wolofquran` |
| Apple ID de l'app | `6761394820` |
| Package Android | `com.saliouseck.wolofquran` |
| Fiche App Store | https://apps.apple.com/sn/app/coran-wolof/id6761394820 |
| Fiche Google Play | https://play.google.com/store/apps/details?id=com.saliouseck.wolofquran |
| Vendeur / développeur | Saliou Seck |
| Contact | saliouseck2009@gmail.com |
| Langues de l'application | Français (principale), anglais, arabe |
| Appareils iOS | iPhone et iPad, iOS 15.0 minimum |
| Prix | Gratuit, sans publicité, sans compte |

## 2. Ce qui change depuis la 1.3.0 (résumé interne)

1. **Objectifs de lecture (Khatm)** : création d'un objectif avec durée, point de départ
   et date de début ; l'application calcule le nombre de pages par jour. Plusieurs
   objectifs possibles, avec pause, reprise, prolongation, duplication, abandon.
2. **Suivi dans le Mushaf** : validation automatique d'une page après un temps minimum
   d'affichage (réglable), ou validation manuelle par page, plage de pages, Juz, Hizb ou
   sourate. Mode « lecture libre » sans objectif.
3. **Rappel quotidien** : notification locale à l'heure choisie, envoyée seulement si le
   quota du jour n'est pas atteint ; elle ouvre le Mushaf.
4. **Page « Mes performances »** : pages lues, Khatm terminés, série en cours, meilleure
   série, moyenne sur 30 jours, meilleur jour, temps de lecture, graphique par jour.
5. **Nouvel écran d'accueil** : bandeau du Khatm en cours, grille d'accès rapide, carte
   « Verset du jour ».
6. **Lecture de plusieurs versets à la suite** depuis la liste des versets et le Mushaf.
7. **Mushaf plus rapide** : défilement des pages plus fluide.
8. **Écran maintenu allumé** pendant la lecture du Mushaf.
9. **Réglages redessinés** (menus et feuilles au même style), messages aux couleurs du thème.
10. **iOS uniquement** : l'entrée « Soutenir le projet » des réglages ouvre une page web
    dans Safari. Compatibilité iOS 27.

Nouveautés techniques à déclarer : permission de notifications (iOS et Android),
`RECEIVE_BOOT_COMPLETED` sur Android. Aucune nouvelle collecte de données.

---

## 3. App Store Connect

Chemin : App Store Connect → Apps → Coran Wolof → « + Version ou plateforme » → iOS → `1.4.0`.

### 3.1 Nouveautés de cette version

#### Français — max 4000

```text
Nouveau : objectifs de lecture (Khatm)
• Planifiez un Khatm à votre rythme : choisissez une durée et un point de départ, l'application vous indique combien de pages lire chaque jour.
• Suivez votre progression directement dans le Mushaf : les pages lues sont validées automatiquement, ou à la main par page, plage de pages, Juz, Hizb ou sourate.
• Rappel quotidien à l'heure de votre choix, envoyé uniquement si l'objectif du jour n'est pas encore atteint.
• Page « Mes performances » : pages lues, séries de jours, moyenne quotidienne, temps de lecture et Khatm terminés.

Aussi dans cette version
• Nouvel écran d'accueil : reprise de la lecture en un geste, verset du jour et accès rapide à toutes les sections.
• Écoute de plusieurs versets à la suite : choisissez une plage de versets depuis la liste des versets ou le Mushaf.
• Mushaf plus fluide : les pages défilent plus rapidement.
• L'écran reste allumé pendant la lecture du Mushaf.
• Réglages redessinés, plus simples à parcourir.
• Corrections et améliorations diverses.
```

#### Anglais — max 4000

```text
New: reading goals (Khatm)
• Plan a Khatm at your own pace: pick a duration and a starting point, and the app tells you how many pages to read each day.
• Track your progress right in the Mushaf: pages are validated automatically as you read, or manually by page, page range, Juz, Hizb or surah.
• Daily reminder at the time you choose, sent only if the day's goal is not reached yet.
• "My performance" page: pages read, day streaks, daily average, reading time and completed Khatm.

Also in this version
• New home screen: resume reading in one tap, verse of the day and quick access to every section.
• Listen to several verses in a row: choose a verse range from the verse list or the Mushaf.
• Smoother Mushaf: pages turn faster.
• The screen stays on while you read the Mushaf.
• Redesigned settings, easier to browse.
• Various fixes and improvements.
```

#### Arabe — max 4000

```text
جديد: أهداف القراءة (الختمة)
• خطّط لختمة على وتيرتك: اختر المدة ونقطة البداية، ويخبرك التطبيق بعدد الصفحات التي تقرؤها كل يوم.
• تابع تقدّمك مباشرة في المصحف: تُحتسب الصفحات المقروءة تلقائيًا، أو يدويًا بالصفحة أو بنطاق صفحات أو بالجزء أو الحزب أو السورة.
• تذكير يومي في الوقت الذي تختاره، يُرسل فقط إذا لم تُكمل ورد اليوم بعد.
• صفحة «أدائي»: الصفحات المقروءة، سلاسل الأيام، المعدل اليومي، وقت القراءة والختمات المكتملة.

أيضًا في هذا الإصدار
• شاشة رئيسية جديدة: متابعة القراءة بلمسة واحدة، آية اليوم ووصول سريع إلى جميع الأقسام.
• الاستماع إلى عدة آيات متتالية: اختر نطاق الآيات من قائمة الآيات أو من المصحف.
• مصحف أكثر سلاسة: تقليب أسرع للصفحات.
• تبقى الشاشة مضاءة أثناء القراءة في المصحف.
• إعدادات بتصميم جديد أسهل في التصفح.
• إصلاحات وتحسينات متنوعة.
```

### 3.2 Texte promotionnel

#### Français — max 170

```text
Nouveau : planifiez votre Khatm, suivez vos pages lues dans le Mushaf, recevez un rappel quotidien et consultez vos performances de lecture.
```

#### Anglais — max 170

```text
New: plan your Khatm, track the pages you read in the Mushaf, get a daily reminder and review your reading performance.
```

#### Arabe — max 170

```text
جديد: خطّط لختمتك، تابع الصفحات المقروءة في المصحف، استقبل تذكيرًا يوميًا واطّلع على أدائك في القراءة.
```

### 3.3 Description

Remplace la description actuelle (elle ajoute les objectifs de lecture et les rappels).

#### Français — max 4000

```text
Coran Wolof est une application de lecture du Saint Coran avec traduction audio en wolof. Elle s'adresse aux musulmans qui savent réciter l'arabe et souhaitent comprendre le sens des versets en wolof.

LIRE
• Les 114 sourates en texte arabe, avec traduction écrite au choix.
• Mode Mushaf page par page, comme le livre, avec coloration des règles de tajwid.
• Taille de police réglable, thème clair ou sombre.
• L'écran reste allumé pendant la lecture.

ÉCOUTER
• Traduction audio en wolof, verset par verset, par l'imam Assane Sarr.
• Lecture d'un verset, d'une plage de versets ou d'une sourate entière.
• Lecture en arrière-plan, avec les commandes sur l'écran verrouillé.
• Téléchargement des sourates pour écouter sans connexion.

PLANIFIER VOTRE KHATM
• Créez un objectif de lecture : choisissez une durée et un point de départ, l'application calcule le nombre de pages à lire chaque jour.
• Les pages lues sont validées automatiquement dans le Mushaf, ou à la main par page, Juz, Hizb ou sourate.
• Rappel quotidien à l'heure de votre choix.
• Page « Mes performances » : pages lues, séries de jours, moyenne quotidienne et Khatm terminés.

RETROUVER ET PARTAGER
• Recherche par mots-clés dans le Coran.
• Signets pour retrouver vos versets préférés.
• Partage d'un verset en image ou en vidéo.
• Verset du jour sur l'écran d'accueil.

RESPECT DE LA VIE PRIVÉE
L'application est gratuite, sans publicité et sans compte. Aucune donnée personnelle n'est collectée : vos préférences, vos signets et votre progression restent sur votre appareil.

Interface disponible en français, en anglais et en arabe.
Texte du Coran : projet Tanzil.
```

#### Anglais — max 4000

```text
Coran Wolof is an app for reading the Holy Quran with an audio translation in Wolof. It is made for Muslims who can recite Arabic and want to understand the meaning of the verses in Wolof.

READ
• All 114 surahs in Arabic text, with the written translation of your choice.
• Page-by-page Mushaf mode, like the printed book, with tajweed coloring.
• Adjustable font size, light or dark theme.
• The screen stays on while you read.

LISTEN
• Audio translation in Wolof, verse by verse, by Imam Assane Sarr.
• Play a single verse, a range of verses or a whole surah.
• Background playback with lock screen controls.
• Download surahs to listen offline.

PLAN YOUR KHATM
• Create a reading goal: pick a duration and a starting point, and the app works out how many pages to read each day.
• Pages are validated automatically in the Mushaf, or manually by page, Juz, Hizb or surah.
• Daily reminder at the time you choose.
• "My performance" page: pages read, day streaks, daily average and completed Khatm.

FIND AND SHARE
• Keyword search in the Quran.
• Bookmarks to find your favourite verses again.
• Share a verse as an image or a video.
• Verse of the day on the home screen.

PRIVACY
The app is free, with no ads and no account. No personal data is collected: your preferences, bookmarks and progress stay on your device.

Interface available in French, English and Arabic.
Quran text: Tanzil project.
```

#### Arabe — max 4000

```text
«قرآن ولوف» تطبيق لقراءة القرآن الكريم مع ترجمة صوتية بلغة الولوف. وهو موجَّه للمسلمين الذين يجيدون التلاوة بالعربية ويرغبون في فهم معاني الآيات بلغة الولوف.

القراءة
• السور الـ114 بالنص العربي، مع ترجمة مكتوبة من اختيارك.
• وضع المصحف صفحة بصفحة كما في المصحف المطبوع، مع ألوان أحكام التجويد.
• حجم خط قابل للتعديل، ومظهر فاتح أو داكن.
• تبقى الشاشة مضاءة أثناء القراءة.

الاستماع
• ترجمة صوتية بلغة الولوف آية بآية، للإمام أسان سار.
• تشغيل آية واحدة أو نطاق من الآيات أو سورة كاملة.
• التشغيل في الخلفية مع أزرار التحكم على شاشة القفل.
• تنزيل السور للاستماع دون اتصال.

خطّط لختمتك
• أنشئ هدفًا للقراءة: اختر المدة ونقطة البداية، ويحسب التطبيق عدد الصفحات التي تقرؤها كل يوم.
• تُحتسب الصفحات المقروءة تلقائيًا في المصحف، أو يدويًا بالصفحة أو الجزء أو الحزب أو السورة.
• تذكير يومي في الوقت الذي تختاره.
• صفحة «أدائي»: الصفحات المقروءة، سلاسل الأيام، المعدل اليومي والختمات المكتملة.

البحث والمشاركة
• بحث بالكلمات في القرآن.
• إشارات مرجعية للعودة إلى آياتك المفضلة.
• مشاركة آية على شكل صورة أو فيديو.
• آية اليوم على الشاشة الرئيسية.

الخصوصية
التطبيق مجاني، بلا إعلانات وبلا حساب. لا تُجمع أي بيانات شخصية: إعداداتك وإشاراتك المرجعية وتقدّمك تبقى على جهازك.

الواجهة متاحة بالفرنسية والإنجليزية والعربية.
نص القرآن: مشروع تنزيل.
```

### 3.4 Autres champs de la fiche

| Champ | Valeur | Statut |
|---|---|---|
| Nom (max 30) | `Coran Wolof` | inchangé |
| Sous-titre (max 30) | `Coran en Wolof` | inchangé |
| Catégorie principale | Éducation | inchangé |
| Classification d'âge | 4+ | inchangé |
| Copyright | `© 2026 Saliou Seck` | à mettre à jour (actuel : 2025) |
| URL de la politique de confidentialité | `https://www.privacypolicies.com/live/65b14f41-1cbe-4e47-ab04-211ff84a8c42` | à confirmer |
| URL d'assistance | valeur déjà saisie | inchangé |
| URL marketing | valeur déjà saisie (facultatif) | inchangé |
| Achats intégrés | aucun à joindre à cette version | — |

#### Mots-clés (français) — max 100 — à confirmer

Garder les mots-clés déjà saisis et y ajouter `khatm` et `objectif` si la place le
permet. Proposition complète si le champ est vide :

```text
quran,tafsir,mushaf,khatm,sourate,islam,sénégal,tajwid,audio,traduction,lecture,juz,hizb,objectif
```

### 3.5 Build

- Sélectionner le build **1.4.0 (13)** une fois traité par TestFlight.
- Conformité d'exportation : aucune question attendue (`ITSAppUsesNonExemptEncryption = false`).
  Si la question apparaît : l'app n'utilise que le chiffrement standard du système (HTTPS) → « Non ».

### 3.6 Informations pour la vérification de l'app (App Review)

- Connexion requise : **Non** (aucun compte dans l'application).
- Coordonnées : Saliou Seck, saliouseck2009@gmail.com, téléphone déjà saisi.
- Notes (en anglais, à coller telles quelles) :

#### Notes de vérification — max 4000

```text
Version 1.4.0 adds reading goals ("Khatm" planning) to the Quran reader.

What is new
- Reading goals: from the home screen, open "Mes objectifs" (My goals) and create a goal. The app computes how many pages to read per day and tracks the pages read in the Mushaf (page-by-page reader).
- Statistics page ("Mes performances"), reachable from the goals screen.
- Redesigned home screen and settings.
- Playback of a range of verses.

No account
The app has no sign-up and no login. Every feature is available right after launch.

Notifications
The app only uses local notifications scheduled on the device; there is no push server. Permission is requested only when the user turns on "Rappel quotidien" (Daily reminder) while creating a reading goal or from the goal's reminder settings. The reminder is delivered at the chosen time only if the day's reading target has not been reached.

Background audio
The "audio" background mode keeps the Quran audio translation playing when the app is in the background or the device is locked, with lock screen controls.

Microphone
The app never records audio. The microphone usage string is present only because the audio library used for playback references the audio session API.

Support the project
Settings > "Soutenir le projet" (Support the project) opens a web page in Safari: https://saliouseck2009.github.io/wolof_quran/soutenir/
The page explains how to make a voluntary contribution to the developer. Contributions are optional and do not unlock any content, feature or service in the app. No payment takes place inside the app, and in-app purchase is not offered in this version.

Privacy
The app collects no personal data. Preferences, bookmarks and reading progress are stored on the device only. Network access is used to download audio files and a small configuration file.
```

### 3.7 Confidentialité de l'app (étiquette App Store)

**Inchangé** : « Données non collectées ». Les rappels sont des notifications locales et
la progression de lecture reste sur l'appareil.

### 3.8 Captures d'écran

Les captures actuelles peuvent être conservées (elles sont reprises automatiquement).
Si elles sont remplacées, écrans à montrer dans cet ordre :

1. Nouvel écran d'accueil (bandeau Khatm, grille, verset du jour)
2. Mushaf avec la barre de suivi d'un objectif
3. Liste « Mes objectifs »
4. Détail d'un objectif (carte des pages)
5. « Mes performances »
6. Liste des versets avec lecture audio

Formats exigés : iPhone 6,9" (1320 × 2868 ou 1290 × 2796) et iPad 13" (2064 × 2752),
car l'application est disponible sur iPad.

### 3.9 Publication

- Mode de publication : laisser le réglage actuel (à confirmer par le propriétaire).
- Publication progressive : au choix du propriétaire.

---

## 4. Google Play Console

Chemin : Play Console → Coran Wolof → Production → « Créer une release ».

### 4.1 Release

| Champ | Valeur |
|---|---|
| Fichier | App Bundle (`.aab`) 1.4.0, versionCode 13 |
| Nom de la release | `1.4.0 (13)` |

### 4.2 Notes de version

À coller dans le champ unique « Notes de version », avec les balises de langue. Ne
garder que les balises des langues présentes dans la fiche.

#### fr-FR — max 500

```text
Nouveau : objectifs de lecture (Khatm)
• Planifiez un Khatm : l'application indique combien de pages lire chaque jour
• Suivi de la progression dans le Mushaf, automatique ou manuel (page, Juz, Hizb, sourate)
• Rappel quotidien et page « Mes performances »

Aussi :
• Nouvel écran d'accueil
• Écoute de plusieurs versets à la suite
• Mushaf plus fluide, écran allumé pendant la lecture
• Réglages redessinés
• Corrections diverses
```

#### en-US — max 500

```text
New: reading goals (Khatm)
• Plan a Khatm: the app tells you how many pages to read each day
• Progress tracked in the Mushaf, automatically or manually (page, Juz, Hizb, surah)
• Daily reminder and "My performance" page

Also:
• New home screen
• Listen to several verses in a row
• Smoother Mushaf, screen stays on while reading
• Redesigned settings
• Various fixes
```

#### ar — max 500

```text
جديد: أهداف القراءة (الختمة)
• خطّط لختمة: يخبرك التطبيق بعدد الصفحات التي تقرؤها كل يوم
• متابعة التقدّم في المصحف تلقائيًا أو يدويًا (صفحة، جزء، حزب، سورة)
• تذكير يومي وصفحة «أدائي»

أيضًا:
• شاشة رئيسية جديدة
• الاستماع إلى عدة آيات متتالية
• مصحف أكثر سلاسة، والشاشة تبقى مضاءة أثناء القراءة
• إعدادات بتصميم جديد
• إصلاحات متنوعة
```

Format attendu dans la console :

```text
<fr-FR>
…texte français…
</fr-FR>
<en-US>
…texte anglais…
</en-US>
<ar>
…texte arabe…
</ar>
```

### 4.3 Fiche Play Store principale

| Champ | Valeur | Statut |
|---|---|---|
| Nom de l'application (max 30) | `Coran Wolof - Quran en Wolof` | inchangé |
| Catégorie, coordonnées, classification du contenu | valeurs actuelles | inchangé |

#### Brève description (français) — max 80 — à confirmer

Garder le texte actuel s'il convient ; proposition qui mentionne la nouveauté :

```text
Lisez le Coran, écoutez la traduction en wolof et planifiez votre Khatm.
```

#### Brève description (anglais) — max 80 — à confirmer

```text
Read the Quran, listen to the Wolof translation and plan your Khatm.
```

#### Brève description (arabe) — max 80 — à confirmer

```text
اقرأ القرآن، استمع إلى الترجمة بلغة الولوف وخطّط لختمتك.
```

#### Description complète — max 4000

Utiliser les mêmes textes que la description App Store (section 3.3), dans chaque langue.
Une seule adaptation : remplacer la ligne sur l'écran verrouillé par celle-ci.

- Français : `• Lecture en arrière-plan, avec les commandes dans les notifications et sur l'écran verrouillé.`
- Anglais : `• Background playback with controls in the notification and on the lock screen.`
- Arabe : `• التشغيل في الخلفية مع أزرار التحكم في الإشعارات وعلى شاشة القفل.`

### 4.4 Contenu de l'application (déclarations)

| Déclaration | Réponse | Statut |
|---|---|---|
| Sécurité des données | Aucune donnée collectée, aucune donnée partagée | inchangé |
| Publicités | Non | inchangé |
| Accès à l'application | Tout est accessible sans identifiants | inchangé |
| Public cible et classification | valeurs actuelles | inchangé |
| Alarmes exactes | Non utilisées (rappels programmés en mode inexact) | rien à déclarer |

Permissions ajoutées par cette version, sans formulaire à remplir :

- `POST_NOTIFICATIONS` : rappels de lecture quotidiens (notifications locales).
- `RECEIVE_BOOT_COMPLETED` : reprogrammer les rappels après un redémarrage du téléphone.

Permission déjà déclarée avec la 1.3.0 : `FOREGROUND_SERVICE_MEDIA_PLAYBACK`. Si la
console redemande la déclaration du service de premier plan, choisir **Lecture de
contenus multimédias** et coller :

#### Justification du service de premier plan — max 500

```text
The app plays the audio translation of the Quran. A media playback foreground service keeps the audio playing when the user leaves the app or locks the screen, and shows the media notification with play, pause, previous and next controls. The service starts only when the user starts playback and stops when playback ends.
```

### 4.5 Déploiement

- Pourcentage de déploiement : au choix du propriétaire (100 % par défaut).
- S'arrêter à l'écran « Vérifier la release » et laisser le propriétaire lancer le déploiement.

---

## 5. Vérifications réservées au propriétaire

- [ ] Le build iOS 13 contient bien la correction UIScene (iOS 27) et a été testé sur l'iPhone.
- [ ] La page https://saliouseck2009.github.io/wolof_quran/soutenir/ est en ligne (vérifié le 9 novembre 2026 : oui).
- [ ] La politique de confidentialité intégrée à l'application ne cite pas encore les
      notifications dans la liste des permissions (texte daté du 11/04/2026).
- [ ] Relire la section « Support the project » des notes de vérification Apple avant l'envoi.
- [ ] Cliquer soi-même sur « Soumettre pour vérification » (Apple) et « Lancer le déploiement » (Google).
