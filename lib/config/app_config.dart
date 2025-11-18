// ============================================
// APP CONFIGURATION
// SECURITY: API Keys should be loaded from environment variables
// For production, use flutter_dotenv or similar package
// ============================================

class AppConfig {
  // NOTE: In production, load these from environment variables
  // Example: use flutter_dotenv package
  // static const String geminiApiKey = String.fromEnvironment('GEMINI_API_KEY');
  
  // For now, keeping as constants but should be moved to secure storage
  // TODO: Implement proper environment variable loading
  static const String geminiApiKey = 'AIzaSyDRJ80dwt7j5wL8WSJoINZRK3enlC8hVkw';
  
  // API URLs
  static const String geminiApiUrl = 
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-lite:generateContent';
  
  static const String chatbotApiUrl = 
      'https://navarasa-chatur-model-api.hf.space/chat';
  
  static const String schemesApiUrl = 
      'https://navarasa-chathur-api.hf.space/en/recommend';
  
  // Cloudinary Configuration (if needed)
  // static const String cloudinaryCloudName = String.fromEnvironment('CLOUDINARY_CLOUD_NAME');
  // static const String cloudinaryApiKey = String.fromEnvironment('CLOUDINARY_API_KEY');
  
  // Firebase configuration is handled in firebase_options.dart
  
  // Helper method to get API key with fallback
  static String getGeminiApiKey() {
    // In production, this should check environment variables first
    // const apiKey = String.fromEnvironment('GEMINI_API_KEY');
    // if (apiKey.isNotEmpty) return apiKey;
    return geminiApiKey;
  }
}

