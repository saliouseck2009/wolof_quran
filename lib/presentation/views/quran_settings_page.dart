import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
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
          style: GoogleFonts.amiri(
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
          print('🔄 Settings page rebuilding with state: $state'); // Debug log

          if (state is! QuranSettingsLoaded) {
            return const Center(child: CircularProgressIndicator());
          }

          print(
            '📋 Current translation in state: ${state.selectedTranslation}',
          ); // Debug log

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
                        style: GoogleFonts.amiri(
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

                // Translation Settings Section
                _buildTranslationSection(context, state, localizations),

                const SizedBox(height: 24),

                // Reciter Selection Section
                _buildReciterSection(context, localizations),

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

  Widget _buildTranslationSection(
    BuildContext context,
    QuranSettingsLoaded state,
    AppLocalizations localizations,
  ) {
    final currentOption = QuranSettingsCubit.getTranslationOption(
      state.selectedTranslation,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          localizations.translationSettings,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColor.primaryGreen,
          ),
        ),

        const SizedBox(height: 8),

        Text(
          localizations.translationDescription,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColor.translationText),
        ),

        const SizedBox(height: 16),

        // Translation setting card
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: AppColor.primaryGreen.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () =>
                  _showTranslationSelector(context, state, localizations),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.translate,
                        color: AppColor.primaryGreen,
                        size: 24,
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            localizations.currentTranslation,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColor.translationText),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            currentOption?.displayName ?? 'Unknown',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: AppColor.primaryGreen,
                                ),
                          ),
                        ],
                      ),
                    ),

                    Icon(Icons.chevron_right, color: AppColor.mediumGray),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
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

  Widget _buildReciterSection(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
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
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.pushNamed(context, '/reciter-list');
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColor.primaryGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.volume_up,
                        color: AppColor.primaryGreen,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Audio Tafsir Management', // TODO: Add to localizations
                            style: GoogleFonts.amiri(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColor.pureWhite
                                  : AppColor.charcoal,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Manage reciters and download chapters', // TODO: Add to localizations
                            style: GoogleFonts.amiri(
                              fontSize: 13,
                              color: AppColor.mediumGray,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      color: AppColor.primaryGreen,
                      size: 16,
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColor.primaryGreen.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppColor.primaryGreen.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.library_music,
                        color: AppColor.primaryGreen,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'View Available Reciters', // TODO: Add to localizations
                        style: GoogleFonts.amiri(
                          fontSize: 14,
                          color: AppColor.primaryGreen,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
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
                      style: GoogleFonts.amiri(
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
