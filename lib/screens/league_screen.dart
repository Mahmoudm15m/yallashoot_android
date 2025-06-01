import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:yallashoot/screens/player_screen.dart';
import 'package:yallashoot/screens/team_screen.dart';
import '../api/main_api.dart';
import 'htm_widget.dart';
import 'match_details.dart';

class LeagueScreen extends StatefulWidget {
  final String id;
  const LeagueScreen({Key? key, required this.id}) : super(key: key);

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late Future<Map<String, dynamic>> futureMatches;
  late Future<Map<String, dynamic>> futureRanks;
  late Future<Map<String, dynamic>> futureScorers;
  late Future<Map<String, dynamic>> futureAssists;
  final ApiData api = ApiData();
  Map<String, dynamic>? adsData;
  String? decodedHtml;

  String? decodeBase64Ad(String? encoded) {
    if (encoded == null) return null;
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    // Fetch matches
    futureMatches = api
        .getChampionMatches(widget.id)
        .then((v) => v as Map<String, dynamic>);

    // Fetch standings (handles cup vs league)
    futureRanks = (() async {
      final champRes = await api.getChampionStanding(widget.id) as Map<String, dynamic>;
      final leagueList = champRes['data']['league'] as List<dynamic>;
      final onlyColors = leagueList.isNotEmpty
          && leagueList.first.keys.length == 1
          && leagueList.first.containsKey('color');
      if (onlyColors) {
        return await api.getCupStanding(widget.id) as Map<String, dynamic>;
      }
      return champRes;
    })();

    // Fetch top scorers
    futureScorers = api
        .getChampionScorers(widget.id)
        .then((v) => v as Map<String, dynamic>);

    // Fetch top assisters
    futureAssists = api
        .getChampionAssists(widget.id)
        .then((v) => v as Map<String, dynamic>);

    fetchAdData();
  }

  Future<void> fetchAdData() async {
    try {
      final data = await api.getAds();
      final encoded = data['ads']?['above_table'];
      setState(() {
        adsData = data;
        decodedHtml = decodeBase64Ad(encoded);
      });
    } catch (_) {
      // ممكن تسجل الخطأ لو حبيت
    }
  }

  // --- Matches tab helpers ---
  Map<String, List<dynamic>> groupGamesByRound(List<dynamic> games) {
    final Map<String, List<dynamic>> grouped = {};
    for (var game in games) {
      final round = game['round'] as String;
      grouped.putIfAbsent(round, () => []).add(game);
    }
    return grouped;
  }

