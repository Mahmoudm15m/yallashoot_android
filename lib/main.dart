import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:yallashoot/screens/home_screen.dart';
import 'package:yallashoot/screens/lives_screen.dart';
import 'package:yallashoot/screens/news_screen.dart';
import 'package:yallashoot/screens/ranks_screen.dart';
import 'package:yallashoot/screens/transfares.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en', '');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = true;

  void _toggleDarkMode(bool value) {
    setState(() {
      _isDarkMode = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('en'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('en'),
      ],
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
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
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const RanksScreen(),
    const NewsScreen(),
    const TransfaresScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Syria Live'),
      ),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'الاعدادات',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            SwitchListTile(
              title: const Text('تفعيل الوضع الداكن'),
              value: widget.isDarkMode,
              onChanged: widget.toggleDarkMode,
              secondary: const Icon(Icons.dark_mode),
            ),
            IconButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return LivesScreen();
                  })) ;
                },
                icon: Row(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 10),
                      child: Icon(Icons.live_tv),
                    ),
                    SizedBox(width: 20,),
                    Text("البث المتاح" , style: TextStyle(
                      fontSize: 18
                    ),),
                  ],
                )
            )
          ],
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white
            : Colors.black, // لون العنصر المحدد بناءً على الثيم
        unselectedItemColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.grey[400]
            : Colors.grey[800], // لون العناصر غير المحددة بناءً على الثيم
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'الرئيسية',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.leaderboard),
            label: 'الترتيب',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.newspaper),
            label: 'الأخبار',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compare_arrows),
            label: 'الانتقالات',
          ),
        ],
      ),
    );
  }
}