import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yallashoot/screens/league_screen.dart';
import 'package:yallashoot/screens/player_screen.dart';
import 'package:yallashoot/screens/team_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class SearchScreen extends StatefulWidget {
  late final String lang ;
  SearchScreen({
    required this.lang,
});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final ApiData api;
  late Future<Map<String, dynamic>> futureResults;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;


  final ScrollController _champController = ScrollController();
  final ScrollController _playerController = ScrollController();
  final ScrollController _teamController = ScrollController();

  @override
  void initState() {
    super.initState();
    api = ApiData();
    futureResults = fetchSearch();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _champController.dispose();
    _playerController.dispose();
    _teamController.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchSearch() async {
    try {
      return await api.getSearchResults();
    } catch (_) {
      return {};
    }
  }

  Future<Map<String, dynamic>> fetchSearchResults(String q) async {
    try {
      return await api.getSearchResults(q: q);
    } catch (_) {
      return {};
    }
  }

  void _onSearchDebounced(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () => _performSearch(query));
  }

  void _performSearch(String q) {
    setState(() {
      futureResults = fetchSearchResults(q);
    });
  }

  Widget _buildSection<T>({
    required String title,
    required List<T> items,
    required Widget Function(T) itemBuilder,
    required ScrollController controller,
  }) {
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 100,
          child: Scrollbar(
            controller: controller,
            thumbVisibility: true,
            child: SingleChildScrollView(
              controller: controller,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: Row(
                children: items
                    .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: itemBuilder(item),
                ))
                    .toList(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _controller,
          decoration: InputDecoration(
            hintText: appStrings[Localizations.localeOf(context).languageCode]!["search_here"]!,
            border: InputBorder.none,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(vertical: 8),
          ),
          onChanged: _onSearchDebounced,
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || snap.data == null || snap.data!['data'] == null) {
            return Center(child: Text(
              appStrings[Localizations.localeOf(context).languageCode]!["error"]!,
              style: const TextStyle(color: Colors.red),
            ));
          }
          final data = snap.data!['data'] as Map<String, dynamic>;
          final champs = List<Map<String, dynamic>>.from(data['championship'] ?? []);
          final players = List<Map<String, dynamic>>.from(data['player'] ?? []);
          final teams = List<Map<String, dynamic>>.from(data['teams'] ?? []);
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection<Map<String, dynamic>>(
                  title: appStrings[Localizations.localeOf(context).languageCode]!["championships"]!,
                  items: champs,
                  controller: _champController,
                  itemBuilder: (item) {
                    final name = item['name'] as Map<String, dynamic>;
                    final imageHex = name['image'] as String;
                    final imgUrl =
                        'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/championship/64/$imageHex';
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context){
                          final Locale currentLocale = Localizations.localeOf(context);
                          return LeagueScreen(id: item["name"]['url_id'].toString(), lang: currentLocale.languageCode,);
                        }));
                      },
                      child: Column(
                        children: [
                          SizedBox(height: 60, child: Image.network(imgUrl, fit: BoxFit.contain)),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 80,
                            child: Text(
                              name['title'],
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _buildSection<Map<String, dynamic>>(
                  title: appStrings[Localizations.localeOf(context).languageCode]!["players"]!,
                  items: players,
                  controller: _playerController,
                  itemBuilder: (item) {
                    final name = item['name'] as Map<String, dynamic>;
                    final imageHex = name['image'] as String;
                    final imgUrl =
                        'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/player/150/$imageHex';
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context){
                          final Locale currentLocale = Localizations.localeOf(context);
                          return PlayerScreen(playerId: item['id'].toString(), lang: currentLocale.languageCode,);
                        }));
                      },
                      child: Column(
                        children: [
                          CircleAvatar(backgroundImage: NetworkImage(imgUrl), radius: 30),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 80,
                            child: Text(
                              name['title'],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                _buildSection<Map<String, dynamic>>(
                  title: appStrings[Localizations.localeOf(context).languageCode]!["teams"]!,
                  items: teams,
                  controller: _teamController,
                  itemBuilder: (item) {
                    final name = item['name'] as Map<String, dynamic>;
                    final imageHex = name['image'] as String;
                    final imgUrl =
                        'https://api.syria-live.fun/img_proxy?url=https://imgs.ysscores.com/teams/64/$imageHex';
                    return InkWell(
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context){
                          final Locale currentLocale = Localizations.localeOf(context);
                          return TeamScreen(teamID: item['id'].toString(), lang: currentLocale.languageCode,);
                        }));
                      },
                      child: Column(
                        children: [
                          SizedBox(height: 60, child: Image.network(imgUrl, fit: BoxFit.contain)),
                          const SizedBox(height: 4),
                          SizedBox(
                            width: 80,
                            child: Text(
                              name['title'],
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
