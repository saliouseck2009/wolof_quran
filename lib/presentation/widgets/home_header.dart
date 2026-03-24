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
      children: [
        // AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.auto_stories_outlined,
            size: 50,
            color: colorScheme.primary,
          ),
        ),
        //  Image.asset(
        //   'assets/icon/app_icon.png',
        //   width: 40,
        //   height: 40,
        // ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            localizations.appTitle,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
              letterSpacing: -0.3,
            ),
          ),
        ),
        _SettingsButton(colorScheme: colorScheme),
      ],
    );
  }
}

class _SettingsButton extends StatelessWidget {
  final ColorScheme colorScheme;

  const _SettingsButton({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/settings'),
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colorScheme.onSurface.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.settings_outlined,
          color: colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
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
        color: accentGreen,
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
