package dev.cadence.app

import android.Manifest
import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.content.pm.PackageManager
import android.content.pm.ServiceInfo
import android.media.AudioAttributes
import android.media.AudioFocusRequest
import android.media.AudioManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.PowerManager
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import android.speech.tts.TextToSpeech
import android.speech.tts.UtteranceProgressListener
import java.text.DateFormat
import java.util.Date
import java.util.Locale

/** Deliberately bounded feasibility experiment, not a production scheduling service. */
class VoiceTestService : Service(), RecognitionListener {
    private val handler = Handler(Looper.getMainLooper())
    private var tts: TextToSpeech? = null
    private var recognizer: SpeechRecognizer? = null
    private var wakeLock: PowerManager.WakeLock? = null
    private var started = false
    private var listening = false
    private var stopped = false
    private lateinit var audioManager: AudioManager
    private lateinit var focusRequest: AudioFocusRequest
    private val listenTimeout = Runnable { fail("No reply within the listening window") }

    override fun onCreate() {
        super.onCreate()
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel("voice_test", "Voice experiment", NotificationManager.IMPORTANCE_LOW))
        audioManager = getSystemService(AudioManager::class.java)
        focusRequest = AudioFocusRequest.Builder(AudioManager.AUDIOFOCUS_GAIN_TRANSIENT)
            .setAudioAttributes(AudioAttributes.Builder().setUsage(AudioAttributes.USAGE_ASSISTANT).setContentType(AudioAttributes.CONTENT_TYPE_SPEECH).build())
            .setOnAudioFocusChangeListener { change ->
                if (change == AudioManager.AUDIOFOCUS_LOSS || change == AudioManager.AUDIOFOCUS_LOSS_TRANSIENT) {
                    handler.post { fail("Audio focus was interrupted; experiment stopped") }
                }
            }.build()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        if (intent?.action == "stop") { stopSelf(); return START_NOT_STICKY }
        if (started) return START_NOT_STICKY
        started = true
        if (checkSelfPermission(Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            fail("Microphone permission is missing")
            return START_NOT_STICKY
        }
        val open = PendingIntent.getActivity(this, 0, Intent(this, VoiceTestActivity::class.java), PendingIntent.FLAG_IMMUTABLE)
        val stop = PendingIntent.getService(this, 1, Intent(this, VoiceTestService::class.java).setAction("stop"), PendingIntent.FLAG_IMMUTABLE)
        val notification = Notification.Builder(this, "voice_test")
            .setSmallIcon(android.R.drawable.ic_btn_speak_now)
            .setContentTitle("Cadence voice experiment")
            .setContentText("Timed speech and brief microphone replies · stops after 10 minutes")
            .setContentIntent(open).setOngoing(true)
            .addAction(Notification.Action.Builder(null, "Stop", stop).build()).build()
        try {
            if (Build.VERSION.SDK_INT >= 29) startForeground(1, notification, ServiceInfo.FOREGROUND_SERVICE_TYPE_MICROPHONE)
            else startForeground(1, notification)
        } catch (error: RuntimeException) {
            fail("Android refused foreground microphone access: ${error.javaClass.simpleName}")
            return START_NOT_STICKY
        }
        // Keep only this short experiment awake. This is not the production battery strategy.
        wakeLock = getSystemService(PowerManager::class.java).newWakeLock(PowerManager.PARTIAL_WAKE_LOCK, "Cadence:voice-test").apply { acquire(10 * 60 * 1000L) }
        handler.postDelayed({ log("Ten-minute experiment ended"); stopSelf() }, 10 * 60 * 1000L)
        if (!SpeechRecognizer.isRecognitionAvailable(this)) {
            fail("No Android speech recognition service is installed")
            return START_NOT_STICKY
        }
        recognizer = SpeechRecognizer.createSpeechRecognizer(this).also { it.setRecognitionListener(this) }
        tts = TextToSpeech(this) { result ->
            handler.post {
                if (stopped) return@post
                if (result != TextToSpeech.SUCCESS) { fail("Text-to-speech could not initialize"); return@post }
                val languageResult = tts?.setLanguage(Locale.getDefault())
                if (languageResult == TextToSpeech.LANG_MISSING_DATA || languageResult == TextToSpeech.LANG_NOT_SUPPORTED) {
                    fail("The text-to-speech engine does not support this language"); return@post
                }
                tts?.setOnUtteranceProgressListener(object : UtteranceProgressListener() {
                    override fun onStart(utteranceId: String?) = Unit
                    override fun onDone(utteranceId: String?) {
                        handler.post {
                            if (utteranceId == "prompt") {
                                audioManager.abandonAudioFocusRequest(focusRequest)
                                listen()
                            } else {
                                audioManager.abandonAudioFocusRequest(focusRequest)
                                schedulePrompt(if (utteranceId == "later") 60_000L else 30_000L)
                            }
                        }
                    }
                    @Deprecated("Android callback")
                    override fun onError(utteranceId: String?) { handler.post { fail("Text-to-speech playback failed") } }
                })
                log("Started while visible. Lock the phone now; first prompt in 30 seconds.")
                schedulePrompt(30_000L)
            }
        }
        return START_NOT_STICKY
    }

