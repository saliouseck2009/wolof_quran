import 'package:flutter/material.dart';

/// Segmented control in the style of the verse range sheet.
class SegmentedSwitch<T> extends StatelessWidget {
  final List<(T, String)> options;
  final T value;
  final ValueChanged<T> onChanged;

  const SegmentedSwitch({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          for (final (option, label) in options)
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 4,
                  ),
                  decoration: BoxDecoration(
                    color: option == value
                        ? colorScheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(11),
                    boxShadow: option == value
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ]
                        : null,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontWeight: option == value
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: option == value
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Stadium chip for a quick choice (duration preset, etc.). With [expanded]
/// the chip fills its parent and centres its content, for chip grids.
class QuickChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final IconData? icon;
  final bool expanded;

  const QuickChoiceChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.icon,
    this.expanded = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final foreground = selected ? colorScheme.primary : colorScheme.onSurface;

    return Material(
      color: selected
          ? colorScheme.primary.withValues(alpha: 0.1)
          : Colors.transparent,
      shape: StadiumBorder(
        side: BorderSide(
          color: selected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.35),
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: expanded ? 10 : 16,
            vertical: 12,
          ),
          child: Row(
            mainAxisSize: expanded ? MainAxisSize.max : MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 16, color: foreground),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: foreground,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Uppercase section label of a form.
class FormSectionLabel extends StatelessWidget {
  final String label;

  const FormSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        label.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          fontWeight: FontWeight.w700,
          color: theme.colorScheme.onSurfaceVariant,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

/// Header of a reading goal bottom sheet: optional icon badge, title,
/// subtitle and a round close button.
class SheetHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData? icon;

  const SheetHeader({super.key, required this.title, this.subtitle, this.icon});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          IconBadge(icon: icon!, size: 44),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        const SheetCloseButton(),
      ],
    );
  }
}

/// Round tonal close button of a bottom sheet.
class SheetCloseButton extends StatelessWidget {
  const SheetCloseButton({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.onSurface.withValues(alpha: 0.06),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(),
        child: Tooltip(
          message: MaterialLocalizations.of(context).closeButtonTooltip,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(
              Icons.close_rounded,
              size: 18,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}

/// Rounded square with a tinted icon, used in sheet rows and headers.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final double size;
  final Color? color;

  const IconBadge({super.key, required this.icon, this.size = 40, this.color});

  @override
  Widget build(BuildContext context) {
    final tint = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(icon, size: size * 0.5, color: tint),
    );
  }
}

/// Row of a bottom sheet menu: icon badge, title, optional subtitle and a
/// chevron. [tint] colours the badge and, when [filled], the whole row.
class SheetActionRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Color? tint;
  final bool filled;
  final bool chevron;

  const SheetActionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.tint,
    this.filled = false,
    this.chevron = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = tint ?? colorScheme.primary;

    return Material(
      color: filled ? accent.withValues(alpha: 0.08) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: filled ? 12 : 4,
            vertical: 10,
          ),
          child: Row(
            children: [
              IconBadge(icon: icon, color: accent),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                        color: filled && tint != null
                            ? accent
                            : colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        subtitle!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (chevron) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.chevron_right_rounded,
                  color: colorScheme.onSurfaceVariant,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Thin separator between sheet rows.
class SheetRowDivider extends StatelessWidget {
  const SheetRowDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 58,
      color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12),
    );
  }
}

/// Full-width primary button at the bottom of a form or sheet.
class PrimaryActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool iconLeading;

  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.iconLeading = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = FilledButton.styleFrom(
      minimumSize: const Size.fromHeight(54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: theme.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
    );
    final iconWidget = Icon(icon, size: 20);
    final text = Text(label);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: onPressed == null
            ? null
            : [
                BoxShadow(
                  color: theme.colorScheme.primary.withValues(alpha: 0.25),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: iconLeading
          ? FilledButton.icon(
              onPressed: onPressed,
              style: style,
              icon: iconWidget,
              label: text,
            )
          : FilledButton(
              onPressed: onPressed,
              style: style,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [text, const SizedBox(width: 8), iconWidget],
              ),
            ),
    );
  }
}

/// Slider look shared by the reading goal forms and sheets: thin primary
/// track, outlined thumb, no value indicator.
class GoalSliderTheme extends StatelessWidget {
  final Widget child;

  const GoalSliderTheme({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 4,
        activeTrackColor: colorScheme.primary,
        inactiveTrackColor: colorScheme.onSurface.withValues(alpha: 0.1),
        thumbColor: colorScheme.surface,
        overlayColor: colorScheme.primary.withValues(alpha: 0.12),
        thumbShape: const _OutlinedThumb(),
        rangeThumbShape: const _OutlinedRangeThumb(),
        showValueIndicator: ShowValueIndicator.never,
        trackShape: const _PaddedTrackShape(),
        activeTickMarkColor: Colors.transparent,
        inactiveTickMarkColor: Colors.transparent,
      ),
      child: child,
    );
  }
}

class _PaddedTrackShape extends RoundedRectSliderTrackShape {
  const _PaddedTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final height = sliderTheme.trackHeight ?? 4;
    final top = offset.dy + (parentBox.size.height - height) / 2;
    return Rect.fromLTWH(
      offset.dx + 12,
      top,
      parentBox.size.width - 24,
      height,
    );
  }
}

void _paintThumb(Canvas canvas, Offset center, Color fill, Color ring) {
  canvas.drawCircle(
    center,
    12,
    Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
  );
  canvas.drawCircle(center, 11, Paint()..color = fill);
  canvas.drawCircle(
    center,
    11,
    Paint()
      ..color = ring
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3,
  );
}

class _OutlinedThumb extends SliderComponentShape {
  const _OutlinedThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    _paintThumb(
      context.canvas,
      center,
      sliderTheme.thumbColor ?? Colors.white,
      sliderTheme.activeTrackColor ?? Colors.green,
    );
  }
}

class _OutlinedRangeThumb extends RangeSliderThumbShape {
  const _OutlinedRangeThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size(24, 24);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    TextDirection? textDirection,
    required SliderThemeData sliderTheme,
    Thumb? thumb,
    bool? isPressed,
  }) {
    _paintThumb(
      context.canvas,
      center,
      sliderTheme.thumbColor ?? Colors.white,
      sliderTheme.activeTrackColor ?? Colors.green,
    );
  }
}
