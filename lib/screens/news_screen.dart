import 'package:flutter/material.dart';
import 'package:yallashoot/screens/news_details_screen.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class NewsScreen extends StatefulWidget {
  late final String lang ;
  NewsScreen({
    required this.lang,
});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> {
  late Future<Map<String, dynamic>> futureResults;
  late ApiData apiData ;

  Future<Map<String, dynamic>> fetchNews() async {
    try {
      final data = await apiData.getNewsData();
      return data;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    futureResults = fetchNews();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('${appStrings[Localizations.localeOf(context).languageCode]!["error"]!}: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text(
                appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ));
            } else {
              var newsData = snapshot.data!['news']['data'];
              var mainNews = newsData['main'];
              var importantNews = newsData['important'] as List;
              var lastTeams = newsData['last_teams'] as List;
              var lastNews = newsData['last_news'] as List;
        
              return SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(appStrings[Localizations.localeOf(context).languageCode]!["main_news"]!,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      IconButton(
                        padding: EdgeInsets.zero,
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context){
                            final Locale currentLocale = Localizations.localeOf(context);
                            return NewsDetailsScreen(id: mainNews["id"].toString(), img:'https://imgs.ysscores.com/news/820/${mainNews['image']}', lang: currentLocale.languageCode,);
                          }));
                        },
                        icon: Card(
                          elevation: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Image.network(
                                   'https://imgs.ysscores.com/news/820/${mainNews['image']}',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox(
                                      height: 200,
                                      child: Center(child: Icon(Icons.error)),
                                    );
                                  },
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: 200,
                                ),
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Text(
                                  mainNews['title'] ?? '',
                                  style: const TextStyle(
                                      fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(mainNews['news_desc'] ?? ''),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // قسم الأخبار الهامة
                      Text(appStrings[Localizations.localeOf(context).languageCode]!["important_news"]!,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 250,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: importantNews.length,
                          itemBuilder: (context, index) {
                            var item = importantNews[index];
                            return IconButton(
                              onPressed: (){
                                Navigator.push(context, MaterialPageRoute(builder: (context){
                                  final Locale currentLocale = Localizations.localeOf(context);
                                  return NewsDetailsScreen(id: item["id"].toString(),
                                      img:  'https://imgs.ysscores.com/news/820/${item['image']}', lang: currentLocale.languageCode,);
                                }));
                              },
                              padding: EdgeInsets.zero,
                              icon: Container(
                                width: 200,
                                margin: const EdgeInsets.only(right: 8),
                                child: Card(
                                  elevation: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                     Image.network(
                                           'https://imgs.ysscores.com/news/820/${item['image']}',
                                          errorBuilder: (context, error, stackTrace) {
                                            return const SizedBox(
                                              height: 120,
                                              child: Center(child: Icon(Icons.error)),
                                            );
                                          },
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: 120,
                                        ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Text(
                                          item['title'] ?? '',
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: Text(
                                            item['news_desc'] ?? '',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      // قسم آخر الأخبار
                      Text(appStrings[Localizations.localeOf(context).languageCode]!["latest_news"]!,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: lastNews.length,
                        itemBuilder: (context, index) {
                          var item = lastNews[index];
                          return IconButton(
                            icon: Card(
                              elevation: 2,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                              child: ListTile(
                                leading: Image.network(
                                   'https://imgs.ysscores.com/news/820/${item['image']}',
                                  errorBuilder: (context, error, stackTrace) {
                                    return const SizedBox(
                                      height: 50,
                                      width: 50,
                                      child: Center(child: Icon(Icons.error)),
                                    );
                                  },
                                  fit: BoxFit.cover,
                                  width: 50,
                                  height: 50,
                                ),
                                title: Text(item['title'] ?? ''),
                                subtitle: Text(
                                  item['news_desc'] ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            onPressed: (){
                              Navigator.push(context, MaterialPageRoute(builder: (context){
                                final Locale currentLocale = Localizations.localeOf(context);
                                return NewsDetailsScreen(id: item["id"].toString(),
                                    img:  'https://imgs.ysscores.com/news/820/${item['image']}', lang: currentLocale.languageCode,);
                              }));
                            },
                            padding: EdgeInsets.zero,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}
