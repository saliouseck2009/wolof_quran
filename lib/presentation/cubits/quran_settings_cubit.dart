import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:quran/quran.dart' as quran;
import '../../domain/entities/reciter.dart';

// Single State class with default values
class QuranSettingsState {
  final quran.Translation selectedTranslation;
  final Reciter? selectedReciter;
  final double ayahFontSize;

  /// Whether mushaf pages are validated in the followed goal after staying
  /// on them for [autoTrackingThresholdSeconds].
  final bool autoTrackingEnabled;
  final int autoTrackingThresholdSeconds;

  const QuranSettingsState({
    this.selectedTranslation = quran.Translation.frHamidullah,
    this.selectedReciter,
    this.ayahFontSize = 28.0,
    this.autoTrackingEnabled = true,
    this.autoTrackingThresholdSeconds =
        QuranSettingsCubit.defaultAutoTrackingThresholdSeconds,
  });

  Duration get autoTrackingThreshold =>
      Duration(seconds: autoTrackingThresholdSeconds);

  QuranSettingsState copyWith({
    quran.Translation? selectedTranslation,
    Reciter? selectedReciter,
    double? ayahFontSize,
    bool? autoTrackingEnabled,
    int? autoTrackingThresholdSeconds,
  }) {
    return QuranSettingsState(
      selectedTranslation: selectedTranslation ?? this.selectedTranslation,
      selectedReciter: selectedReciter ?? this.selectedReciter,
      ayahFontSize: ayahFontSize ?? this.ayahFontSize,
      autoTrackingEnabled: autoTrackingEnabled ?? this.autoTrackingEnabled,
      autoTrackingThresholdSeconds:
          autoTrackingThresholdSeconds ?? this.autoTrackingThresholdSeconds,
    );
  }
}

// Available translations with their display names
class TranslationOption {
  final quran.Translation translation;
  final String displayName;
  final String language;

  const TranslationOption({
    required this.translation,
    required this.displayName,
    required this.language,
  });
}

// Cubit
class QuranSettingsCubit extends Cubit<QuranSettingsState> {
  static const String _translationKey = 'selected_quran_translation';
  static const String _reciterKey = 'selected_reciter_id';
  static const String _ayahFontSizeKey = 'ayah_font_size';
  static const String _autoTrackingEnabledKey = 'reading_auto_tracking_enabled';
  static const String _autoTrackingThresholdKey =
      'reading_auto_tracking_threshold_seconds';

  // Font size constraints
  static const double minFontSize = 16.0;
  static const double maxFontSize = 40.0;
  static const double defaultFontSize = 28.0;

  // Reading tracking: seconds a page must stay open to count as read
  static const int defaultAutoTrackingThresholdSeconds = 30;
  static const List<int> autoTrackingThresholdOptions = [30, 45, 60];

  QuranSettingsCubit() : super(const QuranSettingsState());

  // Getter for easy access to config items directly from context.read<QuranSettingsCubit>().configItem
  // However, users can also just use state.selectedTranslation since state is always available and has defaults.
  quran.Translation get currentTranslation => state.selectedTranslation;
  Reciter? get currentReciter => state.selectedReciter;
  double get currentAyahFontSize => state.ayahFontSize;

  // Available translations based on the README
  static const List<TranslationOption> availableTranslations = [
    TranslationOption(
      translation: quran.Translation.frHamidullah,
      displayName: 'Français (Muhammad Hamidullah)',
      language: 'Français',
    ),
    TranslationOption(
      translation: quran.Translation.enSaheeh,
      displayName: 'English (Saheeh International)',
      language: 'English',
    ),
    TranslationOption(
      translation: quran.Translation.enClearQuran,
      displayName: 'English (Clear Quran)',
      language: 'English',
    ),
    TranslationOption(
      translation: quran.Translation.trSaheeh,
      displayName: 'Türkçe',
      language: 'Turkish',
    ),
    TranslationOption(
      translation: quran.Translation.mlAbdulHameed,
      displayName: 'മലയാളം (Malayalam)',
      language: 'Malayalam',
    ),
    TranslationOption(
      translation: quran.Translation.faHusseinDari,
      displayName: 'فارسی (Farsi)',
      language: 'Farsi',
    ),
    TranslationOption(
      translation: quran.Translation.portuguese,
      displayName: 'Português',
      language: 'Portuguese',
    ),
    TranslationOption(
      translation: quran.Translation.itPiccardo,
      displayName: 'Italiano',
      language: 'Italian',
    ),
    TranslationOption(
      translation: quran.Translation.nlSiregar,
      displayName: 'Nederlands',
      language: 'Dutch',
    ),

    TranslationOption(
      translation: quran.Translation.ruKuliev,
      displayName: 'Русский',
      language: 'Russian',
    ),
    TranslationOption(
      translation: quran.Translation.bengali,
      displayName: 'বাংলা (Bengali)',
      language: 'Bengali',
    ),
    TranslationOption(
      translation: quran.Translation.chinese,
      displayName: '中文 (Chinese)',
      language: 'Chinese',
    ),
    TranslationOption(
      translation: quran.Translation.spanish,
      displayName: 'Español',
      language: 'Spanish',
    ),
    TranslationOption(
      translation: quran.Translation.urdu,
      displayName: 'اردو (Urdu)',
      language: 'Urdu',
    ),
    TranslationOption(
      translation: quran.Translation.indonesian,
      displayName: 'Bahasa Indonesia',
      language: 'Indonesian',
    ),
  ];

