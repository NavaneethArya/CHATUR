// cloudinaryForStore.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class CloudinaryStoreService {
  static const String cloudName = "dihvyw4n4"; // Your Cloudinary cloud name
  static const String uploadPreset = "navarasa"; // Your upload preset

  /// Upload a single store logo image
  static Future<String?> uploadStoreLogo(File imageFile) async {
    final url =
        Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

    try {
      final request = http.MultipartRequest("POST", url)
        ..fields["upload_preset"] = uploadPreset
        ..fields["folder"] = "Store/Logos" // Organized folder structure
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

  /// Upload multiple product images
  static Future<List<String>> uploadProductImages(List<File> imageFiles) async {
    List<String> uploadedUrls = [];

    for (File imageFile in imageFiles) {
      final url =
          Uri.parse("https://api.cloudinary.com/v1_1/$cloudName/image/upload");

      try {
        final request = http.MultipartRequest("POST", url)
          ..fields["upload_preset"] = uploadPreset
          ..fields["folder"] = "Store/Products" // Organized folder for products
          ..files
              .add(await http.MultipartFile.fromPath("file", imageFile.path));

        final response = await request.send();
        final responseData = await response.stream.bytesToString();

        if (response.statusCode == 200) {
          final jsonData = json.decode(responseData);
          uploadedUrls.add(jsonData["secure_url"]);
        } else {
          print(
              "Failed to upload image: ${response.statusCode}, $responseData");
        }
      } catch (e) {
        print("Error uploading image: $e");
      }
    }

    return uploadedUrls;
  }
}
