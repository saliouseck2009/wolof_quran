import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as quran;
import 'package:google_fonts/google_fonts.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';

class SurahDetailPage extends StatelessWidget {
  static const String routeName = "/surah-detail";
  final int surahNumber;

  const SurahDetailPage({super.key, required this.surahNumber});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final surahNameArabic = quran.getSurahName(surahNumber);
    final surahNameEnglish = quran.getSurahNameEnglish(surahNumber);
    final versesCount = quran.getVerseCount(surahNumber);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 200,
            floating: false,
            pinned: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                surahNameEnglish,
                style: GoogleFonts.amiri(
                  fontWeight: FontWeight.w600,
                  color: AppColor.pureWhite,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: isDark
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColor.charcoal, AppColor.darkGray],
                        )
                      : AppColor.primaryGradient,
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 40),
                        Text(
                          surahNameArabic,
                          style: GoogleFonts.amiriQuran(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppColor.pureWhite,
                          ),
                          textAlign: TextAlign.center,
                          textDirection: TextDirection.rtl,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${localizations.surah} $surahNumber • $versesCount ${localizations.verses}',
                          style: TextStyle(
                            color: AppColor.pureWhite.withOpacity(0.9),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            backgroundColor: Colors.transparent,
            foregroundColor: AppColor.pureWhite,
          ),

          // Content placeholder
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColor.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColor.primaryGreen.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          Icons.construction,
                          size: 48,
                          color: AppColor.primaryGreen,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Surah Content Coming Soon',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: AppColor.primaryGreen,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'The verses of this surah will be displayed here with proper Arabic text, translations, and audio features.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColor.translationText),
                          textAlign: TextAlign.center,
                        ),
                      ],
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
}
