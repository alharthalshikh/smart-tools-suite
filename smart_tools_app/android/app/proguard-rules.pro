# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ML Kit Rules
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.internal.mlkit_** { *; }

# Image Processing
-keep class com.google.android.gms.vision.** { *; }

# General
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn com.google.android.gms.**

# Google Play Core (Fix for R8 missing classes)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
