# flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class * extends android.content.BroadcastReceiver { *; }

# firebase_messaging
-keep class io.flutter.plugins.firebase.messaging.** { *; }

# Firebase core
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Gson (used by Firebase serialization)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
