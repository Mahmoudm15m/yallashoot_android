import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api/main_api.dart';
import '../screens/news_details_screen.dart';
import '../strings/languages.dart';

class NewsTabView extends StatefulWidget {
  final String matchRowId;
  final String lang ;
  const NewsTabView({super.key, required this.matchRowId, required this.lang});

  @override
  State<NewsTabView> createState() => _NewsTabViewState();
}

class _NewsTabViewState extends State<NewsTabView> {
  late Future<Map<String, dynamic>> _newsFuture;
  late final ApiData apiData ;

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    _newsFuture = apiData.getMatchNews(widget.matchRowId);
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      final difference = DateTime.now().difference(dateTime);

      if (difference.inDays > 7) {
        return "${dateTime.year}/${dateTime.month}/${dateTime.day}";
      } else if (difference.inDays >= 1) {
        return "${appStrings[Localizations.localeOf(context).languageCode]!["from"]!} ${difference.inDays} ${difference.inDays >= 2 ? appStrings[Localizations.localeOf(context).languageCode]!["days"]! : appStrings[Localizations.localeOf(context).languageCode]!["day"]!}";
      } else if (difference.inHours >= 1) {
        return "${appStrings[Localizations.localeOf(context).languageCode]!["from"]!} ${difference.inHours} ${difference.inHours >= 2 ? appStrings[Localizations.localeOf(context).languageCode]!["hours"]! : appStrings[Localizations.localeOf(context).languageCode]!["hour"]!}";
      } else if (difference.inMinutes >= 1) {
        return "${appStrings[Localizations.localeOf(context).languageCode]!["from"]!} ${difference.inMinutes} ${difference.inMinutes >= 2 ? appStrings[Localizations.localeOf(context).languageCode]!["minutes"]! : appStrings[Localizations.localeOf(context).languageCode]!["minute"]!}";
      } else {
        return appStrings[Localizations.localeOf(context).languageCode]!["now"]!;
      }
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _newsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final baseColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
          final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: ListView.builder(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8.0),
              itemCount: 5,
              itemBuilder: (context, index) {
                return const _NewsCardShimmer();
              },
            ),
          );

        }
        if (snapshot.hasError || !snapshot.hasData) {
          return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!));
        }

        final newsData = snapshot.data!['news']?['data']?['data'] as List?;
        if (newsData == null || newsData.isEmpty) {
          return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["no_data"]!));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(8.0),
          itemCount: newsData.length,
          itemBuilder: (context, index) {
            return _NewsCard(newsItem: newsData[index], formatDate: _formatDate);
          },
        );
      },
    );
  }
}


class _NewsCard extends StatelessWidget {
  final Map<String, dynamic> newsItem;
  final String Function(String) formatDate;

  const _NewsCard({required this.newsItem, required this.formatDate});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final title = newsItem['title'] ?? '';
    final description = newsItem['news_desc'] ?? '';
    final imageUrl = newsItem['image'];
    final newsId = newsItem['id'];
    final date = newsItem['created_at']?['date'] ?? '';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) {
            final Locale currentLocale = Localizations.localeOf(context);
            return NewsDetailsScreen(id: newsId.toString(), img: 'https://imgs.ysscores.com/news/820/$imageUrl', lang: currentLocale.languageCode,);
          }));
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null)
              Image.network(
                "https://imgs.ysscores.com/news/820/$imageUrl",
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 180,
                  color: colorScheme.surfaceContainerHighest,
                  child: Center(child: Icon(Icons.image_not_supported, color: colorScheme.onSurfaceVariant)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      formatDate(date),
                      style: textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NewsCardShimmer extends StatelessWidget {
  const _NewsCardShimmer();

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Container(
            height: 180,
            width: double.infinity,
            color: shimmerColor,
          ),

          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Container(
                  height: 20,
                  width: double.infinity,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 20,
                  width: MediaQuery.of(context).size.width * 0.6,
                  decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(6)),
                ),
                const SizedBox(height: 12),

                Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 14, width: double.infinity, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 6),
                Container(height: 14, width: MediaQuery.of(context).size.width * 0.85, decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4))),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 12,
                    width: 100,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}