import 'dart:convert';
import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:universal_html/html.dart' as html;


class ApiService {
  static const String baseUrl = "http://127.0.0.1:5000";

  // -----------------------------------------
  // PICK FILE (WEB ONLY)
  // -----------------------------------------
  static Future<Uint8List?> pickWebFile({required String accept}) async {
    final completer = Completer<Uint8List?>();
    final input = html.FileUploadInputElement()..accept = accept;
    input.click();

    input.onChange.listen((event) {
      final file = input.files?.first;
      if (file == null) {
        completer.complete(null);
        return;
      }
      final reader = html.FileReader();
      reader.readAsArrayBuffer(file);
      reader.onLoadEnd.listen((event) {
        completer.complete(reader.result as Uint8List);
      });
    });

    return completer.future;
  }

  // -----------------------------------------
  // UPLOAD IMAGES
  // -----------------------------------------
  static Future<Map<String, dynamic>> uploadImages({
    required Uint8List aerialBytes,
    required Uint8List sideBytes,
  }) async {
    final uri = Uri.parse("$baseUrl/predict_images");
    final req = http.MultipartRequest("POST", uri);

    req.files.add(http.MultipartFile.fromBytes(
      "aerial_image",
      aerialBytes,
      filename: "aerial.jpg",
    ));

    req.files.add(http.MultipartFile.fromBytes(
      "side_image",
      sideBytes,
      filename: "side.jpg",
    ));

    final response = await req.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(respStr);
    } else {
      throw Exception("Upload Images Error: $respStr");
    }
  }

  // -----------------------------------------
  // UPLOAD SENSOR CSV
  // -----------------------------------------
  static Future<Map<String, dynamic>> uploadSensors({
    required Uint8List csvBytes,
    required String filename,
  }) async {
    final uri = Uri.parse("$baseUrl/upload_sensors");
    final req = http.MultipartRequest("POST", uri);

    req.files.add(http.MultipartFile.fromBytes(
      "sensor_csv",
      csvBytes,
      filename: filename,
    ));

    final response = await req.send();
    final respStr = await response.stream.bytesToString();

    if (response.statusCode == 200) {
      return jsonDecode(respStr);
    } else {
      throw Exception("CSV Upload Error: $respStr");
    }
  }

  // -----------------------------------------
  // FINAL STABILITY CALCULATION
  // -----------------------------------------
  static Future<Map<String, dynamic>> calculateStability(
      Map<String, dynamic> body) async {
    final url = Uri.parse("$baseUrl/calculate_stability");

    final resp = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (resp.statusCode == 200) {
      return jsonDecode(resp.body);
    } else {
      throw Exception("Stability API Error: ${resp.body}");
    }
  }

  // -----------------------------------------
  // GENERATE URL FOR IMAGES RETURNED BY BACKEND
  // -----------------------------------------
  static String fileUrl(String relPath) {
    if (relPath.startsWith("/")) {
      return "$baseUrl$relPath";
    }
    return "$baseUrl/$relPath";
  }
}