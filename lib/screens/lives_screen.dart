import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yallashoot/screens/m3u8_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';



class LivesScreen extends StatefulWidget {
  late final String lang ;
  LivesScreen({
    required this.lang
});
  @override
  State<LivesScreen> createState() => _LivesScreenState();
}

class _LivesScreenState extends State<LivesScreen> {
  late Future<Map<String, dynamic>> futureResults;
  late ApiData apiData ;
  Map<String, dynamic>? adsData;


  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  Timer? _loadingCheckTimer;

  DateTime? _lastAdShownTime;

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    futureResults = fetchLives();
    fetchAds();
  }

  @override
  void dispose() {
    _loadingCheckTimer?.cancel();
    _interstitialAd?.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> fetchLives() async {
    try {
      final data = await apiData.getLivesData();
      return data;
    } catch (e) {
      return {};
    }
  }

  Future<void> fetchAds() async {
    try {
      late final api ;
      api = ApiData();
      final data = await api.getAds();
      setState(() {
        adsData = data;
      });
    } catch (e) {
      adsData = {};
    }
  }

  String? decodeBase64Ad(String? encoded) {
    if (encoded == null) return null;
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return null;
    }
  }


  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: 'ca-app-pub-9181001319721306/8074630206',
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
          _interstitialAd!.setImmersiveMode(true);
          _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (InterstitialAd ad) {
              ad.dispose();
              _isInterstitialAdReady = false;
            },
            onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
              ad.dispose();
              _isInterstitialAdReady = false;
            },
          );
        },
        onAdFailedToLoad: (LoadAdError error) {
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) _loadInterstitialAd();
          });
        },
      ),
    );
  }

  void _onMatchTap(Map<String, dynamic> match) {
    final now = DateTime.now();


    if (_lastAdShownTime == null ||
        now.difference(_lastAdShownTime!) >= Duration(seconds: 40)) {
      _lastAdShownTime = now;
      _loadInterstitialAd();

      if (_isInterstitialAdReady && _interstitialAd != null) {
        _showInterstitialThenNavigate(match);
      } else {
        _showLoadingDialog();
        _loadingCheckTimer = Timer.periodic(
          const Duration(milliseconds: 500),
              (timer) {
            if (_isInterstitialAdReady && _interstitialAd != null) {
              timer.cancel();
              if (mounted) Navigator.of(context, rootNavigator: true).pop();
              _showInterstitialThenNavigate(match);
            }
          },
        );
      }
    } else {
      final links = Map<String, String>.from(match["stream_links"]);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IframeStreamScreen(streamLinks: links),
        ),
      );
    }
  }

  void _showInterstitialThenNavigate(Map<String, dynamic> match) {
    if (_isInterstitialAdReady && _interstitialAd != null) {
      _interstitialAd!.show();
      _interstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          final links = Map<String, String>.from(match["stream_links"]);
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => IframeStreamScreen(streamLinks: links),
            ),
          );
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          _isInterstitialAdReady = false;
          _interstitialAd = null;
          final links = Map<String, String>.from(match["stream_links"]);
          Navigator.push(
            context,
            CupertinoPageRoute(
              builder: (_) => IframeStreamScreen(streamLinks: links),
            ),
          );
        },
      );
    } else {
      final links = Map<String, String>.from(match["stream_links"]);
      Navigator.push(
        context,
        CupertinoPageRoute(
          builder: (_) => IframeStreamScreen(streamLinks: links),
        ),
      );
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  appStrings[Localizations.localeOf(context).languageCode]!["loading_ad"]!,
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        );
      },
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
                final String? encodedAd = adsData?['ads']?['streaming_page'];
                final String? decodedAd = decodeBase64Ad(encodedAd);

                if (lives.isEmpty) {
                  return Center(
                    child: Text(                      appStrings[Localizations.localeOf(context).languageCode]!["no_available_streams"]!,
                      style: TextStyle(fontSize: 16),
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
                              Column(
                                children: [
                                  Image.network(
                                    "https://api.syria-live.fun/img_proxy?url=" + match["home_logo"],
                                    width: 50,
                                    height: 50,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match["home_team"],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                               Expanded(
                                child: Center(
                                  child: Text(
                                    appStrings[Localizations.localeOf(context).languageCode]!["tap_to_watch"]!,
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Image.network(
                                    "https://api.syria-live.fun/img_proxy?url=" + match["away_logo"],
                                    width: 50,
                                    height: 50,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    match["away_team"],
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ],
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
