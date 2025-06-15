import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../api/main_api.dart';
import '../strings/languages.dart';

class NewsDetailsScreen extends StatefulWidget {
  final String id;
  final String img;
  final String lang ;
  const NewsDetailsScreen({
    Key? key,
    required this.id,
    required this.img,
    required this.lang,
  }) : super(key: key);

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  late Future<Map<String, dynamic>> futureResults;
  late ApiData apiData;

  Future<Map<String, dynamic>> fetchNewsDetails() async {
    try {
      final data = await apiData.getNewsDetails(widget.id);
      return data;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    futureResults = fetchNewsDetails();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(appStrings[Localizations.localeOf(context).languageCode]!["news_details"]!),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return  Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!));
          } else {
            final newsDetails = snapshot.data!['news_details']?['data'];
            if (newsDetails == null) {
              return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!));
            }
            return Padding(
              padding: EdgeInsets.all(8.0),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Center(
                      child: Image.network(
                        "https://api.syria-live.fun/img_proxy?url=" + widget.img,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      newsDetails['title'] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!,
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Html(
                      data: (newsDetails['full_news'] != null && (newsDetails['full_news'] as String).isNotEmpty)
                          ? newsDetails['full_news']
                          : (newsDetails['news_desc'] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!),
                      style: {
                        "img": Style(
                          width: Width(MediaQuery.of(context).size.width * 0.95),
                        ),
                      },
                    )
                  ],
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
