import 'package:flutter/cupertino.dart';
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
                        // تأكد من استخدام الرابط المناسب للبث
                        print(match["stream_link"]);
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
