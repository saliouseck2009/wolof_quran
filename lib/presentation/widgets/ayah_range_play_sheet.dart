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
  // The sheet route strips the bottom padding, so read the system
  // navigation bar height from the caller.
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<AyahRange>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => _AyahRangePlaySheet(
      surahNumber: surahNumber,
      ayahNumber: ayahNumber,
      navigationBarHeight: navigationBarHeight,
    ),
  );
}

enum _RangeMode { untilSurahEnd, custom }

enum _RangeEndpoint { start, end }

const _quickVerseCounts = [5, 10, 20];

class _AyahRangePlaySheet extends StatefulWidget {
  final int surahNumber;
  final int ayahNumber;
  final double navigationBarHeight;

  const _AyahRangePlaySheet({
    required this.surahNumber,
    required this.ayahNumber,
    required this.navigationBarHeight,
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

  /// Endpoint being edited in the verse picker, `null` on the range view.
  _RangeEndpoint? _picking;

  AyahRange get _selectedRange => _mode == _RangeMode.untilSurahEnd
      ? AyahRange(
          startSurah: widget.surahNumber,
          startAyah: widget.ayahNumber,
          endSurah: widget.surahNumber,
          endAyah: quran.getVerseCount(widget.surahNumber),
        )
      : AyahRange(
          startSurah: _startSurah,
          startAyah: _startAyah,
          endSurah: _endSurah,
          endAyah: _endAyah,
        );

  int _minEndAyah(int endSurah) => endSurah == _startSurah ? _startAyah : 1;

  void _setStart(int surahNumber, int ayahNumber) {
    setState(() {
      _startSurah = surahNumber;
      _startAyah = ayahNumber;
      final isEndBeforeStart =
          _endSurah < _startSurah ||
          (_endSurah == _startSurah && _endAyah < _startAyah);
      if (isEndBeforeStart) {
        _endSurah = _startSurah;
        _endAyah = _startAyah;
      }
      _picking = null;
    });
  }

  void _setEnd(int surahNumber, int ayahNumber) {
    setState(() {
      _endSurah = surahNumber;
      _endAyah = ayahNumber;
      _picking = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    // Keep the content above the system navigation bar and the keyboard.
    final bottomInset = mediaQuery.viewInsets.bottom > 0
        ? mediaQuery.viewInsets.bottom
        : widget.navigationBarHeight;

    final picking = _picking;
    final Widget content;
    if (picking == null) {
      content = _buildRangeView(context);
    } else {
      final isStart = picking == _RangeEndpoint.start;
      content = SizedBox(
        height: (mediaQuery.size.height * 0.8 - mediaQuery.viewInsets.bottom)
            .clamp(320.0, double.infinity),
        child: _VersePicker(
          isStart: isStart,
          surahNumber: isStart ? _startSurah : _endSurah,
          ayahNumber: isStart ? _startAyah : _endAyah,
          minSurah: isStart ? 1 : _startSurah,
          minAyahFor: isStart ? (_) => 1 : _minEndAyah,
          onBack: () => setState(() => _picking = null),
          onPicked: isStart ? _setStart : _setEnd,
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset + 16),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: content,
      ),
    );
  }

  Widget _buildRangeView(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final range = _selectedRange;
    final isCustom = _mode == _RangeMode.custom;
    final startSurahVerseCount = quran.getVerseCount(_startSurah);

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.playVerseRange,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      localizations.verseRangeSubtitle(
                        '${quran.getSurahName(widget.surahNumber)} '
                        '${widget.surahNumber}:${widget.ayahNumber}',
                      ),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _ModeSwitch(
            mode: _mode,
            untilEndLabel: localizations.playUntilSurahEnd,
            customLabel: localizations.customVerseRange,
            onChanged: (mode) => setState(() => _mode = mode),
          ),
          const SizedBox(height: 12),
          _RangeCard(
            range: range,
            startLabel: localizations.rangeStartLabel,
            endLabel: localizations.rangeEndLabel,
            onTapStart: isCustom
                ? () => setState(() => _picking = _RangeEndpoint.start)
                : null,
            onTapEnd: isCustom
                ? () => setState(() => _picking = _RangeEndpoint.end)
                : null,
          ),
          const SizedBox(height: 16),
          _SurahProgress(range: range),
          if (isCustom) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final count in _quickVerseCounts)
                  if (_startAyah + count - 1 < startSurahVerseCount)
                    _QuickChip(
                      label: localizations.addVersesChip(count),
                      selected:
                          _endSurah == _startSurah &&
                          _endAyah == _startAyah + count - 1,
                      onTap: () => _setEnd(_startSurah, _startAyah + count - 1),
                    ),
                _QuickChip(
                  label: localizations.surahEndChip,
                  selected:
                      _endSurah == _startSurah &&
                      _endAyah == startSurahVerseCount,
                  onTap: () => _setEnd(_startSurah, startSurahVerseCount),
                ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => Navigator.of(context).pop(range),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              textStyle: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(localizations.playVersesCount(_countVerses(range))),
          ),
        ],
      ),
    );
  }

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

/// Two-option segmented control: until the end of the surah / custom.
class _ModeSwitch extends StatelessWidget {
  final _RangeMode mode;
  final String untilEndLabel;
  final String customLabel;
  final ValueChanged<_RangeMode> onChanged;

