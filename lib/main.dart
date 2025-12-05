import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';

// FIXED IMPORT PATHS
import '../services/api_service.dart';
import '../services/storage_service.dart';
import 'screens/result_screen.dart';
import 'screens/history_screen.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await StorageService().init(); // Initialize IndexedDB
  runApp(const SSATApp());
}

class SSATApp extends StatelessWidget {
  const SSATApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSAT Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _formKey = GlobalKey<FormState>();

  // Inputs
  String? material, damage, reinforcement;
  double? age, height, base, floors;
  bool gas = false, water = false, electric = false;

  Uint8List? blueprintBytes;
  Uint8List? mediaBytes;
  html.File? mediaFile;

  bool loading = false;

  // PICK BLUEPRINT
  Future<void> pickBlueprint() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() => blueprintBytes = result.files.single.bytes);
    }
  }

  // PICK MEDIA IMAGE
  Future<void> pickMedia() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);

    if (result != null) {
      setState(() {
        mediaBytes = result.files.single.bytes;
        mediaFile = html.File(
          result.files.single.bytes!,
          result.files.single.name,
        );
      });
    }
  }

  // ANALYZE + STORE LOCALLY
  Future<void> analyzeStructure() async {
    if (mediaBytes == null) {
      Fluttertoast.showToast(msg: "⚠ Upload a building image first!");
      return;
    }

    setState(() => loading = true);

    final inputs = {
      "material": material ?? "",
      "age": age?.toString() ?? "",
      "height": height?.toString() ?? "",
      "base": base?.toString() ?? "",
      "floors": floors?.toString() ?? "",
      "damage": damage ?? "",
      "reinforcement": reinforcement ?? "",
      "gas": gas ? "1" : "0",
      "water": water ? "1" : "0",
      "electric": electric ? "1" : "0",
      "vibration": "0.3",
    };

    try {
      // CALL FLASK BACKEND
      final result = await ApiService.sendData(
        imageBytes: mediaBytes!,
        fileName: mediaFile!.name,
        fields: inputs,
      );

      // SAVE DATA LOCALLY
      await StorageService().saveRecord({
        "timestamp": DateTime.now().toIso8601String(),
        "inputs": inputs,
        "results": result,
        "blueprint": blueprintBytes != null ? base64Encode(blueprintBytes!) : null,
        "media": base64Encode(mediaBytes!),
      });

      setState(() => loading = false);

      // NAVIGATE TO RESULT SCREEN
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ResultScreen(result: result),
        ),
      );

    } catch (e) {
      setState(() => loading = false);
      Fluttertoast.showToast(msg: "❌ Error: $e");
    }
  }

  // -----------------------------------------------------------
  // UI SECTION
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Structural Stability Assessment Tool"),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
          ),
        ],
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Building Parameters",
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // MATERIAL FIELD
                    DropdownButtonFormField<String>(
                      value: material,
                      items: ['Reinforced Concrete', 'Steel', 'Brick', 'Wood']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => material = v),
                      decoration: const InputDecoration(labelText: 'Material'),
                    ),

                    // AGE
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'Age (Years)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => age = double.tryParse(v),
                    ),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Height (m)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => height = double.tryParse(v),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            decoration:
                                const InputDecoration(labelText: 'Base Width (m)'),
                            keyboardType: TextInputType.number,
                            onChanged: (v) => base = double.tryParse(v),
                          ),
                        ),
                      ],
                    ),

                    // FLOORS
                    TextFormField(
                      decoration: const InputDecoration(labelText: 'No. of Floors'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => floors = double.tryParse(v),
                    ),

                    // DAMAGE FIELD
                    DropdownButtonFormField<String>(
                      value: damage,
                      items: ['Low', 'Moderate', 'Severe']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => damage = v),
                      decoration: const InputDecoration(labelText: 'Damage Level'),
                    ),

                    // REINFORCEMENT FIELD
                    DropdownButtonFormField<String>(
                      value: reinforcement,
                      items: ['Good', 'Average', 'Poor']
                          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                          .toList(),
                      onChanged: (v) => setState(() => reinforcement = v),
                      decoration:
                          const InputDecoration(labelText: 'Reinforcement Quality'),
                    ),

                    const SizedBox(height: 12),
                    const Text("Environmental Hazards"),

                    CheckboxListTile(
                      title: const Text("Gas Leakage"),
                      value: gas,
                      onChanged: (v) => setState(() => gas = v!),
                    ),

                    CheckboxListTile(
                      title: const Text("Water Leakage"),
                      value: water,
                      onChanged: (v) => setState(() => water = v!),
                    ),

                    CheckboxListTile(
                      title: const Text("Electric Faults"),
                      value: electric,
                      onChanged: (v) => setState(() => electric = v!),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: pickBlueprint,
                      icon: const Icon(Icons.upload),
                      label: const Text("Upload Blueprint (Optional)"),
                    ),

                    const SizedBox(height: 10),

                    ElevatedButton.icon(
                      onPressed: pickMedia,
                      icon: const Icon(Icons.camera),
                      label: const Text("Upload Building Image"),
                    ),

                    if (mediaBytes != null) ...[
                      const SizedBox(height: 15),
                      const Text("Image Preview:"),
                      Image.memory(mediaBytes!, height: 180),
                    ],

                    const SizedBox(height: 20),

                    Center(
                      child: ElevatedButton.icon(
                        onPressed: analyzeStructure,
                        icon: const Icon(Icons.analytics),
                        label: const Text("Analyze With AI"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