    private fun schedulePrompt(delay: Long) {
        if (stopped) return
        handler.postDelayed({
            if (!stopped) {
                if (audioManager.requestAudioFocus(focusRequest) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
                    fail("Could not obtain audio focus")
                } else {
                    log("Speaking movement check-in")
                    speak("Ready for a movement break? Say done, later, or skip.", "prompt")
                }
            }
        }, delay)
    }

    private fun speak(text: String, id: String) {
        if (tts?.speak(text, TextToSpeech.QUEUE_FLUSH, null, id) != TextToSpeech.SUCCESS) fail("Could not start speech")
    }

    private fun listen() {
        if (stopped) return
        listening = true
        log("Listening for one reply")
        val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
            .putExtra(RecognizerIntent.EXTRA_LANGUAGE, Locale.getDefault().toLanguageTag())
            .putExtra(RecognizerIntent.EXTRA_MAX_RESULTS, 3)
            .putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, false)
        try {
            recognizer?.startListening(intent)
            handler.postDelayed(listenTimeout, 15_000L)
        } catch (error: RuntimeException) { fail("Could not start recognition: ${error.javaClass.simpleName}") }
    }

    override fun onResults(results: Bundle?) {
        if (!listening || stopped) return
        listening = false
        handler.removeCallbacks(listenTimeout)
        val candidates = results?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION).orEmpty()
        val answer = candidates.firstNotNullOfOrNull { phrase ->
            val words = phrase.lowercase(Locale.ROOT).split(Regex("\\W+"))
            listOf("done", "later", "skip").singleOrNull { words.contains(it) }
        }
        if (answer == null) { fail("No clear done/later/skip reply recognized"); return }
        // Store only the chosen answer, not raw speech or an audio recording.
        log("Saved reply on device: $answer")
        if (audioManager.requestAudioFocus(focusRequest) != AudioManager.AUDIOFOCUS_REQUEST_GRANTED) {
            fail("Could not obtain audio focus for acknowledgement")
            return
        }
        speak(if (answer == "later") "Okay, I will check back in one minute." else "Got it. $answer.", answer)
    }

    override fun onError(error: Int) {
        if (stopped || !listening) return
        listening = false
        handler.removeCallbacks(listenTimeout)
        fail("Recognition failed with Android error $error")
    }

    private fun log(message: String) {
        val preferences = getSharedPreferences("voice_test", MODE_PRIVATE)
        val previous = preferences.getString("log", "").orEmpty()
        val line = "${DateFormat.getTimeInstance().format(Date())} · $message"
        preferences.edit().putString("log", (line + "\n" + previous).take(6000)).apply()
    }

    private fun fail(message: String) { if (!stopped) { log(message); stopSelf() } }

    override fun onDestroy() {
        stopped = true
        listening = false
        handler.removeCallbacksAndMessages(null)
        recognizer?.destroy()
        tts?.stop()
        tts?.shutdown()
        if (::focusRequest.isInitialized) audioManager.abandonAudioFocusRequest(focusRequest)
        wakeLock?.let { if (it.isHeld) it.release() }
        stopForeground(STOP_FOREGROUND_REMOVE)
        log("Experiment stopped")
        super.onDestroy()
    }

    override fun onBind(intent: Intent?): IBinder? = null
    override fun onReadyForSpeech(params: Bundle?) = Unit
    override fun onBeginningOfSpeech() = Unit
    override fun onRmsChanged(rmsdB: Float) = Unit
    override fun onBufferReceived(buffer: ByteArray?) = Unit
    override fun onEndOfSpeech() = Unit
    override fun onPartialResults(partialResults: Bundle?) = Unit
    override fun onEvent(eventType: Int, params: Bundle?) = Unit
}
