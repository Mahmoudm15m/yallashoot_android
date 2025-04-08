import 'package:flutter/material.dart';

import '../api/main_api.dart';

class LivesScreen extends StatefulWidget {
  const LivesScreen({super.key});

  @override
  State<LivesScreen> createState() => _LivesScreenState();
}

class _LivesScreenState extends State<LivesScreen> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData apiData = ApiData();

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
    futureResults = fetchLives();
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

              return ListView.builder(
                padding: const EdgeInsets.all(8.0),
                itemCount: lives.length,
                itemBuilder: (context, index) {
                  final match = lives[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 3,
                    child: InkWell(
                      onTap: () {
                        showModalBottomSheet(
                          context: context,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                          ),
                          builder: (BuildContext context) {
                            Map<String, dynamic> streamLinks = match["stream_links"];
                            List<String> qualities = streamLinks.keys.toList();

                            return Container(
                              padding: const EdgeInsets.all(16.0),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text(
                                    'اختر جودة البث',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 10),
                                  ListView.builder(
                                    shrinkWrap: true,
                                    itemCount: qualities.length,
                                    itemBuilder: (context, index) {
                                      String quality = qualities[index];
                                      return ListTile(
                                        title: Text(quality),
                                        onTap: () {
                                          print(streamLinks[quality]);
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          },
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // الفريق المضيف
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
                            // نص الإشارة لمشاهدة البث
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "اضغط لمشاهده البث",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                            // الفريق الضيف
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
              );
            }
          },
        ),
      ),
    );
  }
}
