import 'dart:async';
import 'package:flutter/material.dart';
import 'package:yallashoot/screens/league_screen.dart';
import 'package:yallashoot/screens/player_screen.dart';
import 'package:yallashoot/screens/team_screen.dart';
import '../api/main_api.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final ApiData api = ApiData();
  late Future<Map<String, dynamic>> futureResults;
  final TextEditingController _controller = TextEditingController();
  Timer? _debounce;

  // Controllers for horizontal scrolling
  final ScrollController _champController = ScrollController();
  final ScrollController _playerController = ScrollController();
  final ScrollController _teamController = ScrollController();

  @override
  void initState() {
    super.initState();
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
          decoration: const InputDecoration(
            hintText: 'ابحث هنا...',
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
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
            return const Center(child: Text('خطأ في جلب النتائج'));
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
                  title: 'الدوريات',
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
                          return LeagueScreen(id: item["name"]['url_id'].toString());
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
                  title: 'اللاعبون',
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
                          return PlayerScreen(playerId: item['id'].toString());
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
                  title: 'الفرق',
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
                          return TeamScreen(teamID: item['id'].toString());
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
