import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ViewFullRecord extends StatelessWidget {
  final Map<String, dynamic> record;

  const ViewFullRecord({super.key, required this.record});

  @override
  Widget build(BuildContext context) {
    final result = record["results"] ?? {};
    final inputs = record["inputs"] ?? {};

    Uint8List? mediaImage;
    if (record["media"] != null) {
      mediaImage = base64Decode(record["media"]);
    }

    Uint8List? blueprintImage;
    if (record["blueprint"] != null) {
      blueprintImage = base64Decode(record["blueprint"]);
    }

    String timestamp = record["timestamp"] ?? "";

    // Extract ML outputs
    final stability = result["stability_score"]?.toStringAsFixed(2) ?? "N/A";
    final damage = result["damage_score"]?.toStringAsFixed(2) ?? "N/A";
    final weakPoint = result["weak_point"].toString();
    final suggestion = result["suggestion"] ?? "";

    final maskUrl = "http://127.0.0.1:5000${result["mask_url"] ?? ""}";
    final heatmapUrl = "http://127.0.0.1:5000${result["heatmap_url"] ?? ""}";

    return Scaffold(
      appBar: AppBar(
        title: const Text("Full Assessment Report"),
        actions: [

          /// ❌ PDF BUTTON REMOVED FOR WEB COMPATIBILITY
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              await StorageService().deleteRecord(record);
              Navigator.pop(context);
            },
          )
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // TIMESTAMP
            Text("Saved on: $timestamp",
                style: const TextStyle(fontSize: 16, color: Colors.grey)),

            const SizedBox(height: 20),

            // USER INPUT SECTION
            const Text("📝 User Input Summary",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),

            infoText("Material", inputs["material"]),
            infoText("Age (years)", inputs["age"]),
            infoText("Height (m)", inputs["height"]),
            infoText("Base Width (m)", inputs["base"]),
            infoText("Floors", inputs["floors"]),
            infoText("Damage Level", inputs["damage"]),
            infoText("Reinforcement Quality", inputs["reinforcement"]),
            infoText("Gas Hazard", inputs["gas"] == "1" ? "Yes" : "No"),
            infoText("Water Hazard", inputs["water"] == "1" ? "Yes" : "No"),
            infoText("Electric Hazard", inputs["electric"] == "1" ? "Yes" : "No"),

            const SizedBox(height: 25),

            // IMAGES SECTION
            const Text("📷 Uploaded Images",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),

            if (mediaImage != null) ...[
              const Text("Building Image:"),
              const SizedBox(height: 5),
              Image.memory(mediaImage, height: 240),
            ],

            const SizedBox(height: 15),

            if (blueprintImage != null) ...[
              const Text("Blueprint:"),
              const SizedBox(height: 5),
              Image.memory(blueprintImage, height: 240),
            ],

            const SizedBox(height: 25),

            // AI OUTPUT SECTION
            const Text("🤖 AI Analysis Result",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),

            infoText("Stability Score", "$stability / 100"),
            infoText("Damage Score", damage),
            infoText("Weak Point", weakPoint),

            const SizedBox(height: 20),

            const Text("Heatmap:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 5),
            Image.network(
              heatmapUrl,
              height: 220,
              errorBuilder: (_, __, ___) =>
                  const Text("Cannot load heatmap image"),
            ),

            const SizedBox(height: 20),

            const Text("Mask Output:", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 5),
            Image.network(
              maskUrl,
              height: 220,
              errorBuilder: (_, __, ___) =>
                  const Text("Cannot load mask image"),
            ),

            const SizedBox(height: 30),

            Text("AI Suggestion:",
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text(suggestion, style: const TextStyle(fontSize: 17)),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget infoText(String title, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text("$title: $value", style: const TextStyle(fontSize: 16)),
    );
  }
}
