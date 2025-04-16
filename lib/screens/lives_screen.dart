import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import '../api/main_api.dart';
import '../unity_ads_helper.dart';
import '../ad_helper.dart';

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
              launchUrl(Uri.parse('https://example.com/app-download')); // غير الرابط هنا
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

  BannerAd? _bannerAd;

  Future<Map<String, dynamic>> fetchLives() async {
    try {
      final data = await apiData.getLivesData();
      return data;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    AdManager.initializeAds(context);
    futureResults = fetchLives();

    _bannerAd = AdHelper.loadBannerAd(
      onAdLoaded: (ad) {
        setState(() {
          _bannerAd = ad as BannerAd;
        });
      },
      onAdFailedToLoad: (ad, error) {
        ad.dispose();
        print('BannerAd failed to load: $error');
      },
    );
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
              final lives = livesData["lives"];

              if (lives.isEmpty) {
                return const Center(
                  child: Text("لا توجد بثوث متاحه حاليا !"),
                );
              }

              return Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(8.0),
                      itemCount: lives.length,
                      itemBuilder: (context, index) {
                        final match = lives[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 8.0),
                          elevation: 3,
                          child: InkWell(
                            onTap: () async {
                              Map<String, dynamic> streamLinks = match["stream_links"];
                              await AdManager.showInterstitialAd(context);
                              openExternalVideoPlayer(context , streamLinks);
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    children: [
                                      Image.network(
                                        match["home_logo"],
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
                                        match["away_logo"],
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
                    ),
                  ),
                  if (_bannerAd != null)
                    SizedBox(
                      width: _bannerAd!.size.width.toDouble(),
                      height: _bannerAd!.size.height.toDouble(),
                      child: AdWidget(ad: _bannerAd!),
                    ),
                ],
              );
            }
          },
        ),
      ),
    );
  }
}