  const _ModeSwitch({
    required this.mode,
    required this.untilEndLabel,
    required this.customLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget segment(_RangeMode value, String label) {
      final selected = mode == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged(value),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: selected ? colorScheme.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(11),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          segment(_RangeMode.untilSurahEnd, untilEndLabel),
          segment(_RangeMode.custom, customLabel),
        ],
      ),
    );
  }
}

/// "From → To" summary. Each end becomes a tappable tile when editable.
class _RangeCard extends StatelessWidget {
  final AyahRange range;
  final String startLabel;
  final String endLabel;
  final VoidCallback? onTapStart;
  final VoidCallback? onTapEnd;

  const _RangeCard({
    required this.range,
    required this.startLabel,
    required this.endLabel,
    required this.onTapStart,
    required this.onTapEnd,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isEditable = onTapStart != null;

    return Container(
      padding: EdgeInsets.all(isEditable ? 6 : 8),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _EndpointTile(
              label: startLabel,
              surahNumber: range.startSurah,
              ayahNumber: range.startAyah,
              onTap: onTapStart,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              Icons.arrow_forward_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          Expanded(
            child: _EndpointTile(
              label: endLabel,
              surahNumber: range.endSurah,
              ayahNumber: range.endAyah,
              onTap: onTapEnd,
            ),
          ),
        ],
      ),
    );
  }
}

class _EndpointTile extends StatelessWidget {
  final String label;
  final int surahNumber;
  final int ayahNumber;
  final VoidCallback? onTap;

  const _EndpointTile({
    required this.label,
    required this.surahNumber,
    required this.ayahNumber,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: onTap != null
          ? colorScheme.surfaceContainerHighest
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: colorScheme.onSurfaceVariant,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$surahNumber:$ayahNumber',
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                quran.getSurahName(surahNumber),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows where the range sits inside its first surah.
class _SurahProgress extends StatelessWidget {
  final AyahRange range;

  const _SurahProgress({required this.range});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surahNumber = range.startSurah;
    final verseCount = quran.getVerseCount(surahNumber);
    final first = range.firstAyahIn(surahNumber);
    final last = range.lastAyahIn(surahNumber, verseCount: verseCount);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: colorScheme.onSurfaceVariant,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final start = (first - 1) / verseCount * width;
            final length = ((last - first + 1) / verseCount * width).clamp(
              6.0,
              width - start,
            );
            return SizedBox(
              height: 6,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                  PositionedDirectional(
                    start: start,
                    top: 0,
                    bottom: 0,
                    width: length,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Text('1', style: labelStyle),
            Expanded(
              child: Text(
                '${quran.getSurahName(surahNumber)} · '
                '${localizations.versesCount(verseCount)}',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: labelStyle,
              ),
            ),
            Text('$verseCount', style: labelStyle),
          ],
        ),
      ],
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _QuickChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer.withValues(alpha: 0.5)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected ? colorScheme.primary : colorScheme.outlineVariant,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: selected ? colorScheme.primary : colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }
}

enum _PickerStep { surah, verse }

/// Two-step picker for one end of the range: surah list, then verse grid.
/// Opens on the verse grid of the current surah.
class _VersePicker extends StatefulWidget {
  final bool isStart;
  final int surahNumber;
  final int ayahNumber;
  final int minSurah;
  final int Function(int surahNumber) minAyahFor;
  final VoidCallback onBack;
  final void Function(int surahNumber, int ayahNumber) onPicked;

  const _VersePicker({
    required this.isStart,
    required this.surahNumber,
    required this.ayahNumber,
    required this.minSurah,
    required this.minAyahFor,
    required this.onBack,
    required this.onPicked,
  });

  @override
  State<_VersePicker> createState() => _VersePickerState();
}

class _VersePickerState extends State<_VersePicker> {
  static const _surahRowExtent = 60.0;
  static const _verseCellExtent = 48.0;
  static const _verseGridSpacing = 8.0;
  static const _verseColumns = 6;

