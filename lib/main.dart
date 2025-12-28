// lib/main.dart
import 'package:flutter/material.dart';

import 'screens/screen1_upload_images.dart';
import 'screens/screen2_result.dart';
import 'screens/screen3_upload_csv.dart';
import 'screens/final_stability_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stability Assessment Tool',
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const Screen1UploadImages(),
        '/results': (context) => const Screen2Result(),
        '/upload_csv': (context) => const Screen3UploadCSV(),
        '/final': (context) => const FinalStabilityScreen(),
      },
    );
  }
}