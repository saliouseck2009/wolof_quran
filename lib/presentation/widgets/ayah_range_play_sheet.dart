import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../domain/entities/ayah_range.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/audio_availability_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_mini_player_cubit.dart';
import 'audio_download_to_play_modal.dart';
import 'snackbar.dart';

/// Icon button that plays several verses starting at
/// [surahNumber]:[ayahNumber], after the user picks the range in
/// [showAyahRangePlaySheet].
class AyahRangePlayButton extends StatelessWidget {
  final int surahNumber;
  final int ayahNumber;
  final double size;
  final Color? color;

  /// Called once the range is playing, e.g. to close a sheet hiding the
  /// mini player.
  final VoidCallback? onPlaybackStarted;

  const AyahRangePlayButton({
    super.key,
    required this.surahNumber,
    required this.ayahNumber,
    this.size = 24.0,
    this.color,
    this.onPlaybackStarted,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
      buildWhen: (previous, current) =>
          previous.selectedReciter != current.selectedReciter,
      builder: (context, settingsState) {
        final reciterId = settingsState.selectedReciter?.id;
        return IconButton(
          tooltip: localizations.playVerseRange,
          onPressed: reciterId == null
              ? null
              : () => _handlePressed(context, reciterId),
          icon: Icon(
            Icons.playlist_play_rounded,
            size: size,
            color: reciterId == null ? null : (color ?? colorScheme.primary),
          ),
        );
      },
    );
  }

  Future<void> _handlePressed(BuildContext context, String reciterId) async {
    final localizations = AppLocalizations.of(context)!;
    final range = await showAyahRangePlaySheet(
      context,
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
    );
    if (range == null || !context.mounted) {
      return;
    }

    final miniPlayerCubit = context.read<SurahMiniPlayerCubit>();
    final missingSurahs = await miniPlayerCubit.missingSurahsForRange(
      reciterId: reciterId,
      range: range,
    );
    for (final missingSurah in missingSurahs) {
      if (!context.mounted) {
        return;
      }
      final isDownloaded = await _downloadSurah(
        context,
        reciterId,
        missingSurah,
      );
      if (!isDownloaded) {
        return;
      }
    }

    AyahRangePlaybackResult result;
    try {
      result = await miniPlayerCubit.playAyahRange(
        reciterId: reciterId,
        range: range,
      );
    } catch (_) {
      result = AyahRangePlaybackResult.audioMissing;
    }
    if (!context.mounted) {
      return;
    }
    switch (result) {
      case AyahRangePlaybackResult.started:
        onPlaybackStarted?.call();
        break;
      case AyahRangePlaybackResult.audioMissing:
        CustomSnackbar.showErrorSnackbar(
          context,
          localizations.audioNotAvailable,
          duration: 3,
        );
        break;
      case AyahRangePlaybackResult.superseded:
        break;
    }
  }

  /// Offers to download [surahNumber]; returns whether it is now available.
  Future<bool> _downloadSurah(
    BuildContext context,
    String reciterId,
    int surahNumber,
  ) async {
    final audioState = context.read<AudioManagementCubit>().state;
    final isDownloadingAnotherSurah =
        audioState is AudioDownloading &&
        (audioState.reciterId != reciterId ||
            audioState.surahNumber != surahNumber);
    if (isDownloadingAnotherSurah) {
      CustomSnackbar.showSnackbar(
        context,
        AppLocalizations.of(context)!.downloadInProgress,
        duration: 2,
      );
      return false;
    }

    return showAudioDownloadToPlayModal(
      context: context,
      reciterId: reciterId,
      surahNumber: surahNumber,
      surahName: quran.getSurahName(surahNumber),
      isAvailableRemotely: context
          .read<AudioAvailabilityCubit>()
          .state
          .isSurahAvailable(reciterId, surahNumber),
    );
  }
}

/// Lets the user choose which verses to play from [surahNumber]:[ayahNumber]:
/// up to the end of the surah (default), or a custom range. Returns `null`
/// when dismissed.
Future<AyahRange?> showAyahRangePlaySheet(
  BuildContext context, {
  required int surahNumber,
  required int ayahNumber,
}) {
  return showModalBottomSheet<AyahRange>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) =>
        _AyahRangePlaySheet(surahNumber: surahNumber, ayahNumber: ayahNumber),
  );
}

enum _RangeMode { untilSurahEnd, custom }

class _AyahRangePlaySheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;

  const _AyahRangePlaySheet({
    required this.surahNumber,
    required this.ayahNumber,
  });

  @override
  State<_AyahRangePlaySheet> createState() => _AyahRangePlaySheetState();
}

class _AyahRangePlaySheetState extends State<_AyahRangePlaySheet> {
  var _mode = _RangeMode.untilSurahEnd;
  late int _startSurah = widget.surahNumber;
  late int _startAyah = widget.ayahNumber;
  late int _endSurah = widget.surahNumber;
  late int _endAyah = widget.ayahNumber;

  AyahRange get _untilSurahEndRange => AyahRange(
    startSurah: widget.surahNumber,
    startAyah: widget.ayahNumber,
    endSurah: widget.surahNumber,
    endAyah: quran.getVerseCount(widget.surahNumber),
  );

  AyahRange get _customRange => AyahRange(
    startSurah: _startSurah,
    startAyah: _startAyah,
    endSurah: _endSurah,
    endAyah: _endAyah,
  );

