import 'package:flutter/material.dart';

class SettingsMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final VoidCallback onTap;
  final bool showArrow;

  const SettingsMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onTap,
    this.showArrow = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final activeColor = colorScheme.primary;
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
}
