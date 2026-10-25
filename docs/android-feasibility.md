# Android locked-screen voice gate

## Required evidence

On a real Android phone, install the prototype, grant permissions during initial setup, place the app in the background, and lock the screen. With no tap or unlock at the scheduled check-in:

1. Cadence initiates an audible spoken prompt.
2. Speech completion opens a short reply window.
3. The user says “done,” “later,” or “skip” hands-free.
4. Cadence acknowledges the result and persists it once.
5. Reopening the shared Rails screen shows the same state; a completed or skipped occurrence is never prompted again.

Repeat for the actual device's battery saver, Doze, speaker/earbuds, network loss, and app process death. Record the exact Android version, device, permissions, battery settings, and whether a persistent foreground notification was present. A manually force-stopped app is a separate case; do not promise it can restart itself.

## Implementation direction

Use Hotwire Native to navigate the authenticated Rails screens. Keep scheduling and completion state in Rails. Use a minimal Kotlin layer for local speech and microphone work. The first speech engines are Android TextToSpeech and SpeechRecognizer, which may rely on installed services and connectivity.

Android restricts starting foreground services from the background, especially those that need while-in-use microphone permission. A microphone foreground service generally must be initiated while the app is visible and the required permission is available. Its persistent notification and service type must be declared. Notification permission, audio focus, Do Not Disturb, OEM battery policies, and the installed speech recognizer also affect behavior.

Do not assume an alarm, push notification, WorkManager job, or a web page can bypass microphone restrictions. Exact alarms have their own permissions and distribution-policy constraints. Do not request exemptions without first establishing they are needed and appropriate.

The first native spike should test an already-authorized foreground microphone service surviving a lock, with timed TTS followed by a bounded recognition window. This tests one possible mechanism; it does not establish that Cadence can start listening from every background state. Explain any required activation before adopting it as product behavior.

## Rails boundary

The authenticated mobile bootstrap endpoint returns active commitments and due check-ins. The same authenticated response endpoint used by the web interface accepts done/later/skip, using normal same-origin session and CSRF protections. Native integrations must preserve account ownership and must not embed a shared secret in an APK.

Offline delivery, device push registration, native token handling, and synchronization need implementation and device tests before relying on the phone independently of the web interface.

## Exit criteria

- **Pass:** repeated locked/background speech and hands-free replies on the intended phone, with durable account-correct state and no duplicate prompts.
- **Conditional:** works only after a visible activation or under specific battery settings. Return that limitation for a product decision; do not silently redefine success.
- **Fail:** requires tapping or unlocking for each prompt/reply. Revisit Android interaction design before expanding features.