  var _step = _PickerStep.verse;
  late int _surah = widget.surahNumber;
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
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surahName = quran.getSurahName(_surah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton.filledTonal(
                tooltip: MaterialLocalizations.of(context).backButtonTooltip,
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.isStart
                      ? localizations.chooseFirstVerse
                      : localizations.chooseLastVerse,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Row(
            children: [
              _BreadcrumbStep(
                label: '1. ${localizations.surah}',
                active: _step == _PickerStep.surah,
                onTap: () => setState(() => _step = _PickerStep.surah),
              ),
              Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
              Flexible(
                child: _BreadcrumbStep(
                  label: '2. ${localizations.ayah} · $surahName',
                  active: _step == _PickerStep.verse,
                  onTap: () => setState(() => _step = _PickerStep.verse),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _step == _PickerStep.surah
              ? _buildSurahStep(context)
              : _buildVerseStep(context),
        ),
      ],
    );
  }

  Widget _buildSurahStep(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final surahs = _filteredSurahs;
    final selectedIndex = surahs.indexOf(_surah);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: localizations.searchSurahOrNumber,
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Expanded(
          child: _InitialScroll(
            initialOffset: selectedIndex > 2
                ? (selectedIndex - 2) * _surahRowExtent
                : 0,
            builder: (controller) => ListView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemExtent: _surahRowExtent,
              itemCount: surahs.length,
              itemBuilder: (context, index) {
                final surahNumber = surahs[index];
                final enabled = surahNumber >= widget.minSurah;
                final selected = surahNumber == _surah;
                final foreground = enabled
                    ? colorScheme.onSurface
                    : colorScheme.onSurface.withValues(alpha: 0.38);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Material(
                    color: selected
                        ? colorScheme.primaryContainer.withValues(alpha: 0.5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: enabled
                          ? () => setState(() {
                              _surah = surahNumber;
                              _step = _PickerStep.verse;
                            })
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          children: [
                            Container(
                              width: 30,
                              height: 30,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected
                                    ? colorScheme.primary
                                    : colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$surahNumber',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: selected
                                      ? colorScheme.onPrimary
                                      : foreground,
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Text(
                                quran.getSurahName(surahNumber),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.bodyLarge?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: foreground,
                                ),
                              ),
                            ),
                            Text(
                              localizations.verseCountShort(
                                quran.getVerseCount(surahNumber),
                              ),
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: enabled
                                    ? colorScheme.onSurfaceVariant
                                    : foreground,
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
        ),
      ],
    );
  }

  Widget _buildVerseStep(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final verseCount = quran.getVerseCount(_surah);
    final minAyah = widget.minAyahFor(_surah);
    final selectedAyah = _surah == widget.surahNumber
        ? widget.ayahNumber
        : null;
    final selectedRow = ((selectedAyah ?? 1) - 1) ~/ _verseColumns;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
          child: Text(
            '${quran.getSurahName(_surah)} · '
            '${localizations.versesCount(verseCount)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: _InitialScroll(
            // Keyed by surah so switching surah resets the scroll position.
            key: ValueKey(_surah),
            initialOffset: selectedRow > 2
                ? (selectedRow - 2) * (_verseCellExtent + _verseGridSpacing)
                : 0,
            builder: (controller) => GridView.builder(
              controller: controller,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: _verseColumns,
                mainAxisExtent: _verseCellExtent,
                mainAxisSpacing: _verseGridSpacing,
                crossAxisSpacing: _verseGridSpacing,
              ),
              itemCount: verseCount,
              itemBuilder: (context, index) {
                final ayahNumber = index + 1;
                final enabled = ayahNumber >= minAyah;
                final selected = ayahNumber == selectedAyah;
                return Material(
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.surfaceContainerHighest.withValues(
                          alpha: enabled ? 1 : 0.4,
                        ),
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: enabled
                        ? () => widget.onPicked(_surah, ayahNumber)
                        : null,
                    child: Center(
                      child: Text(
                        '$ayahNumber',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: selected
                              ? colorScheme.onPrimary
                              : colorScheme.onSurface.withValues(
                                  alpha: enabled ? 1 : 0.38,
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

/// Owns a [ScrollController] starting at [initialOffset] for [builder].
class _InitialScroll extends StatefulWidget {
  final double initialOffset;
  final Widget Function(ScrollController controller) builder;

  const _InitialScroll({
    super.key,
    required this.initialOffset,
    required this.builder,
  });

  @override
  State<_InitialScroll> createState() => _InitialScrollState();
}

class _InitialScrollState extends State<_InitialScroll> {
  late final ScrollController _controller = ScrollController(
    initialScrollOffset: widget.initialOffset,
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(_controller);
}

class _BreadcrumbStep extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _BreadcrumbStep({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active
                ? theme.colorScheme.onSurface
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
