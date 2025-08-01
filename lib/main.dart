import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal[800]!, brightness: Brightness.dark),
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


  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  void initState() {
    super.initState();
    fetchUpdates();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      width = MediaQuery.of(context).size.width.toInt();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchUpdates() async {
    const int currentVersion = 13;
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
                  IconButton(
                  onPressed: () async {
                      final url = data['link'] as String?;
                      if (url != null) {
                        await launchUrl(
                          Uri.parse(url),
                          mode: LaunchMode.externalApplication,
                        );
                      }
                    },
                    icon: Container(
                      decoration: BoxDecoration(
                          color: Colors.blueGrey,
                          borderRadius: BorderRadius.circular(20)),
                      alignment: Alignment.center,
                      child: TextButton(
                        onPressed: () async {
                          final url = data['link'] as String?;
                          if (url != null) {
                            await launchUrl(
                              Uri.parse(url),
                              mode: LaunchMode.externalApplication,
                            );
                          }
                        },
                        child: const Text(
                          'تحديث الآن',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
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
          BottomNavigationBarItem(icon: const Icon(Icons.home), label: appStrings[currentLocale.languageCode]?["today_matches"]),
          BottomNavigationBarItem(icon: const Icon(Icons.leaderboard), label: appStrings[currentLocale.languageCode]?["ranks"]),
          BottomNavigationBarItem(icon: const Icon(Icons.newspaper), label: appStrings[currentLocale.languageCode]?["news"]),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: appStrings[currentLocale.languageCode]?["settings"]),
        ],
      ),
    );
  }
}