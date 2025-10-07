import 'dart:convert';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class WatchScreen extends StatefulWidget {
  final String url;
  final String userAgent;

  const WatchScreen({
    Key? key,
    required this.url,
    required this.userAgent,
  }) : super(key: key);

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  BetterPlayerController? _betterPlayerController;
  final ValueNotifier<BoxFit> _fitNotifier = ValueNotifier(BoxFit.fill);
  final ValueNotifier<bool> _isFullScreenNotifier = ValueNotifier(false);
  OverlayEntry? _logoOverlayEntry;

  String fixBase64(String encoded) {
    encoded = encoded.replaceAll(RegExp(r'[^A-Za-z0-9+/=]'), '');
    while (encoded.length % 4 != 0) {
      encoded += "=";
    }
    return encoded;
  }

  Future<Map<String, dynamic>> extractRealUrlAndDrm(String inputUrl) async {
    try {
      RegExp regex = RegExp(r'urlvplayer://(.*)');
      Match? match = regex.firstMatch(inputUrl);
      String extractedUrl = match != null ? match.group(1)! : inputUrl;
      if (extractedUrl.contains("<F>")) {
        extractedUrl = extractedUrl.split("<F>").last;
      }
      extractedUrl = extractedUrl.replaceAll("Ck2cdUwCtMVdjpYM5v2k", "");
      RegExp urlRegex = RegExp(r'(ht\w+://[^#]+)');
      Match? urlMatch = urlRegex.firstMatch(extractedUrl);
      String finalUrl = urlMatch != null ? urlMatch.group(1)! : extractedUrl;
      if (extractedUrl.contains("###")) {
        List<String> parts = extractedUrl.split("###");
        if (parts.length > 1) {
          String drmKey = parts[1];
          List<String> drmParts = drmKey.split(":");
          if (drmParts.length == 2) {
            String key = drmParts[0];
            String uuid = drmParts[1];
            Map<String, dynamic> clearKeyMap = {
              "keys": [
                {"kty": "oct", "k": key, "kid": uuid}
              ],
              "type": "temporary"
            };
            return {
              "url": finalUrl,
              "drm": {
                "licenseUrl": "",
                "drmType": BetterPlayerDrmType.clearKey,
                "headers": {"User-Agent": widget.userAgent},
                "clearKey": jsonEncode(clearKeyMap),
              }
            };
          }
        }
      }
      return {"url": finalUrl, "drm": null};
    } catch (e) {
      return {"url": inputUrl, "drm": null};
    }
  }

  Widget buildLogoContainer() {
    return Material(
      type: MaterialType.transparency,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.teal[800],
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: const Text(
          "syrialive",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _initVideo();
  }

  Future<void> _initVideo() async {
    if (!mounted) return;
    var extractedData = await extractRealUrlAndDrm(widget.url);
    String videoUrl = extractedData["url"];
    Map<String, dynamic>? drmConfig = extractedData["drm"];
    final theme = Theme.of(context);
    final controlsConfiguration = BetterPlayerControlsConfiguration(
      progressBarPlayedColor: theme.colorScheme.primary,
      progressBarHandleColor: theme.colorScheme.primary,
      controlBarColor: Colors.black.withOpacity(0.6),
      iconsColor: Colors.white,
    );
    BetterPlayerDataSource dataSource = BetterPlayerDataSource(
        BetterPlayerDataSourceType.network,
        videoUrl,
        videoFormat: BetterPlayerVideoFormat.hls,
        headers: {"User-Agent": widget.userAgent},
        drmConfiguration: drmConfig != null
            ? BetterPlayerDrmConfiguration(
          drmType: drmConfig["drmType"],
          licenseUrl: drmConfig["licenseUrl"],
          headers: drmConfig["headers"],
          clearKey: drmConfig["clearKey"],
        )
            : null,
      bufferingConfiguration: BetterPlayerBufferingConfiguration(
        maxBufferMs: 120000,
        minBufferMs: 15000,
      ),
      liveStream: true
    );
    _betterPlayerController = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        allowedScreenSleep: false,
        fullScreenByDefault: true,
        fit: _fitNotifier.value,
        aspectRatio: 16 / 9,
        controlsConfiguration: controlsConfiguration,
        handleLifecycle: true,

      ),
      betterPlayerDataSource: dataSource,
    );

    _betterPlayerController!.addEventsListener((event) {
      if (!mounted) return;
      final isFullScreen = _betterPlayerController?.isFullScreen ?? false;
      if (_isFullScreenNotifier.value != isFullScreen) {
        _isFullScreenNotifier.value = isFullScreen;
      }

      if (event.betterPlayerEventType == BetterPlayerEventType.openFullscreen) {
        _showFullscreenOverlay();
      }
      if (event.betterPlayerEventType == BetterPlayerEventType.hideFullscreen) {
        _removeFullscreenOverlay();
      }
    });

    if (mounted) {
      setState(() {});
    }
  }

  void _showFullscreenOverlay() {
    _logoOverlayEntry = OverlayEntry(
      builder: (context) {
        return ValueListenableBuilder<BoxFit>(
          valueListenable: _fitNotifier,
          builder: (context, fit, child) {
            double top = 20.0;
            double right = (_fitNotifier.value == BoxFit.fill)? 44.0 : 94.0;
            double width = 100.0;
            double height = 22.0;
            return Positioned(
              top: top,
              right: right,
              width: width,
              // height: height,
              child: IgnorePointer(
                child: buildLogoContainer(),
              ),
            );
          },
        );
      },
    );
    Navigator.of(context, rootNavigator: true).overlay!.insert(_logoOverlayEntry!);
  }

  void _removeFullscreenOverlay() {
    _logoOverlayEntry?.remove();
    _logoOverlayEntry = null;
  }

  void _toggleFit() {
    _fitNotifier.value =
    _fitNotifier.value == BoxFit.fill ? BoxFit.contain : BoxFit.fill;
    _betterPlayerController?.setOverriddenFit(_fitNotifier.value);
    _logoOverlayEntry?.markNeedsBuild();
  }

  @override
  void dispose() {
    _removeFullscreenOverlay();
    _betterPlayerController?.dispose();
    _fitNotifier.dispose();
    _isFullScreenNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          "مشاهدة البث",
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_betterPlayerController != null)
            ValueListenableBuilder<BoxFit>(
              valueListenable: _fitNotifier,
              builder: (context, fit, child) {
                return IconButton(
                  onPressed: _toggleFit,
                  icon: Icon(
                    _betterPlayerController?.isFullScreen == true
                        ? (fit == BoxFit.fill
                        ? Icons.fullscreen_exit_rounded
                        : Icons.fullscreen_rounded)
                        : (fit == BoxFit.fill
                        ? Icons.fit_screen_rounded
                        : Icons.fullscreen_rounded),
                  ),
                  tooltip: fit == BoxFit.fill ? "ملء الشاشة" : "الحجم الأصلي",
                );
              },
            ),
        ],
      ),
      body: Center(
        child: _betterPlayerController != null
            ? AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            children: [
              BetterPlayer(controller: _betterPlayerController!),
              ValueListenableBuilder<bool>(
                valueListenable: _isFullScreenNotifier,
                builder: (context, isFullScreen, child) {
                  if (isFullScreen) {
                    return const SizedBox.shrink();
                  } else {
                    return Positioned(
                      top: 15.0,
                      right: 15.0,
                      child: buildLogoContainer(),
                    );
                  }
                },
              )
            ],
          ),
        )
            : AspectRatio(
          aspectRatio: 16 / 9,
          child: Container(
            color: Colors.black,
            child: Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}