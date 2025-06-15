import 'package:flutter/material.dart';
import 'package:sticky_headers/sticky_headers/widget.dart';
import 'package:yallashoot/screens/league_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class TeamScreen extends StatefulWidget {
  final String teamID;
  final String lang ;
  const TeamScreen({Key? key, required this.teamID, required this.lang}) : super(key: key);

  @override
  State<TeamScreen> createState() => _TeamScreenState();
}

class _TeamScreenState extends State<TeamScreen> {
  late final ApiData api ;
  late Future<Map<String, dynamic>> futureInfo;
  late Future<Map<String, dynamic>> futureMatches;

  @override
  void initState() {
    super.initState();
    api = ApiData();
    futureInfo =
        api.getTeamInfo(widget.teamID).then((v) => v as Map<String, dynamic>);
    futureMatches =
        api.getTeamMatches(widget.teamID).then((v) => v as Map<String, dynamic>);
  }


  Map<String, List<dynamic>> groupByPhase(List<dynamic> list, String key) {
    final Map<String, List<dynamic>> grouped = {};
    for (var item in list) {
      final phase = item[key]?.toString() ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!;
      grouped.putIfAbsent(phase, () => []).add(item);
    }
    return grouped;
  }

  Widget buildMatchesSection(
      BuildContext context, String title, List<dynamic> games) {
    // ثيم التطبيق الحالي
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // ألوان متكيّفة مع الوضع
    final Color headerBg   = isDark ? Colors.grey.shade800 : Colors.grey.shade200;
    final Color headerText = isDark ? Colors.white         : Colors.black87;

    final grouped = groupByPhase(games, 'round');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
        ),

        // كل مجموعة مباريات حسب الجولة
        ...grouped.entries.map((entry) {
          return StickyHeader(
            header: Container(
              width: double.infinity,
              color: headerBg,   // خلفية ديناميّة
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: headerText,  // نص ديناميّ
                  ),
                ),
              ),
            ),

            // محتوى المباريات في هذه الجولة
            content: Column(
              children: entry.value.map<Widget>((game) {
                final home = game['home_team'] as Map<String, dynamic>;
                final away = game['away_team'] as Map<String, dynamic>;
                final date = game['match_date'] as String? ?? '';
                final time = game['match_time'] as String? ?? '';

                final homeImg =
                    'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/${home['image'] ?? ''}';
                final awayImg =
                    'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/${away['image'] ?? ''}';

                final champ = game['championship'] as Map<String, dynamic>?;
                final champTitle =
                champ != null ? (champ['title'] as String? ?? '') : '';

                return Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width * 0.9),
                    child: Card(
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      child: ListTile(
                        leading: Image.network(homeImg, width: 30, height: 30),
                        title: Text(
                          '${home['title'] ?? ''} vs ${away['title'] ?? ''}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              '$date  $time',
                              style: const TextStyle(fontSize: 12),
                            ),
                            const SizedBox(height: 6),
                            if (champTitle.isNotEmpty)
                              Text(
                                champTitle,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                          ],
                        ),
                        trailing: Image.network(awayImg, width: 30, height: 30),
                        isThreeLine: true,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    // ألوان ديناميّة
    final Color selectedColor =
    isDark ? Colors.white : theme.colorScheme.primary;
    final Color unselectedColor =
    isDark ? Colors.white70 : theme.colorScheme.onSurface.withOpacity(.7);
    final Color indicatorColor = theme.colorScheme.primary;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(appStrings[Localizations.localeOf(context).languageCode]!["team_info"]!,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          bottom: TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: appStrings[Localizations.localeOf(context).languageCode]!["about_team"]!),
              Tab(icon: Icon(Icons.event_note), text: appStrings[Localizations.localeOf(context).languageCode]!["matches"]!),
            ],
            indicatorColor: indicatorColor,
            indicatorWeight: 4,
            labelColor: selectedColor,
            unselectedLabelColor: unselectedColor,
            labelStyle:
            const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            unselectedLabelStyle:
            const TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
          ),
        ),
        body: TabBarView(
          children: [
            FutureBuilder<Map<String, dynamic>>(
              future: futureInfo,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError ||
                    snap.data == null ||
                    snap.data!['data'] == null) {
                  return Center(child: Text(
                    appStrings[Localizations.localeOf(context).languageCode]!["error"]!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ));
                }
                final info = snap.data!['data'] as Map<String, dynamic>;
                final about = info['about'] as String? ?? '';
                final imgHex = info['image'] as String? ?? '';
                final imgUrl =
                    'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/$imgHex';
                final country = info['country'] as Map<String, dynamic>?;
                final stadium = info['stadium_name'] as String? ?? '';
                final champs = List<Map<String, dynamic>>.from(
                    info['championships'] as List<dynamic>? ?? []);
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircleAvatar(
                          backgroundImage: NetworkImage(imgUrl), radius: 50),
                      const SizedBox(height: 20),
                      Text(about,
                          style: const TextStyle(fontSize: 14),
                          textAlign: TextAlign.center),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_on, size: 16),
                          const SizedBox(width: 4),
                          Text(country?['title'] ?? '',
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 20),
                          const Icon(Icons.stadium, size: 16),
                          const SizedBox(width: 4),
                          Text(stadium,
                              style: const TextStyle(fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Align(
                        alignment: Alignment.center,
                        child: Text(appStrings[Localizations.localeOf(context).languageCode]!["championships"]!,
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 10),
                      Center(
                        child: SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: champs.length,
                            itemBuilder: (context, i) {
                              final c = champs[i];
                              final n = c['title'] as String? ?? '';
                              final img = c['image'] as String? ?? '';
                              final url =
                                  'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/championship/64/$img';
                              return Container(
                                margin:
                                const EdgeInsets.symmetric(horizontal: 6),
                                child: IconButton(
                                  onPressed: (){
                                    Navigator.push(context, MaterialPageRoute(builder: (context){
                                      final Locale currentLocale = Localizations.localeOf(context);
                                      return LeagueScreen(id: c["url_id"].toString(), lang: currentLocale.languageCode,);
                                    }));
                                  },
                                  icon: Column(
                                    children: [
                                      Expanded(
                                          child: Container(
                                            color: Colors.grey,
                                            child: Image.network(url,
                                                fit: BoxFit.contain),
                                          )),
                                      Text(n,
                                          style: const TextStyle(fontSize: 12)),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            FutureBuilder<Map<String, dynamic>>(
              future: futureMatches,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError ||
                    snap.data == null ||
                    snap.data!['data'] == null) {
                  return Center(child: Text(
                    appStrings[Localizations.localeOf(context).languageCode]!["error"]!,
                    style: const TextStyle(fontSize: 16, color: Colors.red),
                  ));
                }
                final data = snap.data!['data'] as Map<String, dynamic>;
                final coming =
                List<dynamic>.from(data['coming']?['data'] as List? ?? []);
                final ended =
                List<dynamic>.from(data['end']?['data'] as List? ?? []);
                return SingleChildScrollView(
                  child: Column(
                    children: [
                      buildMatchesSection(context, appStrings[Localizations.localeOf(context).languageCode]!["next_round"]!, coming),
                      const Divider(height: 1, thickness: 1),
                      buildMatchesSection(context, appStrings[Localizations.localeOf(context).languageCode]!["finished_round"]!, ended),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
