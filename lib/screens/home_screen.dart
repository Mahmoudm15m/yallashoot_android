import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yallashoot/screens/search_screen.dart';
import '../api/main_api.dart';
import '../functions/clock_ticker.dart';
import '../screens/match_details.dart';
import 'lives_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:html' as html;

bool get _isDesktopWeb {
  if (!kIsWeb) return false; // مش ويب أساساً
  final ua = html.window.navigator.userAgent.toLowerCase();
  if (ua.contains('mobi') ||
      ua.contains('android') ||
      ua.contains('ipad') ||
      ua.contains('linux') ||
      ua.contains('iphone')) {
    return false;
  }
  return true;
}
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
    final dateAr  = DateFormat('d MMM yyyy', 'ar').format(_selectedDate);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        centerTitle: true,
        title: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
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
            if (!_isDesktopWeb) ...[
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
              final data = snap.data?['matches'] as List?;
              if (data == null || data.isEmpty) return Center(child: Text('لا توجد بيانات', style: TextStyle(color: txtGrey)));

              final filtered = !_showLiveOnly
                  ? data
                  : data.where((m) => (m['fixture']?['status']?['short'] ?? '') == 'LIVE').toList();
              if (filtered.isEmpty) return Center(child: Text('لا توجد مباريات لايف', style: TextStyle(color: txtGrey)));

              final grouped = <String, List<Map<String, dynamic>>>{};
              for (final m in filtered) {
                final lid = m['league']?['id']?.toString() ?? '';
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
                    champ: section.first['league'] as Map<String, dynamic>,
                    matches: section,
                    cardColor: card,
                    liveRed: liveRed,
                    showLiveOnly: _showLiveOnly,
                    onTogglePriority: _togglePriority,
                    isPinned: _priorityChamps.contains(lid),
                  );
                },
              );

              // عرض مركزي مع حدود عرض للشاشات الكبيرة
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
  void _printId()        => debugPrint(widget.champ['id'].toString());

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
                      "https://api.syria-live.fun/img_proxy?url=" + widget.champ['logo'],
                      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                    ),
                    const SizedBox(width: 8),
                    Text(widget.champ['name'], style: const TextStyle(color: Colors.white)),
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
            key: ValueKey('${m['id']}_${widget.showLiveOnly}'),
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
  late final bool isLive;
  late final bool isEnded;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    final fixture = widget.match['fixture'] as Map<String, dynamic>;
    final status  = fixture['status'] as Map<String, dynamic>;
    isLive   = status['short'] == 'LIVE';
    isEnded  = status['short'] == 'FT';
    fixtureTime = fixture['time'] as String?;

    if (fixture['date'] != null) {
      kickOff = DateTime.parse(fixture['date']).toLocal();
    } else if (isLive && status['elapsed'] != null) {
      kickOff = DateTime.now().subtract(Duration(
        minutes: int.parse(status['elapsed'].toString()),
      ));
    } else {
      kickOff = null;
    }
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
        MaterialPageRoute(builder: (_) => MatchDetails(id: widget.match['id'])),
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
            _TeamSide(team: widget.match['teams']['home'], textStyle: Theme.of(context).textTheme.bodySmall),
            const Spacer(),
            _buildCenter(now, context),
            const Spacer(),
            _TeamSide(team: widget.match['teams']['away'], textStyle: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildCenter(DateTime now, BuildContext context) {
    final textBold = Theme.of(context)
        .textTheme
        .bodyMedium
        ?.copyWith(fontWeight: FontWeight.bold);
    final textGrey = Theme.of(context).textTheme.bodySmall;

    if (isLive && kickOff != null) {
      final diff = now.difference(kickOff!);
      final mm = diff.inMinutes.remainder(140).toString().padLeft(2, '0');
      final ss = diff.inSeconds.remainder(60).toString().padLeft(2, '0');
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: widget.liveRed, borderRadius: BorderRadius.circular(4)),
            child: const Text('LIVE', style: TextStyle(color: Colors.white, fontSize: 10)),
          ),
          const SizedBox(height: 4),
          Text('${widget.match['score']['home']} - ${widget.match['score']['away']}', style: textBold),
          const SizedBox(height: 2),
          Text('$mm:$ss', style: textGrey),
        ],
      );
    }

    if (isEnded) {
      return Column(
        children: [
          Text('${widget.match['score']['home']} - ${widget.match['score']['away']}', style: textBold),
          const SizedBox(height: 2),
          Text('انتهت المباراة', style: textGrey),
        ],
      );
    }

    return Text(fixtureTime ?? '', style: textBold);
  }
}

class _TeamSide extends StatelessWidget {
  const _TeamSide({required this.team, required this.textStyle});
  final Map<String, dynamic> team;
  final TextStyle? textStyle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Image.network(
          "https://api.syria-live.fun/img_proxy?url=" + team['logo'],
          width: 37,
          height: 37,
          errorBuilder: (_, __, ___) => const SizedBox(width: 28, height: 28),
        ),
        const SizedBox(height: 4),
        SizedBox(
          width: 60,
          child: Text(
            team['name'],
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textStyle,
            textAlign: TextAlign.center,
          ),
        ),
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
