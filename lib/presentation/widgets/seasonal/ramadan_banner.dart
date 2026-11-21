import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/config/theme/ramadan_color.dart';
import '../../../core/config/theme/seasonal_theme.dart';
import '../../../core/navigation/create_reading_goal_arguments.dart';
import '../../../core/reading/local_date.dart';
import '../../../core/seasonal/ramadan_calendar.dart';
import '../../../domain/entities/reading_goal.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../cubits/reading_goals_cubit.dart';
import '../../cubits/seasonal_theme_cubit.dart';
import '../../views/create_reading_goal_page.dart';
import 'night_sky.dart';
import 'ramadan_start_sheet.dart';

/// Home greeting of the Ramadan look: a sky with the real moon, a few stars
/// and two lanterns next to the greeting, and where the user stands in the
/// month (day or night N). The sky follows the hour, the Korité has its own.
/// It draws itself (no image asset) and renders nothing out of season.
class RamadanBanner extends StatelessWidget {
  const RamadanBanner({super.key});

  static const double _radius = 24;
  static const double _minHeight = 104;

  /// Room kept free of text for the ornaments, on the end side.
  static const double _ornamentWidth = 132;

  /// The two colors of the sky gradient at [moment]: the night of [decor]
  /// when the month is not dated.
  static (Color, Color) skyOf(SeasonalDecor decor, RamadanMoment? moment) {
    if (moment == null) {
      return (decor.skyStart, decor.skyEnd);
    }
    if (moment.period == RamadanPeriod.eid) {
      return (RamadanColor.eidStart, RamadanColor.eidEnd);
    }
    return switch (moment.sky) {
      RamadanSky.preDawn => (
        RamadanColor.preDawnStart,
        RamadanColor.preDawnEnd,
      ),
      RamadanSky.day => (RamadanColor.dayStart, RamadanColor.dayEnd),
      RamadanSky.sunset => (RamadanColor.sunsetStart, RamadanColor.sunsetEnd),
      RamadanSky.night => (decor.skyStart, decor.skyEnd),
    };
  }

  /// Gold of the line that says where the user stands in the month.
  static Color statusColor(SeasonalDecor decor) =>
      Color.lerp(decor.ornament, decor.onSky, 0.35)!;

