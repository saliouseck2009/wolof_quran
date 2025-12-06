import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
    final colorScheme = Theme.of(context).colorScheme;
    final accentGreen = colorScheme.primary;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Available Reciters', // TODO: Add to localizations
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? colorScheme.surfaceContainer.withValues(alpha: 0.7)
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 2,
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
                  Icon(Icons.error_outline, size: 64, color: colorScheme.error),
                  const SizedBox(height: 16),
                  Text(
                    'Error Loading Reciters', // TODO: Add to localizations
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    reciterState.message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      context.read<ReciterCubit>().loadReciters();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      foregroundColor: colorScheme.onPrimary,
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
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
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
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No Reciters Available', // TODO: Add to localizations
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Check back later for available reciters', // TODO: Add to localizations
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
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

                return CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            gradient: colorScheme.brightness == Brightness.dark
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.surfaceContainer.withValues(alpha: 0.8),
                                      colorScheme.surfaceContainer.withValues(alpha: 0.9),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      colorScheme.primary.withValues(alpha: 0.1),
                                      colorScheme.primaryContainer.withValues(alpha: 0.2),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: colorScheme.primary.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.record_voice_over,
                                size: 48,
                                color: colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Select Reciter',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap card to browse • Tap select button to choose default',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final reciter = reciterState.reciters[index];
                          final isSelected = selectedReciter?.id == reciter.id;

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            child: Container(
                              decoration: BoxDecoration(
                                color: colorScheme.surfaceContainer,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: colorScheme.brightness == Brightness.dark
                                    ? [
                                        BoxShadow(
                                          color: colorScheme.primary.withValues(alpha: 0.08),
                                          blurRadius: 12,
                                          offset: const Offset(0, 2),
                                        ),
                                      ]
                                    : null,
                                border: Border.all(
                                  color: colorScheme.primary.withValues(
                                    alpha: colorScheme.brightness == Brightness.dark ? 0.1 : 0.15,
                                  ),
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
                                    color: accentGreen.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    Icons.person,
                                    color: accentGreen,
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
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w600,
                                          color: colorScheme.onSurface,
                                        ),
                                      ),

                                      const SizedBox(height: 4),

                                      // Arabic name (subtitle)
                                      Text(
                                        reciter.arabicName,
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: colorScheme.onSurfaceVariant,
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
                                              ? accentGreen.withValues(
                                                  alpha: 0.15,
                                                )
                                              : colorScheme.onSurfaceVariant.withValues(
                                                  alpha: 0.12,
                                                ),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: isSelected
                                                ? accentGreen.withValues(
                                                    alpha: 0.25,
                                                  )
                                                : colorScheme.onSurfaceVariant
                                                      .withValues(alpha: 0.2),
                                            width: 1,
                                          ),
                                        ),
                                        child: Text(
                                          isSelected
                                              ? 'Default Reciter'
                                              : 'Available',
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontWeight: FontWeight.w500,
                                            color: isSelected
                                                ? accentGreen
                                                : colorScheme.onSurfaceVariant,
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
                                        ),
                                        backgroundColor: accentGreen,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? accentGreen.withValues(alpha: 0.15)
                                          : colorScheme.onSurfaceVariant.withValues(
                                              alpha: 0.12,
                                            ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      isSelected
                                          ? Icons.check_circle
                                          : Icons.radio_button_unchecked,
                                      color: isSelected
                                          ? accentGreen
                                          : colorScheme.onSurfaceVariant,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
                        childCount: reciterState.reciters.length,
                      ),
                    ),
                  ],
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

// Helper constant to avoid const removal of dynamic reciter.arabicName in compressed edit
const String reciterArabicPlaceholder = '';
