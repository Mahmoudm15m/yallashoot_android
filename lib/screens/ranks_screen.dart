import 'package:flutter/material.dart';
import 'package:yallashoot/screens/league_screen.dart';
import 'package:yallashoot/screens/search_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';
import 'lives_screen.dart';

class RanksScreen extends StatefulWidget {
  late final String lang ;

  RanksScreen({
    required this.lang,
});

  @override
  State<RanksScreen> createState() => _RanksScreenState();
}

class _RanksScreenState extends State<RanksScreen> {
  late Future<Map<String, dynamic>> futureResults;
  late ApiData yasScore ;


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
    yasScore = ApiData();
    futureResults = fetchRanks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
      elevation: 0,
      centerTitle: true,
      title: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          IconButton(
            padding: EdgeInsets.zero,
            icon: Icon(Icons.search_outlined, size: 24),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) {
                return SearchScreen(
                  lang: widget.lang,
                );
              }));
            },
          ),
          SizedBox(
            width: 10,
          ),
          Spacer(),
          IconButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) {
                  return LivesScreen(
                    lang: widget.lang,
                  );
                }));
              },
              icon: Text(
                appStrings[widget.lang]!["live_button"]!,
                style: TextStyle(fontSize: 16, color: Colors.blueAccent),
              )),
        ],
      ),
    ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!));
          } else {
            final data = snapshot.data!;
            List<dynamic> ranks = data["ranks"]?["data"] ?? [];

            if (ranks.isEmpty) {
              return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!));
            }

            return ListView.builder(
              itemCount: ranks.length,
              itemBuilder: (context, index) {
                final item = ranks[index];
                return IconButton(
                  padding: EdgeInsets.zero,
                  onPressed: (){
                    Navigator.push(context, MaterialPageRoute(builder: (context){
                      final Locale currentLocale = Localizations.localeOf(context);
                      return LeagueScreen(id: item["url_id"].toString(), lang: currentLocale.languageCode,);
                    }));
                  },
                  icon: Card(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
                    elevation: 2,
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(8),
                      leading: Image.network(
                        "https://imgs.ysscores.com/championship/64/${item["image"]}",
                        width: 40,
                        height: 40,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) => const Icon(Icons.shield_outlined, size: 40),
                      ),
                      title: Text(
                        item["title"] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!,
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