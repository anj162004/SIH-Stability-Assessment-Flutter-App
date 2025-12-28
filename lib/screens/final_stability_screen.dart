// lib/screens/final_stability_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class FinalStabilityScreen extends StatefulWidget {
  const FinalStabilityScreen({super.key});

  @override
  State<FinalStabilityScreen> createState() => _FinalStabilityScreenState();
}

class _FinalStabilityScreenState extends State<FinalStabilityScreen> {
  Map<String, dynamic> imageResp = {};
  Map<String, dynamic> sensorResp = {};
  Map<String, dynamic> manualInputs = {};
  Map<String, dynamic>? result;

  bool loading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final rawArgs = ModalRoute.of(context)!.settings.arguments;

    if (rawArgs is Map) {
      final args = Map<String, dynamic>.from(rawArgs);

      imageResp = Map<String, dynamic>.from(args["image_response"] ?? {});
      sensorResp = Map<String, dynamic>.from(args["sensor_response"] ?? {});
      manualInputs = Map<String, dynamic>.from(args["manual_inputs"] ?? {});
    }
  }

  Future<void> calculate() async {
    setState(() => loading = true);

    try {
      final body = {
        "crack_severity": imageResp["crack_severity"] ?? 0.0,
        "vibration_norm": sensorResp["vibration_norm"] ?? 0.0,
        "buckling_norm": sensorResp["buckling_norm"] ?? 0.0,
        "reinforcement_quality": sensorResp["reinforcement_quality"] ?? 1.0,
        "age": manualInputs["age"] ?? 0,
        "material": manualInputs["material"] ?? "RCC",
        "height": manualInputs["height"] ?? 0,
        "width": manualInputs["width"] ?? 0,
      };

      final apiResp = await ApiService.calculateStability(body);

      setState(() {
        result = {
          "stability_score": apiResp["stability_score"],
          "classification": apiResp["classification"],
          "weak_points": imageResp["weak_points"] ?? [],
          "safe_points": imageResp["safe_points"] ?? [],
          "hazards": sensorResp["hazards"] ?? [],
          "aerial_heatmap": imageResp["files"]?["aerial_heatmap"],
          "side_heatmap": imageResp["files"]?["side_heatmap"],
        };
        loading = false;
      });
    } catch (e) {
      setState(() => loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Final Stability")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ElevatedButton(
                onPressed: loading ? null : calculate,
                child: loading
                    ? const CircularProgressIndicator()
                    : const Text("Calculate Stability"),
              ),
            ),

            const SizedBox(height: 30),

            if (result != null) _buildResultCard(result!)
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(Map<String, dynamic> data) {
    final aerialHeatmap = data["aerial_heatmap"];
    final sideHeatmap = data["side_heatmap"];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Stability Score: ${(data["stability_score"] ?? 0).toStringAsFixed(3)}",
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        Text(
          "Classification: ${data["classification"]}",
          style: const TextStyle(
              fontSize: 18, color: Colors.blueGrey, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 30),

        // HEATMAPS
        const Text("Aerial Heatmap",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        aerialHeatmap != null
            ? Image.network(ApiService.fileUrl(aerialHeatmap),
                height: 220, fit: BoxFit.cover)
            : const Text("Aerial heatmap not available"),

        const SizedBox(height: 20),

        const Text("Side Heatmap",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        sideHeatmap != null
            ? Image.network(ApiService.fileUrl(sideHeatmap),
                height: 220, fit: BoxFit.cover)
            : const Text("Side heatmap not available"),

        const SizedBox(height: 30),

        // LEGEND
        const Text("Heatmap Legend:",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),

        Row(children: const [
          Icon(Icons.square, color: Colors.red),
          SizedBox(width: 6),
          Text("Red = High Risk")
        ]),
        Row(children: const [
          Icon(Icons.square, color: Colors.yellow),
          SizedBox(width: 6),
          Text("Yellow = Moderate Risk")
        ]),
        Row(children: const [
          Icon(Icons.square, color: Colors.green),
          SizedBox(width: 6),
          Text("Green = Safe")
        ]),
        Row(children: const [
          Icon(Icons.square, color: Colors.blue),
          SizedBox(width: 6),
          Text("Blue = Very Safe")
        ]),

        const SizedBox(height: 30),

        // HAZARDS
        const Text("Secondary Hazards:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 10),
        ...(data["hazards"] as List).map((h) => Text(
            "⚠️ ${h['type']} (Severity: ${h['severity']})",
            style: const TextStyle(fontSize: 16))),

        const SizedBox(height: 30),

        // WEAK POINTS
        const Text("Weak Points:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ...((data["weak_points"] as List).map(
            (p) => Text("⚠️ x:${p['x']} y:${p['y']}"))),

        const SizedBox(height: 30),

        // SAFE POINTS
        const Text("Safe Points:",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        ...((data["safe_points"] as List)
            .map((p) => Text("🟢 x:${p['x']} y:${p['y']}"))),

        const SizedBox(height: 40),
      ],
    );
  }
}