import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:url_launcher/url_launcher.dart';
import '../api/main_api.dart';

class _TabInfo {
  final Tab tab;
  final Widget view;
  _TabInfo({required this.tab, required this.view});
}

class _EventDisplayInfo {
  final Icon icon;
  final String title;
  final Widget? details;
  _EventDisplayInfo({required this.icon, required this.title, this.details});
}

class MatchDetails extends StatefulWidget {
  final String id;
  final String leagueId;
  final String RowId;

  const MatchDetails({
    required this.id,
    required this.leagueId,
    required this.RowId,
    Key? key,
  }) : super(key: key);

  @override
  State<MatchDetails> createState() => _MatchDetailsState();
}

class _MatchDetailsState extends State<MatchDetails> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData apiData = ApiData();
  bool _showKeyEventsOnly = true;

  @override
  void initState() {
    super.initState();
    futureResults = fetchInfo();
  }

  Future<Map<String, dynamic>> fetchInfo() async {
    final results = await Future.wait([
      apiData.getMatchDetails(widget.id).catchError((e) => {'error': e}),
      apiData.getMatchEvents(widget.id).catchError((e) => {'error': e}),
    ]);
    return {'details': results[0], 'events': results[1]};
  }

  bool _isMatchLive(Map<String, dynamic>? detailsData) {
    final status = detailsData?['status']?.toString();
    return status == '1' || status == '2' || status == '3';
  }

  Future<void> _launchVideoUrl(String? url, BuildContext context) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكن فتح رابط الفيديو')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('حدث خطأ: ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return const Center(child: Text('لا توجد بيانات'));
          } else {
            final detailsData = snapshot.data!["details"]?["details"]?["data"];
            final eventsData = snapshot.data!["events"]?["events"]?["data"];

            if (detailsData == null) {
              return const Center(child: Text('لا يمكن عرض تفاصيل المباراة حاليًا'));
            }

            final tabs = _buildTabs(detailsData, eventsData);

            return DefaultTabController(
              length: tabs.length,
              child: NestedScrollView(
                headerSliverBuilder: (context, innerBoxIsScrolled) {
                  return [
                    SliverAppBar(
                      expandedHeight: 240.0,
                      floating: false,
                      pinned: true,
                      backgroundColor: Theme.of(context).primaryColorDark,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHeader(detailsData),
                      ),
                    ),
                    if (tabs.isNotEmpty)
                      SliverPersistentHeader(
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            isScrollable: tabs.length > 3,
                            tabAlignment: tabs.length > 3 ? TabAlignment.center : TabAlignment.fill,
                            tabs: tabs.map((t) => t.tab).toList(),
                          ),
                        ),
                        pinned: true,
                      ),
                  ];
                },
                body: tabs.isEmpty
                    ? const Center(child: Text("لا توجد تفاصيل متوفرة حاليًا"))
                    : TabBarView(
                  children: tabs.map((t) => t.view).toList(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final homeTeam = data["home_team"];
    final awayTeam = data["away_team"];
    final championship = data["championship"];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).primaryColor.withOpacity(0.8),
            Theme.of(context).primaryColorDark.withOpacity(0.9),
          ],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: kToolbarHeight / 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(
                "https://imgs.ysscores.com/championship/64/${championship?['image']}",
                width: 20,
                height: 20,
                color: Colors.white70,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 8),
              Text(
                championship?['title'] ?? '',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white70),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildTeamDisplay(homeTeam, color: Colors.white),
              _buildScoreAndTimeDisplay(data),
              _buildTeamDisplay(awayTeam, color: Colors.white),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamDisplay(Map<String, dynamic>? team, {Color color = Colors.black}) {
    if (team == null) return const Expanded(child: SizedBox.shrink());
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            "https://imgs.ysscores.com/teams/64/${team['image']}",
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) => Icon(Icons.shield, size: 60, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            team['title'] ?? 'فريق غير محدد',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreAndTimeDisplay(Map<String, dynamic> data) {
    final status = data['status']?.toString() ?? '0';
    String statusText;
    bool isLive = _isMatchLive(data);

    switch (status) {
      case '1': case '3':
      statusText = 'مباشر'; break;
      case '2':
        statusText = 'استراحة'; break;
      case '4': case '11':
      statusText = 'انتهت'; break;
      default:
        statusText = 'لم تبدأ';
    }

    return Column(
      children: [
        Text(
          '${data['home_scores'] ?? '?'} - ${data['away_scores'] ?? '?'}',
          style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2.0),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if(isLive)
                Container(
                  width: 8, height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                ),
              Text(statusText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  List<_TabInfo> _buildTabs(Map<String, dynamic> detailsData, Map<String, dynamic>? eventsData) {
    final List<_TabInfo> tabs = [];

    final eventsList = eventsData?['events'] as List?;
    final hasEvents = eventsData != null && eventsList != null && eventsList.isNotEmpty;
    final stats = detailsData['statics_match'] as Map<String, dynamic>?;
    final hasStats = stats != null && stats.isNotEmpty;

    if (hasEvents || hasStats) {
      tabs.add(_TabInfo(
        tab: const Tab(text: 'ملخص المباراة'),
        view: _buildSummaryTabView(detailsData, eventsData),
      ));
    }

    tabs.add(_TabInfo(
      tab: const Tab(text: 'التفاصيل'),
      view: _buildDetailsTab(detailsData),
    ));

    tabs.add(_TabInfo(
      tab: const Tab(text: 'التشكيل'),
      view: _LineupTabView(matchId: widget.id, detailsData: detailsData),
    ));



    final playedResult = detailsData['played_result'] as Map<String, dynamic>?;
    final hasPlayedResult = playedResult != null && (playedResult['home'] as Map?)?.isNotEmpty == true;
    if (hasPlayedResult) {
      tabs.add(_TabInfo(
        tab: const Tab(text: 'المواجهات'),
        view: _buildRecentMatchesTab(playedResult),
      ));
    }

    tabs.add(_TabInfo(
      tab: const Tab(text: 'الأخبار'),
      view: _NewsTabView(matchRowId: widget.RowId),
    ));

    return tabs;
  }

  Widget _buildSummaryTabView(Map<String, dynamic> detailsData, Map<String, dynamic>? eventsData) {
    final eventsList = eventsData?['events'] as List?;
    final hasEvents = eventsData != null && eventsList != null && eventsList.isNotEmpty;

    final stats = detailsData['statics_match'] as Map<String, dynamic>?;
    final hasStats = stats != null && stats.isNotEmpty;

    if (!hasEvents && !hasStats) {
      return const Center(
        child: Text("لا يوجد ملخص متوفر لهذه المباراة بعد."),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (hasEvents) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("أحداث المباراة", style: Theme.of(context).textTheme.titleLarge),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold)
                  ),
                  child: Text(_showKeyEventsOnly ? "عرض الكل" : "الأبرز فقط"),
                  onPressed: () {
                    setState(() => _showKeyEventsOnly = !_showKeyEventsOnly);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            _buildFullEventsView(eventsData, detailsData["home_team"]?["row_id"],
              isKeyEventsOnly: _showKeyEventsOnly,
            ),
          ],

          if (hasEvents && hasStats)
            const Divider(height: 40, thickness: 1),

          if (hasStats) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text("الإحصائيات", style: Theme.of(context).textTheme.titleLarge),
            ),
            _buildStatsTab(stats, detailsData['home_team'], detailsData['away_team'], isNested: true),
          ]
        ],
      ),
    );
  }

  Widget _buildFullEventsView(Map<String, dynamic>? eventsData, int? homeTeamId, {bool isKeyEventsOnly = false}) {
    final eventsListFull = (eventsData?["events"] as List<dynamic>? ?? []).reversed.toList();

    final eventsList = isKeyEventsOnly
        ? eventsListFull.where((e) => e['type'] == 1 || e['type'] == 3 || e['type'] == 22).toList()
        : eventsListFull;

    if (eventsList.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 40.0),
        child: Center(child: Text("لا توجد أحداث بارزة بعد.")),
      );
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: eventsList.length,
      itemBuilder: (context, index) {
        final event = eventsList[index];
        final isHomeEvent = event['team_id'] == homeTeamId;
        final isSystemEvent = event['team_id'] == 0;

        if (isSystemEvent) {
          return _SystemEventChip(event: event);
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(child: isHomeEvent ? _EventTimelineCard(event: event) : const SizedBox()),
            _TimeIndicatorCircle(event: event),
            Expanded(child: !isHomeEvent ? _EventTimelineCard(event: event, isHomeEvent: false) : const SizedBox()),
          ],
        );
      },
    );
  }

  Widget _buildDetailsTab(Map<String, dynamic> data) {
    final channels = data['channel_commm'] as List<dynamic>? ?? [];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          Card(
            elevation: 2,
            margin: const EdgeInsets.all(0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text("معلومات المباراة", style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const Divider(),
                  _buildInfoTile(Icons.calendar_today_outlined, 'التاريخ', data['match_date']),
                  _buildInfoTile(Icons.sports_soccer_outlined, 'البطولة', data['championship']?['title']),
                  _buildInfoTile(Icons.stadium_outlined, 'الملعب', data['Stadium']),
                  _buildInfoTile(Icons.flag_outlined, 'الجولة', data['round']),
                ],
              ),
            ),
          ),
          if (channels.isNotEmpty) const SizedBox(height: 16),
          if (channels.isNotEmpty)
            Card(
              elevation: 2,
              margin: const EdgeInsets.all(0),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text("القنوات الناقلة", style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const Divider(),
                    ...channels.map((ch) => _buildInfoTile(
                      Icons.tv_outlined,
                      ch['channel_name'] ?? 'قناة غير محددة',
                      ch['commentator_name'],
                    )).toList(),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecentMatchesTab(Map<String, dynamic> playedResult) {
    final homeMatches = (playedResult['home'] as Map?)?.values.toList() ?? [];
    final awayMatches = (playedResult['away'] as Map?)?.values.toList() ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildTeamRecentMatches(homeMatches.first['home']?['title'], homeMatches)),
          const SizedBox(width: 16),
          Expanded(child: _buildTeamRecentMatches(awayMatches.first['away']?['title'], awayMatches)),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Map<String, dynamic> stats, Map<String, dynamic>? homeTeam, Map<String, dynamic>? awayTeam, {bool isNested = false}) {
    final homeStats = stats[homeTeam?['row_id']?.toString()];
    final awayStats = stats[awayTeam?['row_id']?.toString()];

    if (homeStats == null || awayStats == null) {
      return const Center(child: Text('لا توجد إحصائيات'));
    }

    final content = Column(
      children: [
        _buildStatRow('الاستحواذ', homeStats['ball_possession'], awayStats['ball_possession'], isPercentage: true),
        _buildStatRow('التسديدات', homeStats['total_shots'], awayStats['total_shots']),
        _buildStatRow('الأخطاء', homeStats['fouls'], awayStats['fouls']),
        _buildStatRow('التسلل', homeStats['offsides'], awayStats['offsides']),
      ],
    );

    if (isNested) {
      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(padding: const EdgeInsets.all(16.0), child: content),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: [content],
    );
  }

  Widget _buildInfoTile(IconData icon, String title, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return ListTile(
      leading: Icon(icon, color: Theme.of(context).primaryColor),
      title: Text(title),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      dense: true,
    );
  }

  Widget _buildTeamRecentMatches(String? teamName, List<dynamic> matches) {
    Color getResultColor(String? winType) {
      switch (winType) {
        case 'win': return Colors.green.shade700;
        case 'lose': return Colors.red.shade700;
        case 'equal': return Colors.orange.shade700;
        default: return Colors.grey;
      }
    }

    String getResultLetter(String? winType) {
      switch (winType) {
        case 'win': return 'ف';
        case 'lose': return 'خ';
        case 'equal': return 'ت';
        default: return '-';
      }
    }

    return Column(
      children: [
        Text(teamName ?? '', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...matches.map((match) {
          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${match['home']?['title'] ?? ''} ${match['home_scores'] ?? ''}-${match['away_scores'] ?? ''} ${match['away']?['title'] ?? ''}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(color: getResultColor(match['win_type']), borderRadius: BorderRadius.circular(4)),
                    child: Center(child: Text(getResultLetter(match['win_type']), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatRow(String title, dynamic homeValue, dynamic awayValue, {bool isPercentage = false}) {
    final hVal = int.tryParse(homeValue.toString()) ?? 0;
    final aVal = int.tryParse(awayValue.toString()) ?? 0;
    final total = isPercentage ? 100 : (hVal + aVal == 0 ? 1 : hVal + aVal);
    final homeFlex = (hVal / total * 100);
    final awayFlex = (aVal / total * 100);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(hVal.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Text(title, style: TextStyle(color: Theme.of(context).hintColor)),
              Text(aVal.toString(), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: Row(
              children: [
                Expanded(flex: homeFlex.toInt(), child: Container(height: 10, color: Theme.of(context).primaryColor)),
                Expanded(flex: awayFlex.toInt(), child: Container(height: 10, color: Colors.grey.shade300)),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class _SystemEventChip extends StatelessWidget {
  final Map<String, dynamic> event;
  const _SystemEventChip({Key? key, required this.event}) : super(key: key);

  String getEventTitle() {
    if (event['type'] == 13) return "▶ بداية المباراة";
    if (event['type'] == 5) return "⏸ نهاية الشوط الأول";
    if (event['type'] == 6) return "⏩ بداية الشوط الثاني";
    if (event['type'] == 7) return "⏹ نهاية المباراة";
    return "";
  }

  IconData getEventIcon() {
    if (event['type'] == 13) return Icons.play_arrow;
    if (event['type'] == 5) return Icons.pause;
    if (event['type'] == 6) return Icons.play_arrow;
    if (event['type'] == 7) return Icons.stop;
    return Icons.info;
  }

  @override
  Widget build(BuildContext context) {
    final title = getEventTitle();
    if(title.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Chip(
          avatar: Icon(getEventIcon(), size: 16, color: Theme.of(context).textTheme.bodySmall?.color),
          label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.surfaceVariant,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
      ),
    );
  }
}

class _TimeIndicatorCircle extends StatelessWidget {
  final Map<String, dynamic> event;
  const _TimeIndicatorCircle({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final timeMin = event["time_minute"] ?? 0;
    final timePlus = event["time_plus"] ?? 0;
    final timeStr = timePlus > 0 ? "$timeMin'..": "$timeMin'";

    final bool isImportantEvent = event['type'] == 1 || event['type'] == 3;
    final bgColor = isImportantEvent ? Theme.of(context).primaryColor.withOpacity(0.1) : Colors.grey.shade200;
    final textColor = isImportantEvent ? Theme.of(context).primaryColorDark : Theme.of(context).textTheme.bodySmall?.color;

    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 0.5)
      ),
      child: Center(
        child: Text(
          timeStr,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: textColor,
              fontSize: 11
          ),
        ),
      ),
    );
  }
}

class _EventTimelineCard extends StatelessWidget {
  final Map<String, dynamic> event;
  final bool isHomeEvent;
  const _EventTimelineCard({required this.event, this.isHomeEvent = true});

  Future<void> _launchVideoUrl(String? url, BuildContext context) async {
    final state = context.findAncestorStateOfType<_MatchDetailsState>();
    await state?._launchVideoUrl(url, context);
  }

  @override
  Widget build(BuildContext context) {
    final type = event["type"] ?? 0;
    final player = event["player_name"]?["title"] as String?;
    final assist = event["assist_player_name"]?["title"] as String?;
    final videoUrl = event["event_video"] as String?;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final eventInfo = _getEventInfo(context, type, player, assist, isHomeEvent);

    final bool isGoal = type == 1;

    final content = Row(
      mainAxisAlignment: isHomeEvent ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if(isHomeEvent) eventInfo.icon,
        if(isHomeEvent) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: isHomeEvent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                  eventInfo.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: isHomeEvent ? TextAlign.start : TextAlign.end
              ),
              if (player != null)
                Text(
                    player,
                    style: const TextStyle(fontSize: 12),
                    textAlign: isHomeEvent ? TextAlign.start : TextAlign.end
                ),
              if (eventInfo.details != null) const SizedBox(height: 2),
              if (eventInfo.details != null) eventInfo.details!,
            ],
          ),
        ),
        if(!isHomeEvent) const SizedBox(width: 8),
        if(!isHomeEvent) eventInfo.icon,
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isGoal ? Border.all(color: Colors.green.withOpacity(0.4), width: 1) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4, offset: const Offset(0, 1))]
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _launchVideoUrl(videoUrl, context),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                content,
                if(hasVideo)
                  Positioned(
                      bottom: -2,
                      left: isHomeEvent ? -2 : null,
                      right: !isHomeEvent ? -2 : null,
                      child: Icon(Icons.play_circle_filled_rounded, color: Theme.of(context).primaryColor, size: 16)
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Theme.of(context).scaffoldBackgroundColor, child: Center(child: _tabBar));
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}

_EventDisplayInfo _getEventInfo(BuildContext context, int type, String? player, String? assist, bool isHomeEvent) {
  switch (type) {
    case 1:
      return _EventDisplayInfo(
          icon: const Icon(Icons.sports_soccer, color: Colors.green, size: 18),
          title: "هدف",
          details: assist != null ? Text("صنع الهدف: $assist", style: TextStyle(color: Theme.of(context).hintColor, fontSize: 11)) : null);
    case 3:
      return _EventDisplayInfo(icon: const Icon(Icons.style, color: Colors.red, size: 18), title: "بطاقة حمراء", details: null);
    case 2:
      return _EventDisplayInfo(icon: const Icon(Icons.style, color: Colors.amber, size: 18), title: "بطاقة صفراء", details: null);
    case 8:
      return _EventDisplayInfo(
          icon: const Icon(Icons.swap_horiz_rounded, color: Colors.blue, size: 18),
          title: "تبديل",
          details: RichText(
              textDirection: isHomeEvent ? TextDirection.ltr : TextDirection.rtl,
              textAlign: isHomeEvent ? TextAlign.start : TextAlign.end,
              text: TextSpan(
                style: DefaultTextStyle.of(context).style.copyWith(fontSize: 11),
                children: [
                  TextSpan(text: 'دخول: ', style: TextStyle(color: Colors.green.shade700)),
                  TextSpan(text: '$player ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'خروج: ', style: TextStyle(color: Colors.red.shade700)),
                  TextSpan(text: '$assist', style: TextStyle(color: Theme.of(context).hintColor, decoration: TextDecoration.lineThrough)),
                ],
              )));
    case 22:
      return _EventDisplayInfo(icon: Icon(Icons.radio_button_checked, color: Theme.of(context).colorScheme.secondary, size: 18), title: "ركلة جزاء", details: null);
    case 23:
      return _EventDisplayInfo(icon: Icon(Icons.cancel_outlined, color: Theme.of(context).colorScheme.error, size: 18), title: "ركلة جزاء ضائعة", details: null);
    default:
      return _EventDisplayInfo(icon: Icon(Icons.info_outline, color: Theme.of(context).hintColor, size: 18), title: "حدث", details: null);
  }
}

class _LineupTabView extends StatefulWidget {
  final String matchId;
  final Map<String, dynamic> detailsData;

  const _LineupTabView({required this.matchId, required this.detailsData});

  @override
  State<_LineupTabView> createState() => _LineupTabViewState();
}

class _LineupTabViewState extends State<_LineupTabView> {
  late Future<Map<String, dynamic>> _lineupFuture;
  final ApiData apiData = ApiData();

  @override
  void initState() {
    super.initState();
    _lineupFuture = apiData.getMatchLinesUp(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _lineupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData || snapshot.data?['lineup']?['data']?['lineup'] == null) {
          return const Center(child: Text('التشكيل غير متوفر حاليًا.'));
        }

        final lineupData = snapshot.data!['lineup']['data'];
        final homeTeamId = widget.detailsData['home_team']['row_id'].toString();
        final awayTeamId = widget.detailsData['away_team']['row_id'].toString();

        final homeLineup = lineupData['lineup'][homeTeamId];
        final awayLineup = lineupData['lineup'][awayTeamId];

        return DefaultTabController(
          length: 2,
          child: Column(
            children: [
              TabBar(
                tabs: [
                  Tab(text: widget.detailsData['home_team']['title']),
                  Tab(text: widget.detailsData['away_team']['title']),
                ],
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _TeamLineupView(
                      lineup: homeLineup,
                      formation: lineupData['0']['home_formation'],
                      coach: lineupData['0']['home_coach'],
                    ),
                    _TeamLineupView(
                      lineup: awayLineup,
                      formation: lineupData['0']['away_formation'],
                      coach: lineupData['0']['away_coach'],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _TeamLineupView extends StatelessWidget {
  final Map<String, dynamic>? lineup;
  final String? formation;
  final Map<String, dynamic>? coach;

  const _TeamLineupView({this.lineup, this.formation, this.coach});

  @override
  Widget build(BuildContext context) {
    if (lineup == null) {
      return const Center(child: Text("لا توجد بيانات تشكيل لهذا الفريق."));
    }
    final startingPlayers = (lineup!['lineup'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final substitutePlayers = (lineup!['substitutions'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          _FootballPitch(players: startingPlayers, formation: formation),
          const SizedBox(height: 16),
          _SectionTitle(title: "المدرب: ${coach?['title'] ?? 'غير محدد'}"),
          const SizedBox(height: 16),
          _SectionTitle(title: "دكة البدلاء"),
          const SizedBox(height: 8),
          _SubstitutesList(players: substitutePlayers),
        ],
      ),
    );
  }
}

class _FootballPitch extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  final String? formation;

  const _FootballPitch({required this.players, this.formation});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 7 / 10,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade700,
          border: Border.all(color: Colors.white.withOpacity(0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          children: [
            const _PitchLines(),
            _buildPlayerMarkers(players),
            Positioned(
              top: 8,
              left: 0,
              right: 0,
              child: Text(
                "خطة اللعب: ${formation ?? 'غير محددة'}",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerMarkers(List<Map<String, dynamic>> players) {
    final List<int> formationLines = _parseFormation(formation);

    Map<String, List<Map<String, dynamic>>> groupedPlayers = {
      'G': [], 'D': [], 'M': [], 'F': []
    };

    for (var p in players) {
      final pos = p['position'];
      if(groupedPlayers.containsKey(pos)) {
        groupedPlayers[pos]!.add(p);
      } else if (pos == 'GK') {
        groupedPlayers['G']!.add(p);
      }
    }

    return LayoutBuilder(
        builder: (context, constraints) {
          List<Widget> markers = [];

          final positionsY = {'G': 0.1, 'D': 0.3, 'M': 0.55, 'F': 0.8};
          final lines = ['G', 'D', 'M', 'F'];
          int formationIndex = 0;

          for(var lineKey in lines) {
            var linePlayers = groupedPlayers[lineKey]!;
            int lineLength = lineKey == 'G' ? 1 : (formationLines.isNotEmpty && formationIndex < formationLines.length ? formationLines[formationIndex] : linePlayers.length);
            if (lineKey != 'G' && formationLines.isNotEmpty) formationIndex++;

            for (int i = 0; i < linePlayers.length; i++) {
              var player = linePlayers[i];
              double x = (i + 1) / (lineLength + 1);
              double y = positionsY[lineKey]!;

              markers.add(
                  Positioned(
                    top: y * constraints.maxHeight - 32,
                    left: x * constraints.maxWidth - 32,
                    child: _PlayerMarker(player: player),
                  )
              );
            }
          }
          return Stack(children: markers);
        }
    );
  }

  List<int> _parseFormation(String? f) {
    if (f == null) return [];
    return f.split('-').map((e) => int.tryParse(e) ?? 0).toList();
  }
}

class _PitchLines extends StatelessWidget {
  const _PitchLines();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: [
          Positioned(
            top: constraints.maxHeight * 0.5 - 0.5, left: 0, right: 0,
            child: Container(height: 1, color: Colors.white.withOpacity(0.4)),
          ),
          Center(
            child: Container(
              width: constraints.maxWidth * 0.25,
              height: constraints.maxWidth * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.4)),
              ),
            ),
          ),
        ],
      );
    });
  }
}

class _PlayerMarker extends StatelessWidget {
  final Map<String, dynamic> player;
  const _PlayerMarker({required this.player});

  @override
  Widget build(BuildContext context) {
    final pData = player['player'];
    final name = pData['title'] as String;
    final image = pData['image'] as String?;

    return GestureDetector(
      onTap: () {
        print("Player ID: ${pData['row_id']}");
      },
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: image != null ? NetworkImage("https://imgs.ysscores.com/player/150/$image") : null,
              backgroundColor: Colors.white.withOpacity(0.8),
              child: image == null
                  ? const Icon(Icons.person, size: 22, color: Colors.grey)
                  : null,
            ),
            const SizedBox(height: 3),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubstitutesList extends StatelessWidget {
  final List<Map<String, dynamic>> players;
  const _SubstitutesList({required this.players});

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: players.length,
        separatorBuilder: (context, index) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final pData = players[index]['player'];
          final image = pData['image'] as String?;
          final number = pData['player_number']?.toString();

          return ListTile(
            dense: true,
            onTap: () => print("Player ID: ${pData['row_id']}"),
            leading: CircleAvatar(
              radius: 18,
              backgroundImage: image != null ? NetworkImage("https://imgs.ysscores.com/player/150/$image") : null,
              backgroundColor: Colors.grey.shade200,
              child: image == null ? const Icon(Icons.person, size: 20, color: Colors.grey) : null,
            ),
            title: Text(pData['title'] ?? 'غير معروف'),
            trailing: number != null
                ? Text(number, style: TextStyle(color: Theme.of(context).hintColor, fontSize: 16, fontWeight: FontWeight.bold))
                : null,
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }
}

class _NewsTabView extends StatefulWidget {
  final String matchRowId;
  const _NewsTabView({required this.matchRowId});

  @override
  State<_NewsTabView> createState() => _NewsTabViewState();
}

class _NewsTabViewState extends State<_NewsTabView> {
  late Future<Map<String, dynamic>> _newsFuture;
  final ApiData apiData = ApiData();

  @override
  void initState() {
    super.initState();
    _newsFuture = apiData.getMatchNews(widget.matchRowId);
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inDays > 7) {
        return "${dateTime.year}/${dateTime.month}/${dateTime.day}";
      } else if (difference.inDays > 0) {
        return "منذ ${difference.inDays} يوم${difference.inDays > 1 ? ' أيام' : ''}";
      } else if (difference.inHours > 0) {
        return "منذ ${difference.inHours} ساعة${difference.inHours > 1 ? ' ساعات' : ''}";
      } else if (difference.inMinutes > 0) {
        return "منذ ${difference.inMinutes} دقيقة${difference.inMinutes > 1 ? ' دقائق' : ''}";
      } else {
        return "الآن";
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const Center(child: Text("حدث خطأ أثناء تحميل الأخبار."));
        }

        final newsData = snapshot.data!['news']?['data']?['data'] as List?;
        if (newsData == null || newsData.isEmpty) {
          return const Center(child: Text("لا توجد أخبار متاحة لهذه المباراة."));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: newsData.length,
          itemBuilder: (context, index) {
            return _NewsCard(newsItem: newsData[index], formatDate: _formatDate);
          },
        );
      },
    );
  }
}

class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> newsItem;
  final String Function(String) formatDate;

  const _NewsCard({required this.newsItem, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final title = newsItem['title'] ?? '';
    final description = newsItem['news_desc'] ?? '';
    final imageUrl = newsItem['image'];
    final date = newsItem['created_at']?['date'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Image.network(
              "https://imgs.ysscores.com/news/820/$imageUrl",
              height: 180,
              width: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => const SizedBox(
                height: 180,
                child: Center(child: Icon(Icons.image_not_supported)),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade700),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    formatDate(date),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}