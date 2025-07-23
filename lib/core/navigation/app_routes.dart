import 'package:flutter/material.dart';

import 'package:wolof_quran/presentation/views/home_page.dart';
import 'package:wolof_quran/presentation/views/settings_page.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return _materialRoute(view: HomePage(), settings: settings);
      case '/settings':
        return _materialRoute(view: SettingsPage(), settings: settings);

      default:
        return _errorRoute(settings);
    }
  }

  static Route<dynamic> _materialRoute({
    required Widget view,
    required RouteSettings settings,
  }) {
    return MaterialPageRoute(settings: settings, builder: (_) => view);
  }

  static Route<dynamic> _errorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (_) {
        return Scaffold(
          appBar: AppBar(title: const Text("Error")),
          body: const Center(child: Text("Error page")),
        );
      },
    );
  }
}
