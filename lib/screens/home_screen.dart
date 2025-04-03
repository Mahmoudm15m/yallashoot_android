import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yallashoot/api/main_api.dart';
import 'package:yallashoot/screens/match_details.dart';
import '../functions/base_functions.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> futureResults;
  ApiData yasScore = ApiData();
  Timer? _timer;
  DateTime? _dataFetchTime;
  late AnimationController _pulseController;

  DateTime selectedDate = DateTime.now();

  Future<Map<String, dynamic>> fetchMatchesForDate(DateTime date) async {
    try {
      String formattedDate = DateFormat('yyyy-MM-dd').format(date);
      final data = await yasScore.getMatchesData(formattedDate);
      _dataFetchTime = DateTime.now();
      return data;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    futureResults = fetchMatchesForDate(selectedDate);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  Widget buildLoadingScreen() {
    return Center(
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[500]!,
        child: Container(
          width: double.infinity,
          height: 80, // قللت الارتفاع هنا
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8), // قللت نصف القطر
          ),
        ),
      ),
    );
  }

  Widget buildDateSelector() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey.shade400),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: const TextStyle(
                        fontSize: 14,
                        fontFamily: 'Cairo',
                        color: Colors.black,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () async {
              DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                locale: const Locale('ar'),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                  futureResults = fetchMatchesForDate(selectedDate);
                });
              }
            },
            icon: const Icon(Icons.edit, size: 18),
            label: const Text("تغيير", style: TextStyle(fontSize: 14)),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildMatchCard(Map<String, dynamic> match) {
    final league = match['league'];
    final teams = match['teams'];
    final fixture = match['fixture'];
    final score = match['score'];

    bool isLive = (fixture['status']['long'] != null && fixture['status']['long'] == "Live") ||
        (fixture['status']['short'] != null &&
            fixture['status']['short'].toString().toUpperCase() == "LIVE");

    // قيمة الدقائق الأولية من API
    int initialElapsed = 0;
    if (isLive && fixture['status']['elapsed'] != null) {
      initialElapsed = int.tryParse(fixture['status']['elapsed'].toString()) ?? 0;
    }

    // حساب الوقت الحالي بدقائق وثواني
    int displayedMinutes;
    int displayedSeconds;
    double progressValue;
    if (isLive && _dataFetchTime != null) {
      final elapsed = DateTime.now().difference(_dataFetchTime!);
      int totalElapsedSeconds = initialElapsed * 60 + elapsed.inSeconds;
      displayedMinutes = totalElapsedSeconds ~/ 60;
      displayedSeconds = totalElapsedSeconds % 60;
      progressValue = (totalElapsedSeconds / (90 * 60)).clamp(0.0, 1.0);
    } else {
      displayedMinutes = initialElapsed;
      displayedSeconds = 0;
      progressValue = (initialElapsed / 90).clamp(0.0, 1.0);
    }

    const textStyle = TextStyle(fontSize: 14, fontFamily: 'Cairo');
    const smallTextStyle = TextStyle(fontSize: 12, fontFamily: 'Cairo', fontWeight: FontWeight.bold);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: IconButton(
        padding: EdgeInsets.zero,
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            return MatchDetails(id: match["id"]);
          }));
        },
        icon: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        if (teams['home']['logo'] != null)
                          Image.network(
                            teams['home']['logo'],
                            width: 30, // تصغير حجم اللوجو
                            height: 30,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          teams['home']['name'] ?? '',
                          style: textStyle,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 50,
                    child: Center(
                      child: isLive
                          ? Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 40,
                            height: 40,
                            child: CircularProgressIndicator(
                              value: progressValue,
                              strokeWidth: 4,
                              backgroundColor: Colors.grey[300],
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
                            ),
                          ),
                          Text(
                            "$displayedMinutes:${displayedSeconds.toString().padLeft(2, '0')}",
                            style: smallTextStyle.copyWith(color: Colors.lightGreen),
                          ),
                          Positioned(
                            bottom: 4,
                            right: 16,
                            child: AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                double scale = 1.0 + _pulseController.value * 0.5;
                                return Transform.scale(
                                  scale: scale,
                                  child: child,
                                );
                              },
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                          : Column(
                        children: [
                          Text(
                            formatTime(fixture['time'] ?? ''),
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            fixture['status']["long"] ?? '',
                            style: textStyle,
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        if (teams['away']['logo'] != null)
                          Image.network(
                            teams['away']['logo'],
                            width: 30,
                            height: 30,
                          ),
                        const SizedBox(height: 2),
                        Text(
                          teams['away']['name'] ?? '',
                          style: textStyle,
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              if (score['home'] != null && score['away'] != null)
                Center(
                  child: Text(
                    "${score['home']} - ${score['away']}",
                    style: smallTextStyle,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            futureResults = fetchMatchesForDate(selectedDate);
          });
          await futureResults;
        },
        child: FutureBuilder(
          future: futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List.generate(
                  5,
                      (index) => Column(
                    children: [
                      buildLoadingScreen(),
                      if (index < 4) const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            } else if (snapshot.hasError ||
                !snapshot.hasData ||
                (snapshot.data!['matches'] == null) ||
                (snapshot.data!['matches'] as List).isEmpty) {
              return const Center(
                child: Text(
                  'لا توجد بيانات متاحة.',
                  style: TextStyle(color: Colors.red, fontSize: 16),
                ),
              );
            }
            final matches = snapshot.data!['matches'] as List;

            Map<String, List<dynamic>> groupedMatches = {};
            for (var match in matches) {
              String leagueId = match['league']['id'];
              if (groupedMatches.containsKey(leagueId)) {
                groupedMatches[leagueId]!.add(match);
              } else {
                groupedMatches[leagueId] = [match];
              }
            }

            List<Widget> leagueSections = [];
            groupedMatches.forEach((leagueId, matchList) {
              var league = matchList.first['league'];
              leagueSections.add(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          print(leagueId);
                        },
                        icon: Text(
                          league['name'] ?? '',
                          style: const TextStyle(
                            fontSize: 16,
                            fontFamily: 'Cairo',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      if (league['logo'] != null)
                        Image.network(
                          league['logo'],
                          width: 24,
                          height: 24,
                        ),
                    ],
                  ),
                ),
              );
              for (var match in matchList) {
                leagueSections.add(buildMatchCard(match));
              }
            });

            return ListView(
              children: [
                buildDateSelector(),
                ...leagueSections,
              ],
            );
          },
        ),
      ),
    );
  }
}
