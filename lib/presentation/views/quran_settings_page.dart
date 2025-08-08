import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/reciter_cubit.dart';
import '../../service_locator.dart';

class QuranSettingsPage extends StatelessWidget {
  static const String routeName = "/quran-settings";

  const QuranSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => locator<ReciterCubit>()..loadReciters(),
        ),
      ],
      child: const _QuranSettingsView(),
    );
  }
}

class _QuranSettingsView extends StatelessWidget {
  const _QuranSettingsView();

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.quranSettings,
          style: TextStyle(
            fontFamily: 'Hafs',
            fontWeight: FontWeight.w600,
            color: AppColor.pureWhite,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? AppColor.charcoal : AppColor.primaryGreen,
        foregroundColor: AppColor.pureWhite,
        elevation: 2,
      ),
      body: BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
        builder: (context, state) {
          if (state is! QuranSettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header section
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: isDark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColor.charcoal.withValues(alpha: 0.3),
                              AppColor.darkGray.withValues(alpha: 0.3),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColor.primaryGreen.withValues(alpha: 0.1),
                              AppColor.gold.withValues(alpha: 0.1),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColor.primaryGreen.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 48,
                        color: AppColor.primaryGreen,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.quranSettings,
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColor.primaryGreen,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customize your Quran reading experience',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColor.translationText,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Settings Menu Items
                _buildSettingsMenuItems(context, state, localizations),

                const SizedBox(height: 24),

                // Future settings sections can be added here
                // Example: Audio settings, font size, etc.
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingsMenuItems(
    BuildContext context,
    QuranSettingsLoaded state,
    AppLocalizations localizations,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentTranslationOption = QuranSettingsCubit.getTranslationOption(
      state.selectedTranslation,
    );

    return Column(
      children: [
        // Translation Settings Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.translate,
          title: localizations.translationSettings,
          subtitle: localizations.currentTranslation,
          value: currentTranslationOption?.displayName ?? 'Unknown',
          isDark: isDark,
          onTap: () => _showTranslationSelector(context, state, localizations),
        ),

        const SizedBox(height: 16),

        // Font Settings Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.format_size,
          title: localizations.fontSettings,
          subtitle: localizations.ayahFontSize,
          value: '${state.ayahFontSize.toInt()}pt',
          isDark: isDark,
          onTap: () => _showFontSizeSelector(context, state, localizations),
        ),

        const SizedBox(height: 16),

        // Audio & Reciters Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.volume_up,
          title: 'Audio & Reciters',
          subtitle: 'Manage reciters and download audio',
          value: 'View available reciters',
          isDark: isDark,
          onTap: () {
            Navigator.pushNamed(context, '/reciter-list');
          },
          showArrow: true,
        ),
      ],
    );
  }

  Widget _buildSettingsMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required bool isDark,
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColor.charcoal : AppColor.pureWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColor.primaryGreen.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Icon container
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColor.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: AppColor.primaryGreen, size: 24),
                ),

                const SizedBox(width: 16),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? AppColor.pureWhite
                              : AppColor.charcoal,
                        ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontFamily: 'Hafs',
                          fontSize: 12,
                          color: AppColor.mediumGray,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Value
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.primaryGreen.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColor.primaryGreen.withValues(alpha: 0.2),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          value,
                          style: TextStyle(
                            fontFamily: 'Hafs',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: AppColor.primaryGreen,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Action indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColor.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    showArrow ? Icons.arrow_forward_ios : Icons.edit,
                    color: AppColor.primaryGreen,
                    size: 16,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showTranslationSelector(
    BuildContext context,
    QuranSettingsLoaded state,
    AppLocalizations localizations,
  ) async {
    final result = await showModalBottomSheet<TranslationOption?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _TranslationSelectorModal(
        currentTranslation: state.selectedTranslation,
        localizations: localizations,
        onTranslationSelected: (translation) {
          print('🎯 Translation selected in modal: $translation'); // Debug log
          context.read<QuranSettingsCubit>().updateTranslation(translation);
        },
      ),
    );

    // If translation was changed, show feedback and return true to parent
    if (result != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(localizations.translationUpdated(result.language)),
          backgroundColor: AppColor.primaryGreen,
          duration: const Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  void _showFontSizeSelector(
    BuildContext context,
    QuranSettingsLoaded state,
    AppLocalizations localizations,
  ) async {
    final result = await showModalBottomSheet<double?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _FontSizeSelectorModal(
        currentFontSize: state.ayahFontSize,
        localizations: localizations,
        onFontSizeChanged: (fontSize) {
          context.read<QuranSettingsCubit>().updateAyahFontSize(fontSize);
        },
      ),
    );

    // If font size was changed, return true to parent
    if (result != null && context.mounted) {
      Navigator.pop(context, true);
    }
  }
}

