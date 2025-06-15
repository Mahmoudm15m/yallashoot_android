import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../screens/player_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class LineupTabView extends StatefulWidget {
  final String matchId;
  final String lang;
  final Map<String, dynamic> detailsData;

  const LineupTabView(
      {super.key,
        required this.matchId,
        required this.detailsData,
        required this.lang});

  @override
  State<LineupTabView> createState() => _LineupTabViewState();
}

class _LineupTabViewState extends State<LineupTabView> {
  late Future<Map<String, dynamic>> _lineupFuture;
  late final ApiData apiData;

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    _lineupFuture = apiData.getMatchLinesUp(widget.matchId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _lineupFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final baseColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
          final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: _buildShimmerLayout(context),
          );
        }
        if (snapshot.hasError ||
            !snapshot.hasData ||
            snapshot.data?['lineup']?['data']?['lineup'] == null) {
          return Center(
              child: Text(appStrings[
              Localizations.localeOf(context).languageCode]!["no_data"]!));
        }

        final lineupData = snapshot.data!['lineup']['data'];
        final homeTeamId = widget.detailsData['home_team']['row_id'].toString();
        final awayTeamId = widget.detailsData['away_team']['row_id'].toString();

        final homeLineup = lineupData['lineup'] != null ? lineupData['lineup'][homeTeamId] : null;
        final awayLineup = lineupData['lineup'] != null ? lineupData['lineup'][awayTeamId] : null;
        final formations = lineupData['0'];

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
                      formation: formations?['home_formation'],
                      coach: formations?['home_coach'],
                    ),
                    _TeamLineupView(
                      lineup: awayLineup,
                      formation: formations?['away_formation'],
                      coach: formations?['away_coach'],
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

  Widget _buildShimmerLayout(BuildContext context) {
    final shimmerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
          child: Row(
            children: [
              Expanded(
                  child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(8)))),
              const SizedBox(width: 16),
              Expanded(
                  child: Container(
                      height: 28,
                      decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(8)))),
            ],
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: _TeamLineupViewShimmer(shimmerColor: shimmerColor),
        ),
      ],
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
      return Center(
          child: Text(
              appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!));
    }
    final startingPlayers =
    (lineup!['lineup'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
    final substitutePlayers = (lineup!['substitutions'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();


    return SingleChildScrollView(
      child: Column(
        children: [
          _FootballPitch(players: startingPlayers, formation: formation),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                _SectionTitle(
                    title:
                    "${appStrings[Localizations.localeOf(context).languageCode]!["coach"]!}: ${coach?['title'] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!}"),
                const SizedBox(height: 24),
                _SectionTitle(
                    title: appStrings[
                    Localizations.localeOf(context).languageCode]!["substitutions"]!),
                const SizedBox(height: 12),
                _SubstitutesList(players: substitutePlayers),
              ],
            ),
          ),
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
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Text(
            "${appStrings[Localizations.localeOf(context).languageCode]!["formations"]!} : ${formation ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!}",
            textAlign: TextAlign.center,
            style: TextStyle(
                color: Colors.teal[900],
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5),
          ),
        ),
        AspectRatio(
          aspectRatio: 5 / 4.5,
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("images/lineup.png"),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3),
                    Colors.transparent,
                    Colors.black.withOpacity(0.5),
                  ],
                ),
              ),
              child: _buildPlayerMarkers(context, players),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPlayerMarkers(BuildContext context, List<Map<String, dynamic>> players) {
    final bool hasDynamicCoordinates = players.isNotEmpty &&
        players.every((p) => p['lineup_x'] != null && p['lineup_y'] != null);

    if (hasDynamicCoordinates) {
      return _buildPlayerMarkersWithCoordinates(context, players);
    } else {
      return _buildPlayerMarkersByPosition(context, players);
    }
  }

  Widget _buildPlayerMarkersWithCoordinates(BuildContext context, List<Map<String, dynamic>> players) {
    return LayoutBuilder(builder: (context, constraints) {
      if (constraints.maxWidth == 0 || constraints.maxHeight == 0) {
        return const SizedBox.shrink();
      }
      List<Widget> markers = [];
      const double assumedMaxX = 100.0;
      const double assumedMaxY = 100.0;

      for (var player in players) {
        final double lineupX = double.tryParse(player['lineup_x'].toString()) ?? 50.0;
        final double lineupY = double.tryParse(player['lineup_y'].toString()) ?? 50.0;

        double yFraction = 1.0 - (lineupX / assumedMaxX);
        yFraction = (yFraction.clamp(0.0, 1.0) * 0.85) + 0.1;

        double xFraction = lineupY / assumedMaxY;
        xFraction = (xFraction.clamp(0.0, 1.0) * 0.9) + 0.05;

        final String position = player['position'] ?? '';
        if (position == 'G' || position == 'GK') {
          yFraction = 0.92;
          xFraction = 0.5;
        }


        double markerSize = constraints.maxWidth / 7.5;

        markers.add(Positioned(
          top: yFraction * constraints.maxHeight - (markerSize / 1.5),
          left: xFraction * constraints.maxWidth - (markerSize / 2),
          child: _PlayerMarker(
            player: player,
            size: markerSize,
          ),
        ));
      }
      return Stack(children: markers);
    });
  }

  Widget _buildPlayerMarkersByPosition(BuildContext context, List<Map<String, dynamic>> players) {
    Map<String, List<Map<String, dynamic>>> groupedPlayers = {
      'G': [], 'D': [], 'M': [], 'F': [], 'S': []
    };

    for (var p in players) {
      final pos = p['position'];
      if (groupedPlayers.containsKey(pos)) {
        groupedPlayers[pos]!.add(p);
      } else if (pos == 'GK') {
        groupedPlayers['G']!.add(p);
      }
    }

    return LayoutBuilder(builder: (context, constraints) {
      List<Widget> markers = [];

      const List<String> formationOrder = ['S', 'F', 'M', 'D'];
      final activeLines = formationOrder.where((key) => groupedPlayers[key]!.isNotEmpty).toList();
      final lineCount = activeLines.length;

      final Map<String, double> positionsY = {};
      if (lineCount > 0) {
        const double topBoundary = 0.12;
        const double bottomBoundary = 0.78;
        const double verticalRange = bottomBoundary - topBoundary;

        for (int i = 0; i < lineCount; i++) {
          final lineKey = activeLines[i];
          final double yPosition = topBoundary + (lineCount > 1 ? (i * (verticalRange / (lineCount - 1))) : verticalRange / 2);
          positionsY[lineKey] = yPosition;
        }
      }
      positionsY['G'] = 0.92;

      final allLinesToDraw = ['S', 'F', 'M', 'D', 'G'];

      for (var lineKey in allLinesToDraw) {
        var linePlayers = groupedPlayers[lineKey]!;
        if (linePlayers.isEmpty) continue;

        for (int i = 0; i < linePlayers.length; i++) {
          var player = linePlayers[i];
          double x = (i + 1) / (linePlayers.length + 1);
          double y = positionsY[lineKey]!;

          double markerSize = constraints.maxWidth / 7.5;

          markers.add(Positioned(
            top: y * constraints.maxHeight - (markerSize / 1.5),
            left: x * constraints.maxWidth - (markerSize / 2),
            child: _PlayerMarker(
              player: player,
              size: markerSize,
            ),
          ));
        }
      }
      return Stack(children: markers);
    });
  }
}

