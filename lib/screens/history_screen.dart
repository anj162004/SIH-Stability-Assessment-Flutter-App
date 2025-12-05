import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';
import 'view_full_record.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Map<String, dynamic>> records = [];

  @override
  void initState() {
    super.initState();
    loadRecords();
  }

  Future<void> loadRecords() async {
    final data = await StorageService().getAllRecords();
    setState(() => records = data.reversed.toList());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Saved Assessments (History)")),
      body: records.isEmpty
          ? const Center(child: Text("No saved assessments yet"))
          : GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,         // 2 cards per row
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: records.length,
              itemBuilder: (context, index) {
                final record = records[index];

                // Thumbnail (from media base64)
                Uint8List? imageBytes;
                if (record["media"] != null) {
                  imageBytes = base64Decode(record["media"]);
                }

                String stability = record["results"]?["stability_score"]?.toStringAsFixed(2) ?? "N/A";
                String timestamp = record["timestamp"] ?? "Unknown";

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ViewFullRecord(record: record),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: imageBytes != null
                              ? ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                  child: Image.memory(imageBytes, fit: BoxFit.cover),
                                )
                              : const Center(child: Text("No Image")),
                        ),

                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Stability: $stability",
                                  style: const TextStyle(
                                      fontSize: 16, fontWeight: FontWeight.bold)),

                              const SizedBox(height: 5),

                              Text(
                                timestamp,
                                style: const TextStyle(fontSize: 12, color: Colors.grey),
                              )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
