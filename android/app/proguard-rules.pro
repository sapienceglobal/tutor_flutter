# ==============================================================================
# TutorApp Flutter Native Proguard/R8 Minification Rules
# ==============================================================================
# These rules ensure reflection-heavy and platform-channel-dependent packages
# do not get stripped or broken during R8 bytecode minification and obfuscation.

# ------------------------------------------------------------------------------
# 1. Core Flutter & Android Engine Rules
# ------------------------------------------------------------------------------
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-keep class io.flutter.provider.** { *; }
-keep class org.chromium.** { *; }
-dontwarn io.flutter.view.FlutterWebviewConnection

# Keep WebKit and JavaScript Interfaces (crucial for webviews and platform channels)
-keepattributes AllowShrinking,KeepSimpleName
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# ------------------------------------------------------------------------------
# 2. Flutter InAppWebView Rules
# ------------------------------------------------------------------------------
-keep class com.pichillilorenzo.flutter_inappwebview.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview.**

# ------------------------------------------------------------------------------
# 3. Razorpay SDK Rules
# ------------------------------------------------------------------------------
-keep class com.razorpay.** { *; }
-dontwarn com.razorpay.**
-keep class com.google.android.gms.wallet.** { *; }
-dontwarn com.google.android.gms.wallet.**

# ------------------------------------------------------------------------------
# 4. Jitsi Meet SDK Rules
# ------------------------------------------------------------------------------
-keep class org.jitsi.meet.** { *; }
-keep class org.jitsi.meet.sdk.** { *; }
-dontwarn org.jitsi.meet.sdk.**
-dontwarn com.facebook.react.**
-keep class com.facebook.react.** { *; }

# ------------------------------------------------------------------------------
# 5. Google ML Kit & Face Detection Rules
# ------------------------------------------------------------------------------
-keep class com.google.mlkit.** { *; }
-dontwarn com.google.mlkit.**
-keep class com.google.android.gms.internal.mlkit_vision_face.** { *; }
-dontwarn com.google.android.gms.internal.mlkit_vision_face.**
-keep class com.google.android.gms.common.** { *; }
-dontwarn com.google.android.gms.common.**

# ------------------------------------------------------------------------------
# 6. Flutter Secure Storage Rules
# ------------------------------------------------------------------------------
-keep class cn.wildfirechat.client.** { *; }
-keep class com.it_verify.flutter_secure_storage.** { *; }
-dontwarn com.it_verify.flutter_secure_storage.**

# ------------------------------------------------------------------------------
# 7. Audio & Media Recording / Playback Rules
# ------------------------------------------------------------------------------
-keep class com.ryandens.record.** { *; }
-dontwarn com.ryandens.record.**
-keep class com.ryanheise.audioservice.** { *; }
-dontwarn com.ryanheise.audioservice.**

# ------------------------------------------------------------------------------
# 8. Play Store / Google Play Core Deferred Components (Fixes R8 compile errors)
# ------------------------------------------------------------------------------
-dontwarn com.google.android.play.core.**
-dontwarn com.google.android.play.tasks.**