class _PlayerMarker extends StatelessWidget {
  final Map<String, dynamic> player;
  final double size;

  const _PlayerMarker({required this.player, this.size = 64});

  @override
  Widget build(BuildContext context) {
    final pData = player['player'];
    final name = pData['title'] as String;
    final image = pData['image'] as String?;
    final number = pData['player_number']?.toString();

    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) {
          final Locale currentLocale = Localizations.localeOf(context);
          return PlayerScreen(
              playerId: pData['row_id'].toString(),
              lang: currentLocale.languageCode);
        }));
      },
      child: SizedBox(
        width: size,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [

                Container(
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.4),
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        )
                      ]
                  ),
                  child: CircleAvatar(
                    radius: size * 0.4,
                    backgroundImage: image != null
                        ? NetworkImage("https://imgs.ysscores.com/player/150/$image")
                        : null,
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: image == null
                        ? Icon(Icons.person,
                        size: size * 0.45,
                        color: Theme.of(context).colorScheme.secondary)
                        : null,
                  ),
                ),
                if (number != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      child: Text(
                        number,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: size * 0.19,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.75),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                name,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: size * 0.16,
                    color: Colors.white,
                    fontWeight: FontWeight.bold),
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
    if (players.isEmpty) {
      return Center(
        child: Text(
          appStrings[Localizations.localeOf(context).languageCode]!["no_substitutes"] ?? "No substitutes available",
          style: TextStyle(color: Colors.grey.shade600),
        ),
      );
    }


    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final pData = players[index]['player'];
        final image = pData['image'] as String?;
        final number = pData['player_number']?.toString();
        final name = pData['title'] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!;
        final colorScheme = Theme.of(context).colorScheme;

        return Card(
          elevation: 0,
          margin: const EdgeInsets.symmetric(vertical: 5.0),
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Theme.of(context).dividerColor.withOpacity(0.5)),
          ),
          child: InkWell(
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                final Locale currentLocale = Localizations.localeOf(context);
                return PlayerScreen(
                    playerId: pData['row_id'].toString(),
                    lang: currentLocale.languageCode);
              }));
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundImage: image != null
                        ? NetworkImage("https://imgs.ysscores.com/player/150/$image")
                        : null,
                    backgroundColor: colorScheme.surfaceContainerHighest,
                    child: image == null
                        ? Icon(Icons.person,
                        size: 24, color: colorScheme.onSurfaceVariant)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        name,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                    ),
                  ),
                  if (number != null)
                    Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        number,
                        style: TextStyle(
                          color: colorScheme.onPrimaryContainer,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}


