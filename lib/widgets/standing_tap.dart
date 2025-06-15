import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api/main_api.dart';
import '../screens/team_screen.dart';
import '../strings/languages.dart';

class StandingsTab extends StatefulWidget {
  final String leagueId;
  final String lang ;
  const StandingsTab({
    Key? key,
    required this.leagueId, required this.lang,
  }) : super(key: key);

  @override
  _StandingsTabState createState() => _StandingsTabState();
}

class _StandingsTabState extends State<StandingsTab> {
  late Future<Map<String, dynamic>> futureRanks;
  late final ApiData yasScore ;

  @override
  void initState() {
    super.initState();
    yasScore = ApiData();
    futureRanks = _fetchStandingsData();
  }

  Future<Map<String, dynamic>> _fetchStandingsData() async {
    try {
      final champRes = await yasScore.getChampionStanding(widget.leagueId) as Map<String, dynamic>;
      if (champRes.containsKey('data') && champRes['data']['league'] is List) {
        final leagueList = champRes['data']['league'] as List<dynamic>;
        final onlyColors = leagueList.isNotEmpty && leagueList.first.keys.length == 1 && leagueList.first.containsKey('color');
        if (onlyColors) {
          final cupRes = await yasScore.getCupStanding(widget.leagueId) as Map<String, dynamic>;
          final standings = cupRes['data']?['standings'] as Map<String, dynamic>?;
          final groups = standings?['groups'] as Map<String, dynamic>?;
          if (groups == null || groups.isEmpty) {
            return await yasScore.getChampionGroups(widget.leagueId) as Map<String, dynamic>;
          }
          return cupRes;
        }
      }
      return champRes;
    } catch (_) {
      return await yasScore.getChampionGroups(widget.leagueId) as Map<String, dynamic>;
    }
  }

  // --- دوال بناء الواجهة الأصلية (بدون تغيير) ---

