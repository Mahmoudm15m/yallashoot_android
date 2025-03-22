import 'package:flutter/material.dart';
import '../api/main_api.dart';

class TransfaresScreen extends StatefulWidget {
  const TransfaresScreen({Key? key}) : super(key: key);

  @override
  State<TransfaresScreen> createState() => _TransfaresScreenState();
}

class _TransfaresScreenState extends State<TransfaresScreen> {
  late Future<Map<String, dynamic>> futureResults;
  ApiData yasScore = ApiData();

  Future<Map<String, dynamic>> fetchTransfares() async {
    try {
      final data = await yasScore.getTransfaresData();
      return data;
    } catch (e) {
      return {};
    }
  }

  @override
  void initState() {
    super.initState();
    futureResults = fetchTransfares();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          bottom: const TabBar(
            tabs: [
              Tab(text: "انتقالات هامة"),
              Tab(text: "كل الانتقالات"),
            ],
          ),
        ),
        body: FutureBuilder<Map<String, dynamic>>(
          future: futureResults,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError ||
                !snapshot.hasData ||
                snapshot.data!.isEmpty) {
              return const Center(child: Text("لا توجد بيانات الانتقالات"));
            }

            final data = snapshot.data!;
            final ranks = data["ranks"] as Map<String, dynamic>? ?? {};
            final List listImportant = ranks["list_important"] as List? ?? [];
            final List listNormal = ranks["list"] as List? ?? [];

            return TabBarView(
              children: [
                // تبويب الانتقالات الهامة
                listImportant.isEmpty
                    ? const Center(child: Text("لا توجد انتقالات هامة"))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listImportant.length,
                  itemBuilder: (context, index) {
                    final transfer =
                    listImportant[index] as Map<String, dynamic>;
                    return buildTransferItem(transfer, isImportant: true);
                  },
                ),
                // تبويب كل الانتقالات
                listNormal.isEmpty
                    ? const Center(child: Text("لا توجد انتقالات"))
                    : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: listNormal.length,
                  itemBuilder: (context, index) {
                    final transfer =
                    listNormal[index] as Map<String, dynamic>;
                    return buildTransferItem(transfer, isImportant: false);
                  },
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget buildTransferItem(Map<String, dynamic> transfer,
      {bool isImportant = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: isImportant ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundImage: transfer["player_image"] != null
                      ? NetworkImage(transfer["player_image"].toString().replaceAll("/48/", "/150/"))
                      : null,
                  backgroundColor: Colors.grey[200],
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transfer["player_name"] ?? "",
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${transfer["player_position"] ?? ""} - رقم ${transfer["player_number"]?.toString() ?? ""}",
                        style: TextStyle(
                            color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // عرض الفرق (الفريق الخارج والفريق الداخل)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                          NetworkImage(transfer["team_out_image"] ?? ""),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transfer["team_out"] ?? "-",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_forward, color: Colors.blue),
                Column(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        image: DecorationImage(
                          image:
                          NetworkImage(transfer["team_in_image"] ?? ""),
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transfer["team_in"] ?? "-",
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // نوع الانتقال وقيمته
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  transfer["transfer_type"] ?? "",
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                Text(
                  transfer["transfer_value"] ?? "",
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.green),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // تواريخ الانتقال
            Row(
              children: [
                Expanded(
                  child: Text(
                    "من: ${transfer["transfer_start_date"] ?? "-"}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    "إلى: ${transfer["transfer_end_date"] ?? "-"}",
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
