# App-specific R8 rules. Flutter, Firebase and the geolocator/flutter_local_notifications
# plugins ship their own consumer rules, so only additions go here.

# flutter_local_notifications serialises scheduled notifications with Gson.
-keep class com.dexterous.** { *; }
-keepattributes *Annotation*, Signature

# Play Core is referenced by the Flutter embedding's deferred-components support,
# which this app does not use.
-dontwarn com.google.android.play.core.**