class _TranslationSelectorModal extends StatelessWidget {
  final dynamic currentTranslation;
  final AppLocalizations localizations;
  final Function(dynamic translation) onTranslationSelected;

  const _TranslationSelectorModal({
    required this.currentTranslation,
    required this.localizations,
    required this.onTranslationSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) {
          return Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      localizations.selectTranslation,
                      style: TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryGreen,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: AppColor.mediumGray),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),

              // Translation list
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: QuranSettingsCubit.availableTranslations.length,
                  itemBuilder: (context, index) {
                    final option =
                        QuranSettingsCubit.availableTranslations[index];
                    final isSelected = currentTranslation == option.translation;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColor.primaryGreen.withValues(alpha: 0.1)
                            : Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: AppColor.primaryGreen.withValues(
                                  alpha: 0.3,
                                ),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            // Update translation using callback
                            onTranslationSelected(option.translation);

                            // Close modal and return the selected option
                            Navigator.pop(context, option);
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColor.primaryGreen
                                        : AppColor.lightGray,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    isSelected ? Icons.check : Icons.language,
                                    color: isSelected
                                        ? AppColor.pureWhite
                                        : AppColor.mediumGray,
                                    size: 20,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.displayName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall
                                            ?.copyWith(
                                              fontWeight: FontWeight.w500,
                                              color: isSelected
                                                  ? AppColor.primaryGreen
                                                  : Theme.of(context)
                                                        .textTheme
                                                        .titleSmall
                                                        ?.color,
                                            ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        option.language,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: AppColor.translationText,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),

                                if (isSelected)
                                  Icon(
                                    Icons.radio_button_checked,
                                    color: AppColor.primaryGreen,
                                    size: 20,
                                  )
                                else
                                  Icon(
                                    Icons.radio_button_unchecked,
                                    color: AppColor.mediumGray,
                                    size: 20,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }
}

class _FontSizeSelectorModal extends StatefulWidget {
  final double currentFontSize;
  final AppLocalizations localizations;
  final Function(double fontSize) onFontSizeChanged;

  const _FontSizeSelectorModal({
    required this.currentFontSize,
    required this.localizations,
    required this.onFontSizeChanged,
  });

  @override
  State<_FontSizeSelectorModal> createState() => _FontSizeSelectorModalState();
}

class _FontSizeSelectorModalState extends State<_FontSizeSelectorModal> {
  late double _currentFontSize;

  @override
  void initState() {
    super.initState();
    _currentFontSize = widget.currentFontSize;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColor.charcoal : AppColor.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle bar
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColor.mediumGray,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              widget.localizations.fontSettings,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColor.pureWhite : AppColor.darkGray,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              widget.localizations.fontSizeDescription,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 14,
                color: AppColor.mediumGray,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Preview Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColor.lightGray.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColor.primaryGreen.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Text(
                'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: TextStyle(
                  fontFamily: 'Hafs',
                  fontSize: _currentFontSize,
                  fontWeight: FontWeight.w500,
                  color: isDark ? AppColor.pureWhite : AppColor.darkGray,
                  height: 1.8,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Font Size Slider
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.localizations.small,
                      style: TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 12,
                        color: AppColor.mediumGray,
                      ),
                    ),
                    Text(
                      '${_currentFontSize.toInt()}pt',
                      style: TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryGreen,
                      ),
                    ),
                    Text(
                      widget.localizations.large,
                      style: TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 12,
                        color: AppColor.mediumGray,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: AppColor.primaryGreen,
                    inactiveTrackColor: AppColor.mediumGray.withValues(
                      alpha: 0.3,
                    ),
                    thumbColor: AppColor.primaryGreen,
                    overlayColor: AppColor.primaryGreen.withValues(alpha: 0.2),
                    trackHeight: 4.0,
                    thumbShape: const RoundSliderThumbShape(
                      enabledThumbRadius: 8,
                    ),
                  ),
                  child: Slider(
                    value: _currentFontSize,
                    min: QuranSettingsCubit.minFontSize,
                    max: QuranSettingsCubit.maxFontSize,
                    divisions:
                        ((QuranSettingsCubit.maxFontSize -
                                    QuranSettingsCubit.minFontSize) /
                                2)
                            .round(),
                    onChanged: (value) {
                      setState(() {
                        _currentFontSize = value;
                      });
                      widget.onFontSizeChanged(value);
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Close Button
            ElevatedButton(
              onPressed: () => Navigator.pop(context, _currentFontSize),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColor.primaryGreen,
                foregroundColor: AppColor.pureWhite,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.localizations.close,
                style: TextStyle(
                  fontFamily: 'Hafs',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
