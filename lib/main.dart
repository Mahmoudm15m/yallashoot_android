import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:media_kit/media_kit.dart';
import 'package:seo_renderer/renderers/text_renderer/text_renderer_vm.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:yallashoot/screens/home_screen.dart';
import 'package:yallashoot/screens/htm_widget.dart';
import 'package:yallashoot/screens/news_screen.dart';
import 'package:yallashoot/screens/ranks_screen.dart';
import 'package:yallashoot/screens/settings_screen.dart';
import 'api/main_api.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  await initializeDateFormatting('en', '');
  final prefs = await SharedPreferences.getInstance();
  final isDarkMode = prefs.getBool('isDarkMode') ?? false;
  runApp(MyApp(initialDarkMode: isDarkMode));
}

class MyApp extends StatefulWidget {
  final bool initialDarkMode;
  const MyApp({
    super.key,
    required this.initialDarkMode,
  });

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;
  ApiData apiData = ApiData();
  Map<String, dynamic>? adsData;
  Timer? _adsRefreshTimer;

  @override
  void initState() {
    super.initState();
    _isDarkMode = widget.initialDarkMode;
    fetchAds();
    startAdsAutoRefresh();
  }

  void startAdsAutoRefresh() {
    _adsRefreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchAds();
    });
  }

  @override
  void dispose() {
    _adsRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAds() async {
    try {
      final data = await apiData.getAds();
      setState(() {
        adsData = data;
      });
    } catch (e) {
      // ممكن تضيف لوج هنا لو حبيت
    }
  }

  Future<void> _toggleDarkMode(bool v) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', v);
    setState(() => _isDarkMode = v);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en'), Locale('ar')],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: MainScreen(
        isDarkMode: _isDarkMode,
        toggleDarkMode: _toggleDarkMode,
        adsData: adsData,
      ),
    );
  }
}


class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleDarkMode;
  final Map<String, dynamic>? adsData;

  const MainScreen({
    Key? key,
    required this.isDarkMode,
    required this.toggleDarkMode,
    required this.adsData,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final encodedHtml = widget.adsData?['ads']?['under_screen'];
    String? decodedHtml;

    if (encodedHtml != null) {
      try {
        decodedHtml = utf8.decode(base64.decode(encodedHtml));
      } catch (e) {
        decodedHtml = null;
      }
    }

    if (isMobile) {
      final screens = <Widget>[
        const HomeScreen(),
        const RanksScreen(),
        const NewsScreen(),
        SettingsScreen(
          isDarkMode: widget.isDarkMode,
          onThemeChanged: widget.toggleDarkMode,
        ),
      ];

      return Scaffold(
        body: screens[_selectedIndex],
        bottomNavigationBar: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (decodedHtml != null)
              HtmlWidget(
                width: 320,
                height: 100,
                htmlContent: decodedHtml,
              ),
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedItemColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[800],
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'مباريات اليوم'),
                BottomNavigationBarItem(icon: Icon(Icons.leaderboard), label: 'الترتيب'),
                BottomNavigationBarItem(icon: Icon(Icons.newspaper), label: 'الأخبار'),
                BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'الإعدادات'),
              ],
            ),
          ],
        ),
      );
    } else {
      return DefaultTabController(
        length: 4,
        initialIndex: _selectedIndex,
        child: Scaffold(
          appBar: AppBar(
            title: TextRenderer(
              child: Text('سوريا لايف'),
            ),
            actions: [
              IconButton(
                icon: Icon(widget.isDarkMode ? Icons.dark_mode : Icons.light_mode),
                onPressed: () => widget.toggleDarkMode(!widget.isDarkMode),
              ),
            ],
            bottom: TabBar(
              tabs: [
                Tab(text: 'مباريات اليوم'),
                Tab(text: 'الترتيب'),
                Tab(text: 'الأخبار'),
                Tab(text: 'الإعدادات'),
              ],
            ),
          ),
          body: Column(
            children: [
              Expanded(
                child: TabBarView(
                  children: [
                    const HomeScreen(),
                    const RanksScreen(),
                    const NewsScreen(),
                    SettingsScreen(
                      isDarkMode: widget.isDarkMode,
                      onThemeChanged: widget.toggleDarkMode,
                    ),
                  ],
                ),
              ),
              if (decodedHtml != null)
                HtmlWidget(
                  width: MediaQuery.of(context).size.width,
                  height: 100,
                  htmlContent: decodedHtml,
                ),
            ],
          ),
        ),
      );
    }
  }
}
