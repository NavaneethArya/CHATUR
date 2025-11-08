// schemeAPI.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class Scheme {
  final String title;
  final String description;
  final String tags;
  final List<String> details;
  final List<String> benefits;
  final List<String> eligibility;
  final List<String> applicationProcess;
  final List<String> documentsRequired;
  final String link;
  final String id;

  Scheme({
    required this.title,
    required this.description,
    required this.tags,
    required this.details,
    required this.benefits,
    required this.eligibility,
    required this.applicationProcess,
    required this.documentsRequired,
    required this.link,
    required this.id,
  });

  factory Scheme.fromJson(Map<String, dynamic> json) {
    // Helper function to safely parse lists
    List<String> parseList(dynamic data) {
      if (data == null) return [];
      if (data is List) {
        return data.map((item) => item.toString()).toList();
      }
      return [];
    }

    return Scheme(
      title: json['Title'] ?? json['title'] ?? 'No Title',
      description:
          json['Description'] ?? json['description'] ?? 'No Description',
      tags: json['Tags'] ?? json['tags'] ?? '',
      details: parseList(json['Details'] ?? json['details']),
      benefits: parseList(json['Benefits'] ?? json['benefits']),
      eligibility: parseList(json['Eligibility'] ?? json['eligibility']),
      applicationProcess: parseList(
        json['Application Process'] ?? json['applicationProcess'],
      ),
      documentsRequired: parseList(
        json['Documents Required'] ?? json['documentsRequired'],
      ),
      link: json['Link'] ?? json['link'] ?? '',
      id: json['id'] ?? '',
    );
  }

  // Convert Scheme to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'Title': title,
      'Description': description,
      'Tags': tags,
      'Details': details,
      'Benefits': benefits,
      'Eligibility': eligibility,
      'Application Process': applicationProcess,
      'Documents Required': documentsRequired,
      'Link': link,
      'id': id,
    };
  }
}

Future<List<Scheme>> fetchKarnatakaSchemes({
  String language = 'English',
}) async {
  // Determine the language code based on the selected language
  String langCode = 'en'; // Default to English

  if (language == 'Kannada') {
    langCode = 'kn';
  } else if (language == 'Hindi') {
    langCode =
        'en'; // Hindi falls back to English (you can add 'hi' endpoint if available)
  }

  final String apiUrl =
      "https://navarasa-chathur-api.hf.space/$langCode/schemes";

  try {
    final response = await http.get(
      Uri.parse(apiUrl),
      headers: {"Accept": "application/json"},
    );

    print('Language: $language ($langCode)');
    print('API URL: $apiUrl');
    print('Response Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);

      // Extract list from "karnataka" key
      List<dynamic> schemesList = decoded["karnataka"];

      // Convert to list of Scheme objects
      return schemesList.map((item) => Scheme.fromJson(item)).toList();
    } else {
      throw Exception(
        "Failed to load schemes. Status code: ${response.statusCode}",
      );
    }
  } catch (e) {
    print("Error: $e");
    throw Exception("Error fetching schemes: $e");
  }
}