  @override
  Widget build(BuildContext context) {
    final decor = Theme.of(context).extension<SeasonalDecor>();
    if (decor == null || decor.season != SeasonalTheme.ramadan) {
      return const SizedBox.shrink();
    }
    final moment = context.select<SeasonalThemeCubit, RamadanMoment?>(
      (cubit) => cubit.state.moment,
    );
    final localizations = AppLocalizations.of(context)!;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final texts = _BannerTexts.of(localizations, moment);
    final (skyStart, skyEnd) = skyOf(decor, moment);

    return Container(
      constraints: const BoxConstraints(minHeight: _minHeight),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_radius),
        gradient: LinearGradient(
          begin: AlignmentDirectional.topStart,
          end: AlignmentDirectional.bottomEnd,
          colors: [skyStart, skyEnd],
        ),
        // Outlines the banner on the night surfaces of the dark mode.
        border: Border.all(color: decor.ornament.withValues(alpha: 0.22)),
      ),
      child: CustomPaint(
        painter: _BannerSkyPainter(
          decor: decor,
          mirrored: isRtl,
          moonPhase: moment?.moonPhase,
          starry: moment == null || moment.sky != RamadanSky.day,
        ),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 18, 20, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                // The texts leave the top end corner to the ornaments; the
                // buttons below take the whole width.
                padding: const EdgeInsetsDirectional.only(
                  end: _ornamentWidth - 20,
                ),
                child: Semantics(
                  container: true,
                  label: texts.semanticsLabel,
                  child: ExcludeSemantics(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            texts.greeting,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.2,
                              height: 1.3,
                              color: decor.onSky,
                            ),
                          ),
                        ),
                        if (texts.status case final status?) ...[
                          const SizedBox(height: 2),
                          Text(
                            status,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
                              color: statusColor(decor),
                            ),
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          texts.tagline,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: decor.onSky.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // The start day is chosen during the month; the Korité greets.
              if (moment != null && moment.period != RamadanPeriod.eid) ...[
                const SizedBox(height: 4),
                _BannerActions(
                  decor: decor,
                  adjustDateLabel: localizations.ramadanAdjustDate,
                ),
              ] else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

/// The three lines of the banner at one moment of the month.
class _BannerTexts {
  final String greeting;
  final String? status;
  final String tagline;

  const _BannerTexts({
    required this.greeting,
    required this.tagline,
    this.status,
  });

  String get semanticsLabel => [greeting, ?status, tagline].join('. ');

  factory _BannerTexts.of(AppLocalizations l, RamadanMoment? moment) {
    if (moment == null) {
      return _BannerTexts(
        greeting: l.ramadanGreeting,
        tagline: l.ramadanTagline,
      );
    }
    if (moment.period == RamadanPeriod.eid) {
      return _BannerTexts(greeting: l.eidGreeting, tagline: l.eidTagline);
    }
    if (moment.period == RamadanPeriod.eve) {
      return _BannerTexts(
        greeting: l.ramadanGreeting,
        status: l.ramadanStartsTonight,
        tagline: l.ramadanTagline,
      );
    }

    final night = moment.night;
    final day = moment.day;
    final status = night != null
        ? l.ramadanNight(night)
        : (day != null ? l.ramadanDay(day) : null);

    // The day before an odd night of the last ten announces it.
    final tonight = moment.tonight;
    final String tagline;
    if (tonight != null &&
        tonight >= RamadanCalendar.firstLastTenNight &&
        tonight.isOdd) {
      tagline = l.ramadanTonight(tonight);
    } else if (moment.period == RamadanPeriod.lastTenNights) {
      tagline = l.ramadanLastTenNights;
    } else {
      tagline = l.ramadanTagline;
    }
    return _BannerTexts(
      greeting: l.ramadanGreeting,
      status: status,
      tagline: tagline,
    );
  }
}

/// The buttons of the banner: "Start my Khatm" while the user has no goal
/// ongoing or planned (the reading card of the home already resumes an
/// existing one), and "Adjust the date", reduced to its icon next to the
/// Khatm so both fit on one line.
class _BannerActions extends StatelessWidget {
  final SeasonalDecor decor;
  final String adjustDateLabel;

  const _BannerActions({required this.decor, required this.adjustDateLabel});

  @override
  Widget build(BuildContext context) {
    // The banner also lives in places without reading goals (tests).
    final goals = context.read<ReadingGoalsCubit?>();
    if (goals == null) {
      return _AdjustDateButton(label: adjustDateLabel, color: decor.onSky);
    }
    return BlocBuilder<ReadingGoalsCubit, ReadingGoalsState>(
      bloc: goals,
      buildWhen: (previous, current) =>
          _canStartKhatm(previous) != _canStartKhatm(current),
      builder: (context, state) {
        final adjust = _AdjustDateButton(
          label: adjustDateLabel,
          color: decor.onSky,
          compact: _canStartKhatm(state),
        );
        if (!_canStartKhatm(state)) {
          return adjust;
        }
        return Wrap(
          spacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            FilledButton.icon(
              onPressed: () => _openKhatm(context),
              icon: const Icon(Icons.auto_stories_outlined, size: 16),
              label: Text(AppLocalizations.of(context)!.ramadanStartKhatm),
              style: FilledButton.styleFrom(
                backgroundColor: decor.ornament,
                foregroundColor: RamadanColor.onSecondaryContainer,
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.padded,
                shape: const StadiumBorder(),
              ),
            ),
            adjust,
          ],
        );
      },
    );
  }

  static bool _canStartKhatm(ReadingGoalsState state) =>
      !state.isLoading && state.ongoing.isEmpty && state.planned.isEmpty;

  /// Opens a reading goal prefilled to finish the Quran by the last day of
  /// fasting of this user.
  void _openKhatm(BuildContext context) {
    final seasonal = context.read<SeasonalThemeCubit>();
    final calendar = seasonal.state.calendar;
    if (calendar == null) {
      return;
    }
    final now = seasonal.now();
    final today = LocalDate.fromDateTime(now);
    final days = calendar.daysLeftFrom(today);
    if (days < 1) {
      return;
    }
    final template = ReadingGoal(
      id: '',
      name: AppLocalizations.of(context)!.ramadanKhatmName,
      status: ReadingGoalStatus.active,
      startPage: 1,
      totalPages: context.read<ReadingGoalsCubit>().totalPages,
      startDate: today,
      endDate: today.addDays(days - 1),
      createdAt: now,
      updatedAt: now,
    );
    Navigator.of(context).pushNamed(
      CreateReadingGoalPage.routeName,
      arguments: CreateReadingGoalArguments(template: template),
    );
  }
}

class _AdjustDateButton extends StatelessWidget {
  final String label;
  final Color color;

