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
import '../../core/config/theme/seasonal_theme.dart';
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
  late _ShareBackground _selectedBackground;
  AyahDisplayMode _selectedDisplayMode = AyahDisplayMode.both;

  /// Backgrounds offered for the card, in the order they are shown.
  late List<_ShareBackground> _backgrounds;
  bool _didConfigureTheme = false;

  /// Tool whose options are shown over the bottom of the card.
  _ShareTool? _openTool;

  Color get _selectedBackgroundColor => _selectedBackground.color;

  bool get _isDarkBackground =>
      ThemeData.estimateBrightnessForColor(_selectedBackgroundColor) ==
      Brightness.dark;

  Color get _selectedForeground =>
      _isDarkBackground ? Colors.white : const Color(0xFF1B1F1E);

  Color get _selectedForegroundMuted =>
      _selectedForeground.withValues(alpha: 0.78);

  /// Colour of the ornament between the Arabic text and its translation.
  Color get _selectedAccent =>
      _isDarkBackground ? const Color(0xFFE9D48F) : const Color(0xFF8A7430);

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
    final mushafColor = mushafBloc?.state.theme.pageBackgroundColor;

    // The card opens on the colour of the reader's Mushaf: it is added to
    // the list when it is not one of the backgrounds always offered.
    _backgrounds = [..._ShareBackground.curated];
    var selected = _backgrounds.first;
    if (mushafColor != null) {
      final match = _backgrounds.where((b) => b.color == mushafColor);
      if (match.isNotEmpty) {
        selected = match.first;
      } else {
        selected = _ShareBackground(mushafColor, (l) => l.shareBgMushaf);
        _backgrounds.insert(0, selected);
      }
    }
    // During Ramadan the night sky of the season comes first, chosen.
    final decor = Theme.of(context).extension<SeasonalDecor>();
    if (decor?.season == SeasonalTheme.ramadan) {
      selected = _ShareBackground(decor!.skyStart, (l) => l.shareBgRamadan);
      _backgrounds.insert(0, selected);
    }
    _selectedBackground = selected;
    _didConfigureTheme = true;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      height: double.infinity,
      clipBehavior: Clip.antiAlias,
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
            margin: const EdgeInsets.only(top: 10, bottom: 2),
            decoration: BoxDecoration(
              color: colorScheme.outlineVariant.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          _buildHeader(localizations),
          Expanded(child: _buildStage(localizations)),
          if (_selectedVerseCount > 1) _buildPreviewPager(),
          _buildToolBar(localizations),
          _buildShareBar(localizations),
        ],
      ),
    );
  }

  /// The app's green as text, icon or outline on the sheet: the primary
  /// colour is too dark to read on a dark surface.
  Color _accentOn(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark
      ? colorScheme.tertiary
      : colorScheme.primary;

  Widget _buildHeader(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: 20, end: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.shareAyah,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.onSurface,
                  ),
                ),
                if (_canPickRange)
                  Text(
                    localizations.shareVerseLabel(_previewVerse),
                    key: const ValueKey('share-preview-verse'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontFeatures: const [ui.FontFeature.tabularFigures()],
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  /// The card, as large as the sheet allows, with the options of the
  /// open tool over its bottom edge.
  Widget _buildStage(AppLocalizations localizations) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
            child: Center(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _openTool == null
                    ? null
                    : () => setState(() => _openTool = null),
                onHorizontalDragEnd: _onPreviewSwipe,
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.3 : 0.14,
                          ),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      // The card is always laid out at the same size and
                      // scaled to fit, so the shared image is the same on
                      // every screen.
                      child: FittedBox(
                        fit: BoxFit.contain,
                        child: RepaintBoundary(
                          key: _captureKey,
                          child: _buildPreviewCard(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          left: 12,
          right: 12,
          bottom: 4,
          child: Center(
            heightFactor: 1,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: _buildTray(localizations),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTray(AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final tool = _openTool;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.08),
            end: Offset.zero,
          ).animate(animation),
          child: child,
        ),
      ),
      child: tool == null
          ? const SizedBox(
              key: ValueKey('share-tray-none'),
              width: double.infinity,
            )
          : Container(
              key: ValueKey('share-tray-${tool.name}'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? colorScheme.surfaceContainerHigh : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.2),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: switch (tool) {
                _ShareTool.text => _buildDisplayModeSelector(localizations),
                _ShareTool.background => _buildBackgroundColorSelector(
                  localizations,
                ),
                _ShareTool.verses => _buildRangeSelector(localizations),
              },
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
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    return SizedBox(
      height: 40,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            key: const ValueKey('share-preview-previous'),
            tooltip: localizations.previousPageTooltip,
            visualDensity: VisualDensity.compact,
            onPressed: _previewVerse > _firstVerse
                ? () => _showPreviewVerse(_previewVerse - 1)
                : null,
            icon: Icon(isRtl ? Icons.chevron_right : Icons.chevron_left),
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
            visualDensity: VisualDensity.compact,
            onPressed: _previewVerse < _lastVerse
                ? () => _showPreviewVerse(_previewVerse + 1)
                : null,
            icon: Icon(isRtl ? Icons.chevron_left : Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  /// The three tools; each opens its options over the bottom of the card.
  Widget _buildToolBar(AppLocalizations localizations) {
    final colorScheme = Theme.of(context).colorScheme;
    // A range shows its two numbers only: with the word in front, the
    // label does not fit a phone. Screen readers still get it in full.
    final hasRange = _selectedVerseCount > 1;
    final versesLabel = hasRange
        ? '$_firstVerse–$_lastVerse'
        : localizations.shareVersesTitle;

    return _buildBarContent(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Expanded(
            flex: 10,
            child: _buildToolButton(
              tool: _ShareTool.text,
              label: localizations.shareToolText,
              leading: (color) =>
                  Icon(Icons.text_fields, size: 18, color: color),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            flex: 10,
            child: _buildToolButton(
              tool: _ShareTool.background,
              label: localizations.shareToolBackground,
              leading: (_) => Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: _selectedBackgroundColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: colorScheme.onSurface.withValues(alpha: 0.25),
                  ),
                ),
              ),
            ),
          ),
          if (_canPickRange) ...[
            const SizedBox(width: 8),
            Expanded(
              flex: 13,
              child: _buildToolButton(
                tool: _ShareTool.verses,
                label: versesLabel,
                semanticLabel: hasRange
                    ? localizations.shareToolVersesRange(
                        _firstVerse,
                        _lastVerse,
                      )
                    : null,
                leading: (color) =>
                    Icon(Icons.format_list_numbered, size: 18, color: color),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Keeps a bar of buttons at a comfortable width on a wide screen.
  Widget _buildBarContent({
    required EdgeInsets padding,
    required Widget child,
  }) {
    return Center(
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Padding(padding: padding, child: child),
      ),
    );
  }

  Widget _buildToolButton({
    required _ShareTool tool,
    required String label,
    required Widget Function(Color color) leading,
    String? semanticLabel,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final selected = _openTool == tool;
    final foreground = selected
        ? _accentOn(colorScheme)
        : colorScheme.onSurface;

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: semanticLabel != null,
      child: Material(
        color: selected
            ? _accentOn(colorScheme).withValues(alpha: 0.14)
            : (isDark ? colorScheme.surfaceContainerHigh : Colors.white),
        shape: StadiumBorder(
          side: BorderSide(
            color: selected
                ? _accentOn(colorScheme)
                : colorScheme.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: ValueKey('share-tool-${tool.name}'),
          onTap: () => setState(() => _openTool = selected ? null : tool),
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                leading(foreground),
                const SizedBox(width: 6),
                // A label a little too wide is scaled down, not cut.
                Flexible(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      label,
                      maxLines: 1,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: foreground,
                        fontFeatures: const [ui.FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// The share actions, always in reach under the card.
  Widget _buildShareBar(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;
    final selection = _audioSelection;

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

    final duration = selection?.totalDuration;
    final videoLabel = duration == null
        ? localizations.shareVideoShort
        : '${localizations.shareVideoShort} · ${_formatDuration(duration)}';
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(14),
    );

    return Container(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainer : Colors.white,
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: _buildBarContent(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (notice != null) ...[
                _buildNotice(notice, isError: noticeIsError),
                const SizedBox(height: 8),
              ],
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
                        localizations.shareImageShort,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorScheme.primary,
                        minimumSize: const Size.fromHeight(52),
                        shape: buttonShape,
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      key: _shareVideoButtonKey,
                      onPressed:
                          _audioSelection?.length == VerseVideoLength.tooLong
                          ? null
                          : _shareVideo,
                      icon: Icon(
                        Icons.movie_creation_outlined,
                        color: _accentOn(colorScheme),
                      ),
                      label: Text(
                        videoLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: _accentOn(colorScheme),
                          fontFeatures: const [ui.FontFeature.tabularFigures()],
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: _accentOn(colorScheme)),
                        minimumSize: const Size.fromHeight(52),
                        shape: buttonShape,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// What stops or shortens the video, right above the button it is about.
  Widget _buildNotice(String notice, {required bool isError}) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final background = isError
        ? colorScheme.errorContainer
        : colorScheme.secondaryContainer;
    final foreground = isError
        ? colorScheme.onErrorContainer
        : colorScheme.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.info_outline,
            size: 16,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              notice,
              key: const ValueKey('share-range-notice'),
              style: theme.textTheme.bodySmall?.copyWith(color: foreground),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSelector(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final duration = _audioSelection?.totalDuration;
    final count = localizations.versesCount(_selectedVerseCount);
    final summary = duration == null
        ? count
        : '$count · ${_formatDuration(duration)}';
    final labelStyle = theme.textTheme.bodyMedium?.copyWith(
      color: colorScheme.onSurface,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          spacing: 10,
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
        const SizedBox(height: 8),
        Text(
          summary,
          key: const ValueKey('share-range-summary'),
          style: theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
            fontFeatures: const [ui.FontFeature.tabularFigures()],
          ),
        ),
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

  /// Surah and verse shown at the top of the card; `null` when the sheet
  /// was opened without a surah name.
  String? get _cardReference {
    final name = widget.surahName.trim();
    if (name.isEmpty) return null;
    final isRealSurah = widget.surahNumber >= 1 && widget.surahNumber <= 114;
    return isRealSurah ? '$name · ${widget.surahNumber}:$_previewVerse' : name;
  }

  /// The shared image: always [_cardSize], whatever the screen.
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
    final reference = _cardReference;
    // Spacing out the letters would break a name written in Arabic script.
    final referenceIsLatin =
        reference != null && !RegExp(r'[؀-ۿ]').hasMatch(reference);

    return MediaQuery.withNoTextScaling(
      child: Container(
        key: const ValueKey('share-card'),
        width: _cardSize.width,
        height: _cardSize.height,
        color: _selectedBackgroundColor,
        padding: const EdgeInsets.fromLTRB(32, 36, 32, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (reference != null)
              Text(
                referenceIsLatin ? reference.toUpperCase() : reference,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: referenceIsLatin ? 2.2 : 0,
                  color: onBackgroundMuted,
                ),
              ),
            const SizedBox(height: 12),
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
                accent: _selectedAccent,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: onBackgroundMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  Constants.appName,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.4,
                    color: onBackgroundMuted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// One row of named backgrounds; the name of the selected one is
  /// spelled out above it.
  Widget _buildBackgroundColorSelector(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            localizations.shareBackgroundNamed(
              _selectedBackground.name(localizations),
            ),
            key: const ValueKey('share-background-name'),
            style: theme.textTheme.labelMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) {
            final fitted = constraints.maxWidth / _backgrounds.length;
            return SizedBox(
              height: 44,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemExtent: fitted < 40 ? 40 : fitted,
                itemCount: _backgrounds.length,
                itemBuilder: (context, index) {
                  final background = _backgrounds[index];
                  final isSelected = background == _selectedBackground;
                  return Semantics(
                    button: true,
                    selected: isSelected,
                    label: background.name(localizations),
                    child: InkResponse(
                      key: ValueKey('share-background-$index'),
                      radius: 22,
                      onTap: () =>
                          setState(() => _selectedBackground = background),
                      child: Center(
                        child: Container(
                          width: 38,
                          height: 38,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? _accentOn(colorScheme)
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: background.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: colorScheme.onSurface.withValues(
                                  alpha: 0.16,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }

  /// What the card shows: one control with three segments.
  Widget _buildDisplayModeSelector(AppLocalizations localizations) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    final modes = [
      (AyahDisplayMode.both, localizations.shareModeBoth, 3),
      (AyahDisplayMode.arabicOnly, localizations.shareModeArabic, 2),
      (AyahDisplayMode.translationOnly, localizations.shareModeTranslation, 2),
    ];

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colorScheme.onSurface.withValues(alpha: isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (mode, label, flex) in modes)
            Expanded(
              flex: flex,
              child: Semantics(
                button: true,
                selected: mode == _selectedDisplayMode,
                child: GestureDetector(
                  key: ValueKey('share-mode-${mode.name}'),
                  behavior: HitTestBehavior.opaque,
                  onTap: () => setState(() => _selectedDisplayMode = mode),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: mode == _selectedDisplayMode
                          ? (isDark ? colorScheme.surface : Colors.white)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(11),
                      boxShadow: mode == _selectedDisplayMode
                          ? [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label,
                        maxLines: 1,
                        style: theme.textTheme.labelLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: mode == _selectedDisplayMode
                              ? _accentOn(colorScheme)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
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
    required this.accent,
  });

  final bool showArabic;
  final bool showTranslation;
  final String arabicText;
  final String translationText;
  final String translationSource;
  final int surahNumber;
  final int verseNumber;
  final Color onBackground;

  /// Colour of the ornament between the two texts.
  final Color accent;

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
    const dividerHeight = 14.0;
    const dividerPadding = 14.0;
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
        textAlign: TextAlign.center,
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
            textAlign: TextAlign.center,
            textDirection: TextDirection.rtl,
            textScaler: textScaler,
          );
          final tHeight = _measureHeight(
            text: translationText,
            style: translationStyle,
            fontSize: tSize,
            maxWidth: maxWidth,
            textAlign: TextAlign.center,
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
          textAlign: TextAlign.center,
          textDirection: TextDirection.rtl,
          textScaler: textScaler,
        );
        final currentTranslationHeight = _measureHeight(
          text: translationText,
          style: translationStyle,
          fontSize: translationFont,
          maxWidth: maxWidth,
          textAlign: TextAlign.center,
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
                textAlign: TextAlign.center,
                textDirection: TextDirection.rtl,
                style: arabicStyle.copyWith(fontSize: arabicFont),
                softWrap: true,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: dividerPadding),
              child: SizedBox(
                height: dividerHeight,
                child: _CardOrnament(color: accent),
              ),
            ),
            SizedBox(
              height: currentTranslationHeight,
              child: Text(
                translationText,
                textAlign: TextAlign.center,
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

/// Size the card is laid out at; captured at three times that, it gives
/// a 1080 × 1920 image.
const Size _cardSize = Size(360, 640);

/// Tools of the share sheet; each opens its options over the card.
enum _ShareTool { text, background, verses }

/// A background the card can take, with the name it is offered under.
class _ShareBackground {
  const _ShareBackground(this.color, this.name);

  final Color color;
  final String Function(AppLocalizations localizations) name;

  static Color _mushaf(int index) =>
      MushafThemeData.fromIndex(index).pageBackgroundColor;

  /// The backgrounds always offered: a few Mushaf themes that are easy to
  /// tell apart, and the green of the app.
  static final List<_ShareBackground> curated = [
    _ShareBackground(_mushaf(0), (l) => l.shareBgIvory),
    _ShareBackground(_mushaf(2), (l) => l.shareBgCream),
    _ShareBackground(_mushaf(4), (l) => l.shareBgSand),
    _ShareBackground(_mushaf(5), (l) => l.shareBgGold),
    _ShareBackground(_mushaf(14), (l) => l.shareBgSage),
    _ShareBackground(const Color(0xFF004A41), (l) => l.shareBgDeepGreen),
    _ShareBackground(_mushaf(10), (l) => l.shareBgNight),
    _ShareBackground(_mushaf(9), (l) => l.shareBgBlack),
  ];
}

/// Ornament between the Arabic text and its translation: an eight-point
/// star between two hairlines.
class _CardOrnament extends StatelessWidget {
  const _CardOrnament({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final line = Container(
      width: 40,
      height: 1,
      color: color.withValues(alpha: 0.7),
    );
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        line,
        const SizedBox(width: 10),
        CustomPaint(size: const Size(14, 14), painter: _StarPainter(color)),
        const SizedBox(width: 10),
        line,
      ],
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final center = size.center(Offset.zero);
    // Two squares, one turned by an eighth of a turn.
    final side = size.shortestSide / 1.4142;
    final square = Rect.fromCenter(center: center, width: side, height: side);
    canvas.drawRect(square, paint);
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.7853981633974483);
    canvas.translate(-center.dx, -center.dy);
    canvas.drawRect(square, paint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(_StarPainter oldDelegate) => oldDelegate.color != color;
}
