import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yallashoot/screens/home_screen.dart';
import 'package:yallashoot/screens/lives_screen.dart';
import 'package:yallashoot/screens/news_screen.dart';
import 'package:yallashoot/screens/ranks_screen.dart';
import 'package:yallashoot/screens/transfares.dart';
import 'ad_helper.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('en', '');
  await MobileAds.instance.initialize();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;
  void _toggleDarkMode(bool v) => setState(() => _isDarkMode = v);
  static const double _phoneWidth = 430;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      supportedLocales: const [Locale('en') , Locale('ar')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,

      builder: (context, child) {
        final screenWidth = MediaQuery.of(context).size.width;
        final targetWidth =
        screenWidth > _phoneWidth ? _phoneWidth : screenWidth;

        return Center(
          child: SizedBox(
            width: targetWidth,
            child: child,
          ),
        );
      },

      home: MainScreen(
        isDarkMode: _isDarkMode,
        toggleDarkMode: _toggleDarkMode,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final bool isDarkMode;
  final Function(bool) toggleDarkMode;

  const MainScreen({
    Key? key,
    required this.isDarkMode,
    required this.toggleDarkMode,
  }) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  BannerAd? _bannerAd;
  bool _isAdLoaded = false;
  bool _showLiveButton = false;
  static const double _phoneWidth = _MyAppState._phoneWidth;

  @override
  void initState() {
    super.initState();
    _checkLiveAvailability();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int screenWidth = MediaQuery.of(context).size.width.toInt();

      _bannerAd = AdHelper.loadAdaptiveBanner(
        width: screenWidth,
        onLoaded: (ad) {
          setState(() {
            _isAdLoaded = true;
            _bannerAd = ad;
          });
        },
        onPermanentFail: (e) => debugPrint(e.message),
      );
    });
  }

  Future<void> _checkLiveAvailability() async {
    try {
      final res = await http.get(
        Uri.parse('https://syria-live.fun/app.json'),
      );

      if (res.statusCode == 200) {
        final ok = jsonDecode(res.body)['ok'] as bool? ?? false;
        if (mounted) setState(() => _showLiveButton = ok);
      } else {
        debugPrint('API error: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('API exception: $e');
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RanksScreen(),
    NewsScreen(),
    TransfaresScreen(),
  ];

  void _onItemTapped(int index) => setState(() => _selectedIndex = index);

  double _bottomBarHeight() {
    final adHeight = (_isAdLoaded && _bannerAd != null)
        ? _bannerAd!.size.height.toDouble()
        : 0;
    return adHeight + kBottomNavigationBarHeight;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(title: const Text('Syria Live')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text('الاعدادات',
                  style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            SwitchListTile(
              title: const Text('تفعيل الوضع الداكن'),
              value: widget.isDarkMode,
              onChanged: widget.toggleDarkMode,
              secondary: const Icon(Icons.dark_mode),
            ),
            // if (_showLiveButton)
              ListTile(
                leading: const Icon(Icons.live_tv),
                title: const Text('البث المتاح', style: TextStyle(fontSize: 18)),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => LivesScreen()),
                ),
              ),
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: SizedBox(
        height: _bottomBarHeight(),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_bannerAd != null && _isAdLoaded)
              SizedBox(
                width: _bannerAd!.size.width.toDouble(),
                height: _bannerAd!.size.height.toDouble(),
                child: AdWidget(ad: _bannerAd!),
              ),
            BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              selectedItemColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black,
              unselectedItemColor:
              Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[400]
                  : Colors.grey[800],
              items: const [
                BottomNavigationBarItem(
                    icon: Icon(Icons.home), label: 'الرئيسية'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.leaderboard), label: 'الترتيب'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.newspaper), label: 'الأخبار'),
                BottomNavigationBarItem(
                    icon: Icon(Icons.compare_arrows), label: 'الانتقالات'),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
