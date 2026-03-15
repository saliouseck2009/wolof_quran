import 'package:flutter/material.dart';

import 'surah_mini_player_overlay.dart';

class GlobalMiniPlayerShell extends StatelessWidget {
  final Widget child;

  const GlobalMiniPlayerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(child: child),
        const Material(
          type: MaterialType.transparency,
          child: SurahMiniPlayerOverlay(),
        ),
      ],
    );
  }
}
