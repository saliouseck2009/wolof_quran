import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/config/theme/app_color.dart';
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
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColor.primaryGreen.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ─── Top Row: verse pill + actions ──────────────────────────
            Row(
              children: [
                // the little "pill" with the verse number
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppColor.primaryGradient,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    verseNumber.toString(),
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      color: AppColor.pureWhite,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),

                const Spacer(),

                // action icons
                ...actions,

                // Share button
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: AppColor.primaryGreen,
                    size: 20,
                  ),
                  onPressed: () => _showShareModal(context),
                  tooltip:
                      AppLocalizations.of(context)?.shareAyah ?? 'Share Ayah',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ─── Arabic Text ─────────────────────────────────────────────
            // Show Arabic text only if mode is both or arabicOnly
            if (displayMode == AyahDisplayMode.both ||
                displayMode == AyahDisplayMode.arabicOnly)
              BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
                builder: (context, settingsState) {
                  // Get font size from settings or use passed parameter or default
                  double arabicFontSize = 28.0; // default
                  if (fontSize != null) {
                    arabicFontSize = fontSize!;
                  } else if (settingsState is QuranSettingsLoaded) {
                    arabicFontSize = settingsState.ayahFontSize;
                  }

                  // Adjust font size based on display mode
                  if (displayMode == AyahDisplayMode.arabicOnly) {
                    arabicFontSize +=
                        4; // Make it slightly larger for Arabic-only mode
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
                      color: Theme.of(context).textTheme.titleLarge?.color,
                    ),
                  );
                },
              ),

            // Add separator between Arabic and translation when both are shown
            if (displayMode == AyahDisplayMode.both) const SizedBox(height: 24),
            if (displayMode == AyahDisplayMode.both)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      AppColor.primaryGreen.withValues(alpha: 0.3),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

            // Add spacing for translation-only mode or after separator
            if (displayMode == AyahDisplayMode.translationOnly ||
                displayMode == AyahDisplayMode.both)
              const SizedBox(height: 24),

            // ─── Translation Section ─────────────────────────────────────
            // Show translation only if mode is both or translationOnly
            if ((displayMode == AyahDisplayMode.both ||
                    displayMode == AyahDisplayMode.translationOnly) &&
                translation.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColor.lightGray.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Translation Label
                    Text(
                      translationSource,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColor.primaryGreen,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Translation Text
                    Text(
                      translation,
                      textAlign: TextAlign.justify,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: displayMode == AyahDisplayMode.translationOnly
                            ? 18
                            : 16,
                        height: 1.5,
                        color: AppColor.translationText,
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
  Color _selectedBackgroundColor = AppColor.primaryGreen;
  AyahDisplayMode _selectedDisplayMode = AyahDisplayMode.both;

  // Available background colors
  final List<Color> _backgroundColors = [
    AppColor.primaryGreen,
    AppColor.charcoal,
    const Color(0xFF2E3440), // Nord dark
    const Color(0xFF3B4252), // Nord darker
    const Color(0xFF5D4037), // Brown
    const Color(0xFF37474F), // Blue Grey
    const Color(0xFF424242), // Grey
    const Color(0xFF1A237E), // Indigo
    const Color(0xFF4A148C), // Purple
    const Color(0xFF0D47A1), // Blue
  ];

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColor.charcoal : AppColor.pureWhite,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: AppColor.mediumGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  localizations.customizeAndShare,
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColor.pureWhite : AppColor.darkGray,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(
                    Icons.close,
                    color: isDark ? AppColor.pureWhite : AppColor.darkGray,
                  ),
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
                  // Preview Card
                  RepaintBoundary(key: _captureKey, child: _buildPreviewCard()),

                  const SizedBox(height: 32),

                  // Background Style Section
                  _buildSectionTitle(localizations.backgroundStyle),
                  const SizedBox(height: 16),
                  _buildBackgroundColorSelector(),

                  const SizedBox(height: 32),

                  // Display Style Section
                  _buildSectionTitle(localizations.displayStyle),
                  const SizedBox(height: 16),
                  _buildDisplayModeSelector(localizations),

                  const SizedBox(height: 32),

                  // Share Button
                  ElevatedButton.icon(
                    onPressed: _shareImage,
                    icon: const Icon(Icons.share, color: AppColor.pureWhite),
                    label: Text(
                      localizations.shareImage,
                      style: const TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColor.pureWhite,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryGreen,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'Hafs',
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDark ? AppColor.pureWhite : AppColor.darkGray,
      ),
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: _selectedBackgroundColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              style: const TextStyle(
                fontFamily: 'Hafs',
                fontSize: 30,
                fontWeight: FontWeight.w500,
                color: AppColor.pureWhite,
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
                color: AppColor.pureWhite.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(1),
              ),
            ),

          // Translation text
          if (_selectedDisplayMode == AyahDisplayMode.both ||
              _selectedDisplayMode == AyahDisplayMode.translationOnly)
            Text(
              widget.translation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'Hafs',
                fontSize: 16,
                fontWeight: FontWeight.w400,
                color: AppColor.pureWhite,
                height: 1.5,
              ),
            ),

          const SizedBox(height: 20),

          // Centered Surah name
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColor.pureWhite.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              widget.surahName,
              style: const TextStyle(
                fontFamily: 'Hafs',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColor.pureWhite,
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
                  color: AppColor.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  '${widget.surahNumber}:${widget.verseNumber}',
                  style: const TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColor.pureWhite,
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
                  color: AppColor.pureWhite.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Wolof-Quran',
                  style: TextStyle(
                    fontFamily: 'Hafs',
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: AppColor.pureWhite,
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
                color: isSelected ? AppColor.pureWhite : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: isSelected
                ? const Icon(Icons.check, color: AppColor.pureWhite, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDisplayModeSelector(AppLocalizations localizations) {
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
        final isDark = Theme.of(context).brightness == Brightness.dark;

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
                  ? AppColor.primaryGreen.withValues(alpha: 0.1)
                  : (isDark
                        ? AppColor.charcoal.withValues(alpha: 0.5)
                        : AppColor.lightGray.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColor.primaryGreen : Colors.transparent,
                width: 2,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppColor.primaryGreen
                      : AppColor.mediumGray,
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
                          ? AppColor.primaryGreen
                          : (isDark ? AppColor.pureWhite : AppColor.darkGray),
                    ),
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.check_circle,
                    color: AppColor.primaryGreen,
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
    try {
      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColor.primaryGreen),
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
      if (mounted) Navigator.pop(context);

      // Share the file
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${widget.surahName} - Verse ${widget.verseNumber}');

      // Close modal
      if (mounted) Navigator.pop(context);
    } catch (e) {
      // Hide loading dialog if still showing
      if (mounted) Navigator.pop(context);

      // Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing image: $e'),
          backgroundColor: AppColor.error,
        ),
      );
    }
  }
}
