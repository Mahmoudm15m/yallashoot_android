import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers.dart';
import 'package:yallashoot/screens/match_details.dart';
import '../api/main_api.dart';
import '../functions/base_functions.dart';
import 'news_details_screen.dart';

class LeagueScreen extends StatefulWidget {
  final String link;
  final String id;

  LeagueScreen({
    required this.link,
    required this.id,
  });

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late Future<Map<String, dynamic>> futureLeague;
  late Future<Map<String, dynamic>> futureLeagueRanks;
  ApiData yasScore = ApiData();

  Future<Map<String, dynamic>> fetchLeague() async {
    try {
      final data = await yasScore.getLeague(widget.link);
      return data;
    } catch (e) {
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchLeagueRanks() async {
    try {
      final data = await yasScore.getLeagueRanks(widget.id);
      return data;
    } catch (e) {
      return {};
    }
  }

  String extractMatchId(String url) {
    final regex = RegExp(r'/match/(\d+)/');
    final match = regex.firstMatch(url);
    if (match != null) {
      return match.group(1)!;
    } else {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    futureLeague = fetchLeague();
    futureLeagueRanks = fetchLeagueRanks();
  }

  Map<String, List<dynamic>> groupGamesByRound(List<dynamic> games) {
    final Map<String, List<dynamic>> grouped = {};
    for (var game in games) {
      String round = game['round'];
      if (grouped.containsKey(round)) {
        grouped[round]!.add(game);
      } else {
        grouped[round] = [game];
      }
    }
    return grouped;
  }

  Widget buildStickyGamesSection(String sectionTitle, Map<String, List<dynamic>> groupedGames) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            sectionTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        ...groupedGames.entries.map((entry) {
          return StickyHeader(
            header: Container(
              height: 50.0,
              color: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              alignment: Alignment.centerLeft,
              child: Text(
                entry.key,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            content: Column(
              children: entry.value.map<Widget>((game) {
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Center(child: Text('${game['home_team']} vs ${game['away_team']}')),
                    subtitle: Center(child: Text('${game['date']} - ${game['match_time'] ?? ""}')),
                    leading: Image.network(
                      game['home_image'],
                      width: 40,
                      height: 40,
                    ),
                    trailing: Image.network(
                      game['away_image'],
                      width: 40,
                      height: 40,
                    ),
                    onTap: () {
                      final String id = extractMatchId(game['match_link'].toString());
                      print(id);
                    },
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  // دوال مساعدة لبناء خلايا جدول الترتيب
  Widget _buildHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold , color: Colors.black)),
    );
  }

  Widget _buildCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: Text(text),
    );
  }

  // بناء جدول الترتيب مع الرأس الثابت للدوري العادي
  Widget buildRankingTable(List<MapEntry<String, dynamic>> rankingItems) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Stack(
        children: [
          // منطقة الصفوف القابلة للتمرير عموديًا (مع هامش علوي يساوي ارتفاع الرأس)
          Padding(
            padding: const EdgeInsets.only(top: 50.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: Column(
                children: rankingItems.map((entry) {
                  final rankKey = entry.key;
                  final team = entry.value;
                  final teamName = team['team_name']['title'];
                  final played = team['play'];
                  final wins = team['wins'];
                  final draws = team['draw'];
                  final loses = team['lose'];
                  final points = team['points'];
                  return Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: Colors.grey[300]!),
                      ),
                    ),
                    child: Row(
                      children: [
                        _buildCell(rankKey, width: 60),
                        Container(
                          width: 150,
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundImage: NetworkImage(team['team_name']['image'] ?? ''),
                                radius: 12,
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  teamName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        _buildCell('$played', width: 60),
                        _buildCell('$wins', width: 60),
                        _buildCell('$draws', width: 60),
                        _buildCell('$loses', width: 60),
                        _buildCell('$points', width: 60),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          // الصف الثابت (رؤوس الأعمدة)
          Container(
            height: 50.0,
            color: Colors.blueGrey,
            child: Row(
              children: [
                _buildHeaderCell('المركز', width: 60),
                _buildHeaderCell('الفريق', width: 150),
                _buildHeaderCell('لعب', width: 60),
                _buildHeaderCell('فوز', width: 60),
                _buildHeaderCell('تعادل', width: 60),
                _buildHeaderCell('خسارة', width: 60),
                _buildHeaderCell('نقاط', width: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // دالة لعرض الترتيب بناءً على نوع الدوري (دوري عادي أو كأس)
  Widget buildRankingView(Map<String, dynamic> ranksData) {
    if (ranksData['league_type'] == 'cup') {
      return buildCupView(ranksData);
    } else {
      final listMatch = ranksData['list_match'] as Map<String, dynamic>;
      final rankingItems = listMatch.entries.toList()
        ..sort((a, b) => int.parse(a.key).compareTo(int.parse(b.key)));
      return buildRankingTable(rankingItems);
    }
  }

  // دالة لبناء عرض مباريات الكأس باستخدام بيانات "cups_rounds"
  Widget buildCupView(Map<String, dynamic> ranksData) {
    final cupsRounds = ranksData['cups_rounds'] as Map<String, dynamic>;
    List<Widget> cupRoundsWidgets = [];

    cupsRounds.forEach((roundKey, matches) {
      cupRoundsWidgets.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Text(
            'الجولة: $roundKey',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
      );

      (matches as Map<String, dynamic>).forEach((matchKey, match) {
        cupRoundsWidgets.add(Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(
              '${match['teamA']['full_title']} vs ${match['teamB']['full_title']}',
            ),
            subtitle: Text(match['round']),
            leading: Image.network(
              match['teamA']['image'],
              width: 40,
              height: 40,
            ),
            trailing: Image.network(
              match['teamB']['image'],
              width: 40,
              height: 40,
            ),
            onTap: () {
              // منطق عند الضغط على المباراة
            },
          ),
        ));
      });
    });

    return ListView(
      padding: const EdgeInsets.all(8.0),
      children: cupRoundsWidgets,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدوري'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'الدوري والجولات'),
              Tab(text: 'جدول الترتيب'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // تبويب الدوري والجولات باستخدام Sticky Headers
            FutureBuilder<Map<String, dynamic>>(
              future: futureLeague,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد بيانات'));
                }
                final leagueData = snapshot.data!['league'] as Map<String, dynamic>;
                final upcomingGames = leagueData['upcoming games'] as List<dynamic>;
                final finishedGames = leagueData['finished games'] as List<dynamic>;
                final news = leagueData['news'] as List<dynamic>;

                final groupedUpcoming = groupGamesByRound(upcomingGames);
                final groupedFinished = groupGamesByRound(finishedGames);

                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    buildStickyGamesSection('الجولات القادمة', groupedUpcoming),
                    const Divider(),
                    buildStickyGamesSection('الجولات المنتهية', groupedFinished),
                    const Divider(),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.0),
                      child: Text(
                        'أخبار الدوري',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                    ),
                    ...news.map((newsItem) {
                      return Card(
                        child: ListTile(
                          title: Text(newsItem['title']),
                          leading: Image.network(
                            newsItem['image'],
                            width: 40,
                            height: 40,
                          ),
                          onTap: () {

                            Navigator.push(context, MaterialPageRoute(builder: (context){
                              return NewsDetailsScreen(id: extractIdFromUrl(newsItem['link']).toString(),
                                  img: newsItem["image"].toString().replaceAll("/150/", "/820/"));
                            }));
                          },
                        ),
                      );
                    }).toList(),
                  ],
                );
              },
            ),
            // تبويب جدول الترتيب مع التعامل مع كلا النموذجين (دوري أو كأس)
            FutureBuilder<Map<String, dynamic>>(
              future: futureLeagueRanks,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Center(child: Text('حدث خطأ أثناء جلب بيانات جدول الترتيب'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('لا توجد بيانات'));
                }
                final ranksData = snapshot.data!['ranks'] as Map<String, dynamic>;
                return buildRankingView(ranksData);
              },
            ),
          ],
        ),
      ),
    );
  }
}
