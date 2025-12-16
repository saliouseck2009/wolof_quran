import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String hintText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final VoidCallback? onClear;
  final VoidCallback? onSearch;
  final bool isInAppBar;
  final bool hasActiveFilter;
  final TextInputAction textInputAction;

  const AppSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onClear,
    this.onSearch,
    this.isInAppBar = false,
    this.hasActiveFilter = false,
    this.textInputAction = TextInputAction.search,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final showClear = value.text.isNotEmpty || hasActiveFilter;

        return Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(12)),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            onChanged: onChanged,
            onSubmitted: onSubmitted,
            textInputAction: textInputAction,
            maxLines: 1,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            decoration: InputDecoration(
              hintText: hintText,
              hintStyle: TextStyle(
                color: isDark
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.6)
                    : colorScheme.onSurfaceVariant,
              ),

              suffixIcon: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showClear)
                    IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: isDark
                            ? colorScheme.error
                            : colorScheme.onSurfaceVariant,
                      ),
                      onPressed: onClear,
                    ),
                  if (value.text.isNotEmpty)
                    IconButton(
                      icon: Icon(Icons.search, color: colorScheme.primary),
                      onPressed: onSearch,
                    ),
                ],
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 16,
                vertical: isInAppBar ? 6 : 8,
              ),
              filled: true,
              fillColor: isDark
                  ? colorScheme.surfaceContainer
                  : colorScheme.onPrimary,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        );
      },
    );
  }
}
