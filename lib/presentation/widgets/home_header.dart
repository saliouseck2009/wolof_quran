import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final accentGreen = colorScheme.primary;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            localizations.appTitle,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushNamed(context, '/settings');
          },
          icon: Icon(
            Icons.settings_outlined,
            color: colorScheme.onSurface,
            size: 24,
          ),
        ),
      ],
    );
  }
}

class AppIcon extends StatelessWidget {
  final double width;
  final double height;
  const AppIcon({
    super.key,
    required this.accentGreen,
    required this.colorScheme,
    this.width = 60,
    this.height = 60,
  });

  final Color accentGreen;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentGreen, accentGreen.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(width / 2),
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        size: width * 0.5,
        color: colorScheme.onPrimary,
      ),
    );
  }
}
