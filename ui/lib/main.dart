import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'routes/app_routes.dart';
import 'services/api_service.dart';
import 'l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService.initializeFromStorage();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static void setLocale(BuildContext context, Locale newLocale) {
    _MyAppState? state = context.findAncestorStateOfType<_MyAppState>();
    state?.changeLocale(newLocale);
  }

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  Locale _locale = const Locale('en');

  @override
  void initState() {
    super.initState();
    _loadSavedLanguage();
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    String? langCode = prefs.getString('selected_lang_code');

    if (langCode == 'mr_IN') {
      _locale = const Locale('mr');
    }
    else if (langCode == 'hi_IN') {
      _locale = const Locale('hi');
    }
    else {
      _locale = const Locale('en');
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'AgriAssist',

      locale: _locale,

      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('mr'),
      ],

      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      initialRoute: AppRoutes.splash,
      routes: AppRoutes.routes,
    );
  }
}