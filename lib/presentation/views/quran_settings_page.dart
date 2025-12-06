import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
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
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.quranSettings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainer.withValues(alpha: 0.7)
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
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
                    gradient: colorScheme.brightness == Brightness.dark
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.surfaceContainer.withValues(
                                alpha: 0.8,
                              ),
                              colorScheme.surfaceContainer.withValues(
                                alpha: 0.9,
                              ),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colorScheme.primary.withValues(alpha: 0.1),
                              colorScheme.primaryContainer.withValues(
                                alpha: 0.2,
                              ),
                            ],
                          ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colorScheme.primary.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.settings,
                        size: 48,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        localizations.quranSettings,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Customize your Quran reading experience',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
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
    required VoidCallback onTap,
    bool showArrow = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
        boxShadow: colorScheme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: colorScheme.primary.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
        border: Border.all(
          color: colorScheme.primary.withValues(
            alpha: colorScheme.brightness == Brightness.dark ? 0.1 : 0.15,
          ),
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
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 24),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),

                      const SizedBox(height: 4),

                      // Subtitle
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),

                      const SizedBox(height: 8),

                      // Value
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w600,
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
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    showArrow ? Icons.arrow_forward_ios : Icons.edit,
                    color: colorScheme.primary,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = isDark
        ? Theme.of(context).colorScheme.secondary
        : Theme.of(context).colorScheme.primary;

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
          backgroundColor: accentGreen,
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
    final colorScheme = Theme.of(context).colorScheme;
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
                  color: colorScheme.outline,
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
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: colorScheme.outline),
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
                            ? colorScheme.primary.withValues(alpha: 0.1)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? colorScheme.primary
                              : colorScheme.outlineVariant.withValues(
                                  alpha: 0.3,
                                ),
                        ),
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
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected
                                        ? colorScheme.primary
                                        : Colors.transparent,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : colorScheme.outline,
                                    ),
                                  ),
                                  child: isSelected
                                      ? Icon(
                                          Icons.check,
                                          size: 8,
                                          color: colorScheme.onPrimary,
                                        )
                                      : null,
                                ),

                                const SizedBox(width: 16),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        option.displayName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : null,
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
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
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
                  color: colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Title
            Text(
              widget.localizations.fontSettings,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 8),

            // Description
            Text(
              widget.localizations.fontSizeDescription,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 32),

            // Preview Text
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: colorScheme.primary.withValues(alpha: 0.2),
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
                  color: colorScheme.onSurface,
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
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      '${_currentFontSize.toInt()}pt',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.primary,
                      ),
                    ),
                    Text(
                      widget.localizations.large,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: colorScheme.primary,
                    inactiveTrackColor: colorScheme.onSurfaceVariant.withValues(
                      alpha: 0.3,
                    ),
                    thumbColor: colorScheme.primary,
                    overlayColor: colorScheme.primary.withValues(alpha: 0.2),
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
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                widget.localizations.close,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
