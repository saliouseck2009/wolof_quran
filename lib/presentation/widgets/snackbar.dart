import 'dart:async';

import 'package:flutter/material.dart';

/// Tone of a toast: it picks the icon and the accent colour.
enum ToastKind { info, success, error }

/// Short floating messages shown above everything (bottom sheets included).
///
/// They follow the app theme: a light card in light mode, a raised
/// container in dark mode, a tinted icon badge and the Poppins text
/// styles. Only one toast is visible at a time; a new one replaces the
/// previous one.
class CustomSnackbar {
  const CustomSnackbar._();

  static OverlayEntry? _current;

  static void showSnackbar(
    BuildContext context,
    String message, {
    int duration = 2,
  }) {
    show(context, message, duration: Duration(seconds: duration));
  }

  static void showSuccessSnackbar(
    BuildContext context,
    String message, {
    int duration = 2,
  }) {
    show(
      context,
      message,
      kind: ToastKind.success,
      duration: Duration(seconds: duration),
    );
  }

  static void showErrorSnackbar(
    BuildContext context,
    String message, {
    int duration = 2,
  }) {
    show(
      context,
      message,
      kind: ToastKind.error,
      duration: Duration(seconds: duration),
    );
  }

  /// A toast with a button; it stays a little longer than a plain one.
  static void showSnackbarAction(
    BuildContext context,
    String message,
    VoidCallback? onPressed, {
    required String actionLabel,
  }) {
    show(
      context,
      message,
      duration: const Duration(seconds: 4),
      actionLabel: actionLabel,
      onAction: onPressed,
    );
  }

  static void show(
    BuildContext context,
    String message, {
    ToastKind kind = ToastKind.info,
    Duration duration = const Duration(seconds: 2),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final overlay = Overlay.of(context, rootOverlay: true);
    _current?.remove();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _Toast(
        message: message,
        kind: kind,
        duration: duration,
        actionLabel: actionLabel,
        onAction: onAction,
        onDismissed: () {
          if (entry.mounted) {
            entry.remove();
          }
          if (identical(_current, entry)) {
            _current = null;
          }
        },
      ),
    );
    _current = entry;
    overlay.insert(entry);
  }
}

class _Toast extends StatefulWidget {
  final String message;
  final ToastKind kind;
  final Duration duration;
  final String? actionLabel;
  final VoidCallback? onAction;
  final VoidCallback onDismissed;

  const _Toast({
    required this.message,
    required this.kind,
    required this.duration,
    required this.actionLabel,
    required this.onAction,
    required this.onDismissed,
  });

  @override
  State<_Toast> createState() => _ToastState();
}

class _ToastState extends State<_Toast> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
    reverseDuration: const Duration(milliseconds: 200),
  );
  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
    reverseCurve: Curves.easeIn,
  );
  late final Animation<Offset> _slide = Tween<Offset>(
    begin: const Offset(0, 0.4),
    end: Offset.zero,
  ).animate(
    CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeIn,
    ),
  );
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration + _controller.duration!, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) {
      return;
    }
    _dismissing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onDismissed();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    // The deep teal and red of the light palette sink into a dark card,
    // so dark mode uses their lighter counterparts.
    final accent = switch (widget.kind) {
      ToastKind.info || ToastKind.success =>
        isDark ? colorScheme.tertiary : colorScheme.primary,
      ToastKind.error => isDark
          ? Color.lerp(colorScheme.error, Colors.white, 0.45)!
          : colorScheme.error,
    };
    final icon = switch (widget.kind) {
      ToastKind.info => Icons.info_outline_rounded,
      ToastKind.success => Icons.check_circle_rounded,
      ToastKind.error => Icons.error_outline_rounded,
    };
    final actionLabel = widget.actionLabel;
    final bottomInset =
        MediaQuery.viewInsetsOf(context).bottom +
        MediaQuery.viewPaddingOf(context).bottom;

    final card = DecoratedBox(
      decoration: BoxDecoration(
        color: isDark ? colorScheme.surfaceContainerHighest : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: isDark ? 0.35 : 0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.10),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsetsDirectional.only(
          start: 12,
          end: actionLabel == null ? 16 : 8,
          top: 10,
          bottom: 10,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                widget.message,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurface,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.35,
                ),
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(width: 8),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: accent,
                  minimumSize: const Size(0, 36),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  textStyle: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onPressed: () {
                  _dismiss();
                  widget.onAction?.call();
                },
                child: Text(actionLabel),
              ),
            ],
          ],
        ),
      ),
    );

    return IgnorePointer(
      ignoring: actionLabel == null,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, bottomInset + 40),
          child: FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: _slide,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 480),
                child: Semantics(liveRegion: true, child: card),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
