# Cadence Android foundation

Hotwire Native loads the same Rails app, preserving Turbo/Stimulus and Devise. The top button opens a deliberately separate, small locked-screen speech experiment.

## Build

Use JDK 17 and Android SDK 35 in a cloud Android build environment. The Gradle wrapper is included:

```sh
./gradlew :app:assembleDebug -PcadenceBaseUrl=https://YOUR-RAILS-PREVIEW-HOST
```

The default URL is the Android emulator's route to the host's development server. Real phones require an HTTPS preview URL accessible to the phone. The debug APK permits cleartext for the emulator; release configuration does not.

The debug APK has been compiled successfully in the cloud workspace. The native project remains a feasibility scaffold: device execution has not been verified. See [the cloud build notes](../docs/movement-check-ins.md); an APK build alone is not evidence that locked-screen audio works.

## Test on your phone

1. Open the app and its **Locked-screen voice experiment** screen.
2. Start the experiment while the app is visible. Grant microphone and notification permission. A persistent notification identifies the running test and has a Stop action.
3. Lock the phone. After 30 seconds, it should speak and listen for one reply. Say done, later, or skip.
4. Unlock and inspect the experiment's saved log. Replies are local only in this spike. A failed recognizer or permission check stops the experiment with a visible error.

Done/skip cause another test prompt after 30 seconds; later uses one minute. These accelerated timings are experiment settings, separate from the Rails schedule. The service stops after 10 minutes and uses a bounded wake lock during the experiment. It does not record audio, start on boot, silently restart after process death, or synchronize test replies to Rails.

Starting this diagnostic while visible is required by the implementation and Android microphone lifecycle rules. This is not an accepted recurring work-session requirement for the product. If the mechanism only works with such activation, that needs a product decision before calling the requirement met.

See [the acceptance gate](../docs/android-feasibility.md) before interpreting a successful run. Test on a real device; an emulator is insufficient for the required battery/lock behavior.
