// lib/screens/match_details.dart

import 'dart:async';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yallashoot/widgets/videos_tap.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';
import '../widgets/lineup_tap.dart';
import '../widgets/news_tap.dart';
import 'package:yallashoot/widgets/standing_tap.dart';

// Helper class to provide a ticking clock every second for live updates.
class ClockTicker {
  late final ValueNotifier<DateTime> _notifier;
  ValueListenable<DateTime> get listenable => _notifier;

  ClockTicker() {
    _notifier = ValueNotifier(DateTime.now());
    Timer.periodic(const Duration(seconds: 1), (timer) {
      _notifier.value = DateTime.now();
    });
  }
}

class _TabInfo {
  final Tab tab;
  final Widget view;
  _TabInfo({required this.tab, required this.view});
}

class _EventDisplayInfo {
  final Widget icon;
  final String title;
  final Widget? details;
  _EventDisplayInfo({required this.icon, required this.title, this.details});
}

class MatchDetails extends StatefulWidget {
  final String id;
  final String leagueId;
  final String RowId;
  final String lang;

  const MatchDetails({
    required this.id,
    required this.leagueId,
    required this.RowId,
    required this.lang,
    Key? key,
  }) : super(key: key);

  @override
  State<MatchDetails> createState() => _MatchDetailsState();
}

class _MatchDetailsState extends State<MatchDetails> {
  late Future<Map<String, dynamic>> futureResults;
  late ApiData apiData;
  bool _showKeyEventsOnly = true;