  Widget buildStickyGamesSection(String title, Map<String, List<dynamic>> grouped) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ),
        ...grouped.entries.map((entry) {
          return StickyHeader(
            header: Container(
              height: 50,
              color: Colors.blueGrey,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.centerLeft,
              child: Text(
                entry.key,
                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            content: Column(
              children: entry.value.map<Widget>((game) {
                final homeImg = 'https://imgs.ysscores.com/teams/64/${game['home_team']['image']}';
                final awayImg = 'https://imgs.ysscores.com/teams/64/${game['away_team']['image']}';
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ListTile(
                    title: Center(child: Text('${game['home_team']['title']} vs ${game['away_team']['title']}')),
                    subtitle: Center(child: Text('${game['match_date']} - ${game['match_time'] ?? ''}')),
                    leading: Image.network(
                      "https://api.syria-live.fun/img_proxy?url=$homeImg",
                      width: 40, height: 40,
                    ),
                    trailing: Image.network(
                      "https://api.syria-live.fun/img_proxy?url=$awayImg",
                      width: 40, height: 40,
                    ),
                    onTap: () {
                      final id = game['match_id'].toString();
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

  Widget buildMatchesTab(Map<String, dynamic> data) {
    final coming = data['coming']['data'] as List<dynamic>;
    final ended = data['end']['data'] as List<dynamic>;
    return ListView(
      padding: const EdgeInsets.all(8),
      children: [
        buildStickyGamesSection('القادمة', groupGamesByRound(coming)),
        const Divider(),
        buildStickyGamesSection('المنتهية', groupGamesByRound(ended)),
      ],
    );
  }

  // --- Ranking tab helpers ---
  Widget _buildHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: FittedBox(                 // ← هنا السحر
        fit: BoxFit.scaleDown,          // يصغر الخط لحد ما يلاقي مساحة
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
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

  Widget buildRankingTab(Map<String, dynamic> data) {

    // Cup standing UI
    if (data.containsKey('standings')) {
      final standings = data['standings'] as Map<String, dynamic>;
      final groupsMap = Map<String, dynamic>.from(standings['groups'] as Map);

      return SingleChildScrollView(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupsMap.entries.map((groupEntry) {
            final groupName = groupEntry.key;
            final teams = groupEntry.value as List<dynamic>;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    groupName,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    const totalFlex = 12;
                    final unitWidth = constraints.maxWidth / totalFlex;
                    return Column(
                      children: [
                        Container(
                          height: 50,
                          color: Colors.blueGrey,
                          child: Row(children: [
                            _buildHeaderCell('مركز', width: unitWidth),
                            _buildHeaderCell('الفريق', width: unitWidth * 3),
                            for (var title in ['لعب', 'فوز', 'تعادل', 'خسارة', 'له', 'عليه', 'فرق', 'نقاط'])
                              _buildHeaderCell(title, width: unitWidth),
                          ]),
                        ),
                        ...teams.asMap().entries.map((e) {
                          final idx = e.key;
                          final item = e.value as Map<String, dynamic>;
                          final imgHex = (item['team_name']?['image'] ?? item['teamA']?['image']) as String;
                          final imgUrl =
                              'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/$imgHex';
                          return Container(
                            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                            child: Row(
                              children: [
                                _buildCell('${idx + 1}', width: unitWidth),
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context){
                                      return TeamScreen(teamID: item["team_id"].toString());
                                    }));
                                  },
                                  icon: Container(
                                    width: unitWidth * 3,
                                    padding: const EdgeInsets.all(8.0),
                                    child: Row(
                                      children: [
                                        CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 12),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: FittedBox(
                                            fit: BoxFit.scaleDown,
                                            alignment: Alignment.centerLeft,
                                            child: Text(
                                              (item['team_name']?['title'] ?? item['teamA']?['title']) as String,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                for (var key in ['play', 'wins', 'draw', 'lose', 'for', 'against', 'diff', 'points'])
                                  _buildCell(item[key].toString(), width: unitWidth),
                              ],
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ],
            );
          }).toList(),
        ),
      );
    }

    // --- Champion league standing UI ---
    final leagueList = List<Map<String, dynamic>>.from(data['league'] as List);
    leagueList.sort((a, b) {
      final p1 = a['points'] as int;
      final p2 = b['points'] as int;
      if (p2 != p1) return p2.compareTo(p1);
      final d1 = a['diff'] as int;
      final d2 = b['diff'] as int;
      if (d2 != d1) return d2.compareTo(d1);
      return (b['wins'] as int).compareTo(a['wins'] as int);
    });

    return LayoutBuilder(
      builder: (context, constraints) {
        const totalFlex = 12;
        final unitWidth = constraints.maxWidth / totalFlex;

        final header = Container(
          height: 50,
          color: Colors.blueGrey,
          child: Row(children: [
            _buildHeaderCell('مركز', width: unitWidth),
            _buildHeaderCell('الفريق', width: unitWidth * 3),
            for (var title in ['لعب', 'فوز', 'تعادل', 'خسارة', 'له', 'عليه', 'فرق', 'نقاط'])
              _buildHeaderCell(title, width: unitWidth),
          ]),
        );

        final rows = leagueList.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final position = index + 1;
          final imgHex = item['team_name']['image'] as String;
          final imgUrl =
              'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/$imgHex';

          return Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: Row(
              children: [
                _buildCell(position.toString(), width: unitWidth),
                Container(
                  width: unitWidth * 3,
                  padding: const EdgeInsets.all(8.0),
                  child: IconButton(
                    onPressed: (){
                      Navigator.push(context, MaterialPageRoute(builder: (context){
                        return TeamScreen(teamID: item["team_id"].toString());
                      }));
                    },
                    icon: Row(
                      children: [
                        CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 12),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(item['team_name']['title']),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (var key in ['play', 'wins', 'draw', 'lose', 'for', 'against', 'diff', 'points'])
                  _buildCell(item[key].toString(), width: unitWidth),
              ],
            ),
          );
        }).toList();

        return SingleChildScrollView(
          child: Column(children: [header, ...rows]),
        );
      },
    );
  }

  // --- Scorers tab helper ---
  Widget buildScorersTab(Map<String, dynamic> data) {
    final scorers = data['scorers'] as List<dynamic>;
    if (scorers.isEmpty) {
      return const Center(child: Text('لا يوجد هدافون'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: scorers.length,
      itemBuilder: (context, index) {
        final sc = scorers[index] as Map<String, dynamic>;
        final player = sc['player_info'] as Map<String, dynamic>;
        final imageHex = player['image'] as String;
        final imageUrl =
            'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/player/150/$imageHex';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context){
                return PlayerScreen(playerId: sc["player_id"].toString());
              }));
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 20,
            ),
            title: Text(player['title']),
            subtitle: Text(player['team_name']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('أهداف: ${sc['goals']}'),
                if ((sc['score_penalty'] as int) > 0 || (sc['miss_penalty'] as int) > 0)
                  Text('ركلات جزاء: ${sc['score_penalty']}/${(sc['score_penalty'] as int) + (sc['miss_penalty'] as int)}'),
              ],
            ),
          ),
        );
      },
    );
  }

  // --- Assists tab helper ---
  Widget buildAssistsTab(List<dynamic> assists) {
    if (assists.isEmpty) {
      return const Center(child: Text('لا يوجد صناع لعب'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: assists.length,
      itemBuilder: (context, index) {
        final a = assists[index] as Map<String, dynamic>;
        final player = a['player_info'] as Map<String, dynamic>;
        final imageHex = player['image'] as String;
        final imageUrl =
            'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/player/150/$imageHex';
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context){
                return PlayerScreen(playerId: a["player_id"].toString());
              }));
            },
            leading: CircleAvatar(
              backgroundImage: NetworkImage(imageUrl),
              radius: 20,
            ),
            title: Text(player['title']),
            subtitle: Text(player['team_name']),
            trailing: Text('صناعات: ${a['assist']}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الدوري'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'المباريات'),
              Tab(text: 'الترتيب'),
              Tab(text: 'الهدافون'),
              Tab(text: 'صناع اللعب'),
            ],
          ),
        ),
        body: Column(
          children: [
            if (decodedHtml != null)
              HtmlWidget(
                width: MediaQuery.of(context).size.width,
                height: 100,
                htmlContent: decodedHtml!,
              ),
            Expanded(
              child: TabBarView(
                children: [
                  FutureBuilder<Map<String, dynamic>>(
                    future: futureMatches,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError || snap.data == null) {
                        return const Center(child: Text('خطأ في جلب المباريات'));
                      }
                      return buildMatchesTab(snap.data!['data'] as Map<String, dynamic>);
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: futureRanks,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError || snap.data == null) {
                        return const Center(child: Text('خطأ في جلب الترتيب'));
                      }
                      return buildRankingTab(snap.data!['data'] as Map<String, dynamic>);
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: futureScorers,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError || snap.data == null) {
                        return const Center(child: Text('خطأ في جلب الهدافون'));
                      }
                      return buildScorersTab(snap.data!['data'] as Map<String, dynamic>);
                    },
                  ),
                  FutureBuilder<Map<String, dynamic>>(
                    future: futureAssists,
                    builder: (context, snap) {
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snap.hasError || snap.data == null) {
                        return const Center(child: Text('خطأ في جلب صناع اللعب'));
                      }
                      final assistsData = snap.data!['data'] as List<dynamic>;
                      return buildAssistsTab(assistsData);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
