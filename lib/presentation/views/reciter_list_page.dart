import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wolof_quran/core/config/theme/app_color.dart';
import '../../domain/entities/reciter.dart';
import '../../l10n/generated/app_localizations.dart';

import '../cubits/reciter_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../widgets/reciter_list/reciter_list_empty_state.dart';
import '../widgets/reciter_list/reciter_list_error_state.dart';
import '../widgets/reciter_list/reciter_list_view.dart';
import '../widgets/snackbar.dart';

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

  void _openReciterChapters(Reciter reciter) {
    Navigator.pushNamed(
      context,
      '/reciter-chapters',
      arguments: reciter,
    );
  }

  void _selectReciter(Reciter reciter) {
    final localizations = AppLocalizations.of(context)!;
    context.read<QuranSettingsCubit>().updateReciter(reciter);
    CustomSnackbar.showSnackbar(
      context,
      localizations.selectedAsDefaultReciter(reciter.name),
      duration: 2,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: colorScheme.brightness == Brightness.dark
          ? colorScheme.surfaceContainerLowest
          : colorScheme.surface,
      appBar: AppBar(
        title: Text(
          localizations.availableReciters,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: colorScheme.onPrimary,
            fontSize: 18,
          ),
        ),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? AppColor.surfaceDark
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        elevation: 0,
        scrolledUnderElevation: 0,
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
            return ReciterListErrorState(
              message: reciterState.message,
              onRetry: () => context.read<ReciterCubit>().loadReciters(),
            );
          }

          if (reciterState is ReciterLoaded) {
            if (reciterState.reciters.isEmpty) {
              return const ReciterListEmptyState();
            }

            return BlocBuilder<QuranSettingsCubit, QuranSettingsState>(
              builder: (context, settingsState) {
                return ReciterListView(
                  reciters: reciterState.reciters,
                  selectedReciter: settingsState.selectedReciter,
                  onSelectReciter: _selectReciter,
                  onOpenChapters: _openReciterChapters,
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
