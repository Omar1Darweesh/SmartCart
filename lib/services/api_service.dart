import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class ApiService {
  static const String baseUrl = "http://10.0.2.2:5000";

  static Future<Map<String, dynamic>?> sendImageToServer(File imageFile) async {
    var url = Uri.parse("$baseUrl/detect");

    var request = http.MultipartRequest("POST", url);
    request.files.add(
      await http.MultipartFile.fromPath("image", imageFile.path),
    );

    try {
      var response = await request.send();
      var responseBody = await response.stream.bytesToString();

      print("📡 Server Response: $responseBody");

      if (response.statusCode == 200) {
        return jsonDecode(responseBody);
      } else {
        print(
          "❌ Failed to connect to the server: Status Code ${response.statusCode}",
        );
        return null;
      }
    } catch (e) {
      print("⚠️ Error while connecting to the server: $e");
      return null;
    }
  }
}