  void loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load Translation
      final translationIndex = prefs.getInt(_translationKey);
      quran.Translation selectedTranslation = quran.Translation.frHamidullah;

      if (translationIndex != null &&
          translationIndex < availableTranslations.length) {
        selectedTranslation =
            availableTranslations[translationIndex].translation;
      }

      // Load font size
      final savedFontSize =
          prefs.getDouble(_ayahFontSizeKey) ?? defaultFontSize;
      final ayahFontSize = savedFontSize.clamp(minFontSize, maxFontSize);

      // Check reciter preference
      final savedReciterId = prefs.getString(_reciterKey);
      if (savedReciterId == null) {
        await prefs.setString(_reciterKey, 'imamsarr');
      }

      // Load reading tracking
      final autoTrackingEnabled =
          prefs.getBool(_autoTrackingEnabledKey) ?? true;
      final savedThreshold = prefs.getInt(_autoTrackingThresholdKey);
      final autoTrackingThresholdSeconds =
          savedThreshold != null && savedThreshold > 0
          ? savedThreshold
          : defaultAutoTrackingThresholdSeconds;

      emit(
        state.copyWith(
          selectedTranslation: selectedTranslation,
          ayahFontSize: ayahFontSize,
          autoTrackingEnabled: autoTrackingEnabled,
          autoTrackingThresholdSeconds: autoTrackingThresholdSeconds,
          // selectedReciter not set here, waiting for loadReciterFromPrefs
        ),
      );
    } catch (e) {
      // Fallback is handled by default state values, but we can emit a reset if needed.
      // In this case, if error occurs, we just keep defaults.
      try {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getString(_reciterKey) == null) {
          await prefs.setString(_reciterKey, 'imamsarr');
        }
      } catch (_) {}
    }
  }

  void updateReciter(Reciter reciter) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reciterKey, reciter.id);
      emit(state.copyWith(selectedReciter: reciter));
    } catch (e) {
      // Handle error
    }
  }

  void loadReciterFromPrefs(List<Reciter> availableReciters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedReciterId = prefs.getString(_reciterKey);

      if (selectedReciterId != null) {
        final selectedReciter = availableReciters.firstWhere(
          (reciter) => reciter.id == selectedReciterId,
          orElse: () => availableReciters.isNotEmpty
              ? availableReciters.first
              : throw Exception('No reciters available'),
        );
        emit(state.copyWith(selectedReciter: selectedReciter));
      } else if (availableReciters.isNotEmpty) {
        // Set imamsarr as default if available, otherwise first reciter
        final defaultReciter = availableReciters.firstWhere(
          (reciter) => reciter.id == 'imamsarr',
          orElse: () => availableReciters.first,
        );
        updateReciter(defaultReciter);
      }
    } catch (e) {
      // Handle error
    }
  }

  void updateTranslation(quran.Translation translation) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = availableTranslations.indexWhere(
        (option) => option.translation == translation,
      );
      if (index != -1) {
        await prefs.setInt(_translationKey, index);
        emit(state.copyWith(selectedTranslation: translation));
      }
    } catch (e) {
      // Handle error
    }
  }

  void updateAyahFontSize(double fontSize) async {
    try {
      final clampedFontSize = fontSize.clamp(minFontSize, maxFontSize);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_ayahFontSizeKey, clampedFontSize);
      emit(state.copyWith(ayahFontSize: clampedFontSize));
    } catch (e) {
      // Handle error
    }
  }

  void updateAutoTrackingEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_autoTrackingEnabledKey, enabled);
      emit(state.copyWith(autoTrackingEnabled: enabled));
    } catch (e) {
      // Handle error
    }
  }

  void updateAutoTrackingThreshold(int seconds) async {
    if (seconds <= 0) {
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_autoTrackingThresholdKey, seconds);
      emit(state.copyWith(autoTrackingThresholdSeconds: seconds));
    } catch (e) {
      // Handle error
    }
  }

  static TranslationOption? getTranslationOption(
    quran.Translation translation,
  ) {
    try {
      return availableTranslations.firstWhere(
        (option) => option.translation == translation,
      );
    } catch (e) {
      return null;
    }
  }

  static String getSurahNameInTranslation(
    int surahNumber,
    quran.Translation translation,
  ) {
    switch (translation) {
      case quran.Translation.frHamidullah:
        return quran.getSurahNameFrench(surahNumber);
      case quran.Translation.trSaheeh:
        return quran.getSurahNameTurkish(surahNumber);
      case quran.Translation.enSaheeh:
      case quran.Translation.enClearQuran:
      default:
        return quran.getSurahNameEnglish(surahNumber);
    }
  }

  static Future<quran.Translation> getCurrentTranslation() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final translationIndex = prefs.getInt(_translationKey);
      if (translationIndex != null &&
          translationIndex < availableTranslations.length) {
        return availableTranslations[translationIndex].translation;
      } else {
        return quran.Translation.frHamidullah;
      }
    } catch (e) {
      return quran.Translation.frHamidullah;
    }
  }

  static Future<String?> getSelectedReciterId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_reciterKey);
    } catch (e) {
      return null;
    }
  }
}
