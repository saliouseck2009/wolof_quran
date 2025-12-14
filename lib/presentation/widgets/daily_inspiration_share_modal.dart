import 'dart:developer';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_min_gpl/return_code.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wolof_quran/core/utils/constants/constants.dart';
import '../../domain/entities/ayah_audio.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_detail_cubit.dart';

void showDailyInspirationShareModal(
  BuildContext context,
  int verseNumber,
  String arabicText,
  String translation,
  String translationSource,
  String surahName,
  int surahNumber,
) {
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

  const DailyInspirationShareModal({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.translationSource,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  State<DailyInspirationShareModal> createState() =>
      _DailyInspirationShareModalState();
}

class _DailyInspirationShareModalState
    extends State<DailyInspirationShareModal> {
  final GlobalKey _captureKey = GlobalKey();

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
    final colorScheme = Theme.of(context).colorScheme;
    _selectedBackgroundColor = colorScheme.primary;
    _backgroundColors = <Color>{
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
                  'Share Ayah ',
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
                  RepaintBoundary(key: _captureKey, child: _buildPreviewCard()),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Background Style'),
                  const SizedBox(height: 16),
                  _buildBackgroundColorSelector(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Display Style'),
                  const SizedBox(height: 16),
                  _buildDisplayModeSelector(localizations),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _shareImage,
                          icon: Icon(
                            Icons.image_outlined,
                            color: colorScheme.onPrimary,
                          ),
                          label: Text(
                            'Share Image',
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
                          onPressed: _shareVideo,
                          icon: Icon(
                            Icons.movie_creation_outlined,
                            color: colorScheme.primary,
                          ),
                          label: Text(
                            'Share Video',
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

  Widget _buildPreviewCard() {
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
                Row(
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
                    Text(
                      '${widget.surahName} (${widget.surahNumber}): ${widget.verseNumber}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: onBackground,
                      ),
                    ),
                  ],
                ),
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
                arabicText: widget.arabicText,
                translationText: widget.translation,
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
    await _shareWithGuard(_createImageAndShare);
  }

  Future<void> _shareVideo() async {
    await _shareWithGuard(() async {
      final imageFile = await _capturePreviewToFile(jpeg: true);
      if (imageFile == null) {
        _showMessage('Impossible de capturer l’image.');
        return false;
      }

      final audioPath = await _getAyahAudioPath();
      if (audioPath == null) return false;

      final videoPath = await _generateVideoFromAssets(
        imagePath: imageFile.path,
        audioPath: audioPath,
      );
      if (videoPath == null) {
        _showMessage('Échec de la génération vidéo.');
        return false;
      }

      await Share.shareXFiles(
        [XFile(videoPath, mimeType: 'video/mp4')],
        text:
            'Daily Inspiration - ${widget.surahName} - Verse ${widget.verseNumber}',
      );
      return true;
    });
  }

  Future<bool> _createImageAndShare() async {
    final imageFile = await _capturePreviewToFile();
    if (imageFile == null) return false;

    await Share.shareXFiles(
      [XFile(imageFile.path)],
      text:
          'Daily Inspiration - ${widget.surahName} - Verse ${widget.verseNumber}',
    );
    return true;
  }

  Future<void> _shareWithGuard(Future<bool> Function() action) async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );

      final didComplete = await action();

      if (!mounted) return;
      Navigator.pop(context);
      if (didComplete && mounted) {
        Navigator.pop(context);
      } else if (!didComplete) {
        _showMessage('Action annulée.');
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.fixed,
          content: Text(
            'Error: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
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
      '${tempDir.path}/daily_inspiration_${widget.surahNumber}_${widget.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(uint8List);
    return file;
  }

  Future<String?> _getAyahAudioPath() async {
    final quranSettings = context.read<QuranSettingsCubit>();
    final selectedReciter = quranSettings.state.selectedReciter;
    if (selectedReciter == null) {
      _showMessage(
        'Veuillez sélectionner un récitateur pour générer la vidéo.',
      );
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
      _showMessage('Audio non disponible pour cette sourate.');
      return null;
    }

    if (ayahAudios.isEmpty) {
      _showMessage(
        'Audio non téléchargé pour ce récitateur. Téléchargez les audios puis réessayez.',
      );
      return null;
    }

    final AyahAudio ayahAudio = ayahAudios.firstWhere(
      (audio) => audio.ayahNumber == widget.verseNumber,
      orElse: () => const AyahAudio(
        surahNumber: -1,
        ayahNumber: -1,
        reciterId: '',
        localPath: '',
      ),
    );

    if ((ayahAudio.surahNumber == -1 || ayahAudio.localPath.isEmpty)) {
      _showMessage('Fichier audio introuvable pour cet ayah.');
      return null;
    }

    final file = File(ayahAudio.localPath ?? '');
    if (!await file.exists()) {
      _showMessage('Fichier audio manquant sur l’appareil.');
      return null;
    }

    return file.path;
  }

  Future<String?> _generateVideoFromAssets({
    required String imagePath,
    required String audioPath,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final outputPath =
        '${tempDir.path}/ayah_video_${DateTime.now().millisecondsSinceEpoch}.mp4';

    final command =
        '-y -loop 1 -i "$imagePath" -i "$audioPath" -vf "scale=1080:1920:force_original_aspect_ratio=decrease,pad=1080:1920:(1080-iw)/2:(1920-ih)/2,format=yuv420p" -c:v libx264 -preset veryfast -tune stillimage -c:a aac -b:a 192k -shortest "$outputPath"';

    final session = await FFmpegKit.execute(command);
    final returnCode = await session.getReturnCode();

    if (!ReturnCode.isSuccess(returnCode)) {
      final output = await session.getOutput();
      log('FFmpeg command failed with output: $output');
      throw Exception('Video generation failed: $output');
    }

    return outputPath;
  }

  void _showMessage(String message) {
    if (!mounted) return;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.fixed,
        content: Text(
          message,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: colorScheme.onErrorContainer,
          ),
        ),
        backgroundColor: colorScheme.errorContainer,
      ),
    );
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
    this.maxLines,
  });

  final String text;
  final TextStyle style;
  final double minFontSize;
  final double maxFontSize;
  final TextAlign textAlign;
  final TextDirection? textDirection;
  final int? maxLines;

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
            maxLines: maxLines,
            overflow: maxLines != null
                ? TextOverflow.ellipsis
                : TextOverflow.fade,
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
    final scale = MediaQuery.textScaleFactorOf(context);

    double measure(double size) {
      final painter = TextPainter(
        text: TextSpan(
          text: text,
          style: style.copyWith(fontSize: size),
        ),
        textAlign: textAlign,
        textDirection: direction,
        textScaleFactor: scale,
        maxLines: maxLines,
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
    required this.onBackground,
    required this.onBackgroundMuted,
  });

  final bool showArabic;
  final bool showTranslation;
  final String arabicText;
  final String translationText;
  final Color onBackground;
  final Color onBackgroundMuted;

  double _measureHeight({
    required String text,
    required TextStyle style,
    required double fontSize,
    required double maxWidth,
    required TextAlign textAlign,
    required TextDirection textDirection,
    required double textScale,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: style.copyWith(fontSize: fontSize),
      ),
      textAlign: textAlign,
      textDirection: textDirection,
      textScaleFactor: textScale,
      maxLines: null,
    )..layout(maxWidth: maxWidth);
    return painter.size.height;
  }

  @override
  Widget build(BuildContext context) {
    if (!showArabic && !showTranslation) {
      return const SizedBox.shrink();
    }

    final textScale = MediaQuery.textScaleFactorOf(context);
    final baseDirection = Directionality.of(context);
    const dividerHeight = 2.0;
    const dividerPadding = 12.0;
    const dividerSpace = dividerHeight + dividerPadding * 2;

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
        final maxHeight = (constraints.maxHeight - dividerSpace)
            .clamp(0.0, double.infinity)
            .toDouble();

        double measureTotal(double aSize, double tSize) {
          final aHeight = _measureHeight(
            text: arabicText,
            style: arabicStyle,
            fontSize: aSize,
            maxWidth: maxWidth,
            textAlign: TextAlign.justify,
            textDirection: TextDirection.rtl,
            textScale: textScale,
          );
          final tHeight = _measureHeight(
            text: translationText,
            style: translationStyle,
            fontSize: tSize,
            maxWidth: maxWidth,
            textAlign: TextAlign.justify,
            textDirection: baseDirection,
            textScale: textScale,
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

        final currentArabicHeight = _measureHeight(
          text: arabicText,
          style: arabicStyle,
          fontSize: arabicFont,
          maxWidth: maxWidth,
          textAlign: TextAlign.justify,
          textDirection: TextDirection.rtl,
          textScale: textScale,
        );
        final currentTranslationHeight = _measureHeight(
          text: translationText,
          style: translationStyle,
          fontSize: translationFont,
          maxWidth: maxWidth,
          textAlign: TextAlign.justify,
          textDirection: baseDirection,
          textScale: textScale,
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
