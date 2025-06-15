import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // --- ADDED: For SystemChrome ---
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:yallashoot/screens/m3u8_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class LivesScreen extends StatefulWidget {
  late final String lang;
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

  RewardedInterstitialAd? _rewardedInterstitialAd;
  bool _isRewardedInterstitialAdReady = false;

  bool _userEarnedReward = false;

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
    _rewardedInterstitialAd?.dispose();
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
      late final api;
      api = ApiData();
      final data = await api.getAds();
      if (mounted) {
        setState(() {
          adsData = data;
        });
      }
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

  void _loadRewardedInterstitialAd() {
    RewardedInterstitialAd.load(
      adUnitId: 'ca-app-pub-9181001319721306/6406366872', // Your Ad Unit ID
      request: const AdRequest(),
      rewardedInterstitialAdLoadCallback: RewardedInterstitialAdLoadCallback(
        onAdLoaded: (RewardedInterstitialAd ad) {
          _rewardedInterstitialAd = ad;
          _isRewardedInterstitialAdReady = true;
          _rewardedInterstitialAd!.setImmersiveMode(true);
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('RewardedInterstitialAd failed to load: $error');
          _rewardedInterstitialAd = null;
          _isRewardedInterstitialAdReady = false;
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) _loadRewardedInterstitialAd();
          });
        },
      ),
    );
  }

  void _onMatchTap(Map<String, dynamic> match) {
    final now = DateTime.now();
    final timeSinceLastAd = _lastAdShownTime != null ? now.difference(_lastAdShownTime!) : null;

    if (timeSinceLastAd == null || timeSinceLastAd >= const Duration(seconds: 50)) {
      _loadRewardedInterstitialAd();

      if (_isRewardedInterstitialAdReady && _rewardedInterstitialAd != null) {
        _showRewardedInterstitialThenNavigate(match);
      } else {
        _showLoadingDialog();
        _loadingCheckTimer?.cancel();
        _loadingCheckTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
          if (_isRewardedInterstitialAdReady && _rewardedInterstitialAd != null) {
            timer.cancel();
            if (mounted) Navigator.of(context, rootNavigator: true).pop();
            _showRewardedInterstitialThenNavigate(match);
          }
        });
        Future.delayed(const Duration(seconds: 5), (){
          if (mounted && _loadingCheckTimer != null && _loadingCheckTimer!.isActive) {
            _loadingCheckTimer!.cancel();
            Navigator.of(context, rootNavigator: true).pop();
            _navigateToStream(match);
          }
        });
      }
    } else {
      _navigateToStream(match);
    }
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

  void _showRewardedInterstitialThenNavigate(Map<String, dynamic> match) {
    if (_rewardedInterstitialAd == null) {
      _navigateToStream(match);
      return;
    }

    setState(() {
      _userEarnedReward = false;
    });

    _rewardedInterstitialAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (RewardedInterstitialAd ad) {
        // --- MODIFIED: Restore system UI after ad is dismissed ---
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        ad.dispose();
        _rewardedInterstitialAd = null;
        _isRewardedInterstitialAdReady = false;

        if (_userEarnedReward) {
          _navigateToStream(match);
        } else {
          print("Ad dismissed without earning reward. Not navigating.");
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(appStrings[Localizations.localeOf(context).languageCode]!["watch_ad_to_continue"]!)),
          );
        }
      },
      onAdFailedToShowFullScreenContent: (RewardedInterstitialAd ad, AdError error) {
        // --- MODIFIED: Restore system UI if ad fails to show ---
        SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

        print('RewardedInterstitialAd failed to show: $error');
        ad.dispose();
        _rewardedInterstitialAd = null;
        _isRewardedInterstitialAdReady = false;
        _navigateToStream(match);
      },
    );

    // --- MODIFIED: Set immersive mode before showing the ad ---
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _rewardedInterstitialAd!.show(onUserEarnedReward: (AdWithoutView ad, RewardItem reward) {
      print('User earned reward: ${reward.amount} ${reward.type}');
      setState(() {
        _userEarnedReward = true;
        _lastAdShownTime = DateTime.now();
      });
    });
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
                const CircularProgressIndicator(),
                const SizedBox(height: 16),
                Text(
                  appStrings[Localizations.localeOf(context).languageCode]!["loading_ad"]!,
                  style: const TextStyle(fontSize: 16),
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
