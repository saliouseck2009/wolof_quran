import 'package:flutter/material.dart';

import '../../../core/helpers/revelation_place_enum.dart';
import '../../widgets/reciter_chapters/chapter_number_widget.dart';

class SurahCard extends StatelessWidget {
  const SurahCard({
    super.key,
    required this.surahNumber,
    required this.translatedName,
    required this.arabicName,
    required this.versesLabel,
    required this.revelationLabel,
    required this.revelationPlace,
    required this.onTap,
  });

  final int surahNumber;
  final String translatedName;
  final String arabicName;
  final String versesLabel;
  final String revelationLabel;
  final String revelationPlace;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final isMeccan = revelationPlace == RevelationPlaceEnum.meccan;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ChapterNumberWidget(
                  color: colorScheme.primary,
                  surahNumber: surahNumber,
                  textTheme: Theme.of(context).textTheme,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        translatedName,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: colorScheme.primary,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Flexible(
                            child: _InfoChip(
                              label: versesLabel,
                              icon: Icons.format_list_numbered,
                              color: colorScheme.secondary,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: _InfoChip(
                              label: revelationLabel,
                              icon: isMeccan
                                  ? Icons.location_on
                                  : Icons.location_city,
                              color: isMeccan
                                  ? colorScheme.secondary
                                  : colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  arabicName,
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                  textAlign: TextAlign.right,
                  textDirection: TextDirection.rtl,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w500,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