  /// Only the icon, named by its tooltip for screen readers.
  final bool compact;

  const _AdjustDateButton({
    required this.label,
    required this.color,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    if (compact) {
      return IconButton(
        onPressed: () => showRamadanStartSheet(context),
        tooltip: label,
        icon: const Icon(Icons.edit_calendar_outlined, size: 18),
        style: IconButton.styleFrom(
          foregroundColor: color,
          backgroundColor: color.withValues(alpha: 0.12),
        ),
      );
    }
    return TextButton.icon(
      onPressed: () => showRamadanStartSheet(context),
      icon: const Icon(Icons.edit_calendar_outlined, size: 16),
      label: Text(label),
      style: TextButton.styleFrom(
        foregroundColor: color,
        backgroundColor: color.withValues(alpha: 0.12),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        minimumSize: const Size(0, 34),
        // Keeps a 48 px target for the finger and the screen reader.
        tapTargetSize: MaterialTapTargetSize.padded,
        shape: const StadiumBorder(),
      ),
    );
  }
}

/// Moon, stars and lanterns, anchored to the top end corner. Sizes are in
/// logical pixels: the ornaments keep their size when the banner grows with
/// the text.
class _BannerSkyPainter extends CustomPainter {
  final SeasonalDecor decor;

  /// Draws the scene on the left, for right-to-left languages.
  final bool mirrored;

  /// Phase of the real moon, null to draw the usual crescent.
  final double? moonPhase;

  /// False in the daytime sky, which keeps only the moon and lanterns.
  final bool starry;

  const _BannerSkyPainter({
    required this.decor,
    required this.mirrored,
    required this.moonPhase,
    required this.starry,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final moonCenter = Offset(mirrored ? 44 : w - 44, 46);

    // The real moon is drawn unmirrored: its lit side is a fact of the sky,
    // not of the reading direction.
    final phase = moonPhase;
    if (phase != null) {
      NightSky.paintRealMoon(canvas, moonCenter, 24, phase, decor);
    }

    canvas.save();
    if (mirrored) {
      canvas
        ..translate(w, 0)
        ..scale(-1, 1);
    }
    if (phase == null) {
      NightSky.paintMoon(canvas, Offset(w - 44, 46), 24, decor);
    }

    if (starry) {
      // Bright stars near the moon, faint ones over the rest of the sky.
      // Next to the real moon, whose faint disc would hide it; in the
      // hollow of the usual crescent otherwise.
      NightSky.paintSparkle(
        canvas,
        phase == null ? Offset(w - 30, 38) : Offset(w - 16, 16),
        5.5,
        decor,
      );
      NightSky.paintSparkle(
        canvas,
        Offset(w - 84, 20),
        4,
        decor,
        opacity: 0.85,
      );
      NightSky.paintSparkle(
        canvas,
        Offset(w - 14, 84),
        3.5,
        decor,
        opacity: 0.7,
      );
      NightSky.paintSparkle(
        canvas,
        Offset(w - 150, 14),
        3,
        decor,
        opacity: 0.5,
      );
      for (final (dx, dy, radius, alpha) in const [
        (0.08, 0.16, 1.1, 0.45),
        (0.22, 0.84, 0.9, 0.35),
        (0.34, 0.12, 1.0, 0.4),
        (0.47, 0.9, 1.2, 0.35),
        (0.56, 0.22, 0.9, 0.5),
        (0.74, 0.86, 1.0, 0.45),
        (0.9, 0.12, 1.1, 0.6),
      ]) {
        canvas.drawCircle(
          Offset(w * dx, size.height * dy),
          radius,
          Paint()..color = decor.onSky.withValues(alpha: alpha),
        );
      }
    }

    NightSky.paintLantern(
      canvas,
      Offset(w - 98, 0),
      drop: 14,
      height: 34,
      decor: decor,
    );
    NightSky.paintLantern(
      canvas,
      Offset(w - 124, 0),
      drop: 6,
      height: 24,
      decor: decor,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_BannerSkyPainter oldDelegate) =>
      oldDelegate.decor != decor ||
      oldDelegate.mirrored != mirrored ||
      oldDelegate.moonPhase != moonPhase ||
      oldDelegate.starry != starry;
}
