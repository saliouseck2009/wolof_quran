import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/mushaf/quran_page_data.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'reading_goal_form_widgets.dart';

/// Lets the user pick a surah; returns its number, or `null` when dismissed.
/// [selectedSurah] is highlighted and scrolled into view.
Future<int?> showSurahPickerSheet(BuildContext context, {int? selectedSurah}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _SurahPickerSheet(selectedSurah: selectedSurah),
  );
}

class _SurahPickerSheet extends StatefulWidget {
  final int? selectedSurah;

  const _SurahPickerSheet({this.selectedSurah});

  @override
  State<_SurahPickerSheet> createState() => _SurahPickerSheetState();
}

class _SurahPickerSheetState extends State<_SurahPickerSheet> {
  static const _rowExtent = 64.0;

  late final ScrollController _scrollController = ScrollController(
    initialScrollOffset: widget.selectedSurah == null
        ? 0
        : ((widget.selectedSurah! - 3).clamp(0, 113)) * _rowExtent,
  );
  var _query = '';

  List<int> get _filteredSurahs {
    final query = _query.trim().toLowerCase();
    final all = [for (var s = 1; s <= 114; s++) s];
    if (query.isEmpty) {
      return all;
    }
    return all.where((s) {
      return '$s'.startsWith(query) ||
          quran.getSurahName(s).toLowerCase().contains(query) ||
          quran.getSurahNameArabic(s).contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surahs = _filteredSurahs;

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: SheetHeader(title: localizations.chooseSurah),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: TextField(
              autofocus: false,
              onChanged: (value) => setState(() => _query = value),
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: localizations.searchSurah,
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                    color: colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
              itemExtent: _rowExtent,
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surahNumber = surahs[index];
                final selected = surahNumber == widget.selectedSurah;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: selected
                        ? colorScheme.primary.withValues(alpha: 0.08)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () => Navigator.of(context).pop(surahNumber),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$surahNumber',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? colorScheme.onPrimary
                                      : colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  text: quran.getSurahName(surahNumber),
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: selected
                                        ? colorScheme.primary
                                        : colorScheme.onSurface,
                                  ),
                                  children: [
                                    TextSpan(
                                      text:
                                          '  · ${localizations.surahAyahCount(quran.getVerseCount(surahNumber))}',
                                      style: theme.textTheme.bodySmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w400,
                                            color: colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                  ],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              localizations.pageNumberLabel(
                                getFirstPageOfSurah(surahNumber),
                              ),
                              style: theme.textTheme.labelMedium?.copyWith(
                                fontWeight: selected
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
