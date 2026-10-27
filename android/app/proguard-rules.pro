# Extra R8/ProGuard rules for release builds (Flutter's own rules are added by the Flutter Gradle plugin).
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-dontwarn com.google.android.play.core.**
-dontwarn javax.annotation.**
