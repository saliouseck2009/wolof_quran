import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:quran/quran.dart' as quran;

import '../../../core/config/theme/app_color.dart';
import '../../../core/services/audio_player_service.dart';
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
        // If the cubit moved away from fullscreen (e.g. player closed), pop.
        if (state.uiState != SurahMiniPlayerUiState.fullscreen &&
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
                        reciterName: activeReciterName,
                        total: total,
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
                      onPressed: () =>
                          context.read<SurahMiniPlayerCubit>().toggleRepeat(),
                      icon: Icon(
                        Icons.repeat,
                        color: state.repeatSurah ? t.accent : t.disabled,
                      ),
                      tooltip: 'Répéter',
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
            tooltip: 'Réduire',
          ),
          Expanded(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'En cours de lecture',
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
  final String reciterName;
  final Duration total;
  final String surahTitle;

  const _CenterNowPlayingCard({
    required this.state,
    required this.tokens,
    required this.reciterName,
    required this.total,
    required this.surahTitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isPlaying =
        state.playerState == AudioPlayerState.playing ||
        state.playerState == AudioPlayerState.loading;
    final progress = state.isSeekReady
        ? _progressValue(state.position, total)
        : null;
    final remaining = state.isSeekReady
        ? _safeRemaining(total, state.position)
        : Duration.zero;

    final cardDecoration = BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      color: tokens.isDark ? cs.surfaceContainerHigh : cs.surfaceContainerLow,
      border: Border.all(
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.08)
            : cs.primary.withValues(alpha: 0.12),
      ),
      boxShadow: [
        BoxShadow(
          color: tokens.isDark
              ? Colors.black.withValues(alpha: 0.22)
              : cs.shadow.withValues(alpha: 0.08),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 520),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        decoration: cardDecoration,
        padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _InfoChip(
                  icon: Icons.menu_book_rounded,
                  label: state.surahNumber != null
                      ? 'Sourate ${state.surahNumber}'
                      : 'Sourate --',
                  tokens: tokens,
                ),
                _InfoChip(
                  icon: isPlaying
                      ? Icons.multitrack_audio_rounded
                      : Icons.pause_circle_outline_rounded,
                  label: isPlaying ? 'Lecture' : 'Pause',
                  tokens: tokens,
                ),
              ],
            ),
            const SizedBox(height: 20),
            _SurahArtwork(
              surahNumber: state.surahNumber,
              isPlaying: isPlaying,
              tokens: tokens,
            ),
            const SizedBox(height: 18),
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
            const SizedBox(height: 6),
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
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 6,
                value: progress,
                color: tokens.accent,
                backgroundColor: tokens.isDark
                    ? Colors.white.withValues(alpha: 0.16)
                    : cs.onSurface.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _formatDuration(state.position),
                    style: TextStyle(
                      color: tokens.muted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  state.isSeekReady ? _formatDuration(total) : '--:--',
                  style: TextStyle(
                    color: tokens.muted,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              height: 1,
              thickness: 1,
              color: tokens.isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : cs.onSurface.withValues(alpha: 0.1),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetaRow(
                    icon: Icons.person_rounded,
                    label: 'Interprète',
                    value: reciterName,
                    tokens: tokens,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetaRow(
                    icon: Icons.schedule_rounded,
                    label: 'Restant',
                    value: state.isSeekReady
                        ? '-${_formatDuration(remaining)}'
                        : '--:--',
                    tokens: tokens,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SurahArtwork extends StatelessWidget {
  final int? surahNumber;
  final bool isPlaying;
  final _ThemeTokens tokens;

  const _SurahArtwork({
    required this.surahNumber,
    required this.isPlaying,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final accentSoft = tokens.isDark
        ? Colors.white.withValues(alpha: 0.24)
        : tokens.accent.withValues(alpha: 0.22);

    return SizedBox(
      width: 196,
      height: 196,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 196,
            height: 196,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accentSoft, width: 1.2),
            ),
          ),
          Container(
            width: 166,
            height: 166,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: tokens.isDark
                    ? Colors.white.withValues(alpha: 0.12)
                    : cs.onSurface.withValues(alpha: 0.08),
                width: 1.2,
              ),
            ),
          ),
          Container(
            width: 138,
            height: 138,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [tokens.accent, tokens.accent.withValues(alpha: 0.62)],
              ),
              boxShadow: [
                BoxShadow(
                  color: tokens.accent.withValues(alpha: 0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${surahNumber ?? '--'}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 38,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 6),
                Icon(
                  isPlaying
                      ? Icons.graphic_eq_rounded
                      : Icons.play_circle_fill_rounded,
                  color: Colors.white.withValues(alpha: 0.92),
                  size: 22,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final _ThemeTokens tokens;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: tokens.isDark
            ? Colors.white.withValues(alpha: 0.1)
            : cs.surface.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: tokens.content),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: tokens.content,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _ThemeTokens tokens;

  const _MetaRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.tokens,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: tokens.muted),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.muted,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: tokens.content,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
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
      padding: const EdgeInsets.symmetric(horizontal: 24),
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
            tooltip: 'Précédent',
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
            tooltip: 'Reculer 10s',
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
            tooltip: 'Avancer 10s',
          ),
          // Next
          IconButton(
            onPressed: state.canGoNext ? cubit.playNextSurah : null,
            icon: Icon(
              Icons.skip_next_rounded,
              color: state.canGoNext ? t.content : t.disabled,
            ),
            iconSize: 36,
            tooltip: 'Suivant',
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
    final shadowColor = t.isDark
        ? Colors.black.withValues(alpha: 0.3)
        : t.accent.withValues(alpha: 0.35);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          color: circleBg,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
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

double _progressValue(Duration position, Duration? duration) {
  if (duration == null || duration.inMilliseconds <= 0) {
    return 0;
  }
  return (position.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
}

Duration _safeRemaining(Duration total, Duration position) {
  if (total <= Duration.zero) return Duration.zero;
  if (position <= Duration.zero) return total;
  if (position >= total) return Duration.zero;
  return total - position;
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
