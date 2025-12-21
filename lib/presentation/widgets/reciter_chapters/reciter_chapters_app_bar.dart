import 'package:flutter/material.dart';

import '../../../domain/entities/reciter.dart';

class ReciterChaptersAppBar extends StatelessWidget {
  final Reciter reciter;
  final Color accentColor;

  const ReciterChaptersAppBar({
    super.key,
    required this.reciter,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = colorScheme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: isDark
          ? colorScheme.surfaceContainer
          : accentColor,
      iconTheme: IconThemeData(
        color: colorScheme.onPrimary,
      ),
      surfaceTintColor: Colors.transparent,
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.4)
          : accentColor.withValues(alpha: 0.3),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          reciter.name,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: colorScheme.onPrimary,
          ),
        ),
        titlePadding: const EdgeInsetsDirectional.only(
          start: 16,
          bottom: 12,
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [
                      colorScheme.surfaceContainer,
                      colorScheme.surface,
                    ]
                  : [accentColor.withValues(alpha: 0.85), accentColor],
            ),
          ),
          child: Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.person,
                size: 40,
                color: colorScheme.onPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
