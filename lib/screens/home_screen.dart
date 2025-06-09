import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yallashoot/screens/league_screen.dart';
import 'package:yallashoot/screens/search_screen.dart';
import '../api/main_api.dart';
import '../functions/clock_ticker.dart';
import '../screens/match_details.dart';
import 'lives_screen.dart';



class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<dynamic> _future;
  late DateTime _selectedDate;
  bool _showLiveOnly = false;

  List<String> _priorityChamps = [];
  final ApiData yasScore = ApiData();

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _loadPriorityChamps();
    _fetchMatches();
  }

  Future<void> _loadPriorityChamps() async {
    final prefs = await SharedPreferences.getInstance();
    _priorityChamps = prefs.getStringList('priorityChamps') ?? [];
    setState(() {});
  }

  Future<void> _savePriorityChamps() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('priorityChamps', _priorityChamps);
  }

  void _fetchMatches() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    setState(() {
      _future = yasScore.getMatchesData(dateStr);
    });
  }

  void _prevDay() {
    _selectedDate = _selectedDate.subtract(const Duration(days: 1));
    _fetchMatches();
  }

  void _nextDay() {
    _selectedDate = _selectedDate.add(const Duration(days: 1));
    _fetchMatches();
  }

  Future<void> _openBottomSheetDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _buildDatePicker(context),
    );
    if (picked != null && picked != _selectedDate) {
      _selectedDate = picked;
      _fetchMatches();
    }
  }

  Widget _buildDatePicker(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 12),
          CalendarDatePicker(
            initialDate: _selectedDate,
            firstDate: DateTime(2000),
            lastDate: DateTime(2100),
            currentDate: DateTime.now(),
            onDateChanged: (date) => Navigator.pop(context, date),
          ),
        ],
      ),
    );
  }

  void _togglePriority(String champId, bool remove) {
    setState(() {
      if (remove) {
        _priorityChamps.remove(champId);
      } else {
        _priorityChamps.remove(champId);
        _priorityChamps.insert(0, champId);
      }
    });
    _savePriorityChamps();
  }

  @override
  Widget build(BuildContext context) {
    final bg      = Theme.of(context).scaffoldBackgroundColor;
    final card    = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF101820)
        : Colors.white;
    final txtGrey = Theme.of(context).hintColor.withOpacity(.8);
    final liveRed = Colors.red;
    final weekday = DateFormat('EEEE', 'ar').format(_selectedDate);
    final dateAr  = DateFormat('d MMM', 'ar').format(_selectedDate);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            IconButton(icon: const Icon(Icons.chevron_left, size: 28), onPressed: _nextDay),
            IconButton(icon: const Icon(Icons.calendar_today, size: 24), onPressed: _openBottomSheetDate),
            IconButton(icon: const Icon(Icons.chevron_right, size: 28), onPressed: _prevDay),
            IconButton(
              padding: EdgeInsets.zero,
              icon: Icon(Icons.search_outlined, size: 24),
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context){
                  return SearchScreen();
                }));
              },
            ),
            SizedBox(width: 10,),
            IconButton(
              icon: Icon(Icons.live_tv, color: _showLiveOnly ? liveRed : null, size: 24),
              tooltip: _showLiveOnly ? 'عرض الكل' : 'عرض اللايف فقط',
              onPressed: () => setState(() => _showLiveOnly = !_showLiveOnly),
            ),
            Spacer(),
            IconButton(
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return LivesScreen();
                  }));
                },
                icon: Text("البث المتاح" , style: TextStyle(fontSize: 16 , color: Colors.blueAccent),)
            ),
          ],

        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 600;
          Widget content = FutureBuilder<dynamic>(
            future: _future,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const _LoadingList();
              if (snap.hasError || !snap.hasData) return Center(child: Text('حدث خطأ في جلب البيانات', style: TextStyle(color: txtGrey)));

              final data = snap.data?['matches']?['data'] as List?;
              if (data == null || data.isEmpty) return Center(child: Text('لا توجد بيانات', style: TextStyle(color: txtGrey)));

              final filtered = !_showLiveOnly
                  ? data
                  : data.where((m) {
                final s = m['status']?.toString() ?? '0';
                return s == '1' || s == '2' || s == '3';
              }).toList();
              if (filtered.isEmpty) {
                return Center(child: Text(_showLiveOnly ? 'لا توجد مباريات لايف حالياً' : 'لا توجد مباريات لهذا اليوم', style: TextStyle(color: txtGrey)));
              }

              final grouped = <String, List<Map<String, dynamic>>>{};
              for (final m in filtered) {
                final lid = m['championship']?['id']?.toString() ?? '';
                grouped.putIfAbsent(lid, () => []).add(m as Map<String, dynamic>);
              }
              final keys = grouped.keys.toList();
              final orderedKeys = [
                ..._priorityChamps.where(grouped.containsKey),
                ...keys.where((id) => !_priorityChamps.contains(id)),
              ];

              Widget listView = ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: orderedKeys.length + 1,
                itemBuilder: (_, i) {
                  if (i == 0) {
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(dateAr, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 5),
                          Text(',$weekday', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }
                  final lid     = orderedKeys[i - 1];
                  final section = grouped[lid]!;
                  return _ChampSection(
                    champ: section.first['championship'] as Map<String, dynamic>,
                    matches: section,
                    cardColor: card,
                    liveRed: liveRed,
                    showLiveOnly: _showLiveOnly,
                    onTogglePriority: _togglePriority,
                    isPinned: _priorityChamps.contains(lid),
                  );
                },
              );

              if (isMobile) {
                return listView;
              } else {
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 800),
                    child: listView,
                  ),
                );
              }
            },
          );
          return content;
        },
      ),
    );
  }
}

