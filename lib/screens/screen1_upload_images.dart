// lib/screens/screen1_upload_images.dart
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class Screen1UploadImages extends StatefulWidget {
  const Screen1UploadImages({super.key});

  @override
  State<Screen1UploadImages> createState() => _Screen1UploadImagesState();
}

class _Screen1UploadImagesState extends State<Screen1UploadImages> {
  Uint8List? aerialBytes;
  Uint8List? sideBytes;

  // Manual inputs (Option A)
  final _formKey = GlobalKey<FormState>();
  String material = 'RCC';
  final TextEditingController _heightCtrl = TextEditingController();
  final TextEditingController _widthCtrl = TextEditingController();
  final TextEditingController _ageCtrl = TextEditingController();

  bool loading = false;

  Future<void> pickAerial() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Web only file picker')));
      return;
    }
    final bytes = await ApiService.pickWebFile(accept: 'image/*');
    if (bytes != null) {
      setState(() => aerialBytes = bytes);
    }
  }

  Future<void> pickSide() async {
    if (!kIsWeb) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Web only file picker')));
      return;
    }
    final bytes = await ApiService.pickWebFile(accept: 'image/*');
    if (bytes != null) {
      setState(() => sideBytes = bytes);
    }
  }

  Future<void> analyseImages() async {
    if (!_formKey.currentState!.validate()) return;

    if (aerialBytes == null || sideBytes == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Please upload BOTH images")));
      return;
    }

    setState(() => loading = true);
    try {
      final resp = await ApiService.uploadImages(
        aerialBytes: aerialBytes!,
        sideBytes: sideBytes!,
      
      );

      // Navigate to results screen with backend response
      if (!mounted) return;
      Navigator.pushNamed(context, '/results', arguments: {'response': resp});
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    _heightCtrl.dispose();
    _widthCtrl.dispose();
    _ageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Screen 1 – Upload Images")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Upload Aerial & Side View Images",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Manual inputs (Option A)
            Form(
              key: _formKey,
              child: Column(
                children: [
                  // Material dropdown
                  Row(
                    children: [
                      const Text("Material:"),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: material,
                        items: const [
                          DropdownMenuItem(value: 'RCC', child: Text('RCC')),
                          DropdownMenuItem(value: 'Brick', child: Text('Brick')),
                          DropdownMenuItem(value: 'Masonry', child: Text('Masonry')),
                        ],
                        onChanged: (v) {
                          if (v != null) setState(() => material = v);
                        },
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _heightCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Height (m)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter height';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _widthCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Width (m)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter width';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _ageCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Age (years)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Enter age';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Aerial upload
            ElevatedButton(
              onPressed: pickAerial,
              child: const Text("Upload Aerial Image"),
            ),
            if (aerialBytes != null) ...[
              const SizedBox(height: 8),
              Image.memory(aerialBytes!, height: 140),
            ],

            const SizedBox(height: 20),

            // Side upload
            ElevatedButton(
              onPressed: pickSide,
              child: const Text("Upload Side Image"),
            ),
            if (sideBytes != null) ...[
              const SizedBox(height: 8),
              Image.memory(sideBytes!, height: 140),
            ],

            const SizedBox(height: 30),

            // Analyse button (sends images, then navigate to results)
            ElevatedButton(
              onPressed: loading ? null : () async {
                // Save manual inputs locally (we will forward them to final screen later)
                if (!_formKey.currentState!.validate()) return;
                // Put manual data into a place where final stage can access it:
                // We'll pass them through /results -> /upload_csv -> /final
                await analyseImages();
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              child: loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Text("Analyse Images"),
            ),
          ],
        ),
      ),
    );
  }
}