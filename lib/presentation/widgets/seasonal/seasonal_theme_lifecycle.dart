import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../cubits/seasonal_theme_cubit.dart';

/// Re-checks the seasonal theme each time the app comes back to the
/// foreground, so a season starts and ends without a restart.
class SeasonalThemeLifecycle extends StatefulWidget {
  final Widget child;

  const SeasonalThemeLifecycle({super.key, required this.child});

  @override
  State<SeasonalThemeLifecycle> createState() => _SeasonalThemeLifecycleState();
}

class _SeasonalThemeLifecycleState extends State<SeasonalThemeLifecycle> {
  late final AppLifecycleListener _listener;

  @override
  void initState() {
    super.initState();
    _listener = AppLifecycleListener(
      onResume: () {
        if (mounted) {
          context.read<SeasonalThemeCubit>().onAppResumed();
        }
      },
    );
  }

  @override
  void dispose() {
    _listener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