  AyahRange get _selectedRange =>
      _mode == _RangeMode.untilSurahEnd ? _untilSurahEndRange : _customRange;

  bool get _isEndBeforeStart =>
      _endSurah < _startSurah ||
      (_endSurah == _startSurah && _endAyah < _startAyah);

  void _setStartSurah(int surahNumber) {
    setState(() {
      _startSurah = surahNumber;
      _startAyah = 1;
      _moveEndAfterStart();
    });
  }

  void _setStartAyah(int ayahNumber) {
    setState(() {
      _startAyah = ayahNumber;
      _moveEndAfterStart();
    });
  }

  void _setEndSurah(int surahNumber) {
    setState(() {
      _endSurah = surahNumber;
      _endAyah = _endAyah.clamp(
        _minEndAyah(surahNumber),
        quran.getVerseCount(surahNumber),
      );
    });
  }

  void _setEndAyah(int ayahNumber) {
    setState(() => _endAyah = ayahNumber);
  }

  void _moveEndAfterStart() {
    if (_isEndBeforeStart) {
      _endSurah = _startSurah;
      _endAyah = _startAyah;
    }
  }

  int _minEndAyah(int endSurah) => endSurah == _startSurah ? _startAyah : 1;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final untilEndRange = _untilSurahEndRange;
    final selectedRange = _selectedRange;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        20,
        0,
        20,
        20 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            localizations.playVerseRange,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${quran.getSurahName(widget.surahNumber)} · '
            '${widget.surahNumber}:${widget.ayahNumber}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 20),
          _RangeOptionTile(
            selected: _mode == _RangeMode.untilSurahEnd,
            title: localizations.playUntilSurahEnd,
            subtitle:
                '${_formatRange(untilEndRange)} · '
                '${localizations.versesCount(_countVerses(untilEndRange))}',
            onTap: () => setState(() => _mode = _RangeMode.untilSurahEnd),
          ),
          const SizedBox(height: 10),
          _RangeOptionTile(
            selected: _mode == _RangeMode.custom,
            title: localizations.customVerseRange,
            subtitle: _mode == _RangeMode.custom
                ? '${_formatRange(_customRange)} · '
                      '${localizations.versesCount(_countVerses(_customRange))}'
                : localizations.customVerseRangeHint,
            onTap: () => setState(() => _mode = _RangeMode.custom),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _mode == _RangeMode.custom
                ? Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _RangeEndpointPicker(
                          label: localizations.rangeStartLabel,
                          surahNumber: _startSurah,
                          ayahNumber: _startAyah,
                          firstSurah: 1,
                          firstAyah: 1,
                          onSurahChanged: _setStartSurah,
                          onAyahChanged: _setStartAyah,
                        ),
                        const SizedBox(height: 16),
                        _RangeEndpointPicker(
                          label: localizations.rangeEndLabel,
                          surahNumber: _endSurah,
                          ayahNumber: _endAyah,
                          firstSurah: _startSurah,
                          firstAyah: _minEndAyah(_endSurah),
                          onSurahChanged: _setEndSurah,
                          onAyahChanged: _setEndAyah,
                        ),
                      ],
                    ),
                  )
                : const SizedBox(width: double.infinity),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(selectedRange),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              localizations.playVersesCount(_countVerses(selectedRange)),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatRange(AyahRange range) =>
      '${range.startSurah}:${range.startAyah} – '
      '${range.endSurah}:${range.endAyah}';

  static int _countVerses(AyahRange range) {
    var count = 0;
    for (final surahNumber in range.surahNumbers) {
      count +=
          range.lastAyahIn(
            surahNumber,
            verseCount: quran.getVerseCount(surahNumber),
          ) -
          range.firstAyahIn(surahNumber) +
          1;
    }
    return count;
  }
}

class _RangeOptionTile extends StatelessWidget {
  final bool selected;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RangeOptionTile({
    required this.selected,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.45)
          : colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Surah + verse dropdowns for one end of the range. Only surahs from
/// [firstSurah] and verses from [firstAyah] can be picked.
class _RangeEndpointPicker extends StatelessWidget {
  final String label;
  final int surahNumber;
  final int ayahNumber;
  final int firstSurah;
  final int firstAyah;
  final ValueChanged<int> onSurahChanged;
  final ValueChanged<int> onAyahChanged;

  const _RangeEndpointPicker({
    required this.label,
    required this.surahNumber,
    required this.ayahNumber,
    required this.firstSurah,
    required this.firstAyah,
    required this.onSurahChanged,
    required this.onAyahChanged,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final verseCount = quran.getVerseCount(surahNumber);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _LabeledDropdown(
                label: localizations.surah,
                value: surahNumber,
                values: [for (var s = firstSurah; s <= 114; s++) s],
                itemLabel: (s) => '$s. ${quran.getSurahName(s)}',
                onChanged: onSurahChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _LabeledDropdown(
                label: localizations.ayah,
                value: ayahNumber,
                values: [for (var a = firstAyah; a <= verseCount; a++) a],
                itemLabel: (a) => '$a',
                onChanged: onAyahChanged,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<int> values;
  final String Function(int value) itemLabel;
  final ValueChanged<int> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        isDense: true,
        contentPadding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isDense: true,
          isExpanded: true,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (final item in values)
              DropdownMenuItem<int>(
                value: item,
                child: Text(
                  itemLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
          onChanged: (selected) {
            if (selected != null) {
              onChanged(selected);
            }
          },
        ),
      ),
    );
  }
}
