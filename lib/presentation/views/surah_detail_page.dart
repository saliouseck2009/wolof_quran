import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/domain/repositories/bookmark_repository.dart';

import '../../l10n/generated/app_localizations.dart';
import '../../core/config/theme/app_color.dart';
import '../cubits/bookmark_cubit.dart';
import '../cubits/surah_detail_cubit.dart';
import '../widgets/surah_detail/surah_detail_content.dart';
import '../../service_locator.dart';

class SurahDetailPage extends StatelessWidget {
  static const String routeName = "/surah-detail";
  final int surahNumber;
  final int? initialAyahNumber;

  const SurahDetailPage({
    super.key,
    required this.surahNumber,
    this.initialAyahNumber,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => SurahDetailCubit()..loadSurah(surahNumber),
        ),
        BlocProvider(
          create: (context) =>
              BookmarkCubit(locator<BookmarkRepository>())..loadBookmarks(),
        ),
      ],
      child: SurahDetailView(
        surahNumber: surahNumber,
        initialAyahNumber: initialAyahNumber,
      ),
    );
  }
}

class SurahDetailView extends StatelessWidget {
  final int surahNumber;
  final int? initialAyahNumber;

  const SurahDetailView({
    super.key,
    required this.surahNumber,
    this.initialAyahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? AppColor.surfaceDark
          : colorScheme.surface,
      body: BlocBuilder<SurahDetailCubit, SurahDetailState>(
        builder: (context, state) {
          if (state is SurahDetailLoading) {
            return const SurahDetailLoadingWidget();
          }

          if (state is SurahDetailError) {
            return SurahDetailErrorWidget(
              message: state.message,
              onRetry: () =>
                  context.read<SurahDetailCubit>().loadSurah(surahNumber),
            );
          }

          if (state is! SurahDetailLoaded) {
            return const SizedBox.shrink();
          }

          return SurahDetailContent(
            state: state,
            surahNumber: surahNumber,
            initialAyahNumber: initialAyahNumber,
          );
        },
      ),
    );
  }
}

class SurahDetailLoadingWidget extends StatelessWidget {
  const SurahDetailLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class SurahDetailErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const SurahDetailErrorWidget({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Theme.of(context).colorScheme.error,
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: Text(localizations.tryAgain),
          ),
        ],
      ),
    );
  }
}
