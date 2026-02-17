import 'package:flutter/material.dart';

import 'package:wolof_quran/presentation/views/home_page.dart';
import 'package:wolof_quran/presentation/views/settings_page.dart';
import 'package:wolof_quran/presentation/views/surah_list_page.dart';
import 'package:wolof_quran/presentation/views/surah_detail_page.dart';
import 'package:wolof_quran/presentation/views/quran_settings_page.dart';
import 'package:wolof_quran/presentation/views/reciter_list_page.dart';
import 'package:wolof_quran/presentation/views/reciter_chapters_download_page.dart';
import 'package:wolof_quran/presentation/views/search_page.dart';
import 'package:wolof_quran/domain/entities/reciter.dart';
import 'package:wolof_quran/core/navigation/surah_detail_arguments.dart';

class AppRoutes {
  static Route onGenerateRoutes(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case '/':
        return _materialRoute(view: HomePage(), settings: settings);
      case '/settings':
        return _materialRoute(view: SettingsPage(), settings: settings);
      case '/surahs':
        return _materialRoute(view: SurahListPage(), settings: settings);
      case '/surah-detail':
        int surahNumber;
        int? initialAyahNumber;

        if (args is SurahDetailArguments) {
          surahNumber = args.surahNumber;
          initialAyahNumber = args.initialAyahNumber;
        } else if (args is int) {
          surahNumber = args;
        } else if (args is Map && args['surahNumber'] is int) {
          surahNumber = args['surahNumber'] as int;
          if (args['initialAyahNumber'] is int) {
            initialAyahNumber = args['initialAyahNumber'] as int;
          }
        } else {
          return _errorRoute(settings);
        }
        return _materialRoute(
          view: SurahDetailPage(
            surahNumber: surahNumber,
            initialAyahNumber: initialAyahNumber,
          ),
          settings: settings,
        );
      case '/quran-settings':
        return _materialRoute(view: QuranSettingsPage(), settings: settings);
      // case '/surah-audio-list':
      //   return _materialRoute(view: SurahAudioListPage(), settings: settings);
      case '/search':
        return _materialRoute(view: SearchPage(), settings: settings);
      case '/bookmarks':
        return _materialRoute(
          view: SearchPage(initialTab: 1),
          settings: settings,
        );
      case '/reciter-list':
        return _materialRoute(view: ReciterListPage(), settings: settings);
      case '/reciter-chapters':
        final reciter = args as Reciter;
        return _materialRoute(
          view: ReciterChaptersDownloadPage(reciter: reciter),
          settings: settings,
        );

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
