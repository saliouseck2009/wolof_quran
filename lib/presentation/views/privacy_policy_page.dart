import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../l10n/generated/app_localizations.dart';

class PrivacyPolicyPage extends StatelessWidget {
  static const String routeName = '/privacy-policy';
  static const String _lastUpdated = '11/04/2026';
  static const String _contactEmail = 'saliouseck2009@gmail.com';
  static const String _publisherName = 'Saliou Seck';
  static const String _onlinePolicyUrl =
      'https://www.privacypolicies.com/live/65b14f41-1cbe-4e47-ab04-211ff84a8c42';

  const PrivacyPolicyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final textTheme = Theme.of(context).textTheme;

    // Reusable text styles
    final sectionTitleStyle = textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
      color: colorScheme.onSurface,
      height: 1.4,
    );
    final bodyStyle = textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurfaceVariant,
      height: 1.7,
    );
    final divider = Divider(
      color: colorScheme.outlineVariant.withValues(alpha: 0.4),
      height: 40,
    );

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.privacyPolicyPageTitle,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: isDark ? colorScheme.surface : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Intro ---
            Icon(
              Icons.verified_user_outlined,
              color: colorScheme.primary,
              size: 32,
            ),
            const SizedBox(height: 12),
            Text(
              localizations.privacyPolicyIntro,
              style: textTheme.bodyLarge?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              localizations.privacyPolicyPublisher(_publisherName),
              style: bodyStyle,
            ),
            const SizedBox(height: 2),
            Text(
              localizations.privacyPolicyAgeRating,
              style: bodyStyle,
            ),
            const SizedBox(height: 2),
            Text(
              localizations.privacyPolicyLastUpdated(_lastUpdated),
              style: textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),

            divider,

            // --- Local data ---
            Text(localizations.privacyPolicyLocalDataTitle,
                style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(localizations.privacyPolicyLocalDataBody, style: bodyStyle),

            divider,

            // --- Internet ---
            Text(localizations.privacyPolicyInternetTitle,
                style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(localizations.privacyPolicyInternetBody, style: bodyStyle),

            divider,

            // --- Permissions ---
            Text(localizations.privacyPolicyPermissionsTitle,
                style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(localizations.privacyPolicyPermissionsBody, style: bodyStyle),

            divider,

            // --- Children ---
            Text(localizations.privacyPolicyChildrenTitle,
                style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(localizations.privacyPolicyChildrenBody, style: bodyStyle),

            divider,

            // --- Contact ---
            Text(localizations.privacyPolicyContactTitle,
                style: sectionTitleStyle),
            const SizedBox(height: 8),
            Text(
              localizations.privacyPolicyContactBody(_contactEmail),
              style: bodyStyle,
            ),

            const SizedBox(height: 32),

            // --- Online policy link ---
            Center(
              child: TextButton.icon(
                onPressed: () => _openOnlinePolicy(),
                icon: Icon(
                  Icons.open_in_new,
                  size: 16,
                  color: colorScheme.primary,
                ),
                label: Text(
                  localizations.privacyPolicyOnlineVersion,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _openOnlinePolicy() async {
    final uri = Uri.parse(_onlinePolicyUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
