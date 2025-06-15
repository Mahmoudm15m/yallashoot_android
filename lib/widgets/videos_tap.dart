import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api/main_api.dart';
import 'package:url_launcher/url_launcher.dart';

import '../strings/languages.dart';

class VideosTap extends StatefulWidget {
  final String MatchId;
  final String lang ;

  const VideosTap({
    super.key,
    required this.MatchId, required this.lang,
  });

  @override
  State<VideosTap> createState() => _VideosTapState();
}

class _VideosTapState extends State<VideosTap> {
  late Future<Map<String, dynamic>> _videosFuture;
  late final ApiData apiData ;

  @override
  void initState() {
    super.initState();
    apiData = ApiData();
    _videosFuture = apiData.getMatchVideos(widget.MatchId);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _videosFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {

          final isDark = Theme.of(context).brightness == Brightness.dark;
          final baseColor = isDark ? Colors.grey[850]! : Colors.grey[200]!;
          final highlightColor = isDark ? Colors.grey[700]! : Colors.grey[100]!;

          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8.0),
              itemCount: 7,
              itemBuilder: (context, index) => const _VideoCardShimmer(),
              separatorBuilder: (context, index) => const SizedBox(height: 4),
            ),
          );

        }
        if (snapshot.hasError || !snapshot.hasData) {

          return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["error"]!));
        }

        final videosData = snapshot.data!['videos']?['data'] as List?;
        if (videosData == null || videosData.isEmpty) {
          return Center(child: Text(appStrings[Localizations.localeOf(context).languageCode]!["no_available_streams"]!));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(8.0),
          itemCount: videosData.length,
          itemBuilder: (context, index) {
            final video = videosData[index];
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: InkWell(
                onTap: () async {
                  final uri = Uri.tryParse(video["live_link"] ?? '');
                  if (uri != null) {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          video["video_pic"] ?? '',
                          width: 120,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, st) => Container(
                            width: 120,
                            height: 80,
                            color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            child: const Icon(Icons.videocam_off_outlined),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              video["channel"]?["title"] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${appStrings[Localizations.localeOf(context).languageCode]!["source"]!} : ${video["link_name"] ?? appStrings[Localizations.localeOf(context).languageCode]!["unknown"]!}",
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.blueGrey.withOpacity(0.5)),
                            ),
                            child: const Icon(Icons.play_arrow, color: Colors.blueAccent, size: 24)),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
          separatorBuilder: (BuildContext context, int index) {
            return const SizedBox(height: 4);
          },
        );
      },
    );
  }
}



class _VideoCardShimmer extends StatelessWidget {
  const _VideoCardShimmer();

  @override
  Widget build(BuildContext context) {
    final shimmerColor = Theme.of(context).brightness == Brightness.dark
        ? Colors.grey.shade700
        : Colors.grey.shade300;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [

            Container(
              width: 120,
              height: 80,
              decoration: BoxDecoration(
                color: shimmerColor,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    height: 14,
                    width: 100,
                    decoration: BoxDecoration(color: shimmerColor, borderRadius: BorderRadius.circular(4)),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(8.0),
              child: CircleAvatar(
                radius: 16,
                backgroundColor: shimmerColor,
              ),
            )
          ],
        ),
      ),
    );
  }
}