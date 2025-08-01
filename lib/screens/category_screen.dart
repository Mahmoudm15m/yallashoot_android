import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../api/main_api.dart';
import 'channel_screen.dart';
import 'dart:ui'; // لاستخدامه في تأثير الضبابية (إذا أردنا)

class CategoryScreen extends StatefulWidget {
  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData apiService = ApiData();

  bool isSearching = false;

  TextEditingController searchController = TextEditingController();
  FocusNode searchFocus = FocusNode();
  List<dynamic> allWorks = [];
  List<dynamic> filteredWorks = [];

  final String defaultImage = 'https://via.placeholder.com/150?text=No+Image';

  @override
  void initState() {
    super.initState();
    futureResults = fetchHomeData();
  }

  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final data = await apiService.getCategory("1");
      if (mounted) {
        setState(() {
          if (data["data"] != null && data["data"] is Map) {
            allWorks = data["data"]["items"] ?? [];
            filteredWorks = List.from(allWorks);
          }
        });
      }
      return data;
    } catch (e) {
      print('An error occurred: $e');
      return {};
    }
  }

  void filterSearchResults(String query) {
    if (query.isEmpty) {
      setState(() {
        filteredWorks = List.from(allWorks);
      });
    } else {
      setState(() {
        filteredWorks = allWorks
            .where((category) =>
            category["name"]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      });
    }
  }

  // --- تحديث شاشة التحميل (Shimmer) لتناسب شكل الـ GridView ---
  Widget buildLoadingScreen() {
    return GridView.builder(
      padding: const EdgeInsets.all(12.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // عدد الأعمدة
        crossAxisSpacing: 12.0, // المسافة الأفقية بين العناصر
        mainAxisSpacing: 12.0, // المسافة الرأسية بين العناصر
        childAspectRatio: 1.0, // نسبة العرض إلى الارتفاع للعنصر
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[800]!,
          highlightColor: Colors.grey[700]!,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- استخدام ألوان الثيم بدلاً من الألوان الثابتة ---
    final theme = Theme.of(context);

    return Scaffold(
      // backgroundColor سيأخذ اللون من الثيم تلقائياً
      appBar: AppBar(
        // لون AppBar سيأخذ اللون من الثيم أيضاً
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back), // اللون سيأتي من الثيم
        ),
        title: isSearching
            ? TextField(
          controller: searchController,
          focusNode: searchFocus,
          decoration: InputDecoration(
            hintText: 'ابحث عن فئة...',
            hintStyle: TextStyle(color: theme.hintColor),
            border: InputBorder.none,
          ),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          onChanged: filterSearchResults,
        )
            : Text(
          "سيرفر البث",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                isSearching = !isSearching;
                if (!isSearching) {
                  searchController.clear();
                  filteredWorks = List.from(allWorks);
                } else {
                  searchFocus.requestFocus();
                }
              });
            },
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: futureResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return buildLoadingScreen();
          }

          if (snapshot.hasError || allWorks.isEmpty) {
            return Center(
              child: Text(
                'فشل تحميل البيانات أو القائمة فارغة.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            );
          }

          if (filteredWorks.isEmpty && isSearching) {
            return Center(
              child: Text(
                'لا توجد نتائج بحث مطابقة.',
                style: TextStyle(color: theme.textTheme.bodyMedium?.color),
              ),
            );
          }

          // --- التغيير إلى GridView لعرض أكثر جاذبية ---
          return GridView.builder(
            padding: const EdgeInsets.all(12.0),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.0,
              mainAxisSpacing: 12.0,
              childAspectRatio: 1.0,
            ),
            itemCount: filteredWorks.length,
            itemBuilder: (context, index) {
              final category = filteredWorks[index];
              final categoryName = category["name"] ?? 'بدون اسم';
              String imageUrl = category["image"] ?? "";
              if (imageUrl.isEmpty) {
                imageUrl = defaultImage;
              }

              // --- تصميم جديد للكارت (Item Card) ---
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChannelsScreen(
                        id: category["id"],
                        name: categoryName,
                      ),
                    ),
                  );
                },
                child: Card(
                  elevation: 4.0,
                  clipBehavior: Clip.antiAlias, // لضمان قص المحتوى الزائد
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0),
                  ),
                  child: Stack(
                    alignment: Alignment.bottomCenter,
                    children: [
                      // الصورة تملأ الكارت بالكامل
                      Positioned.fill(
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Image.network(defaultImage, fit: BoxFit.cover),
                        ),
                      ),
                      // تدرج لوني أسود شفاف في الأسفل لزيادة وضوح النص
                      Container(
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [
                              Colors.black.withOpacity(0.8),
                              Colors.black.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                      // النص فوق التدرج
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: Text(
                          categoryName,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            shadows: [
                              Shadow(
                                blurRadius: 4.0,
                                color: Colors.black,
                                offset: Offset(1.0, 1.0),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}