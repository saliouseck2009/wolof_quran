import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../domain/entities/reciter.dart';
import '../../l10n/generated/app_localizations.dart';
import '../cubits/audio_availability_cubit.dart';
import '../cubits/audio_management_cubit.dart';
import '../cubits/quran_settings_cubit.dart';
import '../widgets/snackbar.dart';

class ReciterAudioUpdatesPage extends StatefulWidget {
  static const String routeName = '/reciter-audio-updates';

  final Reciter reciter;
  final List<int> initialNewSurahs;

  const ReciterAudioUpdatesPage({
    super.key,
    required this.reciter,
    required this.initialNewSurahs,
  });

  @override
  State<ReciterAudioUpdatesPage> createState() =>
      _ReciterAudioUpdatesPageState();
}

class _ReciterAudioUpdatesPageState extends State<ReciterAudioUpdatesPage> {
  late final List<int> _displaySurahs;

  @override
  void initState() {
    super.initState();
    final currentSnapshot = context
        .read<AudioAvailabilityCubit>()
        .state
        .snapshotForReciter(widget.reciter.id);
    final source = widget.initialNewSurahs.isNotEmpty
        ? widget.initialNewSurahs
        : (currentSnapshot?.unreadNewSurahs ?? const []);
    _displaySurahs = source.toSet().toList()..sort();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AudioAvailabilityCubit>().markAsSeen(widget.reciter.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.newAudioUpdatesTitle),
        backgroundColor: colorScheme.brightness == Brightness.dark
            ? colorScheme.surface
            : colorScheme.primary,
        iconTheme: IconThemeData(color: colorScheme.onPrimary),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: colorScheme.onPrimary,
        ),
      ),
      body: _displaySurahs.isEmpty
          ? Center(
              child: Text(
                localizations.noNewAudioUpdates,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurface),
              ),
            )
          : Column(
              children: [
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainer,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    localizations.newAudioUpdatesCount(_displaySurahs.length),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    itemCount: _displaySurahs.length,
                    itemBuilder: (context, index) {
                      final surahNumber = _displaySurahs[index];
                      return _NewAudioSurahTile(
                        reciterId: widget.reciter.id,
                        surahNumber: surahNumber,
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _NewAudioSurahTile extends StatelessWidget {
  final String reciterId;
  final int surahNumber;

  const _NewAudioSurahTile({
    required this.reciterId,
    required this.surahNumber,
  });

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final colorScheme = Theme.of(context).colorScheme;
    final translation = context.read<QuranSettingsCubit>().currentTranslation;

    final arabicName = quran.getSurahNameArabic(surahNumber);
    final translatedName = QuranSettingsCubit.getSurahNameInTranslation(
      surahNumber,
      translation,
    );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: colorScheme.primary.withValues(alpha: 0.14),
              child: Text(
                '$surahNumber',
                style: TextStyle(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$arabicName - $translatedName',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    localizations.audioNowAvailable,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            BlocBuilder<AudioManagementCubit, AudioManagementState>(
              builder: (context, audioState) {
                final isDownloading =
                    audioState is AudioDownloading &&
                    audioState.reciterId == reciterId &&
                    audioState.surahNumber == surahNumber;
                final isOtherDownloading =
                    audioState is AudioDownloading && !isDownloading;

                if (isDownloading) {
                  return SizedBox(
                    width: 72,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            value: audioState.progress,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${(audioState.progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  );
                }

                return ElevatedButton.icon(
                  onPressed: () {
                    if (isOtherDownloading) {
                      CustomSnackbar.showSnackbar(
                        context,
                        localizations.downloadInProgress,
                        duration: 2,
                      );
                      return;
                    }
                    context.read<AudioManagementCubit>().downloadSurahAudio(
                      reciterId,
                      surahNumber,
                    );
                  },
                  icon: const Icon(Icons.download_outlined, size: 18),
                  label: Text(localizations.downloadLabel),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
