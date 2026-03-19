import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/services/audio_player_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/surah_mini_player_cubit.dart';

class SurahMiniPlayerOverlay extends StatelessWidget {
  const SurahMiniPlayerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SurahMiniPlayerCubit, SurahMiniPlayerState>(
      buildWhen: (previous, current) =>
          previous.uiState != current.uiState ||
          previous.surahNumber != current.surahNumber ||
          previous.surahName != current.surahName ||
          previous.playerState != current.playerState ||
          previous.position != current.position ||
          previous.duration != current.duration ||
          previous.isSeekReady != current.isSeekReady ||
          previous.repeatSurah != current.repeatSurah ||
          previous.downloadedQueue != current.downloadedQueue,
      builder: (context, state) {
        if (state.uiState == SurahMiniPlayerUiState.hidden ||
            !state.hasActiveSurah) {
          return const SizedBox.shrink();
        }

        final mediaQuery = MediaQuery.of(context);
        final isExpanded = state.uiState == SurahMiniPlayerUiState.expanded;
        final expandedHeight = (mediaQuery.size.height * 0.30).clamp(
          260.0,
          360.0,
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                height: isExpanded ? expandedHeight : 76,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.14),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: isExpanded
                    ? _ExpandedMiniPlayer(state: state)
                    : _CollapsedMiniPlayer(state: state),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _CollapsedMiniPlayer extends StatelessWidget {
  final SurahMiniPlayerState state;

  const _CollapsedMiniPlayer({required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => context.read<SurahMiniPlayerCubit>().expand(),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${state.surahNumber} - ${state.surahName ?? ''}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: state.isSeekReady
                          ? _progressValue(state.position, state.duration)
                          : null,
                      minHeight: 3,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () =>
                context.read<SurahMiniPlayerCubit>().togglePlayPause(),
            tooltip: _tooltipIfOverlay(
              context,
              isPlaying ? localizations.pauseSurah : localizations.playSurah,
            ),
            icon: Icon(isPlaying ? Icons.pause_circle : Icons.play_circle),
          ),
          IconButton(
            onPressed: () => context.read<SurahMiniPlayerCubit>().closePlayer(),
            tooltip: _tooltipIfOverlay(context, localizations.close),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
    );
  }
}

class _ExpandedMiniPlayer extends StatelessWidget {
  final SurahMiniPlayerState state;

  const _ExpandedMiniPlayer({required this.state});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;
    final total = state.duration ?? Duration.zero;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${state.surahNumber} - ${state.surahName ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            context.read<SurahMiniPlayerCubit>().collapse(),
                        icon: const Icon(Icons.expand_more),
                      ),
                      IconButton(
                        onPressed: () =>
                            context.read<SurahMiniPlayerCubit>().closePlayer(),
                        tooltip: _tooltipIfOverlay(
                          context,
                          localizations.close,
                        ),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: state.position.inMilliseconds
                        .clamp(
                          0,
                          total.inMilliseconds > 0 ? total.inMilliseconds : 0,
                        )
                        .toDouble(),
                    max: total.inMilliseconds <= 0
                        ? 1
                        : total.inMilliseconds.toDouble(),
                    onChanged: !state.isSeekReady || total.inMilliseconds <= 0
                        ? null
                        : (value) {
                            context.read<SurahMiniPlayerCubit>().seek(
                              Duration(milliseconds: value.round()),
                            );
                          },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(_formatDuration(state.position)),
                        Text(
                          state.isSeekReady ? _formatDuration(total) : '--:--',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: state.canGoPrevious
                            ? () => context
                                  .read<SurahMiniPlayerCubit>()
                                  .playPreviousSurah()
                            : null,
                        icon: const Icon(Icons.skip_previous),
                      ),
                      IconButton(
                        onPressed: state.isSeekReady
                            ? () => context
                                  .read<SurahMiniPlayerCubit>()
                                  .seekBySeconds(-10)
                            : null,
                        icon: const Icon(Icons.replay_10),
                      ),
                      IconButton(
                        onPressed: () => context
                            .read<SurahMiniPlayerCubit>()
                            .togglePlayPause(),
                        iconSize: 36,
                        icon: Icon(
                          isPlaying
                              ? Icons.pause_circle_filled
                              : Icons.play_circle_filled,
                        ),
                      ),
                      IconButton(
                        onPressed: state.isSeekReady
                            ? () => context
                                  .read<SurahMiniPlayerCubit>()
                                  .seekBySeconds(10)
                            : null,
                        icon: const Icon(Icons.forward_10),
                      ),
                      IconButton(
                        onPressed: state.canGoNext
                            ? () => context
                                  .read<SurahMiniPlayerCubit>()
                                  .playNextSurah()
                            : null,
                        icon: const Icon(Icons.skip_next),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Align(
                    alignment: Alignment.center,
                    child: IconButton(
                      onPressed: () =>
                          context.read<SurahMiniPlayerCubit>().toggleRepeat(),
                      icon: Icon(
                        Icons.repeat,
                        color: state.repeatSurah
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

double _progressValue(Duration position, Duration? duration) {
  if (duration == null || duration.inMilliseconds <= 0) {
    return 0;
  }
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
}

String? _tooltipIfOverlay(BuildContext context, String message) {
  return Overlay.maybeOf(context) == null ? null : message;
}
