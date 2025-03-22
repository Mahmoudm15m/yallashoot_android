import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiData {
  final String baseUrl = "https://api.fastmovies.online/api/v1";

  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/$endpoint'));
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

  Future<Map<String, dynamic>> getHomeData() async {
    return await fetchData("matches");
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
  Future<Map<String, dynamic>> getMatchesData(String date) async {
    return await fetchData("matches?date=$date");
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
  Future<Map<String, dynamic>> getMatchNews(String id) async {
    return await fetchData("matches/$id/news");
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
