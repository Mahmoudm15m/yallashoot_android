import 'dart:async';
import 'dart:convert';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart'; // استيراد AdMob
import 'package:yallashoot/screens/m3u8_screen.dart';
import '../api/main_api.dart';

void openExternalVideoPlayer(BuildContext context, Map<String, dynamic> streamLinks) async {
  try {
    String json = jsonEncode(streamLinks);
    String encoded = base64Url.encode(utf8.encode(json));
    String url = 'uspl://open.app?data=$encoded';

    await launchUrl(Uri.parse(url));
  } catch (e) {
    _showInstallDialog(context);
  }
}

void _showInstallDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text('تعذر فتح المشغل'),
        content: Text('يرجى تحميل المشغل لتشغيل الفيديو.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('إلغاء'),
          ),
          TextButton(
            onPressed: () {
              launchUrl(Uri.parse('https://syria-live.fun/'));
            },
            child: Text('تحميل المشغل'),
          ),
        ],
      );
    },
  );
}

class LivesScreen extends StatefulWidget {
  const LivesScreen({super.key});

  @override
  State<LivesScreen> createState() => _LivesScreenState();
}

class _LivesScreenState extends State<LivesScreen> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData apiData = ApiData();
  Map<String, dynamic>? adsData;

  // متغيرات الإعلان البيني
  InterstitialAd? _interstitialAd;
  bool _isInterstitialAdReady = false;
  Timer? _loadingCheckTimer;

  // متغير لتقييد عرض الإعلان مرة واحدة كل دقيقة
  DateTime? _lastAdShownTime;

  @override
  void initState() {
    super.initState();
    futureResults = fetchLives();
    fetchAds();
    // لم نعد نحمل الإعلان فوراً عند الدخول، بل حين الحاجة فقط
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
      final api = ApiData();
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

  /// تحميل الإعلان البيني عند الحاجة
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
          // نجرب إعادة التحميل بعد 30 ثانية
          Future.delayed(const Duration(seconds: 30), () {
            if (mounted) _loadInterstitialAd();
          });
        },
      ),
    );
  }

  void _onMatchTap(Map<String, dynamic> match) {
    final now = DateTime.now();

    // تحقق إن مرت دقيقة على آخر عرض
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
      // لم تمرّ دقيقة بعد: نتجاوز الإعلان وننتقل مباشرة
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
              children: const [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text(
                  'جارٍ تحميل الإعلان...',
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
          title: const Text("البث المتاح"),
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
                return Center(child: Text('حدث خطأ: ${snapshot.error}'));
              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(child: Text('لا توجد بيانات'));
              } else {
                var livesData = snapshot.data!;
                final lives = livesData["lives"] as List;
                final String? encodedAd = adsData?['ads']?['streaming_page'];
                final String? decodedAd = decodeBase64Ad(encodedAd);

                if (lives.isEmpty) {
                  return const Center(
                    child: Text("لا توجد بثوث متاحه حاليا !"),
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
                              const Expanded(
                                child: Center(
                                  child: Text(
                                    "اضغط لمشاهدة البث",
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
