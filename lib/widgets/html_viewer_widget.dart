import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class ResponsiveHtmlWidget extends StatefulWidget {
  final String htmlContent;
  const ResponsiveHtmlWidget({Key? key, required this.htmlContent}) : super(key: key);
  @override
  State<ResponsiveHtmlWidget> createState() => _ResponsiveHtmlWidgetState();
}

class _ResponsiveHtmlWidgetState extends State<ResponsiveHtmlWidget> {
  late final WebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..addJavaScriptChannel(
        'ExternalLinkHandler',
        onMessageReceived: (JavaScriptMessage message) {
          final url = message.message;
          _launchURL(url);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url;
            if (url == 'about:blank') return NavigationDecision.prevent;
            if (url.startsWith('http://') || url.startsWith('https://')) {
              _launchURL(url);
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );
    _loadHtml();
  }

  void _loadHtml() {
    String html = widget.htmlContent;
    html = html.replaceAllMapped(RegExp(r'(src|href)\s*=\s*"//'), (match) => '${match.group(1)}="https://');
    if (!html.contains('<div id="ad-container"></div>')) {
      html = '<div id="ad-container"></div>' + html;
    }
    String injectedJS = """
    <script>
      (function() {
        const originalOpen = window.open;
        window.open = function(url) {
          ExternalLinkHandler.postMessage(url);
          return null;
        };
        document.addEventListener('click', function(e) {
          const target = e.target.closest('a');
          if (target && target.target === '_blank' && target.href) {
            e.preventDefault();
            ExternalLinkHandler.postMessage(target.href);
          }
        }, true);
      })();
    </script>
    """;
    String finalHtml = html + injectedJS;
    final String contentBase64 = base64Encode(const Utf8Encoder().convert(finalHtml));
    _controller.loadRequest(Uri.parse('data:text/html;base64,$contentBase64'));
  }

  Future<void> _launchURL(String url) async {
    if (url.startsWith('//')) {
      url = 'http:' + url;
    } else if (!url.startsWith('http://') && !url.startsWith('https://')) {
      url = 'http://' + url;
    }
    final Uri uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return WebViewWidget(controller: _controller);
  }
}

class FullScreenHtmlAdWidget extends StatefulWidget {
  final String htmlContent;
  final VoidCallback onAdClosed;
  final int delaySeconds;
  const FullScreenHtmlAdWidget({
    Key? key,
    required this.htmlContent,
    required this.onAdClosed,
    this.delaySeconds = 5,
  }) : super(key: key);

  @override
  State<FullScreenHtmlAdWidget> createState() => _FullScreenHtmlAdWidgetState();
}

class _FullScreenHtmlAdWidgetState extends State<FullScreenHtmlAdWidget> {
  int _secondsRemaining = 0;
  bool _showCloseButton = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _secondsRemaining = widget.delaySeconds;
    _startCountdown();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() {
          _secondsRemaining = 0;
          _showCloseButton = true;
        });
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _closeAd() {
    widget.onAdClosed();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width, // ممكن تحدد عرض محدد لو تحب
              height: MediaQuery.of(context).size.height * 0.8, // تقريبًا 80% من ارتفاع الشاشة
              child: ResponsiveHtmlWidget(htmlContent: widget.htmlContent),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: _showCloseButton
                ? GestureDetector(
              onTap: _closeAd,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 28),
              ),
            )
                : Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$_secondsRemaining',
                style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
