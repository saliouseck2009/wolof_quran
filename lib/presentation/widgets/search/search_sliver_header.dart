import 'package:flutter/material.dart';

import '../../../core/config/theme/app_color.dart';
import '../../../l10n/generated/app_localizations.dart';

class SearchSliverHeader extends StatelessWidget {
  const SearchSliverHeader({
    super.key,
    required this.expandedHeight,
    required this.collapsedToolbarHeight,
    required this.colorScheme,
    required this.localizations,
    required this.searchBarBuilder,
  });

  final double expandedHeight;
  final double collapsedToolbarHeight;
  final ColorScheme colorScheme;
  final AppLocalizations localizations;
  final Widget Function(bool isCollapsed) searchBarBuilder;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final topPadding = MediaQuery.of(context).padding.top;
        final collapseOffset =
            (expandedHeight - collapsedToolbarHeight - topPadding)
                .clamp(0.0, expandedHeight);
        final isCollapsed = constraints.scrollOffset > collapseOffset;

        return SliverAppBar(
          expandedHeight: expandedHeight,
          floating: false,
          pinned: true,
          elevation: 0,
          backgroundColor: colorScheme.brightness == Brightness.dark
              ? AppColor.surfaceDark
              : colorScheme.primary,
          iconTheme: IconThemeData(color: colorScheme.onPrimary),
          surfaceTintColor: Colors.transparent,
          shadowColor: colorScheme.shadow.withValues(alpha: 0.3),
          toolbarHeight: collapsedToolbarHeight,
          titleSpacing: isCollapsed ? 0 : null,
          title: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: isCollapsed
                ? Padding(
                    key: const ValueKey('search-collapsed'),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: searchBarBuilder(true),
                  )
                : Text(
                    localizations.explorer,
                    key: const ValueKey('search-title'),
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: colorScheme.onPrimary,
                      fontSize: 18,
                    ),
                  ),
          ),
          flexibleSpace: FlexibleSpaceBar(
            titlePadding: EdgeInsets.zero,
            background: Container(
              color: colorScheme.brightness == Brightness.dark
                  ? AppColor.surfaceDark
                  : colorScheme.primary,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 16,
                    bottom: 16,
                  ),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: isCollapsed
                        ? const SizedBox.shrink()
                        : searchBarBuilder(false),
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
