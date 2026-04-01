import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:wolof_quran/core/mushaf/mushaf_theme.dart';
import 'package:wolof_quran/core/utils/constants/constants.dart';
import '../../l10n/generated/app_localizations.dart';
import '../blocs/mushaf/mushaf_bloc.dart';
import '../cubits/surah_detail_cubit.dart';
import 'snackbar.dart';

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
  static const String _playStoreUrl =
      'https://play.google.com/store/apps/details?id=com.saliouseck.wolofquran&hl=fr';

  final GlobalKey _captureKey = GlobalKey();
  final GlobalKey _shareImageButtonKey = GlobalKey();
  final GlobalKey _shareVideoButtonKey = GlobalKey();

  bool _isSharing = false;

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
    final mushafThemeColor =
        mushafBloc?.state.theme.qcfTheme.pageBackgroundColor;
    final mushafPalette = MushafThemeData.allThemes
        .map((theme) => theme.qcfTheme.pageBackgroundColor)
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
                  RepaintBoundary(key: _captureKey, child: _buildPreviewCard()),
                  const SizedBox(height: 32),
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
                          onPressed: _shareVideo,
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
                translationSource: widget.translationSource,
                surahNumber: widget.surahNumber,
                verseNumber: widget.verseNumber,
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
      shareText: _buildShareText(localizations),
      fallbackMessage: localizations.shareActionCancelled,
    );
  }

  Future<void> _shareVideo() async {
    final localizations = AppLocalizations.of(context)!;
    _showMessage(localizations.shareVideoUnavailableInScreenshotMode);
  }

  String _buildShareText(AppLocalizations localizations) {
    final baseText = localizations.shareDefaultText(
      widget.surahName,
      widget.verseNumber,
    );
    return '$baseText\n\n$_playStoreUrl';
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
            Text(
              statusText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.25,
              ),
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                minHeight: 7,
                backgroundColor: colorScheme.surfaceContainerHighest,
                color: colorScheme.primary,
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
      '${tempDir.path}/daily_inspiration_${widget.surahNumber}_${widget.verseNumber}_${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(uint8List);
    return file;
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
