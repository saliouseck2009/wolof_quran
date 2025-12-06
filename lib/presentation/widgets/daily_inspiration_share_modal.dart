import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../../l10n/generated/app_localizations.dart';

enum AyahDisplayMode {
  both,
  arabicOnly,
  translationOnly,
}

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
      height: MediaQuery.of(context).size.height * 0.9,
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Share Daily Inspiration',
                  style: textTheme.titleMedium?.copyWith(
                    fontFamily: 'Hafs',
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
              padding: const EdgeInsets.all(24),
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
                  ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: Icon(Icons.share, color: colorScheme.onPrimary),
                    label: Text(
                      'Share Image',
                      style: textTheme.titleSmall?.copyWith(
                        fontFamily: 'Hafs',
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
        fontFamily: 'Hafs',
        fontWeight: FontWeight.w600,
        color: theme.colorScheme.onSurface,
      ),
    );
  }

  Widget _buildPreviewCard() {
    final onBackground = _selectedForeground;
    final onBackgroundMuted = _selectedForegroundMuted;

    return Container(
      padding: const EdgeInsets.all(32),
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
        children: [
          Container(
            margin: const EdgeInsets.only(bottom: 24),
            child: Column(
              children: [
                Icon(
                  Icons.auto_stories_outlined,
                  color: onBackground,
                  size: 36,
                ),
                const SizedBox(height: 8),
                Text(
                  'Daily Inspiration',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: onBackground,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.arabicOnly)
            Text(
              widget.arabicText,
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: onBackground,
                height: 1.8,
              ),
            ),
          if (_selectedDisplayMode == AyahDisplayMode.both)
            Container(
              width: 60,
              height: 2,
              margin: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                color: onBackgroundMuted,
                borderRadius: BorderRadius.circular(1),
              ),
            ),
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.translationOnly)
            Text(
              widget.translation,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: onBackground,
                height: 1.5,
              ),
            ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: onBackgroundMuted.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.surahName,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: onBackground,
                letterSpacing: 0.3,
              ),
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: onBackgroundMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.surahNumber}:${widget.verseNumber}',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onBackground,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: onBackgroundMuted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'Wolof-Quran',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: onBackground,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
        ],
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
                      fontFamily: 'Hafs',
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
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Center(
          child: CircularProgressIndicator(color: colorScheme.primary),
        ),
      );

      // Capture the widget as an image
      final RenderRepaintBoundary boundary =
          _captureKey.currentContext!.findRenderObject()!
              as RenderRepaintBoundary;
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final ByteData? byteData = await image.toByteData(
        format: ui.ImageByteFormat.png,
      );
      final Uint8List uint8List = byteData!.buffer.asUint8List();

      // Save to temporary file
      final tempDir = await getTemporaryDirectory();
      final file = File(
        '${tempDir.path}/daily_inspiration_${widget.surahNumber}_${widget.verseNumber}.png',
      );
      await file.writeAsBytes(uint8List);

      // Hide loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text:
            'Daily Inspiration - ${widget.surahName} - Verse ${widget.verseNumber}',
      );

      // Close modal
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.pop(context);

      // Show error
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error sharing image: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onError,
            ),
          ),
          backgroundColor: colorScheme.error,
        ),
      );
    }
  }
}