class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 20,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              borderRadius: BorderRadius.circular(2)
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}


class _TeamLineupViewShimmer extends StatelessWidget {
  final Color shimmerColor;
  const _TeamLineupViewShimmer({required this.shimmerColor});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const NeverScrollableScrollPhysics(),
      child: Column(
        children: [
          _ShimmerPitch(shimmerColor: shimmerColor),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),

                Row(children: [
                  Container(width: 5, height: 20, color: shimmerColor),
                  const SizedBox(width: 8),
                  Container(width: 150, height: 20, color: shimmerColor),
                ]),
                const SizedBox(height: 24),

                Row(children: [
                  Container(width: 5, height: 20, color: shimmerColor),
                  const SizedBox(width: 8),
                  Container(width: 120, height: 20, color: shimmerColor),
                ]),
                const SizedBox(height: 12),
                _ShimmerSubstitutesList(shimmerColor: shimmerColor),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ShimmerPitch extends StatelessWidget {
  final Color shimmerColor;
  const _ShimmerPitch({required this.shimmerColor});

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 5 / 4.5,
      child: Container(
        decoration: BoxDecoration(
          color: shimmerColor,
        ),
      ),
    );
  }
}

class _ShimmerSubstitutesList extends StatelessWidget {
  final Color shimmerColor;
  const _ShimmerSubstitutesList({required this.shimmerColor});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(5, (i) =>
          Card(
            elevation: 0,
            margin: const EdgeInsets.symmetric(vertical: 5.0),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: shimmerColor.withOpacity(0.5)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Row(
                children: [
                  CircleAvatar(radius: 22, backgroundColor: shimmerColor),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      height: 16,
                      decoration: BoxDecoration(
                          color: shimmerColor,
                          borderRadius: BorderRadius.circular(4)
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: shimmerColor,
                        borderRadius: BorderRadius.circular(10)
                    ),
                  ),
                ],
              ),
            ),
          )
      ),
    );
  }
}
