import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../../core/config/localization/localization_service.dart';
import '../cubits/language_cubit.dart';

class SettingsPage extends StatelessWidget {
  static const String routeName = "/settings";

  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.settings), elevation: 0),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Language Section
          _buildSectionTitle(context, localizations.language),
          const SizedBox(height: 8),
          _buildLanguageCard(context),

          const SizedBox(height: 24),

          // Theme Section
          _buildSectionTitle(context, localizations.theme),
          const SizedBox(height: 8),
          _buildThemeCard(context),

          const SizedBox(height: 24),

          // About Section
          _buildSectionTitle(context, "À propos"),
          const SizedBox(height: 8),
          _buildAboutCard(context),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w600,
        color: AppColor.primaryGreen,
      ),
    );
  }

  Widget _buildLanguageCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          BlocBuilder<LanguageCubit, Locale>(
            builder: (context, currentLocale) {
              return Column(
                children: LocalizationService.supportedLocales.map((locale) {
                  final isSelected =
                      currentLocale.languageCode == locale.languageCode;
                  final languageName = LocalizationService.getLanguageName(
                    locale,
                  );

                  return ListTile(
                    title: Text(
                      languageName,
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected ? AppColor.primaryGreen : null,
                      ),
                    ),
                    trailing: isSelected
                        ? Icon(Icons.check, color: AppColor.primaryGreen)
                        : null,
                    onTap: () {
                      context.read<LanguageCubit>().changeLanguage(locale);
                    },
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildThemeCard(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.light_mode, color: AppColor.gold),
            title: Text(localizations.light),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement theme switching
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.dark_mode, color: AppColor.primaryGreen),
            title: Text(localizations.dark),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement theme switching
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(
              Icons.settings_system_daydream,
              color: AppColor.accent,
            ),
            title: Text("Système"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement theme switching
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutCard(BuildContext context) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          ListTile(
            leading: Icon(Icons.info_outline, color: AppColor.primaryGreen),
            title: Text("Version"),
            subtitle: Text("1.0.0"),
            onTap: () {
              _showAboutDialog(context);
            },
          ),
          const Divider(height: 1),
          ListTile(
            leading: Icon(Icons.contact_support, color: AppColor.accent),
            title: Text("Support"),
            trailing: Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              // TODO: Implement support
            },
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    showAboutDialog(
      context: context,
      applicationName: localizations.appTitle,
      applicationVersion: "1.0.0",
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: AppColor.primaryGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.menu_book_rounded,
          color: AppColor.pureWhite,
          size: 32,
        ),
      ),
      children: [
        Text(
          "Une application pour lire le Coran et écouter les récitations en langue Wolof.",
          style: TextStyle(fontSize: 14),
        ),
      ],
    );
  }
}
