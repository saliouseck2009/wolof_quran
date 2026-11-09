import 'package:flutter/material.dart';

import '../../utils/home_card_colors.dart';

/// Opens a settings bottom sheet: sized to its content, on the app
/// background with white cards, a drag handle and a left-aligned title.
/// It closes by dragging it down or tapping outside, so it has no close
/// cross.
Future<T?> showSettingsSheet<T>({
  required BuildContext context,
  required String title,
  String? subtitle,
  required WidgetBuilder builder,
}) {
  final navigationBarHeight = MediaQuery.viewPaddingOf(context).bottom;
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, navigationBarHeight + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SheetTitle(title: title, subtitle: subtitle),
          const SizedBox(height: 16),
          builder(sheetContext),
        ],
      ),
    ),
  );
}

class _SheetTitle extends StatelessWidget {
  final String title;
  final String? subtitle;

  const _SheetTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtitle = this.subtitle;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: colorScheme.onSurface,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: colorScheme.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// White card grouping the controls of a settings sheet.
class SettingsSheetCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const SettingsSheetCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: homeCardColor(Theme.of(context).colorScheme),
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Padding(padding: padding, child: child),
    );
  }
}
