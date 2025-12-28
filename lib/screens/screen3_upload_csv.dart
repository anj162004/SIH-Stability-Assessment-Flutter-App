// lib/screens/screen3_upload_csv.dart

import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Screen3UploadCSV extends StatefulWidget {
  const Screen3UploadCSV({super.key});

  @override
  State<Screen3UploadCSV> createState() => _Screen3UploadCSVState();
}

class _Screen3UploadCSVState extends State<Screen3UploadCSV> {
  Uint8List? csvBytes;
  bool loading = false;

  Future<void> pickCSV() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("CSV picker works only on Web")),
      );
      return;
    }

    final bytes = await ApiService.pickWebFile(accept: ".csv");
    if (bytes != null) {
      setState(() => csvBytes = bytes);
    }
  }

  Future<void> uploadCSVAndProceed() async {
    if (csvBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please select a CSV")));
      return;
    }

    setState(() => loading = true);

    try {
      final sensorData = await ApiService.uploadSensors(
        csvBytes: csvBytes!,
        filename: "sensor.csv",
      );

      final args =
          ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;

      final imageResp = Map<String, dynamic>.from(args["image_response"] ?? {});
      final manualInputs = args["manual_inputs"] ?? {};

      Navigator.pushNamed(
        context,
        "/final",
        arguments: {
          "image_response": imageResp,
          "sensor_response": sensorData,
          "manual_inputs": manualInputs,
        },
      );
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Upload Sensor CSV")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Text(
              "Upload sensor CSV (vibration, buckling, reinforcement, gas, voltage, temperature)",
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: pickCSV,
              child: const Text("Pick CSV File"),
            ),

            if (csvBytes != null)
              Text("CSV Selected (${csvBytes!.lengthInBytes} bytes)"),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : uploadCSVAndProceed,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Upload & Continue"),
            ),
          ],
        ),
      ),
    );
  }
}