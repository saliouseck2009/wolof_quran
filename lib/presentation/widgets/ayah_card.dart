import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


import '../../l10n/generated/app_localizations.dart';
import '../cubits/quran_settings_cubit.dart';
import '../cubits/surah_detail_cubit.dart';

/// A card to show one Ayah (verse) of the Quran:
///  • Top row: a little pill with the verse number + action icons (play, bookmark…)
///  • Middle: big centered Arabic text
///  • Bottom: translation label + translation text
class AyahCard extends StatelessWidget {
  /// The verse/ayah number
  final int verseNumber;

  /// The Arabic text of the verse
  final String arabicText;

  /// The translation source, e.g. "Sahih International"
  final String translationSource;

  /// The translated text
  final String translation;

  /// A list of widgets to show in the top row (e.g. play button, bookmark, etc.)
  final List<Widget> actions;

  /// The display mode for showing Arabic, translation, or both
  final AyahDisplayMode displayMode;

  /// The font size for Arabic text
  final double? fontSize;

  /// Additional context for sharing
  final String? surahName;
  final int? surahNumber;

  const AyahCard({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translationSource,
    required this.translation,
    this.actions = const [],
    this.displayMode = AyahDisplayMode.both,
    this.fontSize,
    this.surahName,
    this.surahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(
            alpha: isDark ? 0.25 : 0.3,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: colorScheme.shadow.withValues(alpha: isDark ? 0.45 : 0.12),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verseNumber.toString(),
                    style: textTheme.labelLarge?.copyWith(
                      fontFamily: 'Hafs',
                      color: colorScheme.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Spacer(),
                ...actions,
                IconButton(
                  icon: Icon(Icons.share, color: colorScheme.primary, size: 20),
                  onPressed: () => _showShareModal(context),
                  tooltip:
                      AppLocalizations.of(context)?.shareAyah ?? 'Share Ayah',
                ),
              ],
            ),
            const SizedBox(height: 24),
            if (displayMode == AyahDisplayMode.both ||
                displayMode == AyahDisplayMode.arabicOnly)
              BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
                builder: (context, settingsState) {
                  double arabicFontSize = 28.0;
                  if (fontSize != null) {
                    arabicFontSize = fontSize!;
                  } else if (settingsState is QuranSettingsLoaded) {
                    arabicFontSize = settingsState.ayahFontSize;
                  }
                  if (displayMode == AyahDisplayMode.arabicOnly) {
                    arabicFontSize += 4;
                  }
                  return Text(
                    arabicText,
                    textAlign: TextAlign.justify,
                    textDirection: TextDirection.rtl,
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      fontSize: arabicFontSize,
                      height: 1.8,
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onSurface,
                    ),
                  );
                },
              ),
            if (displayMode == AyahDisplayMode.both) const SizedBox(height: 24),
            if (displayMode == AyahDisplayMode.both)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.3),
                ),
              ),
            if (displayMode == AyahDisplayMode.translationOnly ||
                displayMode == AyahDisplayMode.both)
              const SizedBox(height: 24),
            if ((displayMode == AyahDisplayMode.both ||
                    displayMode == AyahDisplayMode.translationOnly) &&
                translation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      translationSource,
                      textAlign: TextAlign.justify,
                      style: textTheme.labelLarge?.copyWith(
                        fontFamily: 'Hafs',
                        letterSpacing: 0.5,
                        color: colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      translation,
                      textAlign: TextAlign.justify,
                      style: textTheme.bodyMedium?.copyWith(
                        fontSize: displayMode == AyahDisplayMode.translationOnly
                            ? 18
                            : 16,
                        height: 1.5,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showShareModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AyahShareModal(
        verseNumber: verseNumber,
        arabicText: arabicText,
        translation: translation,
        translationSource: translationSource,
        surahName: surahName ?? '',
        surahNumber: surahNumber ?? 0,
      ),
    );
  }
}

class AyahShareModal extends StatefulWidget {
  final int verseNumber;
  final String arabicText;
  final String translation;
  final String translationSource;
  final String surahName;
  final int surahNumber;

  const AyahShareModal({
    super.key,
    required this.verseNumber,
    required this.arabicText,
    required this.translation,
    required this.translationSource,
    required this.surahName,
    required this.surahNumber,
  });

  @override
  State<AyahShareModal> createState() => _AyahShareModalState();
}

class _AyahShareModalState extends State<AyahShareModal> {
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
                  localizations.customizeAndShare,
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
                  _buildSectionTitle(localizations.backgroundStyle),
                  const SizedBox(height: 16),
                  _buildBackgroundColorSelector(),
                  const SizedBox(height: 32),
                  _buildSectionTitle(localizations.displayStyle),
                  const SizedBox(height: 16),
                  _buildDisplayModeSelector(localizations),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: Icon(Icons.share, color: colorScheme.onPrimary),
                    label: Text(
                      localizations.shareImage,
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
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Arabic text
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.arabicOnly)
            Text(
              widget.arabicText,
              textAlign: TextAlign.justify,
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: onBackground,
                height: 1.8,
              ),
            ),

          // Separator
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

          // Translation text
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.translationOnly)
            Text(
              widget.translation,
              textAlign: TextAlign.justify,
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: onBackground,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 20),

          // Centered Surah name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: onBackgroundMuted.withValues(alpha: 0.3),
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

          // Bottom row with surah info and copyright
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left side: Surah and Ayah numbers
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

              // Right side: Copyright
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
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.shadow.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
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
        '${tempDir.path}/ayah_${widget.surahNumber}_${widget.verseNumber}.png',
      );
      await file.writeAsBytes(uint8List);

      // Hide loading dialog
      if (!mounted) return;
      Navigator.pop(context);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${widget.surahName} - Verse ${widget.verseNumber}');

      // Close modal
      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.pop(context);

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
