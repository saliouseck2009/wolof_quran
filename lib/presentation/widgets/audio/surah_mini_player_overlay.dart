import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/services/audio_player_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../cubits/surah_mini_player_cubit.dart';
import 'surah_fullscreen_player.dart';

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
          previous.playbackMode != current.playbackMode ||
          previous.shuffleHistoryDepth != current.shuffleHistoryDepth ||
          previous.downloadedQueue != current.downloadedQueue,
      builder: (context, state) {
        if (state.uiState == SurahMiniPlayerUiState.hidden ||
            state.uiState == SurahMiniPlayerUiState.fullscreen ||
            !state.hasActiveSurah) {
          return const SizedBox.shrink();
        }

        final isExpanded = state.uiState == SurahMiniPlayerUiState.expanded;
        final mediaQuery = MediaQuery.of(context);
        final expandedHeight = (mediaQuery.size.height * 0.32).clamp(
          280.0,
          380.0,
        );

        return Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: GestureDetector(
              onVerticalDragEnd: (details) {
                if (!isExpanded) return;
                // Swipe down → collapse
                if (details.primaryVelocity != null &&
                    details.primaryVelocity! > 250) {
                  context.read<SurahMiniPlayerCubit>().collapse();
                }
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  height: isExpanded ? expandedHeight : 76,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 24,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: isExpanded
                        ? _ExpandedMiniPlayer(state: state)
                        : _CollapsedMiniPlayer(state: state),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// COLLAPSED
// ════════════════════════════════════════════════════════════════════════════

class _CollapsedMiniPlayer extends StatelessWidget {
  final SurahMiniPlayerState state;

  const _CollapsedMiniPlayer({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;
    final isLoading = state.playerState == AudioPlayerState.loading;
    final surahName = _localizedSurahName(
      context,
      state.surahNumber,
      fallbackName: state.surahName,
    );

    return InkWell(
      onTap: () => context.read<SurahMiniPlayerCubit>().expand(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Row(
          children: [
            // ── Artwork badge ──────────────────────────────────────────────
            _MiniArtworkBadge(
              surahNumber: state.surahNumber,
              isPlaying: isPlaying,
            ),
            const SizedBox(width: 12),

            // ── Title + progress ───────────────────────────────────────────
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    surahName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    state.surahNumber != null
                        ? quran.getSurahNameArabic(state.surahNumber!)
                        : '',
                    maxLines: 1,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 6),
                  _ProgressBar(state: state),
                ],
              ),
            ),
            const SizedBox(width: 4),

            // ── Play / Pause ───────────────────────────────────────────────
            isLoading
                ? SizedBox(
                    width: 36,
                    height: 36,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: colorScheme.primary,
                    ),
                  )
                : IconButton(
                    onPressed: () =>
                        context.read<SurahMiniPlayerCubit>().togglePlayPause(),
                    tooltip: _tooltipIfOverlay(
                      context,
                      isPlaying
                          ? localizations.pauseSurah
                          : localizations.playSurah,
                    ),
                    iconSize: 36,
                    icon: Icon(
                      isPlaying
                          ? Icons.pause_circle_filled_rounded
                          : Icons.play_circle_filled_rounded,
                      color: colorScheme.primary,
                    ),
                  ),

            // ── Close ─────────────────────────────────────────────────────
            IconButton(
              onPressed: () =>
                  context.read<SurahMiniPlayerCubit>().closePlayer(),
              tooltip: _tooltipIfOverlay(context, localizations.close),
              iconSize: 20,
              icon: Icon(
                Icons.close_rounded,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Mini artwork badge (48×48) with gradient and surah number.
class _MiniArtworkBadge extends StatelessWidget {
  final int? surahNumber;
  final bool isPlaying;

  const _MiniArtworkBadge({required this.surahNumber, required this.isPlaying});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.primary.withValues(alpha: 0.6),
              ],
            ),
          ),
          child: Center(
            child: Text(
              '${surahNumber ?? ''}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
          ),
        ),
        if (isPlaying) ...[
          Positioned(right: -2, bottom: -2, child: _SoundWaveIndicator()),
        ],
      ],
    );
  }
}

/// Animated equalizer-style indicator when playing.
class _SoundWaveIndicator extends StatefulWidget {
  @override
  State<_SoundWaveIndicator> createState() => _SoundWaveIndicatorState();
}

class _SoundWaveIndicatorState extends State<_SoundWaveIndicator>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
      ),
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, _) {
            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _Bar(height: (4 + _ctrl.value * 6).clamp(2.0, 10.0)),
                _Bar(height: (2 + (1 - _ctrl.value) * 8).clamp(2.0, 10.0)),
                _Bar(height: (6 + _ctrl.value * 4).clamp(2.0, 10.0)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  final double height;

  const _Bar({required this.height});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 2,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

/// Custom progress bar with rounded corners and primary color fill.
class _ProgressBar extends StatelessWidget {
  final SurahMiniPlayerState state;

  const _ProgressBar({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final value = state.isSeekReady
        ? _progressValue(state.position, state.duration)
        : null;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 3,
          child: Stack(
            children: [
              // Track
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              // Fill
              if (value != null)
                FractionallySizedBox(
                  widthFactor: value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                )
              else
                // Indeterminate shimmer
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 1),
                  builder: (_, v, __) => FractionallySizedBox(
                    widthFactor: v,
                    child: Container(
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// EXPANDED
// ════════════════════════════════════════════════════════════════════════════

class _ExpandedMiniPlayer extends StatelessWidget {
  final SurahMiniPlayerState state;

  const _ExpandedMiniPlayer({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context)!;
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;
    final total = state.duration ?? Duration.zero;
    final cubit = context.read<SurahMiniPlayerCubit>();
    final surahName = _localizedSurahName(
      context,
      state.surahNumber,
      fallbackName: state.surahName,
    );

    // SingleChildScrollView absorbs the layout overflow that occurs while the
    // AnimatedContainer is mid-transition (76 px → expanded height).
    // NeverScrollableScrollPhysics keeps the content locked; the ClipRRect
    // on the parent AnimatedContainer handles the visual clipping.
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ────────────────────────────────────────────────────
          GestureDetector(
            onTap: cubit.collapse,
            child: Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
          ),

          // ── Header row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
            child: Row(
              children: [
                // Mini artwork
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: colorScheme.primary,
                    // gradient: LinearGradient(
                    //   begin: Alignment.topLeft,
                    //   end: Alignment.bottomRight,
                    //   colors: [
                    //     colorScheme.primary,
                    //     colorScheme.primary.withValues(alpha: 0.6),
                    //   ],
                    // ),
                  ),
                  child: Center(
                    child: Text(
                      '${state.surahNumber ?? ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Title
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surahName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        state.surahNumber != null
                            ? quran.getSurahNameArabic(state.surahNumber!)
                            : '',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                // Fullscreen button
                IconButton(
                  onPressed: () {
                    context.read<SurahMiniPlayerCubit>().openFullscreen();
                    Navigator.of(
                      context,
                      rootNavigator: true,
                    ).push(buildFullscreenRoute(context));
                  },
                  tooltip: 'Plein écran',
                  icon: const Icon(Icons.open_in_full_rounded, size: 20),
                  color: colorScheme.onSurfaceVariant,
                ),
                // Close button
                IconButton(
                  onPressed: cubit.closePlayer,
                  tooltip: _tooltipIfOverlay(context, localizations.close),
                  icon: const Icon(Icons.close_rounded, size: 20),
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),

          // ── Slider ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 4,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                activeTrackColor: colorScheme.primary,
                inactiveTrackColor: colorScheme.onSurface.withValues(
                  alpha: 0.18,
                ),
                thumbColor: colorScheme.primary,
                disabledActiveTrackColor: colorScheme.onSurface.withValues(
                  alpha: 0.25,
                ),
                disabledInactiveTrackColor: colorScheme.onSurface.withValues(
                  alpha: 0.12,
                ),
              ),
              child: Slider(
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
                        cubit.seek(Duration(milliseconds: value.round()));
                      },
              ),
            ),
          ),

          // ── Time labels ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.position),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  state.isSeekReady ? _formatDuration(total) : '--:--',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // ── Controls ──────────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                onPressed: state.canGoPrevious ? cubit.playPreviousSurah : null,
                icon: const Icon(Icons.skip_previous_rounded),
                iconSize: 28,
              ),
              IconButton(
                onPressed: state.isSeekReady
                    ? () => cubit.seekBySeconds(-10)
                    : null,
                icon: const Icon(Icons.replay_10_rounded),
                iconSize: 26,
              ),
              // Play / Pause
              _ExpandedPlayPauseButton(
                isPlaying: isPlaying,
                isLoading: state.playerState == AudioPlayerState.loading,
                onTap: cubit.togglePlayPause,
                colorScheme: colorScheme,
              ),
              IconButton(
                onPressed: state.isSeekReady
                    ? () => cubit.seekBySeconds(10)
                    : null,
                icon: const Icon(Icons.forward_10_rounded),
                iconSize: 26,
              ),
              IconButton(
                onPressed: state.canGoNext ? cubit.playNextSurah : null,
                icon: const Icon(Icons.skip_next_rounded),
                iconSize: 28,
              ),
            ],
          ),

          const SizedBox(height: 2),

          // ── Playback Mode ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: IconButton(
                  onPressed: cubit.cyclePlaybackMode,
                  iconSize: 20,
                  icon: Icon(
                    _playbackModeIcon(state.playbackMode),
                    color: _playbackModeColor(
                      colorScheme: colorScheme,
                      playbackMode: state.playbackMode,
                    ),
                  ),
                  tooltip: _tooltipIfOverlay(
                    context,
                    _playbackModeTooltip(
                      AppLocalizations.of(context)!,
                      state.playbackMode,
                    ),
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _ExpandedPlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final bool isLoading;
  final VoidCallback onTap;
  final ColorScheme colorScheme;

  const _ExpandedPlayPauseButton({
    required this.isPlaying,
    required this.isLoading,
    required this.onTap,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        width: 52,
        height: 52,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          color: colorScheme.primary,
        ),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: colorScheme.primary,
          shape: BoxShape.circle,
        ),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: colorScheme.onPrimary,
          size: 28,
        ),
      ),
    );
  }
}

// ── Shared helpers ────────────────────────────────────────────────────────────

/// Returns the surah name in the language currently selected by the user
/// via [QuranSettingsCubit]. Falls back to English if [surahNumber] is null.
String _localizedSurahName(
  BuildContext context,
  int? surahNumber, {
  String? fallbackName,
}) {
  if (surahNumber == null) return '';
  final settingsCubit = context.read<QuranSettingsCubit?>();
  if (settingsCubit == null) {
    final fallback = fallbackName?.trim();
    if (fallback != null && fallback.isNotEmpty) {
      return fallback;
    }
    return quran.getSurahNameEnglish(surahNumber);
  }
  final translation = settingsCubit.state.selectedTranslation;
  return QuranSettingsCubit.getSurahNameInTranslation(surahNumber, translation);
}

double _progressValue(Duration position, Duration? duration) {
  if (duration == null || duration.inMilliseconds <= 0) return 0;
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

IconData _playbackModeIcon(PlaybackMode mode) {
  switch (mode) {
    case PlaybackMode.repeatOne:
      return Icons.repeat_one_rounded;
    case PlaybackMode.repeatAll:
    case PlaybackMode.off:
      return Icons.repeat_rounded;
    case PlaybackMode.shuffle:
      return Icons.shuffle_rounded;
  }
}

Color _playbackModeColor({
  required ColorScheme colorScheme,
  required PlaybackMode playbackMode,
}) {
  return playbackMode == PlaybackMode.off
      ? colorScheme.primary.withValues(alpha: 0.4)
      : colorScheme.primary;
}

String _playbackModeTooltip(AppLocalizations localizations, PlaybackMode mode) {
  switch (mode) {
    case PlaybackMode.off:
      return localizations.playbackModeOff;
    case PlaybackMode.repeatOne:
      return localizations.playbackModeRepeatOne;
    case PlaybackMode.repeatAll:
      return localizations.playbackModeRepeatAll;
    case PlaybackMode.shuffle:
      return localizations.playbackModeShuffle;
  }
}

String _formatDuration(Duration duration) {
  final hours = duration.inHours;
  final minutes = duration.inMinutes.remainder(60);
  final seconds = duration.inSeconds.remainder(60);
  if (hours > 0) {
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:'
      '${seconds.toString().padLeft(2, '0')}';
}

String? _tooltipIfOverlay(BuildContext context, String message) {
  return Overlay.maybeOf(context) == null ? null : message;
}
