import 'dart:async';
import 'dart:html' as html;
import 'dart:ui_web' as ui; // ignore: undefined_prefixed_name

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

class IframeStreamScreen extends StatefulWidget {
  /// خريطة من اسم الجودة (مثلاً 'عالي', 'منخفض', 'متعدد') إلى رابط الـ iframe
  final Map<String, String> streamLinks;

  const IframeStreamScreen({
    Key? key,
    required this.streamLinks,
  }) : super(key: key);

  @override
  State<IframeStreamScreen> createState() => _IframeStreamScreenState();
}

class _IframeStreamScreenState extends State<IframeStreamScreen> {
  late final html.IFrameElement _iframe;
  late String _currentKey;

  @override
  void initState() {
    super.initState();

    // تسجيل عنصر الـ IFrame (خاص بالويب فقط)
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

    // نبدأ بأول مفتاح (أول جودة) من الخريطة
    _currentKey = widget.streamLinks.keys.first;
    _loadCurrentUrl();
  }

  /// يقوم بتحديث رابط الـ iframe بحسب الجودة المحددة الآن
  void _loadCurrentUrl() {
    final url = widget.streamLinks[_currentKey]!;
    if (kIsWeb) {
      _iframe.src = url;
    }
  }

  /// يدخل أو يخرج من وضع ملء الشاشة في المتصفح
  Future<void> _toggleFullScreen() async {
    if (!kIsWeb) return;
    if (html.document.fullscreenElement != null) {
      html.document.exitFullscreen();
    } else {
      await html.document.documentElement?.requestFullscreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    // قائمة أسماء الجودة (المفاتيح)
    final keys = widget.streamLinks.keys.toList();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // ---- 1) شريط اختيار الجودة فوق المشغل ----
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  // قائمة أفقيّة قابلة للتمرير (جميع المفاتيح بجانب بعض)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Row(
                        children: keys.map((k) {
                          final bool isSelected = k == _currentKey;
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: TextButton(
                              style: TextButton.styleFrom(
                                minimumSize: const Size(0, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                backgroundColor:
                                isSelected ? Colors.blueGrey[700] : Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              onPressed: () {
                                if (_currentKey != k) {
                                  setState(() {
                                    _currentKey = k;
                                    _loadCurrentUrl();
                                  });
                                }
                              },
                              child: Text(
                                k,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey[300],
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  // زر ملء الشاشة
                  IconButton(
                    icon: const Icon(Icons.fullscreen, color: Colors.white),
                    onPressed: _toggleFullScreen,
                  ),
                ],
              ),
            ),

            // ---- 2) المشغل (iframe) تحت شريط الجودة ----
            Expanded(
              child: kIsWeb
                  ? const HtmlElementView(viewType: 'iframe-stream')
                  : const Center(
                child: Text(
                  'هذه الشاشة مخصصة للويب فقط.',
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
