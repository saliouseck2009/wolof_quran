import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/reciter.dart';
import '../blocs/reciter_chapters_bloc.dart';
import '../../service_locator.dart';
import '../../domain/usecases/get_downloaded_surahs_usecase.dart';
import '../widgets/reciter_chapters/reciter_chapters_app_bar.dart';
import '../widgets/reciter_chapters/reciter_chapters_content.dart';

class ReciterChaptersDownloadPage extends StatelessWidget {
  final Reciter reciter;

  const ReciterChaptersDownloadPage({super.key, required this.reciter});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = Theme.of(context).colorScheme.primary;
    return BlocProvider(
      create: (context) => ReciterChaptersBloc(
        getDownloadedSurahsUseCase: locator<GetDownloadedSurahsUseCase>(),
      )..add(LoadReciterChapters(reciter)),
      child: Scaffold(
        backgroundColor: isDark
            ? Theme.of(context).colorScheme.surface
            : Theme.of(context).colorScheme.surface,
        body: CustomScrollView(
          slivers: [
            ReciterChaptersAppBar(
              reciter: reciter,
              accentColor: accentGreen,
            ),
            SliverToBoxAdapter(
              child: ReciterChaptersContent(
                reciter: reciter,
                accentGreen: accentGreen,
                darkSurfaceHigh: Theme.of(context).colorScheme.surfaceContainer,
                darkSurface: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
