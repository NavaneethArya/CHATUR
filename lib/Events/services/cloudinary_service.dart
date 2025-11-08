import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryService {
  static const String cloudName =
      "dihvyw4n4"; // Replace with your Cloudinary name
  static const String uploadPreset = "navarasa"; // Replace with your preset

  static Future<String?> uploadImage(File imageFile) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    try {
      final request = http.MultipartRequest("POST", url)
        ..fields["upload_preset"] = uploadPreset
        ..fields["folder"] = "Events"
        ..files.add(await http.MultipartFile.fromPath("file", imageFile.path));

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final jsonData = json.decode(responseData);
        return jsonData["secure_url"];
      } else {
        print(
            "Cloudinary upload failed: ${response.statusCode}, $responseData");
        return null;
      }
    } catch (e) {
      print("Cloudinary error: $e");
      return null;
    }
  }
}