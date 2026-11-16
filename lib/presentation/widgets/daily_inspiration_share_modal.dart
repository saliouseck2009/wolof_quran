import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:quran/quran.dart' as quran;
import 'package:share_plus/share_plus.dart';

import '../../core/config/app_links.dart';
import '../../core/services/verse_video_builder.dart';
import 'package:wolof_quran/core/mushaf/mushaf_theme.dart';
import 'package:wolof_quran/core/utils/constants/constants.dart';
import '../../domain/entities/ayah_audio.dart';
import '../../l10n/generated/app_localizations.dart';
import '../blocs/mushaf/mushaf_bloc.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import '../utils/verse_video_selection.dart';
import 'snackbar.dart';

void showDailyInspirationShareModal(
  BuildContext context,
  int verseNumber,
  String arabicText,
  String translation,
  String translationSource,
  String surahName,
  int surahNumber, {
  quran.Translation? translationId,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => DailyInspirationShareModal(
      verseNumber: verseNumber,
      arabicText: arabicText,
      translation: translation,
      translationSource: translationSource,
      surahName: surahName,
      surahNumber: surahNumber,
      translationId: translationId,
    ),
  );
}

class DailyInspirationShareModal extends StatefulWidget {
  final int verseNumber;
  final String arabicText;
  final String translation;
  final String translationSource;
  final String surahName;
  final int surahNumber;

  /// Translation [translation] is taken from. The other verses of a
  /// shared range are read from it; found from [translationSource], then
  /// from the settings, when not given.
  final quran.Translation? translationId;

  const DailyInspirationShareModal({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.translationSource,
    required this.surahName,
    required this.surahNumber,
    this.translationId,
  });

  @override
  State<DailyInspirationShareModal> createState() =>
      _DailyInspirationShareModalState();
}

