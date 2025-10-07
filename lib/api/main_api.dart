import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:yallashoot/locator.dart';
import 'package:yallashoot/settings_provider.dart';

class ApiData {
  late Map<String, String> headers;

  ApiData() {
    _updateHeaders();
    locator<SettingsProvider>().addListener(_updateHeaders);
  }

  static const _aesKeyHex = "4e5c6d1a8b3fe8137a3b9df26a9c4de195267b8e6f6c0b4e1c3ae1d27f2b4e6f";
  static const _ivHex = "a9c21f8d7e6b4a9db12e4f9d5c1a7b8e";

  void _updateHeaders() {
    final settings = locator<SettingsProvider>();
    headers = {
      'user-agent': 'Dart/3.5 (dart:io)',
      'language': settings.locale.languageCode,
      'timezone': settings.timeZoneOffset.toString(),
    };
  }

  final String baseUrl = "https://api.syria-live.fun/api/v2";

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

  Future<Map<String, dynamic>> fetchOData(String endpoint) async {
    try {
      // 1. توليد Subdomain عشوائي
      final randomSubdomain = _generateRandomString();
      final url = "https://${randomSubdomain}.s-25.shop/api/v6.2/$endpoint";

      // 2. إرسال الطلب
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        // 3. فك تشفير الاستجابة
        final decryptedJson = _decodeResponse(response.body);
        return json.decode(decryptedJson) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load Ostora data. Status code: ${response.statusCode}');
      }
    } catch (error) {
      throw Exception('Error fetching Ostora data: $error');
    }
  }


  String _generateRandomString({int length = 10}) {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
  }

  String _decodeResponse(String ciphertext) {
    // تحويل المفتاح والـ IV من صيغة Hex إلى Bytes
    final keyBytes = _hexToBytes(_aesKeyHex);
    final ivBytes = _hexToBytes(_ivHex);

    // إعداد أداة فك التشفير
    final key = encrypt.Key(keyBytes);
    final iv = encrypt.IV(ivBytes);
    // نستخدم AES/CBC مع NoPadding، وسنقوم بإزالة الـ Padding يدويًا
    final encrypter = encrypt.Encrypter(encrypt.AES(key, mode: encrypt.AESMode.cbc, padding: null));

    // فك تشفير النص من Base64 ثم فك تشفير AES
    // نستخدم Encrypted.from64 بدلاً من fromBase64 لأنها تتعامل مع الـ bytes مباشرة
    final encryptedData = encrypt.Encrypted(base64.decode(ciphertext));
    final decryptedBytes = encrypter.decryptBytes(encryptedData, iv: iv);

    // --- تطبيق نفس منطق إزالة الحشو (Padding) المستخدم في Kotlin ---
    if (decryptedBytes.isEmpty) {
      return "";
    }

    final padLen = decryptedBytes.last;

    if (padLen > 16 || padLen <= 0 || decryptedBytes.length < padLen) {
      // إذا كانت قيمة الحشو غير منطقية، نُرجع النص كما هو
      return utf8.decode(decryptedBytes, allowMalformed: true);
    }

    // إزالة الحشو
    final unpaddedBytes = Uint8List.fromList(decryptedBytes.sublist(0, decryptedBytes.length - padLen));

    return utf8.decode(unpaddedBytes);
  }

  Uint8List _hexToBytes(String hex) {
    hex = hex.replaceAll(" ", ""); // إزالة أي مسافات
    final result = Uint8List(hex.length ~/ 2);
    for (int i = 0; i < hex.length; i += 2) {
      final num = hex.substring(i, i + 2);
      result[i ~/ 2] = int.parse(num, radix: 16);
    }
    return result;
  }

  Future<Map<String, dynamic>> getCategory(String id) async {
    return await fetchOData("category/$id");
  }

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
    final url = "https://api.syria-live.fun/api/v2/champion_standing?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getCupStanding(String champion) async {
    final url = "https://api.syria-live.fun/api/v2/cup_standing?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getChampionGroups(String champion) async {
    final url = "https://api.syria-live.fun/api/v2/champion_groups?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getChampionMatches(String champion) async {
    final url = "https://api.syria-live.fun/api/v2/champion_matches?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getChampionScorers(String champion) async {
    final url = "https://api.syria-live.fun/api/v2/champion_scorers?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getChampionAssists(String champion) async {
    final url = "https://api.syria-live.fun/api/v2/champion_assists?champion=$champion" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getTeamInfo(String teamId) async {
    final url = "https://api.syria-live.fun/api/v2/team_info?team_id=$teamId" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getPlayerInfo(String playerId) async {
    final url = "https://api.syria-live.fun/api/v2/player_info?player_id=$playerId" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getTeamMatches(String teamId) async {
    final url = "https://api.syria-live.fun/api/v2/team_matches?team_id=$teamId" ;
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }
  Future<dynamic> getSearchResults({String? q}) async {
    final baseUrl = "https://api.syria-live.fun/api/v2/search";
    final url = q == null || q.isEmpty ? baseUrl : "$baseUrl?q=$q";
    final response = await http.get(Uri.parse(url), headers: headers);
    return jsonDecode(response.body);
  }

  Future<dynamic> getAds() async {
    final baseUrl = "https://api.syria-live.fun/api/v2/app_ads";
    final response = await http.get(Uri.parse(baseUrl));
    return jsonDecode(response.body);
  }

  Future<dynamic> getState() async {
    final baseUrl = "https://api.syria-live.fun/app.json";
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