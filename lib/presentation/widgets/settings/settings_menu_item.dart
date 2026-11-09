import 'package:flutter/material.dart';

import '../../utils/home_card_colors.dart';

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;
  final bool showArrow;

  /// Replaces the default trailing icon (edit pencil, or arrow when
  /// [showArrow] is set).
  final IconData? trailingIcon;

  /// Tints the card, e.g. while a menu anchored to it is open.
  final bool highlighted;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.showArrow = false,
    this.trailingIcon,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final cardColor = isDark
        ? colorScheme.surfaceContainer
        : colorScheme.onPrimary;

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      decoration: BoxDecoration(
        color: highlighted
            ? Color.alphaBlend(
                homeAccentColor(colorScheme).withValues(alpha: 0.08),
                cardColor,
              )
            : cardColor,
        borderRadius: BorderRadius.circular(16),
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
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? colorScheme.onPrimary : colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onSurface,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.surface,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          value,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(
                                color: isDark
                                    ? colorScheme.onPrimary
                                    : colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    trailingIcon ??
                        (showArrow ? Icons.arrow_forward_ios : Icons.edit),
                    color: isDark ? colorScheme.onPrimary : colorScheme.primary,
                    // A chevron glyph fills less of its box than the pencil.
                    size: trailingIcon == null ? 16 : 20,
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