class _DailyInspirationShareModalState
    extends State<DailyInspirationShareModal> {
  final GlobalKey _captureKey = GlobalKey();
  final GlobalKey _shareImageButtonKey = GlobalKey();
  final GlobalKey _shareVideoButtonKey = GlobalKey();

  bool _isSharing = false;

  // Verses to share: [_firstVerse] to [_lastVerse] of the surah, one
  // card each. [_previewVerse] is the card on screen.
  late int _firstVerse = widget.verseNumber;
  late int _lastVerse = widget.verseNumber;
  late int _previewVerse = widget.verseNumber;

  /// Audios of the surah for the selected reciter, once loaded.
  List<AyahAudio>? _surahAudios;
  final Map<String, Duration> _probedDurations = {};

  /// Audios of the selected verses; `null` until loaded, or when the
  /// reciter has no audio for this surah on the device.
  VerseAudioSelection? _audioSelection;
  int _selectionRequest = 0;

  VerseVideoBuilder? _videoBuilder;
  bool _videoCancelled = false;

  /// Verses encoded so far and their total, while a video is built.
  final ValueNotifier<(int, int)?> _videoProgress = ValueNotifier(null);

  int get _verseCount => quran.getVerseCount(widget.surahNumber);

  /// Whether the verse is a real one of a surah with more than one
  /// verse: some callers open the sheet without a surah number.
  bool get _canPickRange =>
      widget.surahNumber >= 1 &&
      widget.surahNumber <= 114 &&
      widget.verseNumber >= 1 &&
      widget.verseNumber <= _verseCount &&
      _verseCount > 1;

  int get _selectedVerseCount => _lastVerse - _firstVerse + 1;

  int get _maxLastVerse {
    final byLimit = _firstVerse + VerseVideoLimits.maxVerses - 1;
    return byLimit < _verseCount ? byLimit : _verseCount;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _refreshAudioSelection();
    });
  }

  @override
  void dispose() {
    _videoProgress.dispose();
    super.dispose();
  }

  void _setFirstVerse(int verse) {
    setState(() {
      _firstVerse = verse;
      if (_lastVerse < verse) _lastVerse = verse;
      if (_lastVerse > _maxLastVerse) _lastVerse = _maxLastVerse;
      _previewVerse = _previewVerse.clamp(_firstVerse, _lastVerse);
      _audioSelection = null;
    });
    _refreshAudioSelection();
  }

  void _setLastVerse(int verse) {
    setState(() {
      _lastVerse = verse;
      _previewVerse = _previewVerse.clamp(_firstVerse, _lastVerse);
      _audioSelection = null;
    });
    _refreshAudioSelection();
  }

  void _showPreviewVerse(int verse) {
    if (verse < _firstVerse || verse > _lastVerse) return;
    setState(() => _previewVerse = verse);
  }

  quran.Translation? get _rangeTranslation {
    final given = widget.translationId;
    if (given != null) return given;
    for (final option in QuranSettingsCubit.availableTranslations) {
      if (option.displayName == widget.translationSource) {
        return option.translation;
      }
    }
    try {
      return context.read<QuranSettingsCubit>().state.selectedTranslation;
    } catch (_) {
      return null;
    }
  }

  /// Arabic text and translation of [verse]. The verse the sheet was
  /// opened on keeps the texts it was given.
  (String, String) _textsOf(int verse) {
    if (verse == widget.verseNumber) {
      return (widget.arabicText, widget.translation);
    }
    final arabic = quran.getVerse(
      widget.surahNumber,
      verse,
      verseEndSymbol: false,
    );
    final translation = _rangeTranslation;
    var translated = '';
    if (translation != null) {
      try {
        translated = quran.getVerseTranslation(
          widget.surahNumber,
          verse,
          translation: translation,
        );
      } catch (_) {
        translated = '';
      }
    }
    return (arabic, translated);
  }

  // Customization options
  late Color _selectedBackgroundColor;
  AyahDisplayMode _selectedDisplayMode = AyahDisplayMode.both;

  // Available background colors
  late List<Color> _backgroundColors;
  bool _didConfigureTheme = false;

  Color get _selectedForeground {
    final brightness = ThemeData.estimateBrightnessForColor(
      _selectedBackgroundColor,
    );
    return brightness == Brightness.dark ? Colors.white : Colors.black87;
  }

  Color get _selectedForegroundMuted =>
      _selectedForeground.withValues(alpha: 0.72);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didConfigureTheme) return;

    MushafBloc? mushafBloc;
    try {
      mushafBloc = BlocProvider.of<MushafBloc>(context);
    } catch (_) {
      mushafBloc = null;
    }
    final mushafThemeColor = mushafBloc?.state.theme.pageBackgroundColor;
    final mushafPalette = MushafThemeData.allThemes
        .map((theme) => theme.pageBackgroundColor)
        .toSet()
        .toList(growable: false);

    final colorScheme = Theme.of(context).colorScheme;
    _backgroundColors = mushafPalette.isNotEmpty
        ? mushafPalette
        : <Color>{
            colorScheme.primary,
            colorScheme.primaryContainer,
            colorScheme.secondary,
            colorScheme.secondaryContainer,
            colorScheme.tertiary,
            colorScheme.tertiaryContainer,
            colorScheme.surface,
            colorScheme.surfaceContainerHighest,
            colorScheme.inverseSurface,
            colorScheme.error,
          }.toList();

    _selectedBackgroundColor = mushafThemeColor ?? _backgroundColors.first;
    _didConfigureTheme = true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final localizations = AppLocalizations.of(context)!;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      height: double.infinity,
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.35 : 0.2,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.shareAyah,
                  style: textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(left: 8, right: 8, bottom: 64),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  GestureDetector(
                    onHorizontalDragEnd: _onPreviewSwipe,
                    child: RepaintBoundary(
                      key: _captureKey,
                      child: _buildPreviewCard(),
                    ),
                  ),
                  if (_selectedVerseCount > 1) ...[
                    const SizedBox(height: 8),
                    _buildPreviewPager(),
                  ],
                  const SizedBox(height: 32),
                  if (_canPickRange) ...[
                    _buildSectionTitle(localizations.shareVersesTitle),
                    const SizedBox(height: 12),
                    _buildRangeSelector(localizations),
                    const SizedBox(height: 32),
                  ],
                  _buildSectionTitle(localizations.backgroundStyle),
                  const SizedBox(height: 16),
                  _buildBackgroundColorSelector(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(localizations.displayStyle),
                  const SizedBox(height: 16),
                  _buildDisplayModeSelector(localizations),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          key: _shareImageButtonKey,
                          onPressed: _shareImage,
                          icon: Icon(
                            Icons.image_outlined,
                            color: colorScheme.onPrimary,
                          ),
                          label: Text(
                            localizations.shareImage,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.onPrimary,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          key: _shareVideoButtonKey,
                          onPressed:
                              _audioSelection?.length ==
                                  VerseVideoLength.tooLong
                              ? null
                              : _shareVideo,
                          icon: Icon(
                            Icons.movie_creation_outlined,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            localizations.shareVideo,
                            style: textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: colorScheme.primary,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: colorScheme.primary),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    final theme = Theme.of(context);
    return Text(
      title,
      style: theme.textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  void _onPreviewSwipe(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    if (velocity.abs() < 100) return;
    final towardsEnd = Directionality.of(context) == TextDirection.rtl
        ? velocity > 0
        : velocity < 0;
    _showPreviewVerse(_previewVerse + (towardsEnd ? 1 : -1));
  }

  /// Moves between the cards of the range, under the preview.
  Widget _buildPreviewPager() {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          key: const ValueKey('share-preview-previous'),
          tooltip: localizations.previousPageTooltip,
          onPressed: _previewVerse > _firstVerse
              ? () => _showPreviewVerse(_previewVerse - 1)
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(
            '${_previewVerse - _firstVerse + 1} / $_selectedVerseCount',
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontFeatures: const [ui.FontFeature.tabularFigures()],
            ),
          ),
        ),
        IconButton(
          key: const ValueKey('share-preview-next'),
          tooltip: localizations.nextPageTooltip,
          onPressed: _previewVerse < _lastVerse
              ? () => _showPreviewVerse(_previewVerse + 1)
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  Widget _buildRangeSelector(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final selection = _audioSelection;
    final duration = selection?.totalDuration;
    final count = localizations.versesCount(_selectedVerseCount);
    final summary = duration == null
        ? count
        : '$count · ${_formatDuration(duration)}';

    String? notice;
    var noticeIsError = false;
    if (selection != null) {
      if (selection.audios.isNotEmpty && selection.missingVerses.isNotEmpty) {
        notice = localizations.shareAudioMissingVerses(
          selection.missingVerses.join(', '),
        );
        noticeIsError = true;
      } else if (selection.length == VerseVideoLength.tooLong) {
        notice = localizations.shareVideoTooLong(
          VerseVideoLimits.maxDuration.inMinutes,
        );
        noticeIsError = true;
      } else if (selection.length == VerseVideoLength.longForStatus) {
        notice = localizations.shareVideoLongForStatus(
          VerseVideoLimits.statusDuration.inSeconds,
        );
      }
    }

    final labelStyle = theme.textTheme.bodyLarge?.copyWith(
      color: colorScheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 12,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(localizations.shareFromVerse, style: labelStyle),
            _buildVerseDropdown(
              key: const ValueKey('share-range-first'),
              value: _firstVerse,
              first: 1,
              last: _verseCount,
              onChanged: _setFirstVerse,
            ),
            Text(localizations.shareToVerse, style: labelStyle),
            _buildVerseDropdown(
              key: const ValueKey('share-range-last'),
              value: _lastVerse,
              first: _firstVerse,
              last: _maxLastVerse,
              onChanged: _setLastVerse,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          summary,
          key: const ValueKey('share-range-summary'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
        if (notice != null) ...[
          const SizedBox(height: 6),
          Text(
            notice,
            key: const ValueKey('share-range-notice'),
            style: theme.textTheme.bodySmall?.copyWith(
              color: noticeIsError
                  ? colorScheme.error
                  : colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildVerseDropdown({
    required Key key,
    required int value,
    required int first,
    required int last,
    required ValueChanged<int> onChanged,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          key: key,
          value: value,
          menuMaxHeight: 320,
          borderRadius: BorderRadius.circular(12),
          items: [
            for (var verse = first; verse <= last; verse++)
              DropdownMenuItem(value: verse, child: Text('$verse')),
          ],
          onChanged: (verse) {
            if (verse != null && verse != value) onChanged(verse);
          },
        ),
      ),
    );
  }

  static String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  Widget _buildPreviewCard() {
    final (arabicText, translationText) = _textsOf(_previewVerse);
    final onBackground = _selectedForeground;
    final onBackgroundMuted = _selectedForegroundMuted;
    final showArabic =
        _selectedDisplayMode == AyahDisplayMode.both ||
        _selectedDisplayMode == AyahDisplayMode.arabicOnly;
    final showTranslation =
        _selectedDisplayMode == AyahDisplayMode.both ||
        _selectedDisplayMode == AyahDisplayMode.translationOnly;

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _selectedBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // The surah label gives way first, so the header never
                // overflows on a narrow card.
                Flexible(
                  child: Row(
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 2),
                        child: Icon(
                          Icons.auto_stories_outlined,
                          color: onBackground,
                          size: 36,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          '${widget.surahName} (${widget.surahNumber}): $_previewVerse',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: onBackgroundMuted.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    Constants.appName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onBackground,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Expanded(
              child: _AyahTexts(
                showArabic: showArabic,
                showTranslation: showTranslation,
                arabicText: arabicText,
                translationText: translationText,
                translationSource: widget.translationSource,
                surahNumber: widget.surahNumber,
                verseNumber: _previewVerse,
                onBackground: onBackground,
                onBackgroundMuted: onBackgroundMuted,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundColorSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _backgroundColors.map((color) {
        final isSelected = color == _selectedBackgroundColor;
        final onColor =
            ThemeData.estimateBrightnessForColor(color) == Brightness.dark
            ? Colors.white
            : Colors.black87;
        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedBackgroundColor = color;
            });
          },
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? onColor : Colors.transparent,
                width: 3,
              ),
              boxShadow: Theme.of(context).brightness == Brightness.dark
                  ? [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: isSelected
                ? Icon(Icons.check, color: onColor, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayModeSelector(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final modes = [
      (
        AyahDisplayMode.both,
        localizations.arabicAndTranslation,
        Icons.view_headline,
      ),
      (
        AyahDisplayMode.arabicOnly,
        localizations.arabicOnly,
        Icons.format_textdirection_r_to_l,
      ),
      (
        AyahDisplayMode.translationOnly,
        localizations.translationOnly,
        Icons.translate,
      ),
    ];

    return Column(
      children: modes.map((modeData) {
        final mode = modeData.$1;
        final label = modeData.$2;
        final icon = modeData.$3;
        final isSelected = mode == _selectedDisplayMode;

        return GestureDetector(
          onTap: () {
            setState(() {
              _selectedDisplayMode = mode;
            });
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.14)
                  : colorScheme.surfaceContainerHigh.withValues(
                      alpha: isDark ? 0.35 : 0.6,
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected
                          ? FontWeight.w600
                          : FontWeight.w500,
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: colorScheme.primary,
                    size: 20,
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Future<void> _shareImage() async {
    final localizations = AppLocalizations.of(context)!;
    await _shareWithGuard(
      originKey: _shareImageButtonKey,
      isVideoShare: false,
      prepareFiles: () async {
        final imageFile = await _capturePreviewToFile();
        if (imageFile == null) {
          _showMessage(localizations.shareCaptureFailed);
          return null;
        }
        return [XFile(imageFile.path, mimeType: 'image/png')];
      },
      shareText: _buildShareText(localizations, _previewVerse, _previewVerse),
      fallbackMessage: localizations.shareActionCancelled,
    );
  }

  Future<void> _shareVideo() async {
    final localizations = AppLocalizations.of(context)!;
    _videoCancelled = false;
    _videoProgress.value = null;
    await _shareWithGuard(
      originKey: _shareVideoButtonKey,
      isVideoShare: true,
      prepareFiles: _prepareVideo,
      shareText: _buildShareText(localizations, _firstVerse, _lastVerse),
      fallbackMessage: localizations.shareActionCancelled,
    );
  }

  /// Builds the video of the selected verses; `null`, after telling the
  /// user why, when it cannot be built or was cancelled.
  Future<List<XFile>?> _prepareVideo() async {
    final localizations = AppLocalizations.of(context)!;
    final firstVerse = _firstVerse;
    final lastVerse = _lastVerse;

    final selection = await _resolveAudioSelection(
      firstVerse: firstVerse,
      lastVerse: lastVerse,
      silent: false,
    );
    if (selection == null) return null;
    if (!selection.isComplete) {
      _showMessage(
        firstVerse == lastVerse
            ? localizations.shareAudioFileMissingAyah
            : localizations.shareAudioMissingVerses(
                selection.missingVerses.join(', '),
              ),
      );
      return null;
    }
    if (selection.length == VerseVideoLength.tooLong) {
      _showMessage(
        localizations.shareVideoTooLong(VerseVideoLimits.maxDuration.inMinutes),
      );
      return null;
    }

    final cards = await _captureRangeCards(firstVerse, lastVerse);
    try {
      if (_videoCancelled) return null;
      if (cards == null) {
        _showMessage(localizations.shareCaptureFailed);
        return null;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final verses = firstVerse == lastVerse
          ? 'verse_$firstVerse'
          : 'verses_${firstVerse}_$lastVerse';
      final builder = VerseVideoBuilder();
      _videoBuilder = builder;
      final result = await builder.build(
        segments: [
          for (var index = 0; index < cards.length; index++)
            VerseVideoSegment(
              imagePath: cards[index].path,
              audioPath: selection.audios[index].localPath,
            ),
        ],
        workDir: tempDir,
        outputPath:
            '${tempDir.path}/chapter_${widget.surahNumber}_${verses}_$timestamp.mp4',
        onProgress: (done, total) {
          if (mounted) _videoProgress.value = (done, total);
        },
      );

      switch (result.status) {
        case VerseVideoStatus.success:
          return [XFile(result.path!, mimeType: 'video/mp4')];
        case VerseVideoStatus.cancelled:
          return null;
        case VerseVideoStatus.failed:
          _showMessage(localizations.shareVideoGenerationFailed);
          return null;
      }
    } finally {
      _videoBuilder = null;
      for (final card in cards ?? const <File>[]) {
        try {
          await card.delete();
        } catch (_) {
          // Left to the system's temporary files clean-up.
        }
      }
    }
  }

  void _cancelVideo() {
    _videoCancelled = true;
    _videoBuilder?.cancel();
  }

  /// Renders the card of each verse in turn and captures it; `null`
  /// when a capture fails or the video is cancelled meanwhile.
  Future<List<File>?> _captureRangeCards(int firstVerse, int lastVerse) async {
    final shownVerse = _previewVerse;
    final cards = <File>[];
    try {
      for (var verse = firstVerse; verse <= lastVerse; verse++) {
        if (!mounted || _videoCancelled) return _discard(cards);
        if (_previewVerse != verse) {
          setState(() => _previewVerse = verse);
          await WidgetsBinding.instance.endOfFrame;
          if (!mounted) return _discard(cards);
        }
        final card = await _capturePreviewToFile(jpeg: true);
        if (card == null) return _discard(cards);
        cards.add(card);
      }
      return cards;
    } finally {
      if (mounted && _previewVerse != shownVerse) {
        setState(() => _previewVerse = shownVerse);
      }
    }
  }

  List<File>? _discard(List<File> cards) {
    for (final card in cards) {
      try {
        card.deleteSync();
      } catch (_) {
        // Left to the system's temporary files clean-up.
      }
    }
    return null;
  }

  String _buildShareText(
    AppLocalizations localizations,
    int firstVerse,
    int lastVerse,
  ) {
    final baseText = firstVerse == lastVerse
        ? localizations.shareDefaultText(widget.surahName, firstVerse)
        : localizations.shareDefaultTextRange(
            widget.surahName,
            firstVerse,
            lastVerse,
          );
    return '$baseText\n\nAndroid: ${AppLinks.playStoreUrl}\niOS: ${AppLinks.appStoreUrl}';
  }

  Future<void> _shareWithGuard({
    required GlobalKey originKey,
    required bool isVideoShare,
    required Future<List<XFile>?> Function() prepareFiles,
    required String shareText,
    required String fallbackMessage,
  }) async {
    if (_isSharing) return;
    _isSharing = true;

    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        useRootNavigator: true,
        builder: (dialogContext) => _buildShareLoadingDialog(
          colorScheme: colorScheme,
          localizations: localizations,
          isVideoShare: isVideoShare,
        ),
      );

      final files = await prepareFiles();

      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }

      if (!mounted || files == null || files.isEmpty) {
        _showMessage(fallbackMessage);
        return;
      }

      final result = await Share.shareXFiles(
        files,
        text: shareText,
        sharePositionOrigin: _shareOrigin(originKey),
      );

      if (!mounted) return;
      _handleShareResult(result);
    } catch (e) {
      if (mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        CustomSnackbar.showErrorSnackbar(
          context,
          localizations.shareUnexpectedError(e.toString()),
          duration: 3,
        );
      }
    } finally {
      _isSharing = false;
    }
  }

  Widget _buildShareLoadingDialog({
    required ColorScheme colorScheme,
    required AppLocalizations localizations,
    required bool isVideoShare,
  }) {
    final icon = isVideoShare
        ? Icons.movie_creation_outlined
        : Icons.image_outlined;
    final title = isVideoShare
        ? localizations.shareVideo
        : localizations.shareImage;
    final statusText = _shareLoadingStatusText(isVideoShare);

    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: colorScheme.outlineVariant.withValues(alpha: 0.45),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: colorScheme.primary.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: colorScheme.primary, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<(int, int)?>(
              valueListenable: _videoProgress,
              builder: (context, progress, _) {
                // Per-verse progress only makes sense for several verses.
                final steps =
                    isVideoShare && progress != null && progress.$2 > 1
                    ? progress
                    : null;
                final current = steps == null
                    ? 0
                    : (steps.$1 + 1).clamp(1, steps.$2);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      steps == null
                          ? statusText
                          : '$statusText\n${localizations.shareVideoProgress(current, steps.$2)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(99),
                      child: LinearProgressIndicator(
                        value: steps == null ? null : steps.$1 / steps.$2,
                        minHeight: 7,
                        backgroundColor: colorScheme.surfaceContainerHighest,
                        color: colorScheme.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
            if (isVideoShare)
              Align(
                alignment: AlignmentDirectional.centerEnd,
                child: TextButton(
                  key: const ValueKey('share-video-cancel'),
                  onPressed: _cancelVideo,
                  child: Text(localizations.cancel),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _shareLoadingStatusText(bool isVideoShare) {
    final localizations = AppLocalizations.of(context)!;
    return isVideoShare
        ? localizations.shareGeneratingVideo
        : localizations.sharePreparingContent;
  }

  ui.Rect _shareOrigin(GlobalKey key) {
    final renderBox = key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox != null && renderBox.hasSize) {
      final offset = renderBox.localToGlobal(Offset.zero);
      return offset & renderBox.size;
    }
    final overlayBox =
        Overlay.maybeOf(context)?.context.findRenderObject() as RenderBox?;
    if (overlayBox != null && overlayBox.hasSize) {
      final offset = overlayBox.localToGlobal(Offset.zero);
      return offset & overlayBox.size;
    }
    return const ui.Rect.fromLTWH(0, 0, 1, 1);
  }

  void _handleShareResult(ShareResult result) {
    final localizations = AppLocalizations.of(context)!;
    switch (result.status) {
      case ShareResultStatus.success:
        if (Navigator.of(context).canPop()) {
          Navigator.pop(context);
        }
        break;
      case ShareResultStatus.dismissed:
        // User intentionally closed the share sheet: no toast needed.
        break;
      case ShareResultStatus.unavailable:
        _showMessage(localizations.shareUnavailable);
        break;
    }
  }

  Future<File?> _capturePreviewToFile({bool jpeg = false}) async {
    final boundary =
        _captureKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
    Uint8List uint8List;

    if (jpeg) {
      final ByteData? rawBytes = await image.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      );
      if (rawBytes == null) return null;
      final img.Image converted = img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: rawBytes.buffer,
        numChannels: 4,
        order: img.ChannelOrder.rgba,
      );
      uint8List = Uint8List.fromList(img.encodeJpg(converted, quality: 95));
    } else {
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      if (byteData == null) return null;
      uint8List = byteData.buffer.asUint8List();
    }

    final tempDir = await getTemporaryDirectory();
    final extension = jpeg ? 'jpg' : 'png';
    final file = File(
      '${tempDir.path}/daily_inspiration_${widget.surahNumber}_${_previewVerse}_${DateTime.now().microsecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(uint8List);
    return file;
  }

  /// Audios of the surah for the selected reciter; `null` when there are
  /// none on the device. Says why unless [silent].
  Future<List<AyahAudio>?> _loadSurahAudios({required bool silent}) async {
    void tell(String message) {
      if (!silent) _showMessage(message);
    }

    final localizations = AppLocalizations.of(context)!;
    final quranSettings = context.read<QuranSettingsCubit>();
    final selectedReciter = quranSettings.state.selectedReciter;
    if (selectedReciter == null) {
      tell(localizations.shareSelectReciterForVideo);
      return null;
    }

    final audioCubit = context.read<AudioManagementCubit>();
    if (audioCubit.state is! AudioManagementLoaded &&
        audioCubit.state is! AudioDownloading) {
      audioCubit.initialize();
    }

    await audioCubit.loadAyahAudios(selectedReciter.id, widget.surahNumber);

    final audioState = audioCubit.state;

    List<AyahAudio> ayahAudios = [];
    if (audioState is AudioManagementLoaded) {
      ayahAudios = audioState.getAyahAudios(
        selectedReciter.id,
        widget.surahNumber,
      );
    } else if (audioState is AudioDownloading) {
      final key = '${selectedReciter.id}_${widget.surahNumber}';
      ayahAudios = audioState.previousAyahAudiosMap[key] ?? [];
    } else {
      tell(localizations.shareAudioUnavailableForSurah);
      return null;
    }

    if (ayahAudios.isEmpty) {
      tell(localizations.shareAudioNotDownloaded);
      return null;
    }
    return ayahAudios;
  }

  /// Audios of the verses [firstVerse] to [lastVerse], with their
  /// lengths; `null` when the surah has no audio on the device.
  Future<VerseAudioSelection?> _resolveAudioSelection({
    required int firstVerse,
    required int lastVerse,
    required bool silent,
  }) async {
    // A share reads the files again: one may have been deleted since.
    final surahAudios = silent && _surahAudios != null
        ? _surahAudios
        : await _loadSurahAudios(silent: silent);
    if (surahAudios == null) return null;
    _surahAudios = surahAudios;

    final selection = VerseAudioSelection.resolve(
      available: surahAudios,
      firstVerse: firstVerse,
      lastVerse: lastVerse,
      fileExists: (path) => File(path).existsSync(),
    );

    // The length of an audio is cached the first time it is played; ask
    // ffprobe for those never played.
    final audios = <AyahAudio>[];
    for (final audio in selection.audios) {
      final duration =
          audio.duration ??
          (_probedDurations[audio.localPath] ??=
              await VerseVideoBuilder.probeDuration(audio.localPath) ??
              Duration.zero);
      audios.add(
        AyahAudio(
          surahNumber: audio.surahNumber,
          ayahNumber: audio.ayahNumber,
          reciterId: audio.reciterId,
          localPath: audio.localPath,
          duration: duration == Duration.zero ? null : duration,
        ),
      );
    }
    return VerseAudioSelection(
      audios: audios,
      missingVerses: selection.missingVerses,
    );
  }

  /// Reloads [_audioSelection] for the selected verses.
  Future<void> _refreshAudioSelection() async {
    if (!_canPickRange) return;
    final request = ++_selectionRequest;
    VerseAudioSelection? selection;
    try {
      selection = await _resolveAudioSelection(
        firstVerse: _firstVerse,
        lastVerse: _lastVerse,
        silent: true,
      );
    } catch (_) {
      selection = null;
    }
    if (!mounted || request != _selectionRequest) return;
    setState(() => _audioSelection = selection);
  }

  void _showMessage(String message) {
    if (!mounted) return;
    CustomSnackbar.showSnackbar(context, message, duration: 3);
  }
}

class _AdaptiveText extends StatelessWidget {
  const _AdaptiveText({
    required this.text,
    required this.style,
    required this.minFontSize,
    required this.maxFontSize,
    this.textAlign = TextAlign.start,
    this.textDirection,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final double maxFontSize;
  final TextAlign textAlign;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final fittedFontSize = _calculateFontSize(
          constraints,
          context,
        ).clamp(4.0, maxFontSize);
        return Align(
          alignment: Alignment.center,
          child: Text(
            text,
            textAlign: textAlign,
            textDirection: textDirection,
            style: style.copyWith(fontSize: fittedFontSize),
            overflow: TextOverflow.fade,
            softWrap: true,
          ),
        );
      },
    );
  }

  double _calculateFontSize(BoxConstraints constraints, BuildContext context) {
    final availableWidth = constraints.maxWidth.isFinite
        ? constraints.maxWidth
        : MediaQuery.sizeOf(context).width;
    final availableHeight = constraints.maxHeight.isFinite
        ? constraints.maxHeight
        : double.infinity;

    final direction = textDirection ?? Directionality.of(context);
    final textScaler = MediaQuery.textScalerOf(context);

    double measure(double size) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: size),
        ),
        textAlign: textAlign,
        textDirection: direction,
        textScaler: textScaler,
      )..layout(maxWidth: availableWidth);
      return painter.height;
    }

    double search(double low, double high) {
      var best = low;
      while (high - low > 0.3) {
        final mid = (low + high) / 2;
        final height = measure(mid);
        final exceedsHeight =
            availableHeight.isFinite && height > availableHeight;
        if (exceedsHeight) {
          high = mid;
        } else {
          best = mid;
          low = mid;
        }
      }
      return best;
    }

    // Try to stay above the preferred minimum first.
    final preferredFit = search(minFontSize, maxFontSize);
    final preferredHeight = measure(preferredFit);
    if (!(availableHeight.isFinite && preferredHeight > availableHeight)) {
      return preferredFit;
    }

    // Fallback: allow going below the preferred min down to a safe floor.
    final floorMin = minFontSize > 6.0 ? 6.0 : minFontSize;
    final fallbackFit = search(floorMin, minFontSize);
    return fallbackFit;
  }
}

class _AyahTexts extends StatelessWidget {
  const _AyahTexts({
    required this.showArabic,
    required this.showTranslation,
    required this.arabicText,
    required this.translationText,
    required this.translationSource,
    required this.surahNumber,
    required this.verseNumber,
    required this.onBackground,
    required this.onBackgroundMuted,
  });

  final bool showArabic;
  final bool showTranslation;
  final String arabicText;
  final String translationText;
  final String translationSource;
  final int surahNumber;
  final int verseNumber;
  final Color onBackground;
  final Color onBackgroundMuted;

  bool get _isLongestQuranVerse => surahNumber == 2 && verseNumber == 282;

  bool get _isFrenchTranslation {
    final source = translationSource.toLowerCase();
    return source.contains('fr') ||
        source.contains('french') ||
        source.contains('francais');
  }

  int get _normalizedTranslationLength {
    final normalized = translationText.replaceAll(RegExp(r'\s+'), ' ').trim();
    return normalized.length;
  }

  bool get _needsAggressiveTranslationShrink {
    if (_isLongestQuranVerse) return false;
    return _normalizedTranslationLength >= 330;
  }

  double _measureHeight({
    required String text,
    required TextStyle style,
    required double fontSize,
    required double maxWidth,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: fontSize),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaler: textScaler,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.size.height;
  }

  @override
  Widget build(BuildContext context) {
    if (!showArabic && !showTranslation) {
      return const SizedBox.shrink();
    }

    final textScaler = MediaQuery.textScalerOf(context);
    final baseDirection = Directionality.of(context);
    const dividerHeight = 2.0;
    const dividerPadding = 12.0;
    const dividerSpace = dividerHeight + dividerPadding * 2;
    const layoutSafety =
        8.0; // Leave breathing room so we never clip the last line.

    final arabicStyle = TextStyle(
      fontFamily: 'Hafs',
      fontSize: 30,
      fontWeight: FontWeight.w400,
      color: onBackground,
      height: 1.45,
      letterSpacing: 0.3,
    );
    final translationStyle = TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w500,
      color: onBackground,
      height: 1.32,
      letterSpacing: 0.3,
    );

    // Slightly lower minimum for Arabic so translation can always fit.
    const arabicMinFont = 7.0;
    const arabicMaxFont = 32.0;
    const translationMinFont = 6.0;
    const translationMaxFont = 18.0;
    const absoluteFloor = 6.0; // Hard floor to always fit everything.

    if (!showArabic || !showTranslation) {
      final isArabicOnly = showArabic && !showTranslation;
      return _AdaptiveText(
        text: isArabicOnly ? arabicText : translationText,
        textAlign: TextAlign.justify,
        textDirection: isArabicOnly ? TextDirection.rtl : baseDirection,
        minFontSize: isArabicOnly ? arabicMinFont : translationMinFont,
        maxFontSize: isArabicOnly ? arabicMaxFont : translationMaxFont,
        style: isArabicOnly ? arabicStyle : translationStyle,
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = (constraints.maxHeight - dividerSpace - layoutSafety)
            .clamp(0.0, double.infinity)
            .toDouble();
        final needsAggressiveShrink = _needsAggressiveTranslationShrink;

        double measureTotal(double aSize, double tSize) {
          final aHeight = _measureHeight(
            text: arabicText,
            style: arabicStyle,
            fontSize: aSize,
            maxWidth: maxWidth,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            textScaler: textScaler,
          );
          final tHeight = _measureHeight(
            text: translationText,
            style: translationStyle,
            fontSize: tSize,
            maxWidth: maxWidth,
            textAlign: TextAlign.justify,
            textDirection: baseDirection,
            textScaler: textScaler,
          );
          return aHeight + tHeight;
        }

        double arabicFont = arabicMinFont;
        double translationFont = translationMinFont;

        double low = 0.0;
        double high = 1.0;
        for (var i = 0; i < 26; i++) {
          final mid = (low + high) / 2;
          final candidateArabic = (arabicMaxFont * mid).clamp(
            arabicMinFont,
            arabicMaxFont,
          );
          final candidateTranslation = (translationMaxFont * mid).clamp(
            translationMinFont,
            translationMaxFont,
          );
          final total = measureTotal(candidateArabic, candidateTranslation);
          if (total <= maxHeight) {
            arabicFont = candidateArabic;
            translationFont = candidateTranslation;
            low = mid;
          } else {
            high = mid;
          }
        }

        // Fallback: if even the minimums don't fit, scale both further down together.
        final minTotal = measureTotal(arabicMinFont, translationMinFont);
        if (minTotal > maxHeight && maxHeight > 0) {
          final squeeze = (maxHeight / minTotal).clamp(0.3, 1.0);
          arabicFont = (arabicMinFont * squeeze).clamp(
            absoluteFloor,
            arabicMaxFont,
          );
          translationFont = (translationMinFont * squeeze).clamp(
            absoluteFloor,
            translationMaxFont,
          );
        }

        // Last safeguard if rounding still causes an overflow.
        final totalAfterFallback = measureTotal(arabicFont, translationFont);
        if (totalAfterFallback > maxHeight && maxHeight > 0) {
          final factor = (maxHeight / totalAfterFallback).clamp(0.1, 1.0);
          arabicFont = (arabicFont * factor).clamp(
            absoluteFloor,
            arabicMaxFont,
          );
          translationFont = (translationFont * factor).clamp(
            absoluteFloor,
            translationMaxFont,
          );
        }

        // Some very long translations (especially FR) need extra reduction.
        // Keep 2:282 unchanged because it already renders correctly.
        if (needsAggressiveShrink) {
          final aggressiveFloor = _isFrenchTranslation ? 4.6 : 5.2;
          final shrinkFactor = _isFrenchTranslation ? 0.72 : 0.84;
          translationFont = (translationFont * shrinkFactor).clamp(
            aggressiveFloor,
            translationMaxFont,
          );

          final totalAfterAggressive = measureTotal(
            arabicFont,
            translationFont,
          );
          if (totalAfterAggressive > maxHeight && maxHeight > 0) {
            final finalFactor = (maxHeight / totalAfterAggressive).clamp(
              0.1,
              1.0,
            );
            arabicFont = (arabicFont * finalFactor).clamp(
              absoluteFloor,
              arabicMaxFont,
            );
            translationFont = (translationFont * finalFactor).clamp(
              aggressiveFloor,
              translationMaxFont,
            );
          }
        }

        final currentArabicHeight = _measureHeight(
          text: arabicText,
          style: arabicStyle,
          fontSize: arabicFont,
          maxWidth: maxWidth,
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          textScaler: textScaler,
        );
        final currentTranslationHeight = _measureHeight(
          text: translationText,
          style: translationStyle,
          fontSize: translationFont,
          maxWidth: maxWidth,
          textAlign: TextAlign.justify,
          textDirection: baseDirection,
          textScaler: textScaler,
        );

        final remainingSpace =
            constraints.maxHeight -
            (currentArabicHeight + currentTranslationHeight + dividerSpace);
        final extraSpacerHeight = remainingSpace > 0 ? remainingSpace : 0.0;
        final topSpacer = extraSpacerHeight > 0 ? extraSpacerHeight / 2 : 0.0;
        final bottomSpacer = extraSpacerHeight > 0
            ? extraSpacerHeight - topSpacer
            : 0.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (topSpacer > 0) SizedBox(height: topSpacer),
            SizedBox(
              height: currentArabicHeight,
              child: Text(
                arabicText,
                textAlign: TextAlign.justify,
                textDirection: TextDirection.rtl,
                style: arabicStyle.copyWith(fontSize: arabicFont),
                softWrap: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: dividerPadding),
              child: Container(
                width: 60,
                height: dividerHeight,
                decoration: BoxDecoration(
                  color: onBackgroundMuted,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            ),
            SizedBox(
              height: currentTranslationHeight,
              child: Text(
                translationText,
                textAlign: TextAlign.justify,
                style: translationStyle.copyWith(fontSize: translationFont),
                softWrap: true,
              ),
            ),
            if (bottomSpacer > 0) SizedBox(height: bottomSpacer),
          ],
        );
      },
    );
  }
}
