# Keep ALL ML Kit classes (vision, text, languages)
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**

# Keep TTS plugin
-keep class com.tundralabs.fluttertts.** { *; }
-dontwarn com.tundralabs.fluttertts.**

# Keep speech_to_text plugin
-keep class com.csdcorp.speech_to_text.** { *; }
-dontwarn com.csdcorp.speech_to_text.**

# Keep Firebase Analytics
-keep class io.flutter.plugins.firebase.analytics.** { *; }
-dontwarn io.flutter.plugins.firebase.analytics.**

# Keep Google internal maps
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**