class _ChampSection extends StatefulWidget {
  const _ChampSection({
    required this.champ,
    required this.matches,
    required this.cardColor,
    required this.liveRed,
    required this.showLiveOnly,
    required this.isPinned,
    required this.onTogglePriority,
    Key? key,
  }) : super(key: key);

  final Map<String, dynamic> champ;
  final List<Map<String, dynamic>> matches;
  final Color cardColor;
  final Color liveRed;
  final bool showLiveOnly;
  final bool isPinned;
  final void Function(String champId, bool remove) onTogglePriority;

  @override
  State<_ChampSection> createState() => _ChampSectionState();
}

class _ChampSectionState extends State<_ChampSection> {
  bool _isExpanded = true;

  void _toggleExpanded() => setState(() => _isExpanded = !_isExpanded);
  void _printId() {
    Navigator.push(context, MaterialPageRoute(builder: (context){
      return LeagueScreen(id: widget.champ['url_id'].toString());
    }));
  }

  @override
  Widget build(BuildContext context) {
    final champId = widget.champ['id'].toString();
    return Column(
      children: [
        Container(
          height: 40,
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blueGrey[900],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: _printId,
                child: Row(
                  children: [
                    Image.network(
                      "https://imgs.ysscores.com/championship/64/${widget.champ['image']}",
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.champ['title'], style: const TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: _toggleExpanded,
                child: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.white),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz, size: 20, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                offset: const Offset(0, 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                tooltip: 'خيارات',
                onSelected: (value) => widget.onTogglePriority(champId, value == 'unpin'),
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: widget.isPinned ? 'unpin' : 'pin',
                    child: Row(
                      children: [
                        Icon(widget.isPinned ? Icons.push_pin_outlined : Icons.push_pin, size: 18),
                        const SizedBox(width: 8),
                        Text(
                          widget.isPinned ? 'إلغاء التثبيت' : 'تثبيت في الأعلى',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (_isExpanded)
          ...widget.matches.map((m) => _MatchCard(
            key: ValueKey('${m['match_id']}_${widget.showLiveOnly}'),
            match: m,
            cardColor: widget.cardColor,
            liveRed: widget.liveRed,
          )),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MatchCard extends StatefulWidget {
  const _MatchCard({
    required Key key,
    required this.match,
    required this.cardColor,
    required this.liveRed,
  }) : super(key: key);

  final Map<String, dynamic> match;
  final Color cardColor;
  final Color liveRed;

  @override
  State<_MatchCard> createState() => _MatchCardState();
}

class _MatchCardState extends State<_MatchCard>
    with AutomaticKeepAliveClientMixin {
  late final DateTime? kickOff;
  late final String? fixtureTime;

  bool _hasPenalties = false;
  String? _penaltyScore;
  List<bool>? _homePenaltyKicks;
  List<bool>? _awayPenaltyKicks;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    fixtureTime = widget.match['match_time'] as String?;
    final timestamp = widget.match['match_timestamp'];

    if (timestamp != null) {
      kickOff = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000).toLocal();
    } else {
      kickOff = null;
    }

    _parsePenalties();
  }

  void _parsePenalties() {
    final penaltiesData = widget.match['penalties'] as Map<String, dynamic>?;
    if (penaltiesData == null || penaltiesData.isEmpty) return;

    _hasPenalties = true;
    final homeTeamId = widget.match['home_team']?['row_id']?.toString();
    final awayTeamId = widget.match['away_team']?['row_id']?.toString();

    final homeKicksRaw = penaltiesData[homeTeamId] as List<dynamic>? ?? [];
    _homePenaltyKicks = homeKicksRaw.map((kick) => (kick as Map).values.first == 1).toList();

    final awayKicksRaw = penaltiesData[awayTeamId] as List<dynamic>? ?? [];
    _awayPenaltyKicks = awayKicksRaw.map((kick) => (kick as Map).values.first == 1).toList();

    final homeScore = _homePenaltyKicks!.where((s) => s).length;
    final awayScore = _awayPenaltyKicks!.where((s) => s).length;
    _penaltyScore = '$homeScore-$awayScore';
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ValueListenableBuilder<DateTime>(
      valueListenable: ClockTicker().listenable,
      builder: (_, now, __) {
        return _cardBody(context, now);
      },
    );
  }

  Widget _cardBody(BuildContext context, DateTime now) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => MatchDetails(id: widget.match['match_id'].toString() , leagueId: widget.match['championship']['id'].toString(), RowId: widget.match["home_team"]["row_id"].toString() + "/" + widget.match["away_team"]["row_id"].toString(),
        )),
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: widget.cardColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            _TeamSide(
              team: widget.match['home_team'],
              textStyle: Theme.of(context).textTheme.bodySmall,
              penaltyKicks: _homePenaltyKicks,
            ),
            const Spacer(),
            _buildCenter(context , now),
            const Spacer(),
            _TeamSide(
              team: widget.match['away_team'],
              textStyle: Theme.of(context).textTheme.bodySmall,
              penaltyKicks: _awayPenaltyKicks,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenter(BuildContext context, DateTime now) {
    final textBold = Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold);
    final textGrey = Theme.of(context).textTheme.bodySmall;
    final status = widget.match['status']?.toString() ?? '0';

    final isPlaying = status == '1' || status == '3';

    if (isPlaying && kickOff != null) {
      // [تعديل] منطق حساب وقت المباراة
      int displayMinutes = 0;
      int displaySeconds = 0;

      if (status == '1') { // الشوط الأول
        final diff = now.difference(kickOff!);
        displayMinutes = diff.inMinutes;
        displaySeconds = diff.inSeconds.remainder(60);
      } else if (status == '3') { // الشوط الثاني
        final htTimestamp = widget.match['ht_time'] as int?;
        if (htTimestamp != null) {
          final secondHalfStartTime = DateTime.fromMillisecondsSinceEpoch(htTimestamp * 1000).toLocal();
          final secondHalfElapsed = now.difference(secondHalfStartTime);
          displayMinutes = 45 + secondHalfElapsed.inMinutes;
          displaySeconds = secondHalfElapsed.inSeconds.remainder(60);
        } else { // Fallback if ht_time is not available
          final diff = now.difference(kickOff!);
          displayMinutes = diff.inMinutes;
          displaySeconds = diff.inSeconds.remainder(60);
        }
      }

      displayMinutes = displayMinutes.clamp(0, 140);
      final mm = displayMinutes.toString().padLeft(2, '0');
      final ss = displaySeconds.toString().padLeft(2, '0');

      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: widget.liveRed, borderRadius: BorderRadius.circular(4)),
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(height: 4),
          Text('${widget.match['home_scores']} - ${widget.match['away_scores']}', style: textBold),
          const SizedBox(height: 2),
          Text('$mm:$ss', style: textGrey),
        ],
      );
    }

    if (status == '2') {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: widget.liveRed, borderRadius: BorderRadius.circular(4)),
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(height: 4),
          Text('${widget.match['home_scores']} - ${widget.match['away_scores']}', style: textBold),
          const SizedBox(height: 2),
          Text('استراحة', style: textGrey?.copyWith(color: widget.liveRed)),
        ],
      );
    }

    final isEnded = status == '4' || status == '11';
    if (isEnded) {
      if (_hasPenalties) {
        return Column(
          children: [
            Text('${widget.match['home_scores']} - ${widget.match['away_scores']}', style: textBold),
            const SizedBox(height: 2),
            Text('(${_penaltyScore!})', style: textBold?.copyWith(color: widget.liveRed, fontSize: 13)),
            const SizedBox(height: 2),
            Text('انتهت', style: textGrey?.copyWith(fontSize: 11)),
          ],
        );
      }
      return Column(
        children: [
          Text('${widget.match['home_scores']} - ${widget.match['away_scores']}', style: textBold),
          const SizedBox(height: 2),
          Text('انتهت المباراة', style: textGrey),
        ],
      );
    }

    String formattedTime = fixtureTime ?? '';
    if (fixtureTime != null && fixtureTime!.isNotEmpty) {
      try {
        final time = TimeOfDay(
          hour: int.parse(fixtureTime!.split(':')[0]),
          minute: int.parse(fixtureTime!.split(':')[1]),
        );
        final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
        formattedTime = DateFormat('h:mm a', 'ar').format(dt);
      } catch (e) {
        formattedTime = fixtureTime!;
      }
    }
    return Text(formattedTime, style: textBold);
  }
}

class _PenaltyKicksVisualizer extends StatelessWidget {
  final List<bool> kicks;
  const _PenaltyKicksVisualizer({required this.kicks});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: kicks.map((scored) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 1.0),
          child: Icon(
            scored ? Icons.check_circle : Icons.cancel,
            color: scored ? Colors.green.shade600 : Colors.red.shade600,
            size: 14,
          ),
        );
      }).toList(),
    );
  }
}


class _TeamSide extends StatelessWidget {
  const _TeamSide({
    required this.team,
    required this.textStyle,
    this.penaltyKicks,
  });

  final Map<String, dynamic> team;
  final TextStyle? textStyle;
  final List<bool>? penaltyKicks;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.network(
          "https://imgs.ysscores.com/teams/64/${team['image']}",
          width: 37,
          height: 37,
          errorBuilder: (_, __, ___) => const SizedBox(width: 37, height: 37),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 80,
          child: Text(
            team['title'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
        if (penaltyKicks != null && penaltyKicks!.isNotEmpty) ...[
          const SizedBox(height: 5),
          _PenaltyKicksVisualizer(kicks: penaltyKicks!),
        ]
      ],
    );
  }
}

class _LoadingList extends StatelessWidget {
  const _LoadingList();

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final base    = isDark ? Colors.grey.shade800 : Colors.grey.shade300;
    final highlight = isDark ? Colors.grey.shade700 : Colors.grey.shade100;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: 8,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: base,
        highlightColor: highlight,
        period: const Duration(milliseconds: 700),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          height: 60,
          decoration: BoxDecoration(color: base, borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}