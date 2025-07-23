import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:wolof_quran/service_locator.dart';

import 'core/navigation/app_routes.dart';
import 'core/config/theme/theme.dart';
import 'core/config/localization/localization_service.dart';
import 'presentation/cubits/language_cubit.dart';
import 'l10n/generated/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting("fr_FR");
  await setupDependencies();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => LanguageCubit(),
      child: BlocBuilder<LanguageCubit, Locale>(
        builder: (context, locale) {
          return MaterialApp(
            title: 'Wolof Quran',
            debugShowCheckedModeBanner: false,

            // Localization setup
            locale: locale,
            supportedLocales: LocalizationService.supportedLocales,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Theme setup
            theme: MaterialTheme().light(),
            darkTheme: MaterialTheme().dark(),
            themeMode: ThemeMode.system,

            onGenerateRoute: AppRoutes.onGenerateRoutes,
          );
        },
      ),
    );
  }
}
