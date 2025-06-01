import 'package:flutter/material.dart';
import 'package:yallashoot/screens/league_screen.dart';
import '../api/main_api.dart';

class RanksScreen extends StatefulWidget {
  const RanksScreen({Key? key}) : super(key: key);

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData yasScore = ApiData();

  Future<Map<String, dynamic>> fetchRanks() async {
    try {
      final data = await yasScore.getRanksData();
      return data;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    futureResults = fetchRanks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("حدث خطأ أثناء جلب البيانات"));
          } else {
            final data = snapshot.data!;
            List<dynamic> ranks = data["ranks"] ?? [];
            return ListView.builder(
              itemCount: ranks.length,
              itemBuilder: (context, index) {
                final item = ranks[index];
                return IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      return LeagueScreen( id: item["rank_id"]);
                    }));
                  },
                  icon: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: Image.network(
                        "https://api.syria-live.fun/img_proxy?url=" + item["image"],
                        width: 40,
                        height: 40,
                        fit: BoxFit.cover,
                      ),
                      title: Text(
                        item["name"],
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
