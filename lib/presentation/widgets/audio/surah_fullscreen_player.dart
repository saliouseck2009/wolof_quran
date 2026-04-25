import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/config/theme/app_color.dart';
import '../../../core/services/audio_player_service.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/quran_settings_cubit.dart';
import '../../cubits/surah_mini_player_cubit.dart';

/// Full-screen audio player page.
/// Opened via [buildFullscreenRoute] — a slide-up PageRoute.
/// Dismiss by swiping down or tapping the collapse button.
class SurahFullscreenPlayer extends StatelessWidget {
  const SurahFullscreenPlayer({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SurahMiniPlayerCubit, SurahMiniPlayerState>(
      listenWhen: (previous, current) => previous.uiState != current.uiState,
      listener: (context, state) {
        // Pop only when playback is no longer active.
        // This avoids accidental fullscreen exits on transient UI state changes.
        if ((state.uiState == SurahMiniPlayerUiState.hidden ||
                !state.hasActiveSurah) &&
            Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        return _FullscreenContent(state: state);
      },
    );
  }
}

// ── Theme tokens ──────────────────────────────────────────────────────────────

/// All theme-aware color values computed once and threaded through sub-widgets.
class _ThemeTokens {
  final bool isDark;
  final Color accent; // primary action color
  final Color content; // main text / icon color
  final Color muted; // secondary text / icon color
  final Color disabled; // disabled icon color

  const _ThemeTokens({
    required this.isDark,
    required this.accent,
    required this.content,
    required this.muted,
    required this.disabled,
  });

  factory _ThemeTokens.of(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final dark = cs.brightness == Brightness.dark;
    return _ThemeTokens(
      isDark: dark,
      // Dark: lighter teal for readability; Light: deep teal primary.
      accent: dark ? AppColor.tertiary : cs.primary,
      content: dark ? Colors.white : cs.onSurface,
      muted: dark ? Colors.white.withValues(alpha: 0.6) : cs.onSurfaceVariant,
      disabled: dark
          ? Colors.white.withValues(alpha: 0.3)
          : cs.onSurface.withValues(alpha: 0.3),
    );
  }
}

// ── Main content ──────────────────────────────────────────────────────────────

class _FullscreenContent extends StatelessWidget {
  final SurahMiniPlayerState state;

  const _FullscreenContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final t = _ThemeTokens.of(context);
    final selectedReciterName = context
        .watch<QuranSettingsCubit>()
        .state
        .selectedReciter
        ?.name;
    final activeReciterName =
        selectedReciterName ?? _formatReciterName(state.reciterId);
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;
    final total = state.duration ?? Duration.zero;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Status-bar icons: white on dark background, dark on light background.
      value: t.isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: GestureDetector(
        onVerticalDragEnd: (details) {
          if (details.primaryVelocity != null &&
              details.primaryVelocity! > 300) {
            _dismiss(context);
          }
        },
        child: Scaffold(
          backgroundColor: colorScheme.surface,
          body: SafeArea(
            child: Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                _FullscreenHeader(
                  tokens: t,
                  reciterName: activeReciterName,
                  onCollapse: () => _dismiss(context),
                ),

                const SizedBox(height: 8),

                // ── Center content ───────────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Center(
                      child: _CenterNowPlayingCard(
                        state: state,
                        tokens: t,
                        surahTitle: _surahTitleWithNumber(
                          context,
                          state.surahNumber,
                          fallbackName: state.surahName,
                        ),
                      ),
                    ),
                  ),
                ),

                // ── Seek bar ──────────────────────────────────────────────
                _SeekBar(state: state, total: total, tokens: t),
                const SizedBox(height: 12),

                // ── Controls ──────────────────────────────────────────────
                _FullscreenControls(
                  state: state,
                  isPlaying: isPlaying,
                  tokens: t,
                  colorScheme: colorScheme,
                ),

                const SizedBox(height: 8),

                // ── Repeat ────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: () => context
                          .read<SurahMiniPlayerCubit>()
                          .cyclePlaybackMode(),
                      icon: Icon(
                        _playbackModeIcon(state.playbackMode),
                        color: state.playbackMode == PlaybackMode.off
                            ? t.disabled
                            : t.accent,
                      ),
                      tooltip: _playbackModeTooltip(
                        AppLocalizations.of(context)!,
                        state.playbackMode,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _dismiss(BuildContext context) {
    context.read<SurahMiniPlayerCubit>().closeFullscreen();
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FullscreenHeader extends StatelessWidget {
  final _ThemeTokens tokens;
  final String reciterName;
  final VoidCallback onCollapse;

  const _FullscreenHeader({
    required this.tokens,
    required this.reciterName,
    required this.onCollapse,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: onCollapse,
            icon: Icon(
              Icons.keyboard_arrow_down,
              size: 32,
              color: tokens.content,
            ),
            tooltip: AppLocalizations.of(context)!.collapsePlayer,
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    AppLocalizations.of(context)!.nowPlaying,
                    style: TextStyle(
                      color: tokens.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reciterName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.content,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Placeholder for symmetry
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

class _CenterNowPlayingCard extends StatelessWidget {
  final SurahMiniPlayerState state;
  final _ThemeTokens tokens;
  final String surahTitle;

  const _CenterNowPlayingCard({
    required this.state,
    required this.tokens,
    required this.surahTitle,
  });

  @override
  Widget build(BuildContext context) {
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final availableHeight = constraints.maxHeight.isFinite
              ? constraints.maxHeight
              : 420.0;
          final artworkSize = (availableHeight - 124).clamp(140.0, 260.0);
          final spacingAfterArtwork = artworkSize >= 220 ? 20.0 : 12.0;
          final spacingBeforeArabic = artworkSize >= 220 ? 6.0 : 4.0;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SurahArtwork(
                surahNumber: state.surahNumber,
                isPlaying: isPlaying,
                tokens: tokens,
                size: artworkSize.toDouble(),
              ),
              SizedBox(height: spacingAfterArtwork),
              Text(
                surahTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: tokens.content,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              SizedBox(height: spacingBeforeArabic),
              Text(
                state.surahNumber != null
                    ? quran.getSurahNameArabic(state.surahNumber!)
                    : '',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: tokens.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SurahArtwork extends StatelessWidget {
  final int? surahNumber;
  final bool isPlaying;
  final _ThemeTokens tokens;
  final double size;

  const _SurahArtwork({
    required this.surahNumber,
    required this.isPlaying,
    required this.tokens,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF006E62), Color(0xFF00201B)],
        ),
      ),
      child: Center(
        child: _AnimatedMusicNote(
          isPlaying: isPlaying,
          iconSize: (size * 0.37).clamp(56.0, 96.0).toDouble(),
        ),
      ),
    );
  }
}

class _AnimatedMusicNote extends StatefulWidget {
  final bool isPlaying;
  final double iconSize;

  const _AnimatedMusicNote({required this.isPlaying, required this.iconSize});

  @override
  State<_AnimatedMusicNote> createState() => _AnimatedMusicNoteState();
}

class _AnimatedMusicNoteState extends State<_AnimatedMusicNote>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _opacity = Tween<double>(
      begin: 0.7,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    if (widget.isPlaying) _ctrl.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AnimatedMusicNote oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isPlaying && !_ctrl.isAnimating) {
      _ctrl.repeat(reverse: true);
    } else if (!widget.isPlaying && _ctrl.isAnimating) {
      _ctrl.stop();
      _ctrl.animateTo(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, _) {
        return Transform.scale(
          scale: _scale.value,
          child: Opacity(
            opacity: _opacity.value,
            child: Icon(
              Icons.music_note_rounded,
              color: Colors.white,
              size: widget.iconSize,
            ),
          ),
        );
      },
    );
  }
}

String _formatReciterName(String? reciterId) {
  if (reciterId == null || reciterId.isEmpty) {
    return 'Imam Sarr';
  }

  const aliases = {'imamsarr': 'Imam Sarr'};
  final alias = aliases[reciterId.toLowerCase()];
  if (alias != null) {
    return alias;
  }

  final normalized = reciterId
      .replaceAll(RegExp(r'[_-]+'), ' ')
      .trim()
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0].toUpperCase() + part.substring(1).toLowerCase())
      .join(' ');

  return normalized.isEmpty ? 'Imam Sarr' : normalized;
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

// ── Controls ──────────────────────────────────────────────────────────────────

class _FullscreenControls extends StatelessWidget {
  final SurahMiniPlayerState state;
  final bool isPlaying;
  final _ThemeTokens tokens;
  final ColorScheme colorScheme;

  const _FullscreenControls({
    required this.state,
    required this.isPlaying,
    required this.tokens,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SurahMiniPlayerCubit>();
    final t = tokens;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Previous
          IconButton(
            onPressed: state.canGoPrevious ? cubit.playPreviousSurah : null,
            icon: Icon(
              Icons.skip_previous_rounded,
              color: state.canGoPrevious ? t.content : t.disabled,
            ),
            iconSize: 36,
            tooltip: AppLocalizations.of(context)!.previousSurah,
          ),
          // Rewind 10s
          IconButton(
            onPressed: state.isSeekReady
                ? () => cubit.seekBySeconds(-10)
                : null,
            icon: Icon(
              Icons.replay_10_rounded,
              color: state.isSeekReady ? t.content : t.disabled,
            ),
            iconSize: 32,
            tooltip: AppLocalizations.of(context)!.rewind10s,
          ),
          // Play / Pause
          _PlayPauseButton(
            isPlaying: isPlaying,
            tokens: t,
            colorScheme: colorScheme,
            onTap: cubit.togglePlayPause,
          ),
          // Forward 10s
          IconButton(
            onPressed: state.isSeekReady ? () => cubit.seekBySeconds(10) : null,
            icon: Icon(
              Icons.forward_10_rounded,
              color: state.isSeekReady ? t.content : t.disabled,
            ),
            iconSize: 32,
            tooltip: AppLocalizations.of(context)!.forward10s,
          ),
          // Next
          IconButton(
            onPressed: state.canGoNext ? cubit.playNextSurah : null,
            icon: Icon(
              Icons.skip_next_rounded,
              color: state.canGoNext ? t.content : t.disabled,
            ),
            iconSize: 36,
            tooltip: AppLocalizations.of(context)!.nextSurah,
          ),
        ],
      ),
    );
  }
}

// ── Play / Pause button ───────────────────────────────────────────────────────

class _PlayPauseButton extends StatelessWidget {
  final bool isPlaying;
  final _ThemeTokens tokens;
  final ColorScheme colorScheme;
  final VoidCallback onTap;

  const _PlayPauseButton({
    required this.isPlaying,
    required this.tokens,
    required this.colorScheme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens;

    // Dark: white circle with teal icon (pop on dark bg).
    // Light: teal circle with white icon (standard FilledButton look).
    final circleBg = t.isDark ? Colors.white : t.accent;
    final iconColor = t.isDark ? AppColor.primary : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(color: circleBg, shape: BoxShape.circle),
        child: Icon(
          isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          size: 38,
          color: iconColor,
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

/// Returns the surah name in the language currently selected by the user.
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

String _surahTitleWithNumber(
  BuildContext context,
  int? surahNumber, {
  String? fallbackName,
}) {
  if (surahNumber == null) {
    return _localizedSurahName(
      context,
      surahNumber,
      fallbackName: fallbackName,
    );
  }
  return '$surahNumber. ${_localizedSurahName(context, surahNumber, fallbackName: fallbackName)}';
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

// ── Route helper ──────────────────────────────────────────────────────────────

/// Pushes the fullscreen player with a slide-up animation.
/// The cubits are taken from [context], so they must be available above.
Route<void> buildFullscreenRoute(BuildContext context) {
  return PageRouteBuilder<void>(
    fullscreenDialog: true,
    opaque: true,
    barrierColor: Colors.black,
    pageBuilder: (ctx, animation, secondaryAnimation) {
      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: context.read<SurahMiniPlayerCubit>()),
          BlocProvider.value(value: context.read<QuranSettingsCubit>()),
        ],
        child: const SurahFullscreenPlayer(),
      );
    },
    transitionsBuilder: (ctx, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
            .animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
            ),
        child: child,
      );
    },
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 280),
  );
}

// ── Seek bar ──────────────────────────────────────────────────────────────────

class _SeekBar extends StatelessWidget {
  final SurahMiniPlayerState state;
  final Duration total;
  final _ThemeTokens tokens;

  const _SeekBar({
    required this.state,
    required this.total,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final t = tokens;

    // Dark: white track (contrast on dark bg).
    // Light: primary-colored track (same as rest of app).
    final activeTrack = t.isDark ? Colors.white : t.accent;
    final inactiveTrack = t.isDark
        ? Colors.white.withValues(alpha: 0.3)
        : t.accent.withValues(alpha: 0.2);
    final thumb = t.isDark ? Colors.white : t.accent;
    final overlay = t.isDark
        ? Colors.white.withValues(alpha: 0.15)
        : t.accent.withValues(alpha: 0.12);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 4,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              activeTrackColor: activeTrack,
              inactiveTrackColor: inactiveTrack,
              thumbColor: thumb,
              overlayColor: overlay,
            ),
            child: Slider(
              value: state.position.inMilliseconds
                  .clamp(0, total.inMilliseconds > 0 ? total.inMilliseconds : 0)
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
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatDuration(state.position),
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  state.isSeekReady ? _formatDuration(total) : '--:--',
                  style: TextStyle(
                    color: t.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
