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
    // اختيار أول جودة من الخريطة افتراضياً
    currentQuality = widget.streamLinks.keys.first;
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.streamLinks[currentQuality],
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

  // دالة لتغيير الجودة
  void _changeQuality(String quality) {
    setState(() {
      currentQuality = quality;
    });
    BetterPlayerDataSource newDataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      widget.streamLinks[quality],
    );
    _betterPlayerController.setupDataSource(newDataSource);
  }

  // عرض القائمة الخاصة بتغيير الجودة
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
