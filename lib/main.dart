import 'dart:convert';
import 'dart:typed_data';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:file_picker/file_picker.dart';

void main() => runApp(const SSATApp());

class SSATApp extends StatelessWidget {
  const SSATApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SSAT Prototype',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.teal),
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
  String? material, damage, reinforcement;
  double? age, height, base, floors;
  bool gas = false, water = false, electric = false;
  double? stabilityScore;

  // File storage
  html.File? blueprintFile;
  Uint8List? blueprintBytes;

  html.File? mediaFile;
  Uint8List? mediaBytes;

  // --- stability calculation ---
  double calculateStability() {
    double M = {
      'Reinforced Concrete': 0.9,
      'Steel': 1.0,
      'Brick': 0.6,
      'Wood': 0.4
    }[material] ?? 0.7;

    double A = (age != null) ? (age! < 10 ? 1.0 : age! < 30 ? 0.8 : 0.6) : 0.8;
    double G = (height != null && base != null)
        ? (1 - ((height! / base!).clamp(0.1, 10) / 10))
        : 0.8;
    double L = (floors != null) ? (floors! <= 2 ? 1 : floors! <= 5 ? 0.8 : 0.6) : 0.8;
    double D = {'Low': 1.0, 'Moderate': 0.7, 'Severe': 0.4}[damage] ?? 0.8;
    double R = {'Good': 1.0, 'Average': 0.8, 'Poor': 0.6}[reinforcement] ?? 0.8;
    double E = 1 -
        ([
              gas ? 1 : 0,
              water ? 1 : 0,
              electric ? 1 : 0
            ].where((e) => e == 1).length *
            0.1); // penalty per hazard

    double baseScore =
        (0.2 * M + 0.15 * A + 0.15 * G + 0.15 * L + 0.2 * D + 0.1 * R + 0.05 * E);
    double correction = 1 - ((height ?? 5) / (base ?? 5)) / 10;
    return (baseScore * correction * 100).clamp(0, 100);
  }

  // --- pick blueprint ---
  Future<void> pickBlueprint() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.image);
    if (result != null) {
      setState(() {
        blueprintBytes = result.files.single.bytes;
        blueprintFile = html.File(result.files.single.bytes!, result.files.single.name);
      });
    }
  }

  // --- pick media (photo/video) ---
  Future<void> pickMedia() async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(type: FileType.media);
    if (result != null) {
      setState(() {
        mediaBytes = result.files.single.bytes;
        mediaFile = html.File(result.files.single.bytes!, result.files.single.name);
      });
    }
  }

  // --- save JSON with blueprint + media ---
  Future<void> saveAsJson() async {
    Map<String, dynamic> data = {
      'material': material,
      'age': age,
      'height': height,
      'base': base,
      'floors': floors,
      'damage': damage,
      'reinforcement': reinforcement,
      'hazards': {
        'gas': gas,
        'water': water,
        'electric': electric,
      },
      'stabilityScore': stabilityScore,
      'timestamp': DateTime.now().toIso8601String(),
      'blueprint': blueprintBytes != null ? base64Encode(blueprintBytes!) : null,
      'media': mediaBytes != null ? base64Encode(mediaBytes!) : null,
    };

    final blob = html.Blob([jsonEncode(data)], 'application/json');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download',
          'assessment_${DateTime.now().millisecondsSinceEpoch}.json')
      ..click();
    html.Url.revokeObjectUrl(url);

    Fluttertoast.showToast(msg: "✅ Assessment & files saved successfully!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Structural Stability Assessment Tool')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Building Parameters",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Material
              DropdownButtonFormField<String>(
                initialValue: material,
                items: ['Reinforced Concrete', 'Steel', 'Brick', 'Wood']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => material = v),
                decoration: const InputDecoration(labelText: 'Material Type'),
              ),

              // Age
              TextFormField(
                decoration:
                    const InputDecoration(labelText: 'Age of Building (years)'),
                keyboardType: TextInputType.number,
                onChanged: (v) => age = double.tryParse(v),
              ),

              // Height & Base
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      decoration: const InputDecoration(labelText: 'Height (m)'),
                      keyboardType: TextInputType.number,
                      onChanged: (v) => height = double.tryParse(v),
                    ),
                  ),
                  const SizedBox(width: 10),
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

              // Floors
              TextFormField(
                decoration: const InputDecoration(labelText: 'No. of Floors'),
                keyboardType: TextInputType.number,
                onChanged: (v) => floors = double.tryParse(v),
              ),

              // Damage
              DropdownButtonFormField<String>(
                initialValue: damage,
                items: ['Low', 'Moderate', 'Severe']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => damage = v),
                decoration:
                    const InputDecoration(labelText: 'Visible Damage Level'),
              ),

              // Reinforcement
              DropdownButtonFormField<String>(
                initialValue: reinforcement,
                items: ['Good', 'Average', 'Poor']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setState(() => reinforcement = v),
                decoration:
                    const InputDecoration(labelText: 'Reinforcement Quality'),
              ),

              const SizedBox(height: 10),
              const Text("Environmental Hazards:"),
              Wrap(
                spacing: 20,
                children: [
                  CheckboxListTile(
                      title: const Text('Gas'),
                      value: gas,
                      onChanged: (v) => setState(() => gas = v!)),
                  CheckboxListTile(
                      title: const Text('Water'),
                      value: water,
                      onChanged: (v) => setState(() => water = v!)),
                  CheckboxListTile(
                      title: const Text('Electric'),
                      value: electric,
                      onChanged: (v) => setState(() => electric = v!)),
                ],
              ),

              const SizedBox(height: 10),

              // Upload buttons
              ElevatedButton.icon(
                onPressed: pickBlueprint,
                icon: const Icon(Icons.upload_file),
                label: const Text("Upload Blueprint"),
              ),
              const SizedBox(height: 10),
              ElevatedButton.icon(
                onPressed: pickMedia,
                icon: const Icon(Icons.video_library),
                label: const Text("Upload Photo/Video"),
              ),

              // Preview Section
              if (blueprintBytes != null) ...[
                const SizedBox(height: 20),
                const Text("Blueprint Preview:"),
                const SizedBox(height: 10),
                Image.memory(blueprintBytes!, height: 200, fit: BoxFit.contain),
              ],
              if (mediaFile != null) ...[
                const SizedBox(height: 20),
                Text("Uploaded Media: ${mediaFile!.name}"),
              ],

              const SizedBox(height: 20),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      setState(() {
                        stabilityScore = calculateStability();
                      });
                    }
                  },
                  child: const Text("Calculate Stability Score"),
                ),
              ),

              // Show score
              if (stabilityScore != null) ...[
                const SizedBox(height: 20),
                Text("Stability Score: ${stabilityScore!.toStringAsFixed(2)}",
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                LinearProgressIndicator(
                  value: stabilityScore! / 100,
                  minHeight: 15,
                  backgroundColor: Colors.red[100],
                  color: stabilityScore! > 70
                      ? Colors.green
                      : stabilityScore! > 40
                          ? Colors.orange
                          : Colors.red,
                ),
                const SizedBox(height: 10),
                Text(
                  stabilityScore! > 70
                      ? "Safe Zone"
                      : stabilityScore! > 40
                          ? "Moderate Risk"
                          : "Critical Risk",
                  style: TextStyle(
                      color: stabilityScore! > 70
                          ? Colors.green
                          : stabilityScore! > 40
                              ? Colors.orange
                              : Colors.red,
                      fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: saveAsJson,
                  icon: const Icon(Icons.save),
                  label: const Text("Save Assessment"),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
