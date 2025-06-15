import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:yallashoot/screens/player_screen.dart';
import 'package:yallashoot/screens/team_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';


class _TabInfo {
  final Tab tab;
  final Widget content;
  _TabInfo({required this.tab, required this.content});
}

class LeagueScreen extends StatefulWidget {
  final String id;
  final String lang;
  const LeagueScreen({Key? key, required this.id, required this.lang}) : super(key: key);

  @override
  State<LeagueScreen> createState() => _LeagueScreenState();
}

class _LeagueScreenState extends State<LeagueScreen> {
  late final ApiData api ;
  bool _isLoading = true;
  List<_TabInfo> _tabs = [];

  @override
  void initState() {
    super.initState();
    api = ApiData();
    _loadAllData();
  }

  Future<void> _loadAllData() async {

    final results = await Future.wait([
      api.getChampionMatches(widget.id).catchError((_) => null),
      _fetchRanksData().catchError((_) => null),
      api.getChampionScorers(widget.id).catchError((_) => null),
      api.getChampionAssists(widget.id).catchError((_) => null),
    ]);

    final matchesData = results[0] as Map<String, dynamic>?;
    final ranksData = results[1] as Map<String, dynamic>?;
    final scorersData = results[2] as Map<String, dynamic>?;
    final assistsData = results[3] as Map<String, dynamic>?;

    _buildTabs(matchesData, ranksData, scorersData, assistsData);

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<Map<String, dynamic>?> _fetchRanksData() async {
    try {
      final champRes = await api.getChampionStanding(widget.id) as Map<String, dynamic>;
      final leagueList = champRes['data']?['league'] as List<dynamic>?;

      final onlyColors = leagueList != null && leagueList.isNotEmpty && leagueList.first.keys.length == 1 && leagueList.first.containsKey('color');

      if (onlyColors) {
        final cupRes = await api.getCupStanding(widget.id) as Map<String, dynamic>;
        final groups = cupRes['data']?['standings']?['groups'] as Map<String, dynamic>?;
        if (groups == null || groups.isEmpty) {
          return await api.getChampionGroups(widget.id) as Map<String, dynamic>;
        }
        return cupRes;
      }
      return champRes;
    } catch (_) {
      return await api.getChampionGroups(widget.id) as Map<String, dynamic>;
    }
  }

  void _buildTabs(
      Map<String, dynamic>? matches,
      Map<String, dynamic>? ranks,
      Map<String, dynamic>? scorers,
      Map<String, dynamic>? assists,
      ) {
    final List<_TabInfo> availableTabs = [];


    final matchesContent = matches?['data'];
    if (matchesContent != null &&
        ((matchesContent['coming']?['data'] as List?)?.isNotEmpty == true ||
            (matchesContent['end']?['data'] as List?)?.isNotEmpty == true)) {
      availableTabs.add(_TabInfo(
        tab: Tab(text: appStrings[Localizations.localeOf(context).languageCode]!["matches"]!),
        content: buildMatchesTab(matchesContent),
      ));
    }


    final ranksContent = ranks?['data'];
    if (ranksContent != null) {
      final bool hasLeague = (ranksContent['league'] as List?)?.isNotEmpty == true;
      final bool hasGroups = (ranksContent['groups'] as Map?)?.isNotEmpty == true;
      final bool hasStandings = (ranksContent['standings']?['groups'] as Map?)?.isNotEmpty == true;
      if (hasLeague || hasGroups || hasStandings) {
        availableTabs.add(_TabInfo(
          tab: Tab(text: appStrings[Localizations.localeOf(context).languageCode]!["ranks"]!),
          content: buildRankingTab(ranksContent),
        ));
      }
    }


    final scorersContent = scorers?['data'];
    if (scorersContent != null && (scorersContent['scorers'] as List?)?.isNotEmpty == true) {
      availableTabs.add(_TabInfo(
        tab: Tab(text: appStrings[Localizations.localeOf(context).languageCode]!["top_scorers"]!),
        content: buildScorersTab(scorersContent),
      ));
    }


    final assistsContent = assists?['data'] as List?;
    if (assistsContent != null && assistsContent.isNotEmpty) {
      availableTabs.add(_TabInfo(
        tab: Tab(text: appStrings[Localizations.localeOf(context).languageCode]!["top_assists"]!),
        content: buildAssistsTab(assistsContent),
      ));
    }

    _tabs = availableTabs;
  }


  Map<String, List<dynamic>> groupGamesByRound(List<dynamic> games) {
    final Map<String, List<dynamic>> grouped = {};
    for (var game in games) {
      final round = game['round'] as String? ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown_round"]!;
      grouped.putIfAbsent(round, () => []).add(game);
    }
    return grouped;
  }

  Widget buildStickyGamesSection(String title, Map<String, List<dynamic>> grouped) {
    if (grouped.isEmpty) return const SizedBox.shrink();
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
              alignment: Alignment.centerRight,
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
                    leading: Image.network(homeImg, width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.shield)),
                    trailing: Image.network(awayImg, width: 40, height: 40, errorBuilder: (_,__,___) => const Icon(Icons.shield)),
                    onTap: () {

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
        buildStickyGamesSection(appStrings[Localizations.localeOf(context).languageCode]!["next_round"]!, groupGamesByRound(coming)),
        const Divider(),
        buildStickyGamesSection(appStrings[Localizations.localeOf(context).languageCode]!["finished_round"]!, groupGamesByRound(ended)),
      ],
    );
  }


  Widget _buildHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
    final leagueList = data['league'] as List?;
    final groupsMap = data['groups'] as Map?;
    final standingsGroups = data['standings']?['groups'] as Map?;

    if (groupsMap != null && groupsMap.isNotEmpty) {

      return _buildGroupsUi(groupsMap);
    }

    if (standingsGroups != null && standingsGroups.isNotEmpty) {

      return _buildGroupsUi(standingsGroups);
    }

    if (leagueList != null && leagueList.isNotEmpty) {

      return _buildLeagueUi(leagueList);
    }

    return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!));
  }

  Widget _buildLeagueUi(List<dynamic> leagueList) {

    return LayoutBuilder(
      builder: (context, constraints) {
        final unitWidth = constraints.maxWidth / 12;
        final header = Container(
          height: 50, color: Colors.blueGrey,
          child: Row(children: [
            _buildHeaderCell(appStrings[Localizations.localeOf(context).languageCode]!["ra"]!, width: unitWidth),
            _buildHeaderCell(appStrings[Localizations.localeOf(context).languageCode]!["team"]!, width: unitWidth * 3),
            for (var title in [appStrings[Localizations.localeOf(context).languageCode]!["played"]!, appStrings[Localizations.localeOf(context).languageCode]!["won"]!, appStrings[Localizations.localeOf(context).languageCode]!["draw"]!, appStrings[Localizations.localeOf(context).languageCode]!["lost"]!, appStrings[Localizations.localeOf(context).languageCode]!["goals"]!,appStrings[Localizations.localeOf(context).languageCode]!["diff"]!, appStrings[Localizations.localeOf(context).languageCode]!["points"]!])
              _buildHeaderCell(title, width: unitWidth),
          ]),
        );

        final rows = leagueList.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final imgUrl = 'https://imgs.ysscores.com/teams/64/${item['team_name']['image']}';
          final Locale currentLocale = Localizations.localeOf(context);
          return Container(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
            child: Row(children: [
              _buildCell((index + 1).toString(), width: unitWidth),
              InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamScreen(teamID: item["team_id"].toString(), lang: currentLocale.languageCode,))),
                child: Container(
                  width: unitWidth * 3, padding: const EdgeInsets.all(8.0),
                  child: Row(children: [
                    CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 12),
                    const SizedBox(width: 8),
                    Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(item['team_name']['title']))),
                  ]),
                ),
              ),
              for (var key in ['play', 'wins', 'draw', 'lose', 'for', 'diff', 'points'])
                _buildCell(item[key].toString(), width: unitWidth),
            ]),
          );
        }).toList();

        return SingleChildScrollView(child: Column(children: [header, ...rows]));
      },
    );
  }

  Widget _buildGroupsUi(Map<dynamic, dynamic> groupsMap) {
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
              Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold))),
              LayoutBuilder(
                builder: (context, constraints) {
                  final unitWidth = constraints.maxWidth / 12;
                  return Column(
                    children: [
                      Container(
                        height: 50, color: Colors.blueGrey,
                        child: Row(children: [
                          _buildHeaderCell(appStrings[Localizations.localeOf(context).languageCode]!["ra"]!, width: unitWidth),
                          _buildHeaderCell(appStrings[Localizations.localeOf(context).languageCode]!["team"]!, width: unitWidth * 3),
                          for (var title in [appStrings[Localizations.localeOf(context).languageCode]!["played"]!, appStrings[Localizations.localeOf(context).languageCode]!["won"]!, appStrings[Localizations.localeOf(context).languageCode]!["draw"]!, appStrings[Localizations.localeOf(context).languageCode]!["lost"]!, appStrings[Localizations.localeOf(context).languageCode]!["goals"]!,appStrings[Localizations.localeOf(context).languageCode]!["diff"]!, appStrings[Localizations.localeOf(context).languageCode]!["points"]!])
                            _buildHeaderCell(title, width: unitWidth),
                        ]),
                      ),
                      ...teams.asMap().entries.map((e) {
                        final idx = e.key;
                        final item = e.value as Map<String, dynamic>;
                        final imgHex = item['team_name']?['image'] ?? '';
                        final imgUrl = 'https://imgs.ysscores.com/teams/64/$imgHex';
                        final teamTitle = item['team_name']?['title'] ?? '';
                        final Locale currentLocale = Localizations.localeOf(context);
                        return Container(
                          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                          child: Row(children: [
                            _buildCell('${idx + 1}', width: unitWidth),
                            InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeamScreen(teamID: item["team_id"].toString(), lang: currentLocale.languageCode,))),
                              child: Container(
                                width: unitWidth * 3, padding: const EdgeInsets.all(8.0),
                                child: Row(children: [
                                  CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 12),
                                  const SizedBox(width: 8),
                                  Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text(teamTitle))),
                                ]),
                              ),
                            ),
                            for (var key in ['play', 'wins', 'draw', 'lose', 'for', 'diff', 'points'])
                              _buildCell(item[key].toString(), width: unitWidth),
                          ]),
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


  Widget buildScorersTab(Map<String, dynamic> data) {
    final scorers = data['scorers'] as List<dynamic>;
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: scorers.length,
      itemBuilder: (context, index) {
        final sc = scorers[index] as Map<String, dynamic>;
        final player = sc['player_info'] as Map<String, dynamic>;
        final imageUrl = 'https://imgs.ysscores.com/player/150/${player['image']}';
        final Locale currentLocale = Localizations.localeOf(context);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(playerId: sc["player_id"].toString(), lang: currentLocale.languageCode,))),
            leading: CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 20),
            title: Text(player['title']),
            subtitle: Text(player['team_name']),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('${appStrings[Localizations.localeOf(context).languageCode]!["goals"]!}: ${sc['goals']}'),
                if ((sc['score_penalty'] as int? ?? 0) > 0)
                  Text('${appStrings[Localizations.localeOf(context).languageCode]!["pk"]!}: ${sc['score_penalty']}'),
              ],
            ),
          ),
        );
      },
    );
  }


  Widget buildAssistsTab(List<dynamic> assists) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: assists.length,
      itemBuilder: (context, index) {
        final a = assists[index] as Map<String, dynamic>;
        final player = a['player_info'] as Map<String, dynamic>;
        final imageUrl = 'https://imgs.ysscores.com/player/150/${player['image']}';
        final Locale currentLocale = Localizations.localeOf(context);
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PlayerScreen(playerId: a["player_id"].toString(), lang: currentLocale.languageCode,))),
            leading: CircleAvatar(backgroundImage: NetworkImage(imageUrl), radius: 20),
            title: Text(player['title']),
            subtitle: Text(player['team_name']),
            trailing: Text('${appStrings[Localizations.localeOf(context).languageCode]!["assists"]!}: ${a['assist']}'),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text(appStrings[Localizations.localeOf(context).languageCode]!["league"]!)),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_tabs.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(appStrings[Localizations.localeOf(context).languageCode]!["league"]!)),
        body: Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!)),
      );
    }

    return DefaultTabController(
      length: _tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(appStrings[Localizations.localeOf(context).languageCode]!["league"]!),
          bottom: TabBar(
            isScrollable: true,
            tabs: _tabs.map((t) => t.tab).toList(),
          ),
        ),
        body: TabBarView(
          children: _tabs.map((t) => t.content).toList(),
        ),
      ),
    );
  }
}