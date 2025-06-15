import 'package:flutter/material.dart';
import 'package:yallashoot/screens/team_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class PlayerScreen extends StatefulWidget {
  final String playerId;
  final String lang;
  const PlayerScreen({Key? key, required this.playerId, required this.lang}) : super(key: key);

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  late final ApiData api;
  late Future<Map<String, dynamic>> futurePlayer;

  @override
  void initState() {
    super.initState();
    api = ApiData();
    futurePlayer = api.getPlayerInfo(widget.playerId).then((v) => v as Map<String, dynamic>);
  }

  // ---------- helpers ----------
  Widget _infoChip(IconData icon, String label) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    );
  }

  // MODIFIED: Made the stat chip theme-aware
  Widget _statChip(BuildContext context, String label, dynamic value) {
    final theme = Theme.of(context);
    return Chip(
      label: Text(
        '$label: ${value ?? 0}',
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSecondaryContainer, // Adapts text color
        ),
      ),
      visualDensity: VisualDensity.compact,
      backgroundColor: theme.colorScheme.secondaryContainer, // Adapts background color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the current theme to use its colors
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return FutureBuilder<Map<String, dynamic>>(
      future: futurePlayer,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError || snap.data == null || snap.data!['data'] == null) {
          return Scaffold(body: Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!)));
        }

        // ------------- data -------------
        final data = snap.data!['data'] as Map<String, dynamic>;
        final cover = data['image_cover'] as String? ?? '';
        final coverUrl =
            'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/player/cover/$cover';
        final img = data['image'] as String? ?? '';
        final imgUrl =
            'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/player/150/$img';
        final name = data['title'] as String? ?? '';
        final position = data['position'] as String? ?? '';
        final number = data['club_number']?.toString() ?? '';
        final birth = data['birth_day'] as String? ?? '';
        final country = (data['country'] as Map<String, dynamic>?)?['title'] as String? ?? '';
        final height = data['height']?.toString() ?? '';
        final weight = data['weight']?.toString() ?? '';
        final foot = data['foot'] as String? ?? '';
        final teamMap = data['team_name'] as Map<String, dynamic>?;
        final teamName = teamMap?['title'] as String? ?? '';
        final teamImgHex = teamMap?['image'] as String? ?? '';
        final teamId = teamMap?['row_id']?.toString() ?? '';
        final teamImgUrl =
            'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/$teamImgHex';
        final stats = List<Map<String, dynamic>>.from(data['player_statistics'] as List<dynamic>? ?? []);
        final transfers = List<Map<String, dynamic>>.from(data['transfers'] as List<dynamic>? ?? []);

        // ------------ UI ------------
        return Scaffold(
          body: NestedScrollView(
            headerSliverBuilder: (context, _) {
              return [
                SliverAppBar(
                  backgroundColor: theme.primaryColor,
                  expandedHeight: 320,
                  pinned: true,
                  stretch: true,
                  elevation: 0,
                  title: Text(name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  centerTitle: true,
                  flexibleSpace: FlexibleSpaceBar(
                    collapseMode: CollapseMode.parallax,
                    background: Stack(
                      fit: StackFit.expand,
                      children: [
                        // ---- cover image ----
                        ClipRRect(
                          borderRadius:
                          const BorderRadius.vertical(bottom: Radius.circular(32)),
                          child: Image.network(
                            coverUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                          ),
                        ),
                        // ---- gradient overlay ----
                        Container(
                          decoration: const BoxDecoration(
                            borderRadius:
                            BorderRadius.vertical(bottom: Radius.circular(32)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                        // ---- player avatar inside cover ----
                        Positioned(
                          right: 16,
                          bottom: 24,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              // MODIFIED: Used theme color for the border
                              border: Border.all(color: theme.cardColor, width: 4),
                              boxShadow: const [
                                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
                              ],
                            ),
                            child: CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 60),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ];
            },
            body: ListView(
              padding: const EdgeInsets.only(top: 24),
              children: [
                const SizedBox(height: 8),
                Center(
                  child: Column(
                    children: [
                      Text(name, style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      // MODIFIED: Used theme text color
                      Text(
                        '#$number • $position',
                        style: textTheme.titleMedium?.copyWith(color: textTheme.bodySmall?.color),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // current team
                if (teamName.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) {
                        final Locale currentLocale = Localizations.localeOf(context);
                        return TeamScreen(
                          teamID: teamId,
                          lang: currentLocale.languageCode,
                        );
                      }));
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ClipOval(child: Image.network(teamImgUrl, width: 40, height: 40, fit: BoxFit.cover)),
                        const SizedBox(width: 8),
                        Text(teamName, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                const SizedBox(height: 20),
                // info chips
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    alignment: WrapAlignment.center,
                    children: [
                      if (birth.isNotEmpty) _infoChip(Icons.cake, birth),
                      if (country.isNotEmpty) _infoChip(Icons.flag, country),
                      if (height.isNotEmpty) _infoChip(Icons.height, '$height cm'),
                      if (weight.isNotEmpty) _infoChip(Icons.monitor_weight, '$weight kg'),
                      if (foot.isNotEmpty) _infoChip(Icons.sports, foot == 'L' ? appStrings[Localizations.localeOf(context).languageCode]!["left"]! : appStrings[Localizations.localeOf(context).languageCode]!["right"]!),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // stats
                if (stats.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appStrings[Localizations.localeOf(context).languageCode]!["season_statistics"]!, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...stats.map((st) {
                          final league = (st['league'] as Map<String, dynamic>?)?['title'] as String? ?? '';
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(league, style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 4,
                                    children: [
                                      // MODIFIED: Passed context to _statChip
                                      _statChip(context, appStrings[Localizations.localeOf(context).languageCode]!["matches"]!, st['appearances']),
                                      _statChip(context, appStrings[Localizations.localeOf(context).languageCode]!["goals"]!, st['goals']),
                                      _statChip(context, appStrings[Localizations.localeOf(context).languageCode]!["assists"]!, st['assist']),
                                      _statChip(context, appStrings[Localizations.localeOf(context).languageCode]!["yellow_cards"]!, st['yellow_card']),
                                      _statChip(context, appStrings[Localizations.localeOf(context).languageCode]!["red_cards"]!, st['red_card']),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                const SizedBox(height: 24),
                // transfers
                if (transfers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(appStrings[Localizations.localeOf(context).languageCode]!["transfers"]!, style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ...transfers.map((t) {
                          final inTeam = (t['team_in'] as Map<String, dynamic>?)?['title'] as String? ?? '';
                          final imgHex = (t['team_in'] as Map<String, dynamic>?)?['image'] as String? ?? '';
                          final teamImg =
                              'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/$imgHex';
                          final from = t['date_from'] as String? ?? '';
                          final to = t['date_to'] as String? ?? '';
                          final type = t['trans'] as String? ?? '';
                          final tid = (t['team_in'] as Map<String, dynamic>?)?['row_id']?.toString() ?? '';
                          final Locale currentLocale = Localizations.localeOf(context);
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => TeamScreen(teamID: tid, lang: currentLocale.languageCode,)));
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: ClipOval(
                                  child: Image.network(teamImg, width: 40, height: 40, fit: BoxFit.cover),
                                ),
                                title: Text(inTeam),
                                subtitle: Text('$from → $to'),
                                // MODIFIED: Used theme color for the trailing text
                                trailing: Text(type, style: TextStyle(color: textTheme.bodySmall?.color)),
                              ),
                            ),
                          );
                        }).toList(),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}