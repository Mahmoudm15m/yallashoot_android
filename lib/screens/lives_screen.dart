import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:yallashoot/screens/m3u8_screen.dart';
import '../api/main_api.dart';
import '../unity_ads_helper.dart';
import 'htm_widget.dart';

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
            child: Text(' إلغاء'),
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
    fetchAds();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final int screenWidth = MediaQuery.of(context).size.width.toInt();

    });
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


  @override
  void dispose() {
    super.dispose();
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
                final lives = livesData["lives"];
                final String? encodedAd = adsData?['ads']?['streaming_page'];
                final String? decodedAd = decodeBase64Ad(encodedAd);
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
                                final links = Map<String, String>.from(streamLinks);
                                // if (Platform.isAndroid){
                                //   await AdManager.showInterstitialAd(context);
                                //   openExternalVideoPlayer(context , streamLinks);
                                // }
                                Navigator.push(
                                    context,
                                    CupertinoPageRoute(
                                      builder: (_) =>
                                          IframeStreamScreen(streamLinks: links),
                                    ),
                                  );

                              },
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
                      ),
                    ),
                    if (decodedAd != null)
                      HtmlWidget(
                        width: MediaQuery.of(context).size.width,
                        height: 100,
                        htmlContent: decodedAd,
                      ),

                  ],
                );
              }
            },
          ),
        ),
      ),
    );
  }
}
