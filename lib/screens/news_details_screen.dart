import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import '../api/main_api.dart';

class NewsDetailsScreen extends StatefulWidget {
  final String id;
  final String img;

  const NewsDetailsScreen({
    Key? key,
    required this.id,
    required this.img,
  }) : super(key: key);

  @override
  State<NewsDetailsScreen> createState() => _NewsDetailsScreenState();
}

class _NewsDetailsScreenState extends State<NewsDetailsScreen> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData apiData = ApiData();

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
    futureResults = fetchNewsDetails();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل الخبر'),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return const Center(child: Text('حدث خطأ أثناء جلب البيانات'));
          } else {
            final newsDetails = snapshot.data!['news_details']?['data'];
            if (newsDetails == null) {
              return const Center(child: Text('لا توجد بيانات للخبر'));
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
                        widget.img,
                        errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 100),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      newsDetails['title'] ?? 'بدون عنوان',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Html(
                      data: (newsDetails['full_news'] != null && (newsDetails['full_news'] as String).isNotEmpty)
                          ? newsDetails['full_news']
                          : (newsDetails['news_desc'] ?? 'لا يوجد وصف للخبر'),
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
