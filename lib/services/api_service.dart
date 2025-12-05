import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;

class ApiService {
  // IMPORTANT: Use actual backend IP
  static const String baseUrl = "http://192.168.1.9:5000";


  static Future<Map<String, dynamic>> sendData({
    required Uint8List imageBytes,
    required String fileName,
    required Map<String, String> fields,
  }) async {
    final uri = Uri.parse('$baseUrl/predict');

    var request = http.MultipartRequest("POST", uri);

    request.fields.addAll(fields);

    request.files.add(
      http.MultipartFile.fromBytes(
        "image",
        imageBytes,
        filename: fileName,
      ),
    );

    final streamedResponse = await request.send();
    final response = await http.Response.fromStream(streamedResponse);

    if (response.statusCode != 200) {
      throw Exception("Server error: ${response.body}");
    }

    return jsonDecode(response.body);
  }
}
