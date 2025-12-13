import 'dart:ui' as ui;
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
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.salamAlaikum,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                    fontFamily: 'Hafs',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  localizations.welcome,
                  style: TextStyle(
                    fontSize: 14,
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
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

  final ui.Color accentGreen;
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
        boxShadow: colorScheme.brightness == Brightness.dark
            ? [
                BoxShadow(
                  color: accentGreen.withValues(alpha: 0.35),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Icon(
        Icons.auto_stories_outlined,
        size: width * 0.5,
        color: colorScheme.onPrimary,
      ),
    );
  }
}
