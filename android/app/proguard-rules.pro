
# Keep Flutter plugin registrant and plugin entry points used at startup.
-keep class io.flutter.plugins.GeneratedPluginRegistrant { *; }
-keep class io.flutter.plugins.** { *; }

# Keep startup plugins that are critical for app launch and persistence.
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.tekartik.sqflite.** { *; }
-keep class com.ryanheise.audio_session.** { *; }
-keep class com.ryanheise.just_audio.** { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep class dev.fluttercommunity.plus.share.** { *; }

# Respect AndroidX @Keep annotations.
-keep @androidx.annotation.Keep class * { *; }