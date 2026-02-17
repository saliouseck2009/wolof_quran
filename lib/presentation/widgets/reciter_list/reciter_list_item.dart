import 'package:flutter/material.dart';

import '../../../domain/entities/reciter.dart';
import '../../../l10n/generated/app_localizations.dart';

class ReciterListItem extends StatelessWidget {
  const ReciterListItem({
    super.key,
    required this.reciter,
    required this.isSelected,
    required this.onSelect,
    required this.onOpenChapters,
  });

  final Reciter reciter;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onOpenChapters;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final accentGreen = colorScheme.primary;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? colorScheme.surfaceContainer : colorScheme.onPrimary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isDark
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onOpenChapters,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: accentGreen.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.person,
                      color: accentGreen,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          reciter.name,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: colorScheme.onSurface,
                                  ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          reciter.arabicName,
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? accentGreen.withValues(alpha: 0.15)
                                : colorScheme.onSurfaceVariant
                                    .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? accentGreen.withValues(alpha: 0.25)
                                  : colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            isSelected
                                ? localizations.defaultReciter
                                : localizations.available,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: isSelected
                                      ? accentGreen
                                      : colorScheme.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: onSelect,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? accentGreen.withValues(alpha: 0.15)
                            : colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        isSelected
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color:
                            isSelected ? accentGreen : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
