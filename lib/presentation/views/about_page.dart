import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../widgets/snackbar.dart';

class AboutPage extends StatelessWidget {
  static const String routeName = '/about';

  static const String _appVersion = '1.0.0';
  static const String _quranSourceUrl =
      'https://tanzil.net/docs/tanzil_project';
  // static const String _audioManifestUrl =
  //     'https://github.com/saliouseck2009/algo-practice/raw/refs/heads/main/availability.json';
  static const String _contactEmail = 'saliouseck2009@gmail.com';

  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.about,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? colorScheme.surface
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
            _HeaderCard(
              appName: localizations.appTitle,
              versionLabel: localizations.appVersion(_appVersion),
              description: localizations.aboutDescription,
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: localizations.aboutContentSourcesTitle,
              children: [
                _SourceRow(
                  label: localizations.quranTextSourceTitle,
                  value: "package: quran -> TANZIL \n$_quranSourceUrl",
                  onCopy: () => _copyValue(
                    context,
                    localizations,
                    _quranSourceUrl,
                    localizations.quranTextSourceTitle,
                  ),
                ),
                // const SizedBox(height: 12),
                // _SourceRow(
                //   label: localizations.audioManifestSourceTitle,
                //   value: _audioManifestUrl,
                //   onCopy: () => _copyValue(
                //     context,
                //     localizations,
                //     _audioManifestUrl,
                //     localizations.audioManifestSourceTitle,
                //   ),
                // ),
                const SizedBox(height: 12),
                _SourceRow(
                  label: localizations.tafsirAudioSourceTitle,
                  value: localizations.tafsirAudioSourceDetails,
                  onCopy: null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SectionCard(
              title: localizations.aboutContactTitle,
              children: [
                _SourceRow(
                  label: localizations.contactEmailLabel,
                  value: _contactEmail,
                  onCopy: () => _copyValue(
                    context,
                    localizations,
                    _contactEmail,
                    localizations.contactEmailLabel,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _copyValue(
    BuildContext context,
    AppLocalizations localizations,
    String value,
    String label,
  ) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      CustomSnackbar.showSnackbar(
        context,
        localizations.copiedToClipboard(label),
        duration: 2,
      );
    }
  }
}

class _HeaderCard extends StatelessWidget {
  final String appName;
  final String versionLabel;
  final String description;

  const _HeaderCard({
    required this.appName,
    required this.versionLabel,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.menu_book_rounded,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appName,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      versionLabel,
                      style: textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            description,
            style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _SourceRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback? onCopy;

  const _SourceRow({
    required this.label,
    required this.value,
    required this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final localizations = AppLocalizations.of(context)!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        // border: Border.all(
        //   color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        // ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null) ...[
            const SizedBox(width: 8),
            IconButton(
              onPressed: onCopy,
              tooltip: localizations.copyLabel,
              icon: Icon(Icons.copy_rounded, color: colorScheme.primary),
            ),
          ],
        ],
      ),
    );
  }
}
