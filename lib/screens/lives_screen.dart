import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:yallashoot/screens/m3u8_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';
import '../widgets/admob_helper.dart';
import '../widgets/html_viewer_widget.dart';


class LivesScreen extends StatefulWidget {
  final String lang;
  LivesScreen({
    required this.lang
  });
  @override
  State<LivesScreen> createState() => _LivesScreenState();
}

class _LivesScreenState extends State<LivesScreen> {
  late Future<Map<String, dynamic>> futureResults;
  late ApiData apiData;
  Map<String, dynamic>? adsData;

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    futureResults = fetchLives();
    // _fetchAds();
    AdHelper.preloadInterstitialAd();
  }

  Future<void> _fetchAds() async {
    try {
      final ads = await apiData.getAds();
      if (mounted) {
        setState(() {
          adsData = ads;
        });
      }
    } catch (e) {
      print("Failed to fetch ads: $e");
    }
  }

  Future<Map<String, dynamic>> fetchLives() async {
    try {
      final data = await apiData.getLivesData();
      return data;
    } catch (e) {
      return {};
    }
  }

  String? decodeBase64Ad(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _onMatchTap(Map<String, dynamic> match) async {

    AdHelper.showAdThenNavigate(context, () {
      _navigateToStream(match);
    });
  }

  void _navigateToStream(Map<String, dynamic> match){
    final links = Map<String, String>.from(match["stream_links"]);
    Navigator.push(
      context,
      CupertinoPageRoute(
        builder: (_) => IframeStreamScreen(streamLinks: links),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Center(
      child: Scaffold(
        appBar: AppBar(
          title: Text(appStrings[Localizations.localeOf(context).languageCode]!["live_button"]!),
        ),
        body: RefreshIndicator(
          onRefresh: () async {
            setState(() {
              futureResults = fetchLives();
            });
            await futureResults;
          },
          child: FutureBuilder<Map<String, dynamic>>(
            future: futureResults,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              } else if (snapshot.hasError) {
                return Center(child: Text(' ${appStrings[Localizations.localeOf(context).languageCode]!["error"]!}: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return Center(child: Text(' ${appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!}'));
              } else {
                var livesData = snapshot.data!;
                final lives = livesData["lives"] as List;

                if (lives.isEmpty) {
                  return Center(
                    child: Text(
                      appStrings[Localizations.localeOf(context).languageCode]!["no_available_streams"]!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: lives.length,
                  itemBuilder: (context, index) {
                    final match = lives[index] as Map<String, dynamic>;
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8.0),
                      elevation: 3,
                      child: InkWell(
                        onTap: () => _onMatchTap(match),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Flexible(
                                child: Column(
                                  children: [
                                    Image.network(
                                      "https://api.syria-live.fun/img_proxy?url=" + match["home_logo"],
                                      width: 50,
                                      height: 50,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_outlined, size: 50),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match["home_team"],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Text(
                                    appStrings[Localizations.localeOf(context).languageCode]!["tap_to_watch"]!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(fontSize: 16, color: Colors.blueAccent, fontWeight: FontWeight.w600),
                                  ),
                                ),
                              ),
                              Flexible(
                                child: Column(
                                  children: [
                                    Image.network(
                                      "https://api.syria-live.fun/img_proxy?url=" + match["away_logo"],
                                      width: 50,
                                      height: 50,
                                      errorBuilder: (context, error, stackTrace) => const Icon(Icons.shield_outlined, size: 50),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      match["away_team"],
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
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
            },
          ),
        ),
      ),
    );
  }
}