# ============================================================
# flutter_local_notifications
# ============================================================
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**

# Keep all BroadcastReceivers (used by flutter_local_notifications)
-keep class * extends android.content.BroadcastReceiver { *; }

# ============================================================
# firebase_messaging
# ============================================================
-keep class io.flutter.plugins.firebase.messaging.** { *; }
-dontwarn io.flutter.plugins.firebase.messaging.**

# ============================================================
# Firebase core
# ============================================================
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# ============================================================
# Flutter plugin method channel handlers
# ============================================================
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.plugins.**

# ============================================================
# Gson (used by Firebase serialization)
# ============================================================
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# ============================================================
# timezone (used by flutter_local_notifications)
# ============================================================
-dontwarn java.time.**
-dontwarn org.threeten.bp.**

# ============================================================
# Supabase / PostgREST
# ============================================================
-dontwarn com.supabase.**
-dontwarn io.ktor.**
-dontwarn org.slf4j.**
