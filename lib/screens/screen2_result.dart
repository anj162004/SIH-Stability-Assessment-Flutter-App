// lib/screens/screen2_result.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Screen2Result extends StatelessWidget {
  const Screen2Result({super.key});

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
    final resp = args["response"];
    final manualInputs = args["manual_inputs"] ?? {};

    final crack = resp["crack_severity"];
    final beams = resp["beam_coordinates"] ?? [];
    final columns = resp["column_coordinates"] ?? [];

    final files = resp["files"] ?? {};

    // Heatmap + overlay keys
    final overlay = files["beam_column_overlay"];
    final aerialHeatmap = files["aerial_heatmap"];
    final sideHeatmap = files["side_heatmap"];

    return Scaffold(
      appBar: AppBar(title: const Text("AI Analysis Result")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Crack Severity: ${(crack * 100).toStringAsFixed(1)}%",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),

            const Text("Beam Coordinates:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...beams.map((b) => Text("Beam → x:${b['x']}  y:${b['y']}")),
            const SizedBox(height: 16),

            const Text("Column Coordinates:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ...columns.map((c) => Text("Column → x:${c['x']}  y:${c['y']}")),
            const SizedBox(height: 20),

            // IMAGES
            _imageTile("Beam / Column Overlay", overlay),
            _imageTile("Aerial Heatmap", aerialHeatmap),
            _imageTile("Side Heatmap", sideHeatmap),

            const SizedBox(height: 20),

            // ---------------- HEATMAP LEGEND ----------------
            const Text("Heatmap Legend:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            Row(children: const [
              Icon(Icons.square, color: Colors.red),
              SizedBox(width: 6),
              Text("Red = High Risk (Severe Damage)")
            ]),
            Row(children: const [
              Icon(Icons.square, color: Colors.yellow),
              SizedBox(width: 6),
              Text("Yellow = Moderate Damage")
            ]),
            Row(children: const [
              Icon(Icons.square, color: Colors.green),
              SizedBox(width: 6),
              Text("Green = Safe Zone")
            ]),
            Row(children: const [
              Icon(Icons.square, color: Colors.blue),
              SizedBox(width: 6),
              Text("Blue = Very Safe (No cracks)")
            ]),

            const SizedBox(height: 30),

            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    "/upload_csv",
                    arguments: {
                      "image_response": {
                        ...resp,
                        "files": {
                          ...files,
                          "aerial_heatmap": aerialHeatmap,
                          "side_heatmap": sideHeatmap,
                          "beam_column_overlay": overlay,
                        }
                      },
                      "manual_inputs": manualInputs,
                    },
                  );
                },
                child: const Text("Proceed → Upload Sensor CSV"),
              ),
            )
          ],
        ),
      ),
    );
  }

  // ---------------- IMAGE TILE ----------------
  Widget _imageTile(String title, String? path) {
    if (path == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const Text("Not available"),
          const SizedBox(height: 20),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Image.network(ApiService.fileUrl(path), height: 240, fit: BoxFit.cover),
        const SizedBox(height: 20),
      ],
    );
  }
}