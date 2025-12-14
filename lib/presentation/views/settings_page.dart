import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../../core/config/theme/app_gradients.dart';
import '../../core/config/localization/localization_service.dart';
import '../cubits/language_cubit.dart';
import '../cubits/theme_cubit.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = "/settings";

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.settings,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? AppColor.surfaceDark
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section with welcome message
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: colorScheme.brightness == Brightness.dark
                    ? colorScheme.surfaceContainer
                    : colorScheme.onPrimary,

                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: colorScheme.brightness == Brightness.dark
                      ? colorScheme.outline.withValues(alpha: 0.1)
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(Icons.settings, size: 48, color: colorScheme.primary),
                  const SizedBox(height: 12),
                  Text(
                    localizations.settings,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    localizations.settingsDescription,
                    style: TextStyle(
                      fontSize: 14,
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Settings Menu Items
            _buildSettingsMenuItems(context, localizations),

            const SizedBox(height: 54),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsMenuItems(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final currentLocale = context.watch<LanguageCubit>().state;
    final languageValue = LocalizationService.getLanguageName(currentLocale);

    return Column(
      children: [
        // Language Settings Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.language,
          title: localizations.language,
          subtitle: localizations.changeAppLanguage,
          value: languageValue,
          onTap: () => _showLanguageSelector(context, localizations),
        ),

        const SizedBox(height: 16),

        // Theme Settings Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.palette,
          title: localizations.theme,
          subtitle: localizations.chooseAppTheme,
          value: _getCurrentThemeName(context, localizations),
          onTap: () => _showThemeSelector(context, localizations),
        ),

        const SizedBox(height: 16),

        // Quran Settings Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.settings_applications,
          title: localizations.quranSettings,
          subtitle: localizations.manageRecitersAndDownloadAudio,
          value: localizations.managePreferences,
          onTap: () {
            Navigator.pushNamed(context, '/quran-settings');
          },
          showArrow: true,
        ),

        const SizedBox(height: 16),

        // About Menu Item
        _buildSettingsMenuItem(
          context: context,
          icon: Icons.info_outline,
          title: localizations.about,
          subtitle: localizations.aboutSubtitle,
          value: localizations.appVersion('1.0.0'),
          onTap: () => _showAboutDialog(context),
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
    final isDark = colorScheme.brightness == Brightness.dark;
    final activeColor = isDark ? colorScheme.primary : colorScheme.primary;
    final activeColorWithAlpha = activeColor.withValues(alpha: 0.1);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: isDark
              ? colorScheme.outline.withValues(alpha: 0.1)
              : Colors.transparent,
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
                    color: activeColorWithAlpha,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: activeColor, size: 24),
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
                          color: activeColorWithAlpha,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: activeColor.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: activeColor,
                                fontWeight: FontWeight.w600,
                              ),
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
                    color: activeColorWithAlpha,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    showArrow ? Icons.arrow_forward_ios : Icons.edit,
                    color: activeColor,
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

  String _getCurrentThemeName(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final themeCubit = context.read<ThemeCubit>();
    final currentTheme = themeCubit.state;
    return themeCubit.getThemeName(currentTheme, localizations);
  }

  void _showLanguageSelector(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) =>
          _buildLanguageSelectorModal(modalContext, localizations),
    );
  }

  void _showThemeSelector(
    BuildContext context,
    AppLocalizations localizations,
  ) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) =>
          _buildThemeSelectorModal(modalContext, localizations),
    );
  }

  Widget _buildLanguageSelectorModal(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, currentLocale) {
          return DraggableScrollableSheet(
            initialChildSize: 0.6,
            maxChildSize: 0.8,
            minChildSize: 0.4,
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
                          localizations.language,
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

                  // Language list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: LocalizationService.supportedLocales.length,
                      itemBuilder: (context, index) {
                        final locale =
                            LocalizationService.supportedLocales[index];
                        final isSelected =
                            currentLocale.languageCode == locale.languageCode;
                        final languageName =
                            LocalizationService.getLanguageName(locale);

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
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.read<LanguageCubit>().changeLanguage(
                                  locale,
                                );
                                Navigator.pop(context);
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
                                      child: Text(
                                        languageName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? colorScheme.primary
                                              : null,
                                        ),
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
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildThemeSelectorModal(
    BuildContext context,
    AppLocalizations localizations,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, currentTheme) {
          return DraggableScrollableSheet(
            initialChildSize: 0.5,
            maxChildSize: 0.7,
            minChildSize: 0.4,
            expand: false,
            builder: (context, scrollController) {
              final themeOptions = [
                ThemeMode.light,
                ThemeMode.dark,
                ThemeMode.system,
              ];

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
                          localizations.theme,
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

                  // Theme list
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      itemCount: themeOptions.length,
                      itemBuilder: (context, index) {
                        final themeMode = themeOptions[index];
                        final isSelected = currentTheme == themeMode;
                        final themeCubit = context.read<ThemeCubit>();
                        final themeName = themeCubit.getThemeName(
                          themeMode,
                          localizations,
                        );
                        final themeIcon = themeCubit.getThemeIcon(themeMode);
                        final themeColor = themeCubit.getThemeColor(themeMode);

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
                            borderRadius: BorderRadius.circular(12),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                context.read<ThemeCubit>().changeTheme(
                                  themeMode,
                                );
                                Navigator.pop(context);
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: themeColor.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        themeIcon,
                                        color: themeColor,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Text(
                                        themeName,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: isSelected
                                              ? AppColor.primaryGreen
                                              : null,
                                        ),
                                      ),
                                    ),
                                    if (isSelected)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: colorScheme.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.check,
                                          size: 16,
                                          color: colorScheme.onPrimary,
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
                ],
              );
            },
          );
        },
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppGradients.primary(colorScheme),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.menu_book_rounded,
                color: colorScheme.onPrimary,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    localizations.appTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    localizations.appVersion('1.0.0'),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.aboutDescription,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      localizations.developedWithLove,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(
              localizations.close,
              style: TextStyle(
                color: colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
