import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/presentation/cubits/audio_management_cubit.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';

class HomePage extends StatelessWidget {
  static const String routeName = "/";

  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return MultiBlocListener(
      listeners: [
        // audio management cubit listens to playback events
        BlocListener<AudioManagementCubit, AudioManagementState>(
          listener: (context, audioState) {
            if (audioState is AudioManagementError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(audioState.message),
                  // backgroundColor: Colors.red,
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: Container(
          decoration: BoxDecoration(gradient: AppColor.primaryGradient),
          child: SafeArea(
            child: Column(
              children: [
                // App Bar with Settings
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        localizations.appTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColor.pureWhite,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pushNamed(context, '/settings');
                        },
                        icon: Icon(Icons.settings, color: AppColor.pureWhite),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // App Logo/Icon placeholder
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: AppColor.pureWhite.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(60),
                            border: Border.all(
                              color: AppColor.pureWhite.withValues(alpha: 0.3),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            Icons.menu_book_rounded,
                            size: 60,
                            color: AppColor.pureWhite,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Welcome Text
                        Text(
                          localizations.welcome,
                          style: theme.textTheme.displayMedium?.copyWith(
                            color: AppColor.pureWhite,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 16),

                        // Subtitle
                        Text(
                          localizations.quran,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColor.pureWhite.withValues(alpha: 0.9),
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),

                        const SizedBox(height: 48),

                        // Quick Action Buttons
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Column(
                            children: [
                              _buildActionButton(
                                context,
                                icon: Icons.menu_book,
                                title: localizations.quran,
                                onTap: () {
                                  Navigator.pushNamed(context, '/surahs');
                                },
                              ),

                              const SizedBox(height: 16),

                              _buildActionButton(
                                context,
                                icon: Icons.play_circle_fill,
                                title: localizations.recitation,
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/surah-audio-list',
                                  );
                                },
                              ),

                              const SizedBox(height: 16),

                              _buildActionButton(
                                context,
                                icon: Icons.translate,
                                title: localizations.translation,
                                onTap: () {
                                  // Navigate to translation page
                                },
                              ),

                              const SizedBox(height: 16),

                              _buildActionButton(
                                context,
                                icon: Icons.search,
                                title: localizations.search,
                                onTap: () {
                                  Navigator.pushNamed(context, '/search');
                                },
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
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Material(
      color: AppColor.pureWhite.withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColor.pureWhite.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: AppColor.pureWhite, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColor.pureWhite,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: AppColor.pureWhite.withValues(alpha: 0.7),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
