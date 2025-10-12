import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yallashoot/locator.dart';
import 'package:yallashoot/screens/home_screen.dart';
import 'package:yallashoot/screens/news_screen.dart';
import 'package:yallashoot/screens/ranks_screen.dart';
import 'package:yallashoot/screens/settings_screen.dart';
import 'package:yallashoot/settings_provider.dart';
import 'package:yallashoot/strings/languages.dart';
import 'api/main_api.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MobileAds.instance.initialize();
  final settingsProvider = SettingsProvider();
  await settingsProvider.init();
  setupLocator(settingsProvider);

  runApp(
    ChangeNotifierProvider.value(
      value: locator<SettingsProvider>(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsProvider = context.watch<SettingsProvider>();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: settingsProvider.locale,
      themeMode: settingsProvider.themeMode,
      navigatorObservers: [routeObserver],
      supportedLocales: const [
        Locale('en'),
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            // ignore: deprecated_member_use
            textScaleFactor: settingsProvider.fontScaleFactor,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: Colors.teal[800],
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.tealAccent,
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData.dark(useMaterial3: true).copyWith(
        primaryColor: Colors.teal[800],
        colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal[800]!, brightness: Brightness.dark),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  Timer? _retryTimer;
  int width = 500;

  final GlobalKey _settingsKey = GlobalKey();
  late TutorialCoachMark tutorialCoachMark;

  @override
  void initState() {
    super.initState();
    _createTutorial();
    fetchUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      width = MediaQuery.of(context).size.width.toInt();
      _checkFirstLaunch();
    });
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final isFirstLaunch = prefs.getBool('isFirstLaunch') ?? true;

    if (isFirstLaunch) {
      Future.delayed(const Duration(seconds: 1), () {
        tutorialCoachMark.show(context: context);
      });
      await prefs.setBool('isFirstLaunch', false);
    }
  }

  void _createTutorial() {
    tutorialCoachMark = TutorialCoachMark(
      targets: _createTargets(),
      colorShadow: Colors.teal,
      textSkip: "تخطي",
      paddingFocus: 10,
      opacityShadow: 0.8,
      onFinish: () {
        print("finish");
      },
      onClickTarget: (target) {
        print('onClickTarget: $target');
      },
      onClickOverlay: (target) {
        print('onClickOverlay: $target');
      },
    );
  }

  List<TargetFocus> _createTargets() {
    List<TargetFocus> targets = [];
    targets.add(
      TargetFocus(
        identify: "settings-key",
        keyTarget: _settingsKey,
        alignSkip: Alignment.topRight,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  "أهلاً بك في سوريا لايف",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20.0,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10.0),
                  child: Text(
                    "من هنا يمكنك تغيير حجم الخط ومظهر التطبيق واللغه ليناسبك.",
                    style: TextStyle(color: Colors.white),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
    return targets;
  }

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchUpdates() async {
    const int currentVersion = 16;
    try {
      final data = await locator<ApiData>().checkUpdate(currentVersion);
      if (data['ok'] == true && data['version'] > currentVersion) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final ctx = context;
          if (!ctx.mounted) return;
          showDialog(
            context: ctx,
            barrierDismissible: false,
            builder: (_) => WillPopScope(
              onWillPop: () async => false,
              child: AlertDialog(
                title: const Text('تحديث متوفر'),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('رقم الاصدار: ${data['version']}'),
                    const SizedBox(height: 8),
                    Text(data['changes'] ?? ''),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () async {
                      final url = data['link'] as String?;
                      if (url != null) {
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    child: const Text('تحديث الآن'),
                  ),
                ],
              ),
            ),
          );
        });
      }
    } catch (e) {
      debugPrint('Update check failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentLocale = Localizations.localeOf(context);

    final screens = <Widget>[
      HomeScreen(),
      RanksScreen(lang: currentLocale.languageCode),
      NewsScreen(lang: currentLocale.languageCode),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: appStrings[currentLocale.languageCode]?["today_matches"]),
          BottomNavigationBarItem(
              icon: const Icon(Icons.leaderboard),
              label: appStrings[currentLocale.languageCode]?["ranks"]),
          BottomNavigationBarItem(
              icon: const Icon(Icons.newspaper),
              label: appStrings[currentLocale.languageCode]?["news"]),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, key: _settingsKey),
            label: appStrings[currentLocale.languageCode]?["settings"],
          ),
        ],
      ),
    );
  }
}