import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class HtmlWidget extends StatelessWidget {
  final double width;
  final double height;
  final String htmlContent;
  final String viewType;

  HtmlWidget({
    Key? key,
    required this.width,
    required this.height,
    required this.htmlContent,
  })  : viewType = 'html-widget-${DateTime.now().microsecondsSinceEpoch}',
        super(key: key) {
    if (kIsWeb) {
      ui.platformViewRegistry.registerViewFactory(
        viewType,
            (int viewId) {
          // 1) إنشاء الحاوية الرئيسة
          final container = html.DivElement()
            ..style.width = '${width}px'
            ..style.height = '${height}px'
            ..style.overflow = 'hidden';

          // 2) محلل مؤقت لتحليل htmlContent
          final parser = html.DivElement();
          parser.setInnerHtml(
            htmlContent,
            treeSanitizer: html.NodeTreeSanitizer.trusted, // use trusted sanitizer
          );

          // 3) نسخ جميع العناصر غير <script> إلى الحاوية
          for (var node in parser.nodes.toList()) {
            if (node is html.Element && node.localName == 'script') continue;
            container.append(node.clone(true));
          }

          // 4) إعادة بناء وتنفيذ جميع <script> داخل الحاوية
          for (var oldScript in parser.querySelectorAll('script')) {
            final newScript = html.ScriptElement()
              ..async = oldScript.attributes.containsKey('async')
              ..defer = oldScript.attributes.containsKey('defer');

            oldScript.attributes.forEach((name, value) {
              if (name == 'src') {
                // تحويل الروابط النسبية "//…" إلى "https://…"
                newScript.src = value.startsWith('//') ? 'https:$value' : value;
              } else if (name != 'async' && name != 'defer') {
                newScript.setAttribute(name, value!);
              }
            });

            container.append(newScript);
          }

          return container;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Text('هذا الويدجت يدعم فقط Flutter Web');
    }
    return SizedBox(
      width: width,
      height: height,
      child: HtmlElementView(viewType: viewType),
    );
  }
}