  Widget _buildHeaderCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(text, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
      ),
    );
  }

  Widget _buildCell(String text, {required double width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(8.0),
      alignment: Alignment.center,
      child: Text(text, style: const TextStyle(fontFamily: 'Cairo')),
    );
  }

  Widget _noDataWidget() {
    return Center(
      child: Text(appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!, style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
    );
  }

  Widget _buildGroupsStandings(Map<String, dynamic> data) {
    final groupsMap = Map<String, dynamic>.from(data['groups'] as Map);
    if (groupsMap.isEmpty) return _noDataWidget();
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
                child: Text(groupName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, fontFamily: 'Cairo')),
              ),
              LayoutBuilder(builder: (context, constraints) {
                const totalFlex = 12;
                final unitWidth = constraints.maxWidth / totalFlex;
                return Column(
                  children: [
                    Container(
                      height: 50,
                      color: Colors.blueGrey,
                      child: Row(
                        children: [
                          _buildHeaderCell(appStrings[Localizations.localeOf(context).languageCode]!["ra"]!, width: unitWidth),
                          _buildHeaderCell(appStrings[Localizations.localeOf(context).languageCode]!["team"]!, width: unitWidth * 3),
                          for (var title in [appStrings[Localizations.localeOf(context).languageCode]!["played"]!, appStrings[Localizations.localeOf(context).languageCode]!["won"]!, appStrings[Localizations.localeOf(context).languageCode]!["draw"]!, appStrings[Localizations.localeOf(context).languageCode]!["lost"]!, appStrings[Localizations.localeOf(context).languageCode]!["goals"]!,appStrings[Localizations.localeOf(context).languageCode]!["diff"]!, appStrings[Localizations.localeOf(context).languageCode]!["points"]!])
                            _buildHeaderCell(title, width: unitWidth),
                        ],
                      ),
                    ),
                    ...teams.asMap().entries.map((e) {
                      final idx = e.key;
                      final item = e.value as Map<String, dynamic>;
                      final imgHex = (item['team_name']?['image'] ?? item['teamA']?['image'] ?? '') as String;
                      final imgUrl = 'https://imgs.ysscores.com/teams/64/$imgHex';
                      final Locale currentLocale = Localizations.localeOf(context);
                      return Container(
                        decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
                        child: Row(children: [
                          _buildCell('${idx + 1}', width: unitWidth),
                          Container(
                            width: unitWidth * 3,
                            padding: const EdgeInsets.all(8.0),
                            child: InkWell(
                              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeamScreen(teamID: item["team_id"].toString(), lang: currentLocale.languageCode,))),
                              child: Row(children: [
                                CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 12, backgroundColor: Colors.transparent),
                                const SizedBox(width: 8),
                                Expanded(child: FittedBox(fit: BoxFit.scaleDown, alignment: Alignment.centerRight, child: Text((item['team_name']?['title'] ?? item['teamA']?['title'] ?? '') as String))),
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
              }),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLeagueStandings(Map<String, dynamic> data) {
    final leagueList = List<Map<String, dynamic>>.from(data['league'] as List);
    if (leagueList.isEmpty || (leagueList.length == 1 && leagueList.first.containsKey('color'))) {
      return _noDataWidget();
    }
    leagueList.sort((a, b) {
      final p1 = a['points'] as int;
      final p2 = b['points'] as int;
      if (p2 != p1) return p2.compareTo(p1);
      final d1 = a['diff'] as int;
      final d2 = b['diff'] as int;
      if (d2 != d1) return d2.compareTo(d1);
      return (b['wins'] as int).compareTo(a['wins'] as int);
    });
    return LayoutBuilder(builder: (context, constraints) {
      const totalFlex = 12;
      final unitWidth = constraints.maxWidth / totalFlex;
      final header = Container(
        height: 50,
        color: Colors.blueGrey,
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
        final position = index + 1;
        final imgHex = item['team_name']['image'] as String;
        final imgUrl = 'https://imgs.ysscores.com/teams/64/$imgHex';
        final Locale currentLocale = Localizations.localeOf(context);
        return Container(
          decoration: BoxDecoration(border: Border(bottom: BorderSide(color: Colors.grey.shade300))),
          child: Row(children: [
            _buildCell(position.toString(), width: unitWidth),
            Container(
              width: unitWidth * 3,
              padding: const EdgeInsets.all(8.0),
              child: InkWell(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TeamScreen(teamID: item["team_id"].toString(), lang: currentLocale.languageCode,))),
                child: Row(children: [
                  CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 12, backgroundColor: Colors.transparent),
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
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: futureRanks,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // --- واجهة الشيمر تبدأ هنا ---
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final baseColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
          final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;
          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: _buildShimmerLayout(),
          );
          // --- واجهة الشيمر تنتهي هنا ---
        }

        if (snapshot.hasError || !snapshot.hasData || snapshot.data == null) {
          return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!, style: TextStyle(fontFamily: 'Cairo', color: Colors.red)));
        }

        final data = snapshot.data!['data'] as Map<String, dynamic>?;
        if (data == null) return _noDataWidget();
        if (data.containsKey('groups')) return _buildGroupsStandings(data);
        if (data.containsKey('standings') && data['standings'] is Map && (data['standings'] as Map).containsKey('groups')) {
          return _buildGroupsStandings(data['standings']);
        }
        if (data.containsKey('league')) return _buildLeagueStandings(data);
        return _noDataWidget();
      },
    );
  }

  Widget _buildShimmerLayout() {
    final shimmerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // محاكاة عنوان المجموعة
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              height: 24,
              width: 180,
              decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
            ),
          ),
          // محاكاة جدول الترتيب
          LayoutBuilder(
            builder: (context, constraints) {
              const totalFlex = 12;
              final unitWidth = constraints.maxWidth / totalFlex;

              // محاكاة رأس الجدول
              final header = Container(
                height: 50,
                color: shimmerColor,
              );

              // محاكاة صفوف الجدول
              final rows = List.generate(15, (index) {
                return Container(
                  height: 48,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: shimmerColor.withOpacity(0.5))),
                  ),
                  child: Row(
                    children: [
                      // محاكاة خلية الترتيب
                      SizedBox(width: unitWidth, child: Padding(padding: const EdgeInsets.all(14.0), child: CircleAvatar(backgroundColor: shimmerColor))),
                      // محاكاة خلية الفريق
                      Container(
                        width: unitWidth * 3,
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            CircleAvatar(radius: 12, backgroundColor: shimmerColor),
                            const SizedBox(width: 8),
                            Expanded(child: Container(height: 14, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)))),
                          ],
                        ),
                      ),
                      // محاكاة خلايا الإحصائيات
                      ...List.generate(8, (_) => Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 17),
                        child: Container(decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                      ))),
                    ],
                  ),
                );
              });

              return Column(children: [header, ...rows]);
            },
          ),
        ],
      ),
    );
  }
}