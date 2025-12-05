import 'package:flutter/material.dart';

class ResultScreen extends StatelessWidget {
  final Map<String, dynamic> result;

  const ResultScreen({super.key, required this.result});

  @override
  Widget build(BuildContext context) {
    // ---------- BASIC SCORES ----------
    final stabilityVal = _toDouble(result['stability_score']);
    final damageVal = _toDouble(result['damage_score']);

    final stability =
        stabilityVal != null ? stabilityVal.toStringAsFixed(2) : "N/A";
    final damage = damageVal != null ? damageVal.toStringAsFixed(2) : "N/A";

    // ---------- WEAK POINT ----------
    String weakPointText = "N/A";

    if (result['weak_point'] is Map) {
      final wp = Map<String, dynamic>.from(result['weak_point']);
      final score = _toDouble(wp['score']) ?? 0.0;
      final x = wp['x']?.toString() ?? "N/A";
      final y = wp['y']?.toString() ?? "N/A";

      weakPointText = "Severity ${score.toStringAsFixed(2)} at (x: $x, y: $y)";
    }

    final suggestion = result['suggestion']?.toString() ?? "No suggestion";

    // ---------- IMAGE URLS ----------
    const backendBase = "http://192.168.1.9:5000";

    final maskUrl = _fullUrl(backendBase, result['mask_url']);
    final heatmapUrl = _fullUrl(backendBase, result['heatmap_url']);
    final weakOverlayUrl = _fullUrl(backendBase, result['weak_overlay_url']);
    final weakCropUrl = _fullUrl(backendBase, result['weak_crop_url']);

    return Scaffold(
      appBar: AppBar(title: const Text("AI Analysis Result")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            //---------------------- SCORES -----------------------
            Text("Stability Score: $stability / 100",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            Text("Damage Score: $damage", style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 8),

            Text("Weak Point: $weakPointText",
                style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),

            const Text("AI Recommendation:",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(suggestion, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 24),

            const Divider(),
            const SizedBox(height: 16),

            //---------------------- HEATMAP -----------------------
            if (heatmapUrl != null) ...[
              const Text("Heatmap Output (Overall)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              InkWell(
                onTap: () => _showFullImage(context, heatmapUrl!),
                child: Hero(
                  tag: "heatmap_full",
                  child: Image.network(
                    heatmapUrl!,
                    height: 250,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) =>
                        const Text("Unable to load heatmap"),
                  ),
                ),
              ),

              const SizedBox(height: 12),
              _buildHeatmapLegend(),
              const SizedBox(height: 24),
            ],

            //----------------- WEAK POINT OVERLAY ------------------
            if (weakOverlayUrl != null) ...[
              const Text("Weak Point Highlighted",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              InkWell(
                onTap: () => _showFullImage(context, weakOverlayUrl!),
                child: Hero(
                  tag: "weak_overlay_full",
                  child: Image.network(
                    weakOverlayUrl!,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "🔴 Black-centered mark shows the highest risk location.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
            ],

            //------------------ WEAK POINT ZOOM -------------------
            if (weakCropUrl != null) ...[
              const Text("Zoomed Weak Region (Close-up)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              InkWell(
                onTap: () => _showFullImage(context, weakCropUrl!),
                child: Hero(
                  tag: "weak_crop_full",
                  child: Image.network(
                    weakCropUrl!,
                    height: 220,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Helps NDRF quickly identify the most critical damaged area.",
                style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 24),
            ],

            //------------------ SEGMENTATION MASK ------------------
            if (maskUrl != null) ...[
              const Text("Segmentation Mask (Crack Regions)",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              InkWell(
                onTap: () => _showFullImage(context, maskUrl!),
                child: Hero(
                  tag: "mask_full",
                  child: Image.network(
                    maskUrl!,
                    height: 250,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _buildMaskLegend(),
              const SizedBox(height: 24),
            ],

            const Divider(),
            const SizedBox(height: 12),
            const Text(
              "Red = high risk | Yellow = moderate | Green = safe\n"
              "Mask: White = crack | Black = healthy surface",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }

  //========================================
  // IMAGE VIEWER (FULL SCREEN POP-UP)
  //========================================
  void _showFullImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: EdgeInsets.zero,
        child: InteractiveViewer(
          panEnabled: true,
          child: Image.network(url, fit: BoxFit.contain),
        ),
      ),
    );
  }

  //========================================
  // HEATMAP LEGEND
  //========================================
  Widget _buildHeatmapLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Heatmap Legend",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        _legendRow(Colors.red, "Red – High Risk (Severe crack)"),
        _legendRow(Colors.yellow, "Yellow – Moderate Risk"),
        _legendRow(Colors.green, "Green – Safe Zone"),
      ],
    );
  }

  //========================================
  // MASK LEGEND
  //========================================
  Widget _buildMaskLegend() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Segmentation Mask Legend",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        _legendRow(Colors.white, "White – Crack Detected"),
        _legendRow(Colors.black, "Black – No Crack"),
      ],
    );
  }

  // reusable legend row
  Widget _legendRow(Color color, String text) {
    return Row(children: [
      _legendBox(color),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(fontSize: 15))),
    ]);
  }

  // square color box
  Widget _legendBox(Color color) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: color,
        border: Border.all(color: Colors.black),
      ),
    );
  }

  // Utility: safe double parser
  double? _toDouble(dynamic val) {
    if (val is num) return val.toDouble();
    return double.tryParse(val.toString());
  }

  // Utility: prepend server address
  static String? _fullUrl(String base, dynamic url) {
    if (url == null) return null;
    final s = url.toString();
    if (s.isEmpty) return null;
    return "$base$s";
  }
}
