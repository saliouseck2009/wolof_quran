import 'package:flutter/material.dart';
import '../../l10n/generated/app_localizations.dart';
import '../utils/home_card_colors.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        // AppIcon(accentGreen: accentGreen, colorScheme: colorScheme),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            Icons.auto_stories_outlined,
            size: 50,
            color: homeAccentColor(colorScheme),
          ),
        ),

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
        _HeaderButton(
          icon: Icons.search_rounded,
          tooltip: localizations.search,
          routeName: '/search',
        ),
        const SizedBox(width: 8),
        _HeaderButton(
          icon: Icons.settings_outlined,
          tooltip: localizations.settings,
          routeName: '/settings',
        ),
      ],
    );
  }
}

class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final String routeName;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return IconButton(
      onPressed: () => Navigator.pushNamed(context, routeName),
      tooltip: tooltip,
      icon: Icon(
        icon,
        color: colorScheme.onSurface.withValues(alpha: 0.75),
        size: 20,
      ),
      style: IconButton.styleFrom(
        backgroundColor: homeCardColor(colorScheme),
        minimumSize: const Size(44, 44),
        maximumSize: const Size(44, 44),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
