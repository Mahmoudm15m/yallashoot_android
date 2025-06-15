import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:yallashoot/locator.dart';
import 'package:yallashoot/settings_provider.dart';

class ApiData {
  late Map<String, String> headers;

  ApiData() {
    _updateHeaders();
    locator<SettingsProvider>().addListener(_updateHeaders);
  }

  void _updateHeaders() {
    final settings = locator<SettingsProvider>();
    headers = {
      'user-agent': 'Dart/3.5 (dart:io)',
      'language': settings.locale.languageCode,
      'timezone': settings.timeZoneOffset.toString(),
    };
    print("Headers updated reactively: $headers"); // للتحقق
  }


  final String baseUrl = "http://185.224.129.206:5000/api/v2";

  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'), headers: headers);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching data: $error');
    }
  }

  Future<Map<String, dynamic>> fetchUpdateData(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('https://api.syria-live.fun/$endpoint'), headers: headers);
      if (response.statusCode == 200) {
        final decodedBody = utf8.decode(response.bodyBytes);
        return json.decode(decodedBody) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching data: $error');
    }
  }

  // ... باقي الدوال كما هي بدون أي تغيير
  Future<Map<String, dynamic>> getHomeData() async {
    return await fetchData("matches");
  }
  Future<Map<String, dynamic>> checkUpdate(int v) async {
    return await fetchUpdateData("app/check_update?v=$v");
  }
  Future<Map<String, dynamic>> getRanksData() async {
    return await fetchData("ranks");
  }
  Future<Map<String, dynamic>> getTransfaresData() async {
    return await fetchData("transfares");
  }
  Future<Map<String, dynamic>> getNewsData() async {
    return await fetchData("news");
  }
  Future<Map<String, dynamic>> getLivesData() async {
    final url = "https://api.syria-live.fun/api/v2/lives" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMatchesData(String date) async {
    return await fetchData("matches?date=$date");
  }
  Future<dynamic> getChampionStanding(String champion) async {
    final url = "http://185.224.129.206:5000/api/v2/champion_standing?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getCupStanding(String champion) async {
    final url = "http://185.224.129.206:5000/api/v2/cup_standing?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getChampionGroups(String champion) async {
    final url = "http://185.224.129.206:5000/api/v2/champion_groups?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getChampionMatches(String champion) async {
    final url = "http://185.224.129.206:5000/api/v2/champion_matches?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getChampionScorers(String champion) async {
    final url = "http://185.224.129.206:5000/api/v2/champion_scorers?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getChampionAssists(String champion) async {
    final url = "http://185.224.129.206:5000/api/v2/champion_assists?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getTeamInfo(String teamId) async {
    final url = "http://185.224.129.206:5000/api/v2/team_info?team_id=$teamId" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getPlayerInfo(String playerId) async {
    final url = "http://185.224.129.206:5000/api/v2/player_info?player_id=$playerId" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getTeamMatches(String teamId) async {
    final url = "http://185.224.129.206:5000/api/v2/team_matches?team_id=$teamId" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getSearchResults({String? q}) async {
    final baseUrl = "http://185.224.129.206:5000/api/v2/search";
    final url = q == null || q.isEmpty ? baseUrl : "$baseUrl?q=$q";
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getAds() async {
    final baseUrl = "http://185.224.129.206:5000/api/v2/ads";
    final response = await http.get(Uri.parse(baseUrl));
    return jsonDecode(response.body);
  }

  Future<Map<String, dynamic>> getMatchDetails(String id) async {
    return await fetchData("matches/$id/details");
  }
  Future<Map<String, dynamic>> getMatchLinesUp(String id) async {
    return await fetchData("matches/$id/lineup");
  }
  Future<Map<String, dynamic>> getMatchEvents(String id) async {
    return await fetchData("matches/$id/events");
  }
  Future<Map<String, dynamic>> getMatchVideos(String id) async {
    return await fetchData("matches/$id/videos");
  }
  Future<Map<String, dynamic>> getMatchNews(String id) async {
    return await fetchData("match_news?row_id=$id");
  }
  Future<Map<String, dynamic>> getNewsDetails(String id) async {
    return await fetchData("news_detail/$id");
  }
  Future<Map<String, dynamic>> getMatchLeagueRanks(String id) async {
    return await fetchData("league_rank?match_id=$id");
  }
  Future<Map<String, dynamic>> getLeague(String link) async {
    return await fetchData("get_league?link=$link");
  }
  Future<Map<String, dynamic>> getLeagueRanks(String id) async {
    return await fetchData("get_league_ranks?rank_id=$id");
  }

}