import 'package:flutter/widgets.dart';

/// Width classes of the Material 3 window size system.
///
/// A class describes the space the app window offers, never the device:
/// an iPad in Split View is [compact], a phone in landscape is [medium].
enum WindowSizeClass {
  /// Below 600: phones in portrait. The layouts are the original ones.
  compact,

  /// From 600 to 840: small tablets, tablets in portrait.
  medium,

  /// 840 and above: tablets in landscape, large tablets.
  expanded;

  /// The class of a space [width] logical pixels wide.
  static WindowSizeClass fromWidth(double width) {
    if (width < Breakpoints.medium) {
      return WindowSizeClass.compact;
    }
    if (width < Breakpoints.expanded) {
      return WindowSizeClass.medium;
    }
    return WindowSizeClass.expanded;
  }

  /// The class of the app window.
  static WindowSizeClass of(BuildContext context) =>
      fromWidth(MediaQuery.sizeOf(context).width);

  bool get isCompact => this == WindowSizeClass.compact;

  /// Medium or expanded: there is room for more than one column.
  bool get isWide => this != WindowSizeClass.compact;
}

/// Widths at which the layouts change.
abstract final class Breakpoints {
  static const double medium = 600;
  static const double expanded = 840;
}

/// Widest a block of content grows before it is centred instead.
abstract final class ContentWidths {
  /// Running text: Quran verses, translations, policy pages.
  static const double reading = 760;

  /// Forms and settings lists.
  static const double form = 640;

  /// Pages made of cards and grids.
  static const double page = 1100;

  /// Bottom sheets and the floating audio player.
  static const double sheet = 640;
}

/// Horizontal margin between the window edge and the content.
///
/// [compact] is the margin the screen already uses on phones, so each
/// screen keeps its own phone spacing and only grows from there.
double pageMarginFor(double width, {double compact = 24}) {
  return switch (WindowSizeClass.fromWidth(width)) {
    WindowSizeClass.compact => compact,
    WindowSizeClass.medium => compact < 32 ? 32 : compact,
    WindowSizeClass.expanded => compact < 48 ? 48 : compact,
  };
}
