# --- Flutter engine ---
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# --- Your app's own native code ---
-keep class com.roswaltrealty.myhome.** { *; }

# --- Firebase / Google Play Services ---
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- WebView JS bridges (webview_flutter, youtube_player_iframe, chewie) ---
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class io.flutter.plugins.webviewflutter.** { *; }

# --- PDF / Printing (pdf, printing, flutter_pdfview) ---
-keep class net.nfet.** { *; }
-keep class com.github.barteksc.** { *; }
-keep class com.davemorrissey.labs.subscaleview.** { *; }
-keep class io.grpc.** { *; }
-dontwarn com.github.barteksc.**

# --- File Picker / Open File ---
-keep class androidx.core.content.FileProvider { *; }
-keep class com.mr.flutter.plugin.filepicker.** { *; }
-keep class com.dexterous.** { *; }

# --- Local Auth (biometric) ---
-keep class androidx.biometric.** { *; }

# --- Secure storage ---
-keep class com.it_nomads.fluttersecurestorage.** { *; }

# --- Video player ---
-keep class io.flutter.plugins.videoplayer.** { *; }

# --- Keep attributes needed by reflection-based libraries ---
-keepattributes *Annotation*
-keepattributes Signature
-keepattributes InnerClasses
-keepattributes EnclosingMethod

# --- Suppress noisy known-safe warnings ---
-dontwarn org.bouncycastle.**
-dontwarn org.conscrypt.**
-dontwarn org.openjsse.**

# --- gRPC (via cloud_firestore) references an old okhttp TLS codepath it
# never actually uses at runtime on Android (Conscrypt/Play Services
# handles TLS instead) ---
-dontwarn com.squareup.okhttp.**
