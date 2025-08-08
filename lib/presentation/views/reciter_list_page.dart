import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
              style: TextStyle(
                fontFamily: 'Hafs',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColor.pureWhite : AppColor.charcoal,
              ),
            ),
            Text(
              'Tap card to browse • Tap select button to choose default',
              style: TextStyle(
                fontFamily: 'Hafs',
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
                    style: TextStyle(
                      fontFamily: 'Hafs',
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reciterState.message,
                    style: TextStyle(
                      fontFamily: 'Hafs',
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
                      style: TextStyle(
                        fontFamily: 'Hafs',
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
                      style: TextStyle(
                        fontFamily: 'Hafs',
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColor.pureWhite : AppColor.charcoal,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for available reciters', // TODO: Add to localizations
                      style: TextStyle(
                        fontFamily: 'Hafs',
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
                        boxShadow: [
                          BoxShadow(
                            color: AppColor.primaryGreen.withValues(
                              alpha: 0.08,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                        border: Border.all(
                          color: AppColor.primaryGreen.withValues(alpha: 0.1),
                          width: 1,
                        ),
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
                                // Reciter icon container (consistent with settings page)
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColor.primaryGreen.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: AppColor.primaryGreen,
                                    size: 24,
                                  ),
                                ),

                                const SizedBox(width: 16),

                                // Reciter info (consistent content structure)
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // English name (title)
                                      Text(
                                        reciter.name,
                                        style: TextStyle(
                                          fontFamily: 'Hafs',
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: isDark
                                              ? AppColor.pureWhite
                                              : AppColor.charcoal,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Arabic name (subtitle)
                                      Text(
                                        reciter.arabicName,
                                        style: TextStyle(
                                          fontFamily: 'Hafs',
                                          fontSize: 12,
                                          color: AppColor.mediumGray,
                                        ),
                                      ),

                                      const SizedBox(height: 8),

                                      // Status badge
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isSelected
                                              ? AppColor.primaryGreen
                                                    .withValues(alpha: 0.1)
                                              : AppColor.mediumGray.withValues(
                                                  alpha: 0.1,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? AppColor.primaryGreen
                                                      .withValues(alpha: 0.2)
                                                : AppColor.mediumGray
                                                      .withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isSelected
                                              ? 'Default Reciter'
                                              : 'Available',
                                          style: TextStyle(
                                            fontFamily: 'Hafs',
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? AppColor.primaryGreen
                                                : AppColor.mediumGray,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(width: 12),

                                // Selection action (consistent with settings page)
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
                                          style: TextStyle(fontFamily: 'Hafs'),
                                        ),
                                        backgroundColor: AppColor.primaryGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppColor.primaryGreen.withValues(
                                              alpha: 0.1,
                                            )
                                          : AppColor.mediumGray.withValues(
                                              alpha: 0.1,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? AppColor.primaryGreen
                                          : AppColor.mediumGray,
                                      size: 20,
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
