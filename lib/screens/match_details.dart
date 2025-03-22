import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import '../api/main_api.dart';
import '../functions/base_functions.dart';
import 'news_details_screen.dart';
import 'package:url_launcher/url_launcher.dart';

class MatchDetails extends StatefulWidget {
  final String id;
  const MatchDetails({required this.id, Key? key}) : super(key: key);

  @override
  _MatchDetailsState createState() => _MatchDetailsState();
}

class _MatchDetailsState extends State<MatchDetails> with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> futureResults;
  late Future<Map<String, dynamic>> futureLineup;
  late Future<Map<String, dynamic>> futureEvents;
  late Future<Map<String, dynamic>> futureNews;
  late Future<Map<String, dynamic>> futureStanding;
  bool showHomeTeam = true;
  ApiData yasScore = ApiData();

  Timer? _timer;
  Duration _timeRemaining = Duration.zero;

  Future<Map<String, dynamic>> fetchDetails() async {
    try {
      final data = await yasScore.getMatchDetails(widget.id);
      // تحويل الخريطة الرئيسية إلى Map<String, dynamic>
      return Map<String, dynamic>.from(data);
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    futureResults = fetchDetails();
    futureLineup = yasScore.getMatchLinesUp(widget.id);
    futureEvents = yasScore.getMatchEvents(widget.id);
    futureStanding = yasScore.getMatchLeagueRanks(widget.id);
    futureNews = yasScore.getMatchNews(widget.id);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String formatDuration(Duration duration) {
    if (duration.isNegative) return "00:00:00";
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$hours:$minutes:$seconds";
  }

  DateTime parseMatchDateTime(String datetimeStr) {
    try {
      final format = DateFormat("EEE, dd MMM yyyy HH:mm:ss 'GMT'");
      return format.parseUtc(datetimeStr).toLocal();
    } catch (e) {
      return DateTime.now();
    }
  }

  void _startCountdown(DateTime matchDateTime) {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final remaining = matchDateTime.difference(now);
      if (remaining.isNegative) {
        _timer?.cancel();
      }
      setState(() {
        _timeRemaining = remaining;
      });
    });
  }

  Widget buildLoadingScreen() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[400]!,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget buildTeamHeader(Map<String, dynamic> teams, Map<String, dynamic> matchInfo) {
    final homeTeam = Map<String, dynamic>.from(teams['home']);
    final awayTeam = Map<String, dynamic>.from(teams['away']);
    String homeScore = "";
    String awayScore = "";
    if (matchInfo.containsKey('score') && matchInfo['score'] is Map) {
      final score = Map<String, dynamic>.from(matchInfo['score']);
      homeScore = score['home'] ?? "";
      awayScore = score['away'] ?? "";
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            children: [
              if (homeTeam['logo'] != null)
                Image.network(
                  homeTeam['logo'],
                  width: 80,
                  height: 80,
                ),
              const SizedBox(height: 8),
              Text(
                homeTeam['name'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (homeScore.isNotEmpty)
                Text(
                  homeScore,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                ),
            ],
          ),
          const Icon(Icons.sports_soccer, size: 40, color: Colors.grey),
          Column(
            children: [
              if (awayTeam['logo'] != null)
                Image.network(
                  awayTeam['logo'],
                  width: 80,
                  height: 80,
                ),
              const SizedBox(height: 8),
              Text(
                awayTeam['name'] ?? '',
                style: const TextStyle(
                  fontSize: 18,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (awayScore.isNotEmpty)
                Text(
                  awayScore,
                  style: const TextStyle(fontSize: 16, fontFamily: 'Cairo'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildMatchStatusSection(Map<String, dynamic> matchInfo) {
    final String status = matchInfo['status'] ?? "";
    final String datetimeStr = matchInfo['datetime'] ?? "";
    DateTime matchDateTime = parseMatchDateTime(datetimeStr);

    String displayText;
    Color backgroundColor;
    IconData iconData;

    if (matchDateTime.isAfter(DateTime.now())) {
      if (_timer == null || !_timer!.isActive) {
        _startCountdown(matchDateTime);
      }
      displayText = "تبدأ المباراة خلال: ${formatDuration(_timeRemaining)}";
      backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      iconData = Icons.schedule;
    } else if (status.contains("إنتهت") || status.contains("انتهت")) {
      displayText = "انتهت المباراة";
      backgroundColor = Theme.of(context).colorScheme.tertiaryContainer;
      iconData = Icons.check_circle_outline;
    } else {
      displayText = "المباراة جارية";
      backgroundColor = Theme.of(context).colorScheme.secondaryContainer;
      iconData = Icons.play_arrow;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(iconData,
              color: Theme.of(context).colorScheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              displayText,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSecondaryContainer,
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget buildMatchInfoTab(Map<String, dynamic> info) {
    // دالة مساعدة لبناء بطاقة معلومات واحدة
    Widget infoCard({required IconData icon, required String label, required String value}) {
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: ListTile(
          leading: Icon(icon, color: Theme.of(context).colorScheme.primary),
          title: Text(
            label,
            style: const TextStyle(
              fontFamily: 'Cairo',
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Text(
            value,
            style: const TextStyle(fontFamily: 'Cairo'),
          ),
        ),
      );
    }

    // بطاقة تعرض قائمة القنوات مع فاصل بين كل قناة
    Widget channelsCard() {
      final channels = info['channels'];
      if (channels == null || channels.isEmpty) return Container();
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "القنوات",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              ...channels.map<Widget>((channel) {
                final channelMap = Map<String, dynamic>.from(channel);
                final commentator = channelMap['commentator'] is Map
                    ? Map<String, dynamic>.from(channelMap['commentator'])
                    : {};
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.tv, color: Colors.green, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              channelMap['name'] ?? "",
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              commentator['name'] ?? "",
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }

    // بطاقة تعرض قائمة الحكام مع فاصل بين كل حكم
    Widget refereesCard() {
      final referees = info['referees'];
      if (referees == null || referees.isEmpty) return Container();
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 3,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "الحكام",
                style: TextStyle(
                  fontFamily: 'Cairo',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Divider(),
              ...referees.map<Widget>((referee) {
                final refereeMap = Map<String, dynamic>.from(referee);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel, color: Colors.brown, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              refereeMap['name'] ?? "",
                              style: const TextStyle(
                                fontFamily: 'Cairo',
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              refereeMap['role'] ?? "",
                              style: const TextStyle(fontFamily: 'Cairo', fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          infoCard(
            icon: Icons.access_time,
            label: "الوقت",
            value: formatTime(info['time']),
          ),
          infoCard(
            icon: Icons.calendar_today,
            label: "التاريخ",
            value: info['date'],
          ),
          infoCard(
            icon: Icons.emoji_events,
            label: "الدوري",
            value: info['tournament']['name'],
          ),
          infoCard(
            icon: Icons.format_list_numbered,
            label: "الجولة",
            value: info['round']?? "ودي",
          ),
          infoCard(
            icon: Icons.stadium,
            label: "الملعب",
            value: info['stadium']?['name'] ?? "",
          ),
          channelsCard(),
          refereesCard(),
        ],
      ),
    );
  }

  Widget buildLastFiveMatchesCircles(String teamLabel, List matches) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamLabel,
            style: const TextStyle(
                fontFamily: 'Cairo',
                fontSize: 16,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Row(
          children: matches.map<Widget>((match) {
            Color circleColor;
            String txt ;
            String result = (match['result'] ?? '').toString().toLowerCase();
            if (result == 'win') {
              circleColor = Colors.green;
              txt = "ف";
            } else if (result == 'loss') {
              circleColor = Colors.red;
              txt = "خ";
            } else if (result == 'draw') {
              circleColor = Colors.grey;
              txt = "ع";
            } else {
              circleColor = Colors.black;
              txt = "؟";
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CircleAvatar(
                radius: 12,
                backgroundColor: circleColor,
                child: Text(txt),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget buildLastFiveMatchesSection(Map<String, dynamic> lastFiveMatches) {
    List homeMatches = lastFiveMatches['home'] ?? [];
    List awayMatches = lastFiveMatches['away'] ?? [];
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (homeMatches.isNotEmpty)
            buildLastFiveMatchesCircles("آخر خمس مباريات (المضيف)", homeMatches),
          if (awayMatches.isNotEmpty) ...[
            const SizedBox(height: 12),
            buildLastFiveMatchesCircles("آخر خمس مباريات (الضيف)", awayMatches),
          ],
        ],
      ),
    );
  }

  Widget buildVideosTab(List videos) {
    if (videos.isEmpty) {
      return const Center(
        child: Text(
          "لا توجد فيديوهات.",
          style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: videos.length,
      itemBuilder: (context, index) {
        final video = Map<String, dynamic>.from(videos[index]);
        final videoUrl = video['url']?.toString() ?? "";
        final title = video['title']?.toString() ?? "فيديو بدون عنوان";
        final type = video['type']?.toString() ?? "";

        if (videoUrl.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ListTile(
              contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              title: Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => launchUrl(Uri.parse(videoUrl), mode: LaunchMode.externalApplication),
                    child: Text(
                      videoUrl,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    type,
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              trailing: Icon(Icons.play_circle_fill, color: Colors.blue, size: 30),
              onTap: () => launchUrl(Uri.parse(videoUrl), mode: LaunchMode.externalApplication),
            ),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget buildEventsTab() {
    return FutureBuilder(
      future: futureEvents,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: buildLoadingScreen());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              "لا توجد احداث حاليا.",
              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final matchData = data["events"]?["data"] as Map<String, dynamic>? ?? {};
        final eventsList = matchData["events"] as List<dynamic>? ?? [];
        final homeTeam = matchData["home_team"] as Map<String, dynamic>? ?? {};
        final awayTeam = matchData["away_team"] as Map<String, dynamic>? ?? {};


        // دالة لمطابقة رقم الفريق مع اسم الفريق المناسب
        String getTeamName(int teamId) {
          if (teamId == homeTeam["row_id"]) {
            return homeTeam["title"];
          } else if (teamId == awayTeam["row_id"]) {
            return awayTeam["title"];
          } else {
            return "نظام";
          }
        }

        // دالة لتحويل نوع الحدث إلى نصوص مفهومة
        String getEventTypeDescription(int type) {
          switch (type) {
            case 1:
            case 2:
              return "هدف";
            case 8:
              return "تبديل";
            case 100:
              return "توقف/وقت إضافي";
            default:
              return "حدث";
          }
        }

        // دالة لاختيار الأيقونة واللون المناسب لكل نوع حدث
        Icon getEventIcon(int type, String teamName) {
          if (teamName == "نظام") {
            return Icon(Icons.timer_off, color: Colors.grey);
          }
          switch (type) {
            case 1:
            case 2:
              return Icon(Icons.sports_soccer, color: Colors.green);
            case 8:
              return Icon(Icons.swap_horiz, color: Colors.orange);
            case 100:
              return Icon(Icons.pause, color: Colors.red);
            default:
              return Icon(Icons.event, color: Colors.blue);
          }
        }

        // دالة لتحديد رسالة نظام خاصة بناءً على الوقت وقيمة time_plus
        String getSystemMessage(int timeMinute, int timePlus) {
          if (timeMinute == 0) {
            return "بدأت المباراة";
          } else if (timeMinute == 45) {
            // إذا كان time_plus == 45 فهذا يعني بداية الشوط التاني
            if (timePlus == 45) {
              return "بدأ الشوط التاني";
            } else {
              return "انتهى الشوط الأول";
            }
          } else if (timeMinute >= 90) {
            return "انتهت المباراة";
          } else {
            return "حدث نظام";
          }
        }

        // دالة لتنسيق عرض الوقت، بالنسبة للأحداث النظامية نتجاهل time_plus
        String formatEventTime(int timeMinute, int timePlus, int type) {
          if (type == 100) {
            // عرض الوقت الأساسي فقط للأحداث النظامية
            return "$timeMinute";
          } else {
            return timePlus > 0 ? "$timeMinute+$timePlus" : "$timeMinute";
          }
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: eventsList.length,
          itemBuilder: (context, index) {
            final event = eventsList[index] as Map<String, dynamic>;
            final int timeMinute = event["time_minute"] ?? 0;
            final int timePlus = event["time_plus"] ?? 0;
            final int type = event["type"] ?? 0;
            final int teamId = event["team_id"] ?? 0;
            final String teamName = getTeamName(teamId);
            String eventType = getEventTypeDescription(type);
            final String eventTime = formatEventTime(timeMinute, timePlus, type);

            // إذا كان الحدث نظامي، نستخدم رسالة النظام الخاصة مع التمييز بين انتهاء الشوط وبداية الشوط التاني
            if (teamName == "نظام") {
              eventType = getSystemMessage(timeMinute, timePlus);
            }

            String playerName = "";
            if (event["player_name"] != null &&
                event["player_name"] is Map<String, dynamic>) {
              playerName = event["player_name"]["title"] ?? "";
            }

            String assistName = "";
            if (event["assist_player_name"] != null &&
                event["assist_player_name"] is Map<String, dynamic>) {
              assistName = event["assist_player_name"]["title"] ?? "";
            }

            final eventIcon = getEventIcon(type, teamName);

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              elevation: 3,
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green,
                  radius: 25,
                  child: Text(
                    eventTime,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
                title: Row(
                  children: [
                    eventIcon,
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        "$eventType${(type != 8 && playerName.isNotEmpty) ? ' - $playerName' : ''}",
                        style: TextStyle(
                          fontFamily: 'Cairo',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // إذا كان الحدث تبديل، نعرض معلومات الدخول والخروج
                    if (type == 8)
                      Row(
                        children: [
                          Icon(Icons.swap_horiz, color: Colors.orange, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "الدخول: ${assistName.isNotEmpty ? assistName : 'غير محدد'} - الخروج: ${playerName.isNotEmpty ? playerName : 'غير محدد'}",
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      )
                    // إذا كان الحدث تمرير حاسم
                    else if (assistName.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.forward, color: Colors.purple, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "تمرير حاسم: $assistName",
                              style: TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    if (teamName != "نظام")
                      Row(
                        children: [
                          Icon(Icons.group, color: Colors.brown, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            "الفريق: $teamName",
                            style: TextStyle(fontFamily: 'Cairo'),
                          ),
                        ],
                      ),
                    if (event["status_name"] != null)
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.red, size: 16),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "الحالة: ${event["status_name"]}",
                              style: TextStyle(
                                fontFamily: 'Cairo',
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget buildStatCard(String statLabel, Map<String, dynamic> statData,
      Map<String, dynamic> teams) {
    String homeValue = statData['home']
        ?.toString()
        .trim()
        .replaceAll(RegExp(r'\s+'), '') ??
        "";
    String awayValue = statData['away']
        ?.toString()
        .trim()
        .replaceAll(RegExp(r'\s+'), '') ??
        "";
    String? homeLogo = teams['home']['logo'];
    String? awayLogo = teams['away']['logo'];
    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              children: [
                if (homeLogo != null)
                  Image.network(homeLogo, width: 40, height: 40),
                const SizedBox(height: 4),
                Text(homeValue, style: const TextStyle(fontFamily: 'Cairo')),
              ],
            ),
            Text(statLabel,
                style: const TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
            Column(
              children: [
                if (awayLogo != null)
                  Image.network(awayLogo, width: 40, height: 40),
                const SizedBox(height: 4),
                Text(awayValue, style: const TextStyle(fontFamily: 'Cairo')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildStatisticsTab(Map<String, dynamic> statistics, Map<String, dynamic> teams) {
    List<Widget> statWidgets = [];
    statistics.forEach((key, value) {
      if (value is Map) {
        String label;
        if (key == 'possession') {
          label = "الاستحواذ";
        } else if (key == 'shots') {
          label = "التسديدات";
        } else if (key == 'shots_on_target') {
          label = "التسدسدات علي المرمى";
        } else if (key == "shots_off_target"){
          label = "التسديدات خارج المرمى" ;
        } else if (key == "corners"){
          label = "الركنيات" ;
        } else if (key == "blocked_shots"){
          label = "الكرات المنقذه" ;
        } else if (key == "offsides"){
          label = "التسللات" ;
        } else if (key == "fouls"){
          label = "الاخطاء" ;
        } else if (key == "saves"){
          label = "الانقاذات" ;
        } else if (key == "yellow_cards"){
          label = "بطاقات صفراء" ;
        } else if (key == "yellow_cards"){
          label = "بطاقات جمراء" ;
        } else {
          label = key;
        }
        final statMap = Map<String, dynamic>.from(value);
        statWidgets.add(buildStatCard(label, statMap, teams));
      } else {
        statWidgets.add(
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              title: Text(key,
                  style: const TextStyle(
                      fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
              trailing: Text(value.toString().replaceAll(" ", ""),
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
        );
      }
    });
    return ListView(
      padding: const EdgeInsets.all(12),
      children: statWidgets,
    );
  }

  Widget buildLineupTab() {
    return FutureBuilder(
      future: futureLineup,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: buildLoadingScreen());
        } else if (snapshot.hasError ||
            !snapshot.hasData ||
            (snapshot.data as Map).isEmpty) {
          return const Center(
              child: Text("لا توجد بيانات التشكيل.",
                  style: TextStyle(color: Colors.red, fontSize: 18)));
        }

        final lineupData =
        Map<String, dynamic>.from((snapshot.data as Map)['lineup']);
        final matchInfo = Map<String, dynamic>.from(lineupData['match_info']);
        final String homeTeamId = matchInfo['home_team_id'];
        final String awayTeamId = matchInfo['away_team_id'];
        final homeTeamLineup =
        Map<String, dynamic>.from(lineupData['teams'][homeTeamId] ?? {});
        final awayTeamLineup =
        Map<String, dynamic>.from(lineupData['teams'][awayTeamId] ?? {});

        return SingleChildScrollView(
          padding: const EdgeInsets.all(12),
          child: Column(
            children: [
              // عرض بيانات المدربين مع اسم الفريق تحت كل مدرب مع تظليل المدرب المختار
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showHomeTeam = true;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: showHomeTeam
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            buildCoachInfo(matchInfo['home_coach']),
                            const SizedBox(height: 8),
                            Text(
                              homeTeamLineup['team_name'] ?? "المضيف",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          showHomeTeam = false;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: !showHomeTeam
                              ? Colors.blue.withOpacity(0.2)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            buildCoachInfo(matchInfo['away_coach']),
                            const SizedBox(height: 8),
                            Text(
                              awayTeamLineup['team_name'] ?? "الضيف",
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // عرض تشكيل الفريق المحدد (مع تقليل مساحة الملعب لزيادة تماسك العناصر)
              Container(
                height: 600,
                child: showHomeTeam
                    ? buildSingleFormationPitch(
                  teamLineup: homeTeamLineup,
                  formation: matchInfo['home_formation'] ?? "",
                  isHome: true,
                )
                    : buildSingleFormationPitch(
                  teamLineup: awayTeamLineup,
                  formation: matchInfo['away_formation'] ?? "",
                  isHome: false,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget buildCoachInfo(dynamic coachData) {
    if (coachData is Map) {
      final coach = Map<String, dynamic>.from(coachData);
      return Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        child: ListTile(
          leading: (coach['image_url'] != null)
              ? Image.network(coach['image_url'], width: 40, height: 40)
              : null,
          title: Text("المدرب: ${coach['name']}",
              style: const TextStyle(
                  fontFamily: 'Cairo', fontWeight: FontWeight.bold)),
        ),
      );
    }
    return Container();
  }

  Widget buildSingleFormationPitch({
    required Map<String, dynamic> teamLineup,
    required String formation,
    required bool isHome,
  }) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final double pitchWidth = constraints.maxWidth;
        final double pitchHeight = constraints.maxHeight;
        const double topMargin = 10;
        const double bottomMargin = 10;
        const double gkHeight = 50;

        List starting = teamLineup['starting_lineup'] ?? [];
        final goalkeeper = starting.firstWhere(
              (p) => p['position_group'] == 'G',
          orElse: () => null,
        );
        final List outfield =
        starting.where((p) => p['position_group'] != 'G').toList();
        final List<int> formationRows =
        formation.split('-').map((s) => int.tryParse(s) ?? 0).toList();
        final int rows = formationRows.isNotEmpty ? formationRows.length : 1;

        // بدء رسم أرض الملعب من بعد الحارس (الذي سيظهر دائماً في الأعلى)
        final double outfieldStart = topMargin + gkHeight;
        final double outfieldEnd = pitchHeight - bottomMargin;
        final double outfieldHeight = outfieldEnd - outfieldStart;
        final double rowHeight = outfieldHeight / rows;

        List<Widget> playerWidgets = [];
        int index = 0;
        for (int i = 0; i < rows; i++) {
          int count = formationRows[i];
          if (index + count > outfield.length) {
            count = outfield.length - index;
          }
          final List rowPlayers = outfield.sublist(index, index + count);
          index += count;
          final double yPos = outfieldStart + i * rowHeight + rowHeight / 2;
          playerWidgets.add(Positioned(
            top: yPos - 25,
            left: 0,
            width: pitchWidth,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: rowPlayers.map<Widget>((player) {
                return Column(
                  children: [
                    CircleAvatar(
                      backgroundImage: (player['image_url'] != null)
                          ? NetworkImage(player['image_url'])
                          : null,
                      radius: 25,
                      backgroundColor: Colors.white,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      player['name'] ?? "",
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ));
        }

        if (goalkeeper != null) {
          playerWidgets.add(Positioned(
            top: topMargin,
            left: pitchWidth / 2 - 25,
            child: Column(
              children: [
                CircleAvatar(
                  backgroundImage: (goalkeeper['image_url'] != null)
                      ? NetworkImage(goalkeeper['image_url'])
                      : null,
                  radius: 25,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  goalkeeper['name'] ?? "",
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ],
            ),
          ));
        }

        return Stack(
          children: [
            Container(
              width: pitchWidth,
              height: pitchHeight,
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            ...playerWidgets,
          ],
        );
      },
    );
  }

  Widget buildPreviousEncountersTab(List encounters) {
    if (encounters.isEmpty) {
      return const Center(
        child: Text("لا توجد مواجهات سابقة.",
            style: TextStyle(fontSize: 16, fontFamily: 'Cairo')),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: encounters.length,
      itemBuilder: (context, index) {
        final encounter = Map<String, dynamic>.from(encounters[index]);
        return Card(
          elevation: 3,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.symmetric(vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.sports_soccer, color: Colors.redAccent),
            title: Text(
              "${encounter['home_team']} vs ${encounter['away_team']}",
              style: const TextStyle(
                  fontSize: 16,
                  fontFamily: 'Cairo',
                  fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("النتيجة: ${encounter['score']}",
                    style: const TextStyle(
                        fontSize: 16, fontFamily: 'Cairo')),
                Text("التاريخ: ${encounter['date']}",
                    style: const TextStyle(
                        fontSize: 16, fontFamily: 'Cairo')),
                Text("الدوري: ${encounter['tournament']}",
                    style: const TextStyle(
                        fontSize: 16, fontFamily: 'Cairo')),
              ],
            ),
            onTap: () {
              // تنفيذ عملية عند الضغط على المواجهة
            },
          ),
        );
      },
    );
  }

  Widget buildStandingsTab() {
    return FutureBuilder(
      future: futureStanding,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: buildLoadingScreen());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              "لا توجد بيانات للترتيب.",
              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
            ),
          );
        }

        final data = Map<String, dynamic>.from(snapshot.data as Map);
        final league = data['league'] as Map<String, dynamic>;
        final List teamsRanking = league['teams_ranking'] ?? [];

        if (teamsRanking.isEmpty) {
          return Center(
            child: Text(
              "لا توجد بيانات للترتيب.",
              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
            ),
          );
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: SingleChildScrollView(
            child: DataTable(
              columnSpacing: 12,
              headingRowColor: MaterialStateColor.resolveWith(
                    (states) => Colors.blueAccent.shade100,
              ),
              columns: const [
                DataColumn(
                  label: Text(
                    "الترتيب",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "الفريق",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "لعب",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "فوز",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "تعادل",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "خسارة",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "أهداف",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "فرق",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
                DataColumn(
                  label: Text(
                    "نقاط",
                    style: TextStyle(
                        fontFamily: 'Cairo', fontWeight: FontWeight.bold),
                  ),
                ),
              ],
              rows: teamsRanking.map<DataRow>((team) {
                final teamInfo = team['team_info'] as Map<String, dynamic>;
                final stats = team['stats'] as Map<String, dynamic>;
                return DataRow(
                  cells: [
                    DataCell(
                      Text(
                        team['position'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          if (teamInfo['image_url'] != null)
                            Image.network(
                              teamInfo['image_url'],
                              width: 30,
                              height: 30,
                            ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              teamInfo['name'] ?? "",
                              style: const TextStyle(fontFamily: 'Cairo'),
                            ),
                          ),
                        ],
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['matches_played'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['wins'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['draws'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['losses'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['goals_for'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['goal_difference'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                    DataCell(
                      Text(
                        stats['points'].toString(),
                        style: const TextStyle(fontFamily: 'Cairo'),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget buildNewsTab() {
    return FutureBuilder(
      future: futureNews,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: buildLoadingScreen());
        } else if (snapshot.hasError || !snapshot.hasData) {
          return Center(
            child: Text(
              "لا توجد بيانات للترتيب.",
              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
            ),
          );
        }

        final data = snapshot.data as Map<String, dynamic>;
        final List<dynamic> news = data['news'];

        if (news.isEmpty) {
          return Center(
            child: Text(
              "لا توجد بيانات.",
              style: TextStyle(fontSize: 16, fontFamily: 'Cairo'),
            ),
          );
        }

        return ListView.builder(
          itemCount: news.length,
          padding: EdgeInsets.symmetric(vertical: 10),
          itemBuilder: (context, index) {
            final Map<String, dynamic> child = news[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: IconButton(
                icon: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            child["title"],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            child["created_at"],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ],
                      ),
                    ),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: MediaQuery.of(context).size.width * 0.9,
                        child: Image.network(
                          child["image"].toString().replaceAll("/150/", "/820/"),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Divider(height: 20, thickness: 1),
                  ],
                ),
                onPressed: (){
                  Navigator.push(context, MaterialPageRoute(builder: (context){
                    return NewsDetailsScreen(id: extractIdFromUrl(child["link"]).toString(),
                        img: child["image"].toString().replaceAll("/150/", "/820/"));
                  }));
                },
                padding: EdgeInsets.zero,
              ),
            );
          },
        );
      },
    );
  }

  Widget buildPredictionTab(Map<String, dynamic> prediction) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: const ListTile(
              title: Text(
                "توقعات المباراة",
                style: TextStyle(
                    fontFamily: 'Cairo', fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.home, color: Colors.blue),
              title: const Text("فوز الفريق المضيف",
                  style: TextStyle(fontFamily: 'Cairo')),
              trailing: Text(
                  prediction['home'] is Map
                      ? prediction['home']['text'] ?? ""
                      : prediction['home'] ?? "",
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.remove, color: Colors.orange),
              title: const Text("تعادل",
                  style: TextStyle(fontFamily: 'Cairo')),
              trailing: Text(
                  prediction['draw'] is Map
                      ? prediction['draw']['text'] ?? ""
                      : prediction['draw'] ?? "",
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
          Card(
            elevation: 3,
            margin: const EdgeInsets.symmetric(vertical: 6),
            child: ListTile(
              leading: const Icon(Icons.sports_soccer, color: Colors.red),
              title: const Text("فوز الفريق الضيف",
                  style: TextStyle(fontFamily: 'Cairo')),
              trailing: Text(
                  prediction['away'] is Map
                      ? prediction['away']['text'] ?? ""
                      : prediction['away'] ?? "",
                  style: const TextStyle(fontFamily: 'Cairo')),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        setState(() {
          futureResults = fetchDetails();
        });
        await futureResults;
      },
      child: FutureBuilder(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(title: const Text("تفاصيل المباراة")),
              body: Center(child: buildLoadingScreen()),
            );
          } else if (snapshot.hasError ||
              !snapshot.hasData ||
              (snapshot.data as Map).isEmpty) {
            return Scaffold(
              appBar: AppBar(title: const Text("تفاصيل المباراة")),
              body: const Center(
                child: Text("لا توجد بيانات متاحة.",
                    style: TextStyle(color: Colors.red, fontSize: 18)),
              ),
            );
          }
          final detailsData = Map<String, dynamic>.from(snapshot.data as Map);
          final details = Map<String, dynamic>.from(detailsData['details']);
          final matchInfo = Map<String, dynamic>.from(details['match_info']);
          final teams = Map<String, dynamic>.from(details['teams']);
          final videos = details['videos'] ?? [];
          final statistics = details['statistics'] ?? {};
          final lastEncounters = details['last_encounters'] ?? [];
          final lastFiveMatches = details['last_five_matches'] ?? {};
          final prediction = details['prediction'] ?? {};

          return DefaultTabController(
            length: 9,
            child: Scaffold(
              appBar: AppBar(
                title: const Text("تفاصيل المباراة"),
                // إزالة التبويبات من AppBar
              ),
              body: Column(
                children: [
                  buildTeamHeader(teams, matchInfo),
                  buildMatchStatusSection(matchInfo),
                  // استخدام Padding بدلاً من Container مع إزالة الخلفية واللون الأزرق
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: TabBar(
                      isScrollable: true,
                      // استخدام ألوان تعتمد على ثيم التطبيق الحالي
                      labelColor: Theme.of(context).colorScheme.onBackground,
                      unselectedLabelColor: Theme.of(context).disabledColor,
                      indicatorColor: Theme.of(context).colorScheme.primary,
                      tabs: const [
                        Tab(text: "معلومات المباراة"),
                        Tab(text: "الأحداث"),
                        Tab(text: "فيديوهات"),
                        Tab(text: "الإحصائيات"),
                        Tab(text: "التشكيل"),
                        Tab(text: "المواجهات السابقة"),
                        Tab(text: "الترتيب"),
                        Tab(text: "الاخبار"),
                        Tab(text: "التوقعات"),
                      ],
                    ),
                  ),
                  const Divider(),
                  Expanded(
                    child: TabBarView(
                      children: [
                        SingleChildScrollView(
                          child: Column(
                            children: [
                              buildMatchInfoTab(matchInfo),
                              buildLastFiveMatchesSection(
                                  Map<String, dynamic>.from(lastFiveMatches)),
                            ],
                          ),
                        ),
                        buildEventsTab(),
                        buildVideosTab(videos),
                        buildStatisticsTab(Map<String, dynamic>.from(statistics), teams),
                        buildLineupTab(),
                        buildPreviousEncountersTab(lastEncounters),
                        buildStandingsTab(),
                        buildNewsTab(),
                        buildPredictionTab(Map<String, dynamic>.from(prediction)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

}
