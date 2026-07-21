# flutter_local_notifications persists scheduled notifications via Gson with
# a bare TypeToken<List<...>>() {} — R8 strips the generic signature by
# default, which throws "TypeToken must be created with a type argument" at
# runtime the first time it loads/cancels a scheduled notification (caught
# live: NotificationService.cancelEventReminders crashing on every Home
# load in the release build). Keep rules per the plugin's own README.
-keep class com.dexterous.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.google.gson.reflect.TypeToken { *; }
-keepattributes Signature
-keepattributes *Annotation*
