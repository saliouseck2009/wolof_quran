import 'package:flutter/material.dart';

import '../../utils/home_card_colors.dart';
import 'settings_menu_item.dart';

/// One entry of a [SettingsChoiceMenuItem] menu.
class SettingsChoice<T> {
  final T value;
  final String label;

  /// Shown muted at the end of the entry, e.g. the language name in the
  /// current app language.
  final String? secondary;
  final IconData? icon;

  const SettingsChoice({
    required this.value,
    required this.label,
    this.secondary,
    this.icon,
  });
}

/// Settings row that opens a small menu anchored under it, aligned on its
/// end edge, instead of a bottom sheet. Picking an entry applies it and
/// closes the menu.
class SettingsChoiceMenuItem<T> extends StatefulWidget {
  static const double menuWidth = 244;

  final IconData icon;
  final String title;
  final String subtitle;
  final String value;
  final List<SettingsChoice<T>> choices;
  final T selected;
  final ValueChanged<T> onSelected;

  /// Makes the menu as wide as the row, for long labels or many entries
  /// (a long menu scrolls).
  final bool fullWidthMenu;

  const SettingsChoiceMenuItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.choices,
    required this.selected,
    required this.onSelected,
    this.fullWidthMenu = false,
  });

  @override
  State<SettingsChoiceMenuItem<T>> createState() =>
      _SettingsChoiceMenuItemState<T>();
}

class _SettingsChoiceMenuItemState<T> extends State<SettingsChoiceMenuItem<T>> {
  bool _isOpen = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => _buildAnchor(
        context,
        widget.fullWidthMenu
            ? constraints.maxWidth
            : SettingsChoiceMenuItem.menuWidth,
      ),
    );
  }

  Widget _buildAnchor(BuildContext context, double width) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return MenuAnchor(
      // The menu keeps the exact width below instead of shrinking to its
      // entries.
      crossAxisUnconstrained: false,
      onOpen: () => setState(() => _isOpen = true),
      onClose: () => setState(() => _isOpen = false),
      style: MenuStyle(
        backgroundColor: WidgetStatePropertyAll(
          isDark ? colorScheme.surfaceContainerHigh : Colors.white,
        ),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        elevation: const WidgetStatePropertyAll(8),
        shadowColor: WidgetStatePropertyAll(
          Colors.black.withValues(alpha: isDark ? 0.5 : 0.25),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        padding: const WidgetStatePropertyAll(EdgeInsets.all(6)),
        minimumSize: WidgetStatePropertyAll(Size(width, 0)),
        maximumSize: WidgetStatePropertyAll(Size(width, double.infinity)),
      ),
      menuChildren: [
        for (final choice in widget.choices)
          _ChoiceButton<T>(
            choice: choice,
            isSelected: choice.value == widget.selected,
            onPressed: () => widget.onSelected(choice.value),
          ),
      ],
      builder: (context, controller, _) => Builder(
        builder: (rowContext) => SettingsMenuItem(
          icon: widget.icon,
          title: widget.title,
          subtitle: widget.subtitle,
          value: widget.value,
          trailingIcon: Icons.keyboard_arrow_down_rounded,
          highlighted: _isOpen,
          onTap: () {
            if (controller.isOpen) {
              controller.close();
            } else {
              controller.open(position: _menuPosition(rowContext, width));
            }
          },
        ),
      ),
    );
  }

  /// Top-left corner of the menu, relative to the row: under its end edge
  /// (the right one, or the left one in right-to-left), overlapping it a
  /// little. The menu is still kept inside the screen.
  Offset _menuPosition(BuildContext rowContext, double menuWidth) {
    final row = (rowContext.findRenderObject()! as RenderBox).size;
    final isRtl = Directionality.of(rowContext) == TextDirection.rtl;
    return Offset(
      isRtl ? 0 : row.width - menuWidth,
      row.height - 12,
    );
  }
}

class _ChoiceButton<T> extends StatelessWidget {
  final SettingsChoice<T> choice;
  final bool isSelected;
  final VoidCallback onPressed;

  const _ChoiceButton({
    required this.choice,
    required this.isSelected,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final ink = homeAccentInk(colorScheme);
    final foreground = isSelected ? ink : colorScheme.onSurface;
    final secondary = choice.secondary;

    return MenuItemButton(
      onPressed: onPressed,
      // Lets a long label shrink and clip instead of overflowing the menu.
      overflowAxis: Axis.vertical,
      style: MenuItemButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: isSelected
            ? homeAccentColor(colorScheme).withValues(alpha: 0.12)
            : null,
        foregroundColor: foreground,
        iconColor: isSelected
            ? ink
            : colorScheme.onSurface.withValues(alpha: 0.7),
      ),
      leadingIcon: choice.icon == null ? null : Icon(choice.icon, size: 20),
      trailingIcon: secondary == null && !isSelected
          ? null
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (secondary != null)
                  Text(
                    secondary,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                if (secondary != null && isSelected) const SizedBox(width: 8),
                if (isSelected) Icon(Icons.check_rounded, size: 20, color: ink),
              ],
            ),
      child: Text(
        choice.label,
        style: TextStyle(
          fontSize: 15,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
    );
  }
}
