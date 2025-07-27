import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/config/theme/app_color.dart';
import '../cubits/reciter_cubit.dart';

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
        title: Text(
          'Available Reciters', // TODO: Add to localizations
          style: GoogleFonts.amiri(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColor.pureWhite : AppColor.charcoal,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocBuilder<ReciterCubit, ReciterState>(
        builder: (context, state) {
          if (state is ReciterLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is ReciterError) {
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
                    state.message,
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

          if (state is ReciterLoaded) {
            if (state.reciters.isEmpty) {
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

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: state.reciters.length,
              itemBuilder: (context, index) {
                final reciter = state.reciters[index];

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColor.charcoal : AppColor.pureWhite,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColor.primaryGreen.withValues(alpha: 0.08),
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
                                color: AppColor.primaryGreen.withValues(
                                  alpha: 0.1,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                Icons.person,
                                color: AppColor.primaryGreen,
                                size: 28,
                              ),
                            ),

                            const SizedBox(width: 16),

                            // Reciter info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
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

                            // Arrow icon
                            Icon(
                              Icons.arrow_forward_ios,
                              color: AppColor.primaryGreen,
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
