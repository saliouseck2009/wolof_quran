import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/theme/app_color.dart';
import '../cubits/reciter_cubit.dart';
import '../cubits/quran_settings_cubit.dart';

class ReciterListPage extends StatefulWidget {
  const ReciterListPage({super.key});

  @override
  State<ReciterListPage> createState() => _ReciterListPageState();
}

class _ReciterListPageState extends State<ReciterListPage> {
  @override
  void initState() {
    super.initState();
    // Load reciters when page initializes
    context.read<ReciterCubit>().loadReciters();
    // Load current settings
    context.read<QuranSettingsCubit>().loadSettings();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColor.charcoal : AppColor.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppColor.pureWhite : AppColor.charcoal,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          children: [
            Text(
              'Available Reciters', // TODO: Add to localizations
              style: GoogleFonts.amiri(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.pureWhite : AppColor.charcoal,
              ),
            ),
            Text(
              'Tap card to browse • Tap select button to choose default',
              style: GoogleFonts.amiri(
                fontSize: 12,
                color: AppColor.mediumGray,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ReciterCubit, ReciterState>(
        listener: (context, reciterState) {
          // When reciters are loaded, update the settings cubit
          if (reciterState is ReciterLoaded) {
            context.read<QuranSettingsCubit>().loadReciterFromPrefs(
              reciterState.reciters,
            );
          }
        },
        builder: (context, reciterState) {
          if (reciterState is ReciterLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (reciterState is ReciterError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Reciters', // TODO: Add to localizations
                    style: GoogleFonts.amiri(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reciterState.message,
                    style: GoogleFonts.amiri(
                      fontSize: 14,
                      color: AppColor.mediumGray,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReciterCubit>().loadReciters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.primaryGreen,
                      foregroundColor: AppColor.pureWhite,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Retry', // TODO: Add to localizations
                      style: GoogleFonts.amiri(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (reciterState is ReciterLoaded) {
            if (reciterState.reciters.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_music_outlined,
                      size: 64,
                      color: AppColor.mediumGray,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Reciters Available', // TODO: Add to localizations
                      style: GoogleFonts.amiri(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for available reciters', // TODO: Add to localizations
                      style: GoogleFonts.amiri(
                        fontSize: 14,
                        color: AppColor.mediumGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }

            return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
              builder: (context, settingsState) {
                final selectedReciter = settingsState is QuranSettingsLoaded
                    ? settingsState.selectedReciter
                    : null;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: reciterState.reciters.length,
                  itemBuilder: (context, index) {
                    final reciter = reciterState.reciters[index];
                    final isSelected = selectedReciter?.id == reciter.id;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColor.charcoal : AppColor.pureWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected
                            ? Border.all(color: AppColor.primaryGreen, width: 2)
                            : null,
                        boxShadow: [
                          BoxShadow(
                            color: isSelected
                                ? AppColor.primaryGreen.withValues(alpha: 0.2)
                                : AppColor.primaryGreen.withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () {
                            // Navigate to reciter chapters (restored original behavior)
                            Navigator.pushNamed(
                              context,
                              '/reciter-chapters',
                              arguments: reciter,
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Row(
                              children: [
                                // Reciter icon
                                Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? AppColor.primaryGreen
                                        : AppColor.primaryGreen.withValues(
                                            alpha: 0.1,
                                          ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: isSelected
                                        ? AppColor.pureWhite
                                        : AppColor.primaryGreen,
                                    size: 28,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Reciter info
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reciter.name,
                                        style: GoogleFonts.amiri(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColor.pureWhite
                                              : AppColor.charcoal,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        reciter.arabicName,
                                        style: GoogleFonts.amiri(
                                          fontSize: 16,
                                          color: AppColor.mediumGray,
                                          height: 1.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Selection indicator or navigation icon
                                GestureDetector(
                                  onTap: () {
                                    // Select this reciter when tapping the selection area
                                    context
                                        .read<QuranSettingsCubit>()
                                        .updateReciter(reciter);

                                    // Show feedback
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          'Selected ${reciter.name} as default reciter',
                                          style: GoogleFonts.amiri(),
                                        ),
                                        backgroundColor: AppColor.primaryGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: isSelected
                                        ? Container(
                                            padding: const EdgeInsets.all(6),
                                            decoration: BoxDecoration(
                                              color: AppColor.primaryGreen,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                            ),
                                            child: Icon(
                                              Icons.check,
                                              color: AppColor.pureWhite,
                                              size: 16,
                                            ),
                                          )
                                        : Column(
                                            children: [
                                              Icon(
                                                Icons.radio_button_unchecked,
                                                color: AppColor.primaryGreen,
                                                size: 20,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                'Select',
                                                style: GoogleFonts.amiri(
                                                  fontSize: 10,
                                                  color: AppColor.mediumGray,
                                                ),
                                                textAlign: TextAlign.center,
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}
