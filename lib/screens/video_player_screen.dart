import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';

class VideoPlayerScreen extends StatefulWidget {
  final Map<String, dynamic> streamLinks;

  const VideoPlayerScreen({
    super.key,
    required this.streamLinks,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late BetterPlayerController _betterPlayerController;
  late String currentQuality;

  @override
  void initState() {
    super.initState();
    currentQuality = widget.streamLinks.keys.first;
    _setupPlayer(currentQuality);
  }

  void _setupPlayer(String quality) {
    String url = widget.streamLinks[quality];

    // تحديد نوع الفيديو تلقائي حسب الامتداد
    BetterPlayerVideoFormat? format;
    if (url.contains(".m3u8")) {
      format = BetterPlayerVideoFormat.hls;
    } else if (url.contains(".mp4")) {
      format = BetterPlayerVideoFormat.other;
    } else {
      format = null; // ExoPlayer يحاول يتعرف لوحده
    }

    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: format,
      headers: {
        "Referer": "", // أو fake لو لزم الأمر
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Mobile Safari/537.36"
      },
    );

    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        aspectRatio: 16 / 9,
        autoPlay: true,
        looping: false,
      ),
      betterPlayerDataSource: dataSource,
    );
  }

  @override
  void dispose() {
    _betterPlayerController.dispose();
    super.dispose();
  }

  void _changeQuality(String quality) {
    setState(() {
      currentQuality = quality;
    });

    String url = widget.streamLinks[quality];
    BetterPlayerVideoFormat? format;
    if (url.contains(".m3u8")) {
      format = BetterPlayerVideoFormat.hls;
    } else if (url.contains(".mp4")) {
      format = BetterPlayerVideoFormat.other;
    } else {
      format = null;
    }

    BetterPlayerDataSource newDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      url,
      videoFormat: format,
      headers: {
        "Referer": "",
        "User-Agent": "Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/89.0.4389.90 Mobile Safari/537.36"
      },
    );

    _betterPlayerController.setupDataSource(newDataSource);
  }

  void _showQualityDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("اختر جودة البث"),
          content: SingleChildScrollView(
            child: ListBody(
              children: widget.streamLinks.keys.map((quality) {
                return ListTile(
                  title: Text(quality),
                  trailing: quality == currentQuality
                      ? const Icon(Icons.check, color: Colors.green)
                      : null,
                  onTap: () {
                    Navigator.pop(context);
                    if (quality != currentQuality) {
                      _changeQuality(quality);
                    }
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Video Player"),
      ),
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: BetterPlayer(
                controller: _betterPlayerController,
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showQualityDialog,
        icon: const Icon(Icons.high_quality),
        label: const Text("جودة"),
      ),
    );
  }
}
