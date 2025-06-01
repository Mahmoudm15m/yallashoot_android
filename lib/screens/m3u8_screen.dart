import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'dart:html' as html;
import 'dart:ui_web' as ui;

import '../api/main_api.dart';
import 'htm_widget.dart'; // ignore: undefined_prefixed_name

class M3u8Screen extends StatefulWidget {
  final Map<String, String> streamLinks;

  const M3u8Screen({
    Key? key,
    required this.streamLinks,
  }) : super(key: key);

  @override
  State<M3u8Screen> createState() => _M3u8ScreenState();
}

class _M3u8ScreenState extends State<M3u8Screen> {
  // Media Kit player & controller
  late final Player _player;
  late final VideoController _controller;
  Map<String, dynamic>? adsData;
  String? decodedHtml;

  // IFrame for non-m3u8 streams
  late final html.IFrameElement _iframe;

  // UI state
  bool _showControls = true;
  Timer? _hideTimer;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isBuffering = false;
  late String _currentResolution;

  String? decodeBase64Ad(String? encoded) {
    if (encoded == null) return null;
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return null;
    }
  }


  @override
  void initState() {
    super.initState();
    fetchAdData();
    // 1) Register the IFrameElement (Web only)
    if (kIsWeb) {
      _iframe = html.IFrameElement()
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%'
        ..allowFullscreen = true;
      // ignore: undefined_prefixed_name
      ui.platformViewRegistry.registerViewFactory(
        'iframe-stream',
            (int viewId) => _iframe,
      );
    }

    // 2) Initialize Media Kit player
    _player = Player();
    _controller = VideoController(_player);

    // 3) Start with the first quality
    _currentResolution = widget.streamLinks.keys.first;
    _openOrIFrame(_currentResolution);

    // 4) Listen for position, duration, buffering
    _player.streams.position.listen((p) => setState(() => _position = p));
    _player.streams.duration.listen((d) => setState(() => _duration = d));
    _player.streams.buffering.listen((b) => setState(() => _isBuffering = b));

    _startHideTimer();
  }

  Future<void> fetchAdData() async {
    try {
      final api = ApiData();
      final data = await api.getAds();
      final encoded = data['ads']?['streaming_page'];
      setState(() {
        adsData = data;
        decodedHtml = decodeBase64Ad(encoded);
      });
    } catch (_) {
      // ممكن تسجل الخطأ لو حبيت
    }
  }

  Future<void> _openOrIFrame(String res) async {
    final url = widget.streamLinks[res]!;

    if (url.toLowerCase().endsWith('.m3u8')) {
      // Play via Media Kit
      final resumePos = _position;
      await _player.open(Media(url)); // auto-play
      if (resumePos > Duration.zero) {
        await _player.seek(resumePos);
      }
    } else {
      // Load in IFrame (Web only)
      if (kIsWeb) {
        _iframe.src = url;
      }
    }
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _startHideTimer();
    } else {
      _hideTimer?.cancel();
    }
  }

  void _startHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      setState(() => _showControls = false);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _player.dispose();
    super.dispose();
  }

  String _format(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '${d.inHours > 0 ? '${d.inHours}:' : ''}$mm:$ss';
  }

  Future<void> _toggleFullScreen() async {
    if (kIsWeb) {
      if (html.document.fullscreenElement != null) {
        html.document.exitFullscreen();
      } else {
        await html.document.documentElement?.requestFullscreen();
      }
    } else {
      // Native mobile fullscreen
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      await Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => _NativeFullScreenVideo(controller: _controller),
      ));
      // Restore portrait afterward
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUrl = widget.streamLinks[_currentResolution]!;

    // If it's not an m3u8 link, show the iframe (Web only)
    if (kIsWeb && !currentUrl.toLowerCase().endsWith('.m3u8')) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: HtmlElementView(viewType: 'iframe-stream'),
      );
    }

    // Otherwise, show the custom Media Kit player
    final resolutions = widget.streamLinks.keys.toList();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // Video display
                Center(
                  child: ValueListenableBuilder<Rect?>(
                    valueListenable: _controller.rect,
                    builder: (context, rect, child) {
                      final aspect = (rect != null && rect.height > 0)
                          ? rect.width / rect.height
                          : 16 / 9;
                      return AspectRatio(
                        aspectRatio: aspect,
                        child: child!,
                      );
                    },
                    child: Video(
                      controller: _controller,
                      controls: NoVideoControls,
                    ),
                  ),
                ),

                // Loading spinner
                if (_isBuffering)
                  const Positioned.fill(
                    child: Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation(Colors.white),
                      ),
                    ),
                  ),

                // Tap to toggle controls
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: _toggleControls,
                  ),
                ),

                // Dark overlay when controls visible
                if (_showControls)
                  Positioned.fill(
                    child: Container(color: Colors.black38),
                  ),

                // Controls UI
                if (_showControls)
                  _buildControls(resolutions),
              ],
            ),
          ),
          if (decodedHtml != null)
            HtmlWidget(
              width: MediaQuery.of(context).size.width,
              height: 100,
              htmlContent: decodedHtml!,
            ),
        ],
      ),
    );
  }

  Widget _buildControls(List<String> resolutions) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top bar: resolution selector + fullscreen
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (resolutions.length > 1)
                PopupMenuButton<String>(
                  initialValue: _currentResolution,
                  color: Colors.grey[900],
                  onSelected: (res) async {
                    setState(() => _currentResolution = res);
                    await _openOrIFrame(res);
                  },
                  itemBuilder: (_) => resolutions
                      .map(
                        (r) => PopupMenuItem(
                      value: r,
                      child: Text(r, style: TextStyle(color: Colors.white)),
                    ),
                  )
                      .toList(),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Text(
                      _currentResolution,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: IconButton(
                  icon: Icon(Icons.fullscreen, color: Colors.white),
                  onPressed: _toggleFullScreen,
                ),
              ),
            ],
          ),

          // Bottom bar: progress + controls
          Column(
            children: [
              Slider(
                value: _position.inMilliseconds
                    .clamp(0, _duration.inMilliseconds)
                    .toDouble(),
                max: _duration.inMilliseconds
                    .clamp(1, double.infinity)
                    .toDouble(),
                onChanged: (v) =>
                    _player.seek(Duration(milliseconds: v.toInt())),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_format(_position),
                        style: TextStyle(color: Colors.white)),
                    Text(_format(_duration),
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              Container(
                color: Colors.black54,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    IconButton(
                      iconSize: 32,
                      color: Colors.white,
                      icon: Icon(Icons.replay_10),
                      onPressed: () =>
                          _player.seek(_position - Duration(seconds: 10)),
                    ),
                    IconButton(
                      iconSize: 48,
                      color: Colors.white,
                      icon: Icon(_player.state.playing
                          ? Icons.pause_circle_filled
                          : Icons.play_circle_filled),
                      onPressed: () => _player.state.playing
                          ? _player.pause()
                          : _player.play(),
                    ),
                    IconButton(
                      iconSize: 32,
                      color: Colors.white,
                      icon: Icon(Icons.forward_10),
                      onPressed: () =>
                          _player.seek(_position + Duration(seconds: 10)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NativeFullScreenVideo extends StatelessWidget {
  final VideoController controller;

  const _NativeFullScreenVideo({
    Key? key,
    required this.controller,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.black,
    body: SafeArea(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        child: Center(
          child: ValueListenableBuilder<Rect?>(
            valueListenable: controller.rect,
            builder: (context, rect, child) {
              final aspect = (rect != null && rect.height > 0)
                  ? rect.width / rect.height
                  : 16 / 9;
              return AspectRatio(
                aspectRatio: aspect,
                child: child!,
              );
            },
            child: Video(
              controller: controller,
              controls: NoVideoControls,
              fit: BoxFit.cover,
            ),
          ),
        ),
      ),
    ),
  );
}
