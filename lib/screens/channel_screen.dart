import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:yallashoot/screens/watch_screen.dart';
import '../api/main_api.dart';
import '../main.dart';
import '../widgets/html_viewer_widget.dart';

Widget buildLoadingScreen(BuildContext context) {
  final theme = Theme.of(context);
  final isDarkMode = theme.brightness == Brightness.dark;
  final baseColor = isDarkMode ? Colors.grey[800]! : Colors.grey[300]!;
  final highlightColor = isDarkMode ? Colors.grey[700]! : Colors.grey[200]!;

  return ListView.builder(
    itemCount: 8,
    itemBuilder: (context, index) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        child: Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Row(
            children: [
              Container(
                width: 80,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class ChannelsScreen extends StatefulWidget {
  final String id;
  final String name;

  ChannelsScreen({required this.id, required this.name});

  @override
  State<ChannelsScreen> createState() => _ChannelsScreenState();
}

class _ChannelsScreenState extends State<ChannelsScreen> with RouteAware {
  late Future<Map<String, dynamic>> futureResults;
  ApiData apiService = ApiData();
  bool isSearching = false;
  TextEditingController searchController = TextEditingController();
  List<dynamic> allChannels = [];
  List<dynamic> filteredChannels = [];
  final String defaultChannelImage = 'https://via.placeholder.com/150/222B32/FFFFFF?Text=Channel';

  Map<String, dynamic>? adsData;

  @override
  void initState() {
    super.initState();
    _reloadData();
    _fetchAds();
  }

  Future<void> _fetchAds() async {
    try {
      final ads = await apiService.getAds();
      if (mounted) {
        setState(() {
          adsData = ads;
        });
      }
    } catch (e) {
      print("Failed to fetch ads for channels: $e");
    }
  }

  String? decodeBase64Ad(String? encoded) {
    if (encoded == null || encoded.isEmpty) return null;
    try {
      return utf8.decode(base64.decode(encoded));
    } catch (_) {
      return null;
    }
  }

  Future<void> _onChannelTap(Map<String, dynamic> channel) async {
    final encodedAd = adsData?['app_ads']?['video_on_channel_open'] as String?;
    final adHtmlContent = decodeBase64Ad(encodedAd);

    if (adHtmlContent != null) {
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FullScreenHtmlAdWidget(
            htmlContent: adHtmlContent,
            onAdClosed: () {
              Navigator.pop(context);
              _navigateToWatchScreen(channel);
            },
          ),
        ),
      );
    } else {
      _navigateToWatchScreen(channel);
    }
  }

  void _navigateToWatchScreen(Map<String, dynamic> channel) {
    Navigator.push(context, MaterialPageRoute(builder: (context) {
      return WatchScreen(
        url: channel["source"],
        userAgent: channel["agent"],
      );
    }));
  }

  // --- باقي الدوال تبقى كما هي ---
  Future<Map<String, dynamic>> fetchHomeData() async {
    try {
      final data = await apiService.getCategory(widget.id);
      if (mounted) {
        setState(() {
          allChannels = data["data"]?["items"] ?? [];
          filterSearchResults(searchController.text);
        });
      }
      return data;
    } catch (e) {
      return {};
    }
  }

  void _reloadData() {
    setState(() {
      futureResults = fetchHomeData();
    });
  }

  void filterSearchResults(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredChannels = List.from(allChannels);
      } else {
        filteredChannels = allChannels
            .where((channel) =>
            channel["name"]
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    searchController.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    _reloadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: isSearching
            ? TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'ابحث عن قناة...',
            hintStyle: TextStyle(color: theme.hintColor),
            border: InputBorder.none,
          ),
          style: TextStyle(color: theme.textTheme.bodyLarge?.color),
          onChanged: filterSearchResults,
        )
            : Text(
          widget.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
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
                  filterSearchResults('');
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
            return buildLoadingScreen(context);
          }
          if (snapshot.hasError || allChannels.isEmpty) {
            return Center(
              child: Text(
                'لم يتم العثور على قنوات في هذه الفئة.',
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }
          if (filteredChannels.isEmpty && searchController.text.isNotEmpty) {
            return Center(
              child: Text(
                'لا توجد نتائج بحث مطابقة.',
                style: TextStyle(color: theme.hintColor),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            itemCount: filteredChannels.length,
            itemBuilder: (context, index) {
              final channel = filteredChannels[index];
              final channelName = channel["name"] ?? 'اسم القناة';
              final channelImage = channel["image"] ?? defaultChannelImage;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 5.0),
                child: Card(
                  elevation: 2.0,
                  clipBehavior: Clip.antiAlias,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8.0),
                      child: Image.network(
                        channelImage,
                        width: 80,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 80,
                            height: 60,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.tv_rounded, color: theme.colorScheme.onSurfaceVariant),
                          );
                        },
                      ),
                    ),
                    title: Text(
                      channelName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      Icons.play_arrow_rounded,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),

                    onTap: () => _onChannelTap(channel),
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