  final ClockTicker _clock = ClockTicker();

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    futureResults = fetchInfo();
  }

  Future<Map<String, dynamic>> fetchInfo() async {
    final results = await Future.wait([
      apiData.getMatchDetails(widget.id).catchError((e) => {'error': e}),
      apiData.getMatchEvents(widget.id).catchError((e) => {'error': e}),
    ]);
    return {'details': results[0], 'events': results[1]};
  }

  Future<void> _launchVideoUrl(String? url, BuildContext context) async {
    if (url != null && url.isNotEmpty) {
      final uri = Uri.tryParse(url);
      if (uri != null && await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(appStrings[
                Localizations.localeOf(context).languageCode]!["error"]!)),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildShimmerLayout(context);
          } else if (snapshot.hasError) {
            return Center(
                child: Text(
                    '${appStrings[Localizations.localeOf(context).languageCode]!["error"]!} : ${snapshot.error}'));
          } else if (!snapshot.hasData) {
            return Center(
                child: Text(
                    appStrings[Localizations.localeOf(context).languageCode]![
                    "no_data"]!));
          } else {
            final detailsData = snapshot.data!["details"]?["details"]?["data"];
            final eventsData = snapshot.data!["events"]?["events"]?["data"];

            if (detailsData == null) {
              return Center(
                  child: Text(
                      appStrings[Localizations.localeOf(context).languageCode]![
                      "no_data"]!));
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
                      backgroundColor: theme.primaryColor,
                      elevation: 0,
                      flexibleSpace: FlexibleSpaceBar(
                        background: _buildHeader(detailsData),
                        titlePadding: EdgeInsets.zero,
                        centerTitle: true,
                        title: const SizedBox.shrink(),
                      ),
                      bottom: TabBar(
                        tabs: tabs.map((t) => t.tab).toList(),
                        isScrollable: true,
                        tabAlignment: TabAlignment.start,
                        labelColor: Colors.blueGrey,
                        unselectedLabelColor: Colors.white,
                        labelStyle: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 14),
                        unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.normal, fontSize: 14),
                        indicatorSize: TabBarIndicatorSize.tab,
                        indicator: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: colorScheme.onPrimary.withOpacity(0.15),
                        ),
                        indicatorPadding:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                      ),
                    ),
                  ];
                },
                body: tabs.isEmpty
                    ? Center(
                    child: Text(appStrings[
                    Localizations.localeOf(context).languageCode]![
                    "no_data"]!))
                    : Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: TabBarView(
                    children: tabs.map((t) => t.view).toList(),
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildShimmerLayout(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bodyShimmerColor =
    isDark ? Colors.grey.shade700 : Colors.grey.shade300;

    final headerShimmerColor = Colors.white.withOpacity(0.2);

    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          // Shimmer for the Header (AppBar)
          Container(
            height: 240.0 + kToolbarHeight,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            color: Theme.of(context).primaryColorDark.withOpacity(0.9),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: kToolbarHeight),
                // Shimmer for Championship info
                Container(
                  width: 120,
                  height: 16,
                  decoration: BoxDecoration(
                    color: headerShimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 32),
                // Shimmer for Teams and Score
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Home Team Shimmer
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                              radius: 30, backgroundColor: headerShimmerColor),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: headerShimmerColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Score Shimmer
                    Container(
                      width: 100,
                      height: 40,
                      decoration: BoxDecoration(
                        color: headerShimmerColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // Away Team Shimmer
                    Expanded(
                      child: Column(
                        children: [
                          CircleAvatar(
                              radius: 30, backgroundColor: headerShimmerColor),
                          const SizedBox(height: 8),
                          Container(
                            width: 80,
                            height: 16,
                            decoration: BoxDecoration(
                              color: headerShimmerColor,
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Shimmer for Tabs area
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(
                4,
                    (index) => Container(
                  width: 70,
                  height: 20,
                  decoration: BoxDecoration(
                    color: bodyShimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                )),
          ),
          const Divider(height: 24),
          // Shimmer for Tab Content (e.g., Summary)
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  // Title shimmer
                  width: 150,
                  height: 24,
                  decoration: BoxDecoration(
                    color: bodyShimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                _buildShimmerEventItem(color: bodyShimmerColor),
                const SizedBox(height: 12),
                _buildShimmerEventItem(color: bodyShimmerColor, isHome: false),
                const SizedBox(height: 12),
                _buildShimmerEventItem(color: bodyShimmerColor),
                const SizedBox(height: 24),
                Container(
                  // Title shimmer
                  width: 120,
                  height: 24,
                  decoration: BoxDecoration(
                    color: bodyShimmerColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                _buildShimmerStatRow(color: bodyShimmerColor),
                const SizedBox(height: 12),
                _buildShimmerStatRow(color: bodyShimmerColor),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildShimmerEventItem({bool isHome = true, required Color color}) {
    return Row(
      children: [
        if (isHome)
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
            ),
          ),
        const SizedBox(width: 8),
        CircleAvatar(radius: 21, backgroundColor: color),
        const SizedBox(width: 8),
        if (!isHome)
          Expanded(
            child: Container(
              height: 50,
              decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(8)),
            ),
          ),
      ],
    );
  }

  Widget _buildShimmerStatRow({required Color color}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
                width: 30,
                height: 16,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
            Container(
                width: 80,
                height: 16,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
            Container(
                width: 30,
                height: 16,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(4))),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          height: 10,
          decoration: BoxDecoration(
              color: color, borderRadius: BorderRadius.circular(10)),
        ),
      ],
    );
  }

  Widget _buildHeader(Map<String, dynamic> data) {
    final homeTeam = data["home_team"];
    final awayTeam = data["away_team"];
    final championship = data["championship"];

    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          'images/stade.png',
          fit: BoxFit.cover,
        ),
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 4.0, sigmaY: 4.0),
          child: Container(
            color: Colors.black.withOpacity(0.4),
          ),
        ),
        Column(
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
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.white70),
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
      ],
    );
  }

  Widget _buildTeamDisplay(Map<String, dynamic>? team,
      {Color color = Colors.black}) {
    if (team == null) return const Expanded(child: SizedBox.shrink());
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.network(
            "https://imgs.ysscores.com/teams/64/${team['image']}",
            width: 60,
            height: 60,
            errorBuilder: (_, __, ___) =>
                Icon(Icons.shield, size: 60, color: color.withOpacity(0.7)),
          ),
          const SizedBox(height: 8),
          Text(
            team['title'] ??
                appStrings[Localizations.localeOf(context).languageCode]![
                "unknown"]!,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontWeight: FontWeight.bold, fontSize: 16, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreAndTimeDisplay(Map<String, dynamic> data) {
    // This builder will run every second, getting the current time 'now'
    return ValueListenableBuilder<DateTime>(
      valueListenable: _clock.listenable,
      builder: (context, now, __) {
        final status = data['status']?.toString() ?? '0';
        final locale = Localizations.localeOf(context).languageCode;
        Widget statusWidget;

        // --- 1. Live Match ---
        final isPlaying = status == '1' || status == '3';
        if (isPlaying) {
          final kickOffTimestamp = data['match_timestamp'] as int?;
          int displayMinutes = 0;

          if (kickOffTimestamp != null) {
            final kickOff =
            DateTime.fromMillisecondsSinceEpoch(kickOffTimestamp * 1000)
                .toLocal();

            if (status == '1') {
              // First Half
              displayMinutes = now.difference(kickOff).inMinutes;
            } else {
              // status == '3', Second Half
              final htTimestamp = data['ht_time'] as int?;
              if (htTimestamp != null) {
                final secondHalfStartTime =
                DateTime.fromMillisecondsSinceEpoch(htTimestamp * 1000)
                    .toLocal();
                displayMinutes =
                    45 + now.difference(secondHalfStartTime).inMinutes;
              } else {
                // Fallback if halftime timestamp is missing
                displayMinutes = now.difference(kickOff).inMinutes;
              }
            }
          }
          // Clamp minutes to a reasonable range
          displayMinutes = displayMinutes.clamp(0, 140);

          statusWidget = Text(
            "${displayMinutes}'", // Display current minute with a '
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          );

          // --- 2. Halftime Break ---
        } else if (status == '2') {
          statusWidget = Text(
            appStrings[locale]!["break"]!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          );

          // --- 3. Ended Match ---
        } else if (status == '4' || status == '11') {
          statusWidget = Text(
            appStrings[locale]!["match_ended"]!,
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.bold),
          );

          // --- 4. Not Started Match (with Timezone Correction) ---
        } else {
          final fixtureTimeString = data['match_time'] as String?;
          String timeText = appStrings[locale]!["not_started"]!;

          if (fixtureTimeString != null && fixtureTimeString.isNotEmpty) {
            try {
              // a. Parse time from server
              final timeParts = fixtureTimeString.split(':');
              final serverTime = DateTime.now().copyWith(
                  hour: int.parse(timeParts[0]),
                  minute: int.parse(timeParts[1]),
                  second: 0,
                  millisecond: 0,
                  microsecond: 0
              );

              // b. Calculate difference between user's timezone and server's (UTC+3)
              const serverOffsetInMinutes = 180; // UTC+3 is 180 minutes
              final userOffsetInMinutes = now.timeZoneOffset.inMinutes;
              final differenceInMinutes =
                  userOffsetInMinutes - serverOffsetInMinutes;

              // c. Apply difference to get correct local time
              final correctedKickOffTime =
              serverTime.add(Duration(minutes: differenceInMinutes));

              timeText =
                  DateFormat('h:mm a', locale).format(correctedKickOffTime);
            } catch (e) {
              // Fallback to original time string if parsing fails
              timeText = fixtureTimeString.substring(0,5);
            }
          }
          statusWidget = Text(timeText,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold));
        }

        // The final layout for the score and status widget
        return Column(
          children: [
            Text(
              '${data['home_scores'] ?? '?'} - ${data['away_scores'] ?? '?'}',
              style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 2.0),
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
                  // Show live dot if playing or in break
                  if (isPlaying || status == '2')
                    Container(
                      width: 8,
                      height: 8,
                      margin: const EdgeInsetsDirectional.only(end: 6),
                      decoration: const BoxDecoration(
                          color: Colors.redAccent, shape: BoxShape.circle),
                    ),
                  statusWidget,
                ],
              ),
            ),
          ],
        );
      },
    );
  }


  List<_TabInfo> _buildTabs(Map<String, dynamic> detailsData,
      Map<String, dynamic>? eventsData) {
    final List<_TabInfo> tabs = [];

    final eventsList = eventsData?['events'] as List?;
    final hasEvents =
        eventsData != null && eventsList != null && eventsList.isNotEmpty;
    final stats = detailsData['statics_match'] as Map<String, dynamic>?;
    final hasStats = stats != null && stats.isNotEmpty;
    final Locale currentLocale = Localizations.localeOf(context);
    if (hasEvents || hasStats) {
      tabs.add(_TabInfo(
        tab: Tab(text: appStrings[currentLocale.languageCode]!["summary"]!),
        view: _buildSummaryTabView(detailsData, eventsData),
      ));
    }

    tabs.add(_TabInfo(
      tab: Tab(text: appStrings[currentLocale.languageCode]!["details"]!),
      view: _buildDetailsTab(detailsData),
    ));

    tabs.add(_TabInfo(
      tab: Tab(text: appStrings[currentLocale.languageCode]!["lineup"]!),
      view: LineupTabView(
        matchId: widget.id,
        detailsData: detailsData,
        lang: currentLocale.languageCode,
      ),
    ));

    final playedResult = detailsData['played_result'] as Map<String, dynamic>?;
    final hasPlayedResult =
        playedResult != null && (playedResult['home'] as Map?)?.isNotEmpty == true;
    if (hasPlayedResult) {
      tabs.add(_TabInfo(
        tab: Tab(
            text: appStrings[currentLocale.languageCode]!["confrontations"]!),
        view: _buildRecentMatchesTab(playedResult),
      ));
    }

    tabs.add(_TabInfo(
      tab: Tab(text: appStrings[currentLocale.languageCode]!["videos"]!),
      view: VideosTap(
        MatchId: widget.id.toString(),
        lang: currentLocale.languageCode,
      ),
    ));

    tabs.add(_TabInfo(
      tab: Tab(text: appStrings[currentLocale.languageCode]!["ranks"]!),
      view: StandingsTab(
        leagueId: widget.leagueId,
        lang: currentLocale.languageCode,
      ),
    ));

    tabs.add(_TabInfo(
      tab: Tab(text: appStrings[currentLocale.languageCode]!["news"]!),
      view: NewsTabView(
        matchRowId: widget.RowId,
        lang: currentLocale.languageCode,
      ),
    ));

    return tabs;
  }

  Widget _buildSummaryTabView(
      Map<String, dynamic> detailsData, Map<String, dynamic>? eventsData) {
    final eventsList = eventsData?['events'] as List?;
    final hasEvents =
        eventsData != null && eventsList != null && eventsList.isNotEmpty;

    final stats = detailsData['statics_match'] as Map<String, dynamic>?;
    final hasStats = stats != null && stats.isNotEmpty;

    if (!hasEvents && !hasStats) {
      return Center(
        child: Text(
            appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!),
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
                Text(
                    appStrings[Localizations.localeOf(context).languageCode]![
                    "events"]!,
                    style: Theme.of(context).textTheme.titleLarge),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      textStyle: const TextStyle(fontWeight: FontWeight.bold)),
                  child: Text(_showKeyEventsOnly
                      ? appStrings[Localizations.localeOf(context)
                      .languageCode]!["show_all"]!
                      : appStrings[Localizations.localeOf(context)
                      .languageCode]!["only_important"]!),
                  onPressed: () {
                    setState(() => _showKeyEventsOnly = !_showKeyEventsOnly);
                  },
                )
              ],
            ),
            const SizedBox(height: 8),
            _buildFullEventsView(
              eventsData,
              detailsData["home_team"]?["row_id"],
              isKeyEventsOnly: _showKeyEventsOnly,
            ),
          ],
          if (hasEvents && hasStats) const Divider(height: 40, thickness: 1),
          if (hasStats) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Text(
                  appStrings[Localizations.localeOf(context).languageCode]![
                  "statistics"]!,
                  style: Theme.of(context).textTheme.titleLarge),
            ),
            _buildStatsTab(stats, detailsData['home_team'],
                detailsData['away_team'],
                isNested: true),
          ]
        ],
      ),
    );
  }

  Widget _buildFullEventsView(Map<String, dynamic>? eventsData, int? homeTeamId,
      {bool isKeyEventsOnly = false}) {
    final eventsListFull =
    (eventsData?["events"] as List<dynamic>? ?? []).reversed.toList();

    final eventsList = isKeyEventsOnly
        ? eventsListFull
        .where((e) => e['type'] == 1 || e['type'] == 3 || e['type'] == 22)
        .toList()
        : eventsListFull;

    if (eventsList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0),
        child: Center(
            child: Text(appStrings[
            Localizations.localeOf(context).languageCode]!["no_data"]!)),
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
          return _SystemEventChip(
            event: event,
            lang: widget.lang,
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
                child: isHomeEvent
                    ? _EventTimelineCard(event: event)
                    : const SizedBox()),
            _TimeIndicatorCircle(event: event),
            Expanded(
                child: !isHomeEvent
                    ? _EventTimelineCard(event: event, isHomeEvent: false)
                    : const SizedBox()),
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
            shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                        appStrings[Localizations.localeOf(context)
                            .languageCode]!["match_details"]!,
                        style: Theme.of(context).textTheme.titleLarge),
                  ),
                  const Divider(),
                  _buildInfoTile(
                      Icons.calendar_today_outlined,
                      appStrings[Localizations.localeOf(context)
                          .languageCode]!["history"]!,
                      data['match_date']),
                  _buildInfoTile(
                      Icons.sports_soccer_outlined,
                      appStrings[Localizations.localeOf(context)
                          .languageCode]!["championship"]!,
                      data['championship']?['title']),
                  _buildInfoTile(
                      Icons.stadium_outlined,
                      appStrings[Localizations.localeOf(context)
                          .languageCode]!["stadium"]!,
                      data['Stadium']),
                  _buildInfoTile(
                      Icons.flag_outlined,
                      appStrings[Localizations.localeOf(context)
                          .languageCode]!["round"]!,
                      data['round']),
                ],
              ),
            ),
          ),
          if (channels.isNotEmpty) const SizedBox(height: 16),
          if (channels.isNotEmpty)
            Card(
              elevation: 2,
              margin: const EdgeInsets.all(0),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                          appStrings[Localizations.localeOf(context)
                              .languageCode]!["channels"]!,
                          style: Theme.of(context).textTheme.titleLarge),
                    ),
                    const Divider(),
                    ...channels
                        .map((ch) => _buildInfoTile(
                      Icons.tv_outlined,
                      ch['channel_name'] ??
                          appStrings[Localizations.localeOf(context)
                              .languageCode]!["unknown"]!,
                      ch['commentator_name'],
                    ))
                        .toList(),
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
          Expanded(
              child: _buildTeamRecentMatches(
                  homeMatches.first['home']?['title'], homeMatches)),
          const SizedBox(width: 16),
          Expanded(
              child: _buildTeamRecentMatches(
                  awayMatches.first['away']?['title'], awayMatches)),
        ],
      ),
    );
  }

  Widget _buildStatsTab(Map<String, dynamic> stats,
      Map<String, dynamic>? homeTeam, Map<String, dynamic>? awayTeam,
      {bool isNested = false}) {
    final homeStats = stats[homeTeam?['row_id']?.toString()];
    final awayStats = stats[awayTeam?['row_id']?.toString()];

    if (homeStats == null || awayStats == null) {
      return Center(
          child: Text(
              appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!));
    }

    final content = Column(
      children: [
        _buildStatRow(
            appStrings[Localizations.localeOf(context).languageCode]![
            "possession"]!,
            homeStats['ball_possession'],
            awayStats['ball_possession'],
            isPercentage: true),
        _buildStatRow(
            appStrings[Localizations.localeOf(context).languageCode]!["shots"]!,
            homeStats['total_shots'],
            awayStats['total_shots']),
        _buildStatRow(
            appStrings[Localizations.localeOf(context).languageCode]!["fouls"]!,
            homeStats['fouls'],
            awayStats['fouls']),
        _buildStatRow(
            appStrings[Localizations.localeOf(context).languageCode]![
            "offsides"]!,
            homeStats['offsides'],
            awayStats['offsides']),
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
      leading: Icon(icon, color: Colors.blueGrey),
      title: Text(title),
      subtitle: Text(value, style: Theme.of(context).textTheme.bodyLarge),
      dense: true,
    );
  }

  Widget _buildTeamRecentMatches(String? teamName, List<dynamic> matches) {
    Color getResultColor(String? winType) {
      switch (winType) {
        case 'win':
          return Colors.green.shade700;
        case 'lose':
          return Colors.red.shade700;
        case 'equal':
          return Colors.orange.shade700;
        default:
          return Colors.grey;
      }
    }

    String getResultLetter(String? winType) {
      switch (winType) {
        case 'win':
          return appStrings[Localizations.localeOf(context).languageCode]!["f"]!;
        case 'lose':
          return appStrings[Localizations.localeOf(context).languageCode]!["l"]!;
        case 'equal':
          return appStrings[Localizations.localeOf(context).languageCode]!["d"]!;
        default:
          return '-';
      }
    }

    return Column(
      children: [
        Text(teamName ?? '',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                        color: getResultColor(match['win_type']),
                        borderRadius: BorderRadius.circular(4)),
                    child: Center(
                        child: Text(getResultLetter(match['win_type']),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold))),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildStatRow(
      String title, dynamic homeValue, dynamic awayValue,
      {bool isPercentage = false}) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

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
              Text(hVal.toString(),
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              Text(title,
                  style: textTheme.bodyMedium
                      ?.copyWith(color: colorScheme.onSurfaceVariant)),
              Text(aVal.toString(),
                  style: textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(10)),
            child: Row(
              children: [
                Expanded(
                    flex: homeFlex.toInt(),
                    child: Container(height: 10, color: colorScheme.primary)),
                Expanded(
                    flex: awayFlex.toInt(),
                    child: Container(
                        height: 10,
                        color: colorScheme.surfaceContainerHighest)),
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
  final String lang;
  const _SystemEventChip({Key? key, required this.event, required this.lang})
      : super(key: key);

  String getEventTitle() {
    if (event['type'] == 13) return appStrings[lang]!["match_started"]!;
    if (event['type'] == 5) return appStrings[lang]!["end_first_half"]!;
    if (event['type'] == 6) return appStrings[lang]!["start_second_half"]!;
    if (event['type'] == 7) return appStrings[lang]!["match_ended"]!;
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
    if (title.isEmpty) return const SizedBox.shrink();

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: Chip(
          avatar: Icon(getEventIcon(), size: 16), // Color will be inherited
          label: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
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
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    final timeMin = event["time_minute"] ?? 0;
    final timePlus = event["time_plus"] ?? 0;
    final timeStr = timePlus > 0 ? "$timeMin'.." : "$timeMin'";

    final bool isImportantEvent =
        event['type'] == 1 || event['type'] == 3 || event['type'] == 22;
    final bgColor = isImportantEvent
        ? colorScheme.primaryContainer
        : colorScheme.surfaceContainerHighest;
    final textColor = isImportantEvent
        ? colorScheme.onPrimaryContainer
        : textTheme.bodySmall?.color;

    return Container(
      width: 42,
      height: 42,
      margin: const EdgeInsets.symmetric(horizontal: 6.0),
      decoration: BoxDecoration(
          color: bgColor,
          shape: BoxShape.circle,
          border: Border.all(color: colorScheme.outlineVariant, width: 0.5)),
      child: Center(
        child: Text(
          timeStr,
          style: TextStyle(
              fontWeight: FontWeight.bold, color: textColor, fontSize: 11),
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
    final eventInfo =
    _getEventInfo(context, type, player, assist, isHomeEvent);

    final bool isGoal = type == 1;

    final content = Row(
      mainAxisAlignment:
      isHomeEvent ? MainAxisAlignment.start : MainAxisAlignment.end,
      children: [
        if (isHomeEvent) eventInfo.icon,
        if (isHomeEvent) const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment:
            isHomeEvent ? CrossAxisAlignment.start : CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(eventInfo.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14),
                  textAlign: isHomeEvent ? TextAlign.start : TextAlign.end),
              if (player != null)
                Text(player,
                    style: const TextStyle(fontSize: 12),
                    textAlign: isHomeEvent ? TextAlign.start : TextAlign.end),
              if (eventInfo.details != null) const SizedBox(height: 2),
              if (eventInfo.details != null) eventInfo.details!,
            ],
          ),
        ),
        if (!isHomeEvent) const SizedBox(width: 8),
        if (!isHomeEvent) eventInfo.icon,
      ],
    );

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4.0),
      decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(8),
          border: isGoal
              ? Border.all(color: Colors.green.withOpacity(0.4), width: 1)
              : null,
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 4,
                offset: const Offset(0, 1))
          ]),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: () => _launchVideoUrl(videoUrl, context),
          child: Padding(
            padding:
            const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
            child: Stack(
              alignment: Alignment.center,
              children: [
                content,
                if (hasVideo)
                  Positioned(
                      bottom: -2,
                      left: isHomeEvent ? -2 : null,
                      right: !isHomeEvent ? -2 : null,
                      child: Icon(Icons.play_circle_filled_rounded,
                          color: Theme.of(context).primaryColor, size: 16)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

_EventDisplayInfo _getEventInfo(BuildContext context, int type, String? player,
    String? assist, bool isHomeEvent) {
  final colorScheme = Theme.of(context).colorScheme;

  switch (type) {
    case 1:
      return _EventDisplayInfo(
          icon: const Icon(Icons.sports_soccer, color: Colors.green, size: 18),
          title: appStrings[Localizations.localeOf(context).languageCode]![
          "goal"]!,
          details: assist != null
              ? Text(
              "${appStrings[Localizations.localeOf(context).languageCode]!["assists"]!} : $assist",
              style: TextStyle(
                  color: colorScheme.onSurfaceVariant, fontSize: 11))
              : null);
    case 3:
      return _EventDisplayInfo(
          icon: const Icon(Icons.style, color: Colors.red, size: 18),
          title: appStrings[Localizations.localeOf(context).languageCode]![
          "red_card"]!,
          details: null);
    case 2:
      return _EventDisplayInfo(
          icon: const Icon(Icons.style, color: Colors.amber, size: 18),
          title: appStrings[Localizations.localeOf(context).languageCode]![
          "yellow_card"]!,
          details: null);
    case 8:
      return _EventDisplayInfo(
          icon: const Icon(Icons.swap_horiz_rounded,
              color: Colors.blue, size: 18),
          title: appStrings[Localizations.localeOf(context).languageCode]![
          "substitution"]!,
          details: RichText(
              textAlign: isHomeEvent ? TextAlign.start : TextAlign.end,
              text: TextSpan(
                style: DefaultTextStyle.of(context)
                    .style
                    .copyWith(fontSize: 11),
                children: [
                  TextSpan(
                      text:
                      '${appStrings[Localizations.localeOf(context).languageCode]!["in"]!}: ',
                      style: TextStyle(color: Colors.green.shade700)),
                  TextSpan(
                      text: '$player ',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(
                      text:
                      '${appStrings[Localizations.localeOf(context).languageCode]!["out"]!}: ',
                      style: TextStyle(color: Colors.red.shade700)),
                  TextSpan(
                      text: '$assist',
                      style: TextStyle(
                          color: colorScheme.onSurfaceVariant,
                          decoration: TextDecoration.lineThrough)),
                ],
              )));
    case 22:
      return _EventDisplayInfo(
          icon: Icon(Icons.radio_button_checked,
              color: colorScheme.secondary, size: 18),
          title: appStrings[Localizations.localeOf(context).languageCode]![
          "penalty"]!,
          details: null);
    case 23:
      return _EventDisplayInfo(
          icon:
          Icon(Icons.cancel_outlined, color: colorScheme.error, size: 18),
          title: appStrings[Localizations.localeOf(context).languageCode]![
          "penalty_missed"]!,
          details: null);
    default:
      return _EventDisplayInfo(
          icon: Icon(Icons.info_outline,
              color: colorScheme.onSurfaceVariant, size: 18),
          title:
          appStrings[Localizations.localeOf(context).languageCode]!["event"]!,
          details: null);
  }
}