package dev.cadence.app

import android.Manifest
import android.app.Activity
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView

class VoiceTestActivity : Activity() {
    private val handler = Handler(Looper.getMainLooper())
    private lateinit var status: TextView
    private val refresh = object : Runnable {
        override fun run() {
            status.text = getSharedPreferences("voice_test", MODE_PRIVATE).getString("log", "No test results yet.")
            handler.postDelayed(this, 1000)
        }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val layout = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL; setPadding(32, 48, 32, 32) }
        layout.addView(TextView(this).apply {
            text = "Voice feasibility test\n\nStart while visible, then lock the phone. A prompt should play in 30 seconds. Say done, later, or skip. This experiment runs for at most 10 minutes with a persistent microphone notification. Replies are saved on this device only; Rails sync is not connected yet."
        })
        layout.addView(Button(this).apply { text = "Start 30-second experiment"; setOnClickListener { requestAndStart() } })
        layout.addView(Button(this).apply {
            text = "Stop experiment"
            setOnClickListener { stopService(Intent(this@VoiceTestActivity, VoiceTestService::class.java)) }
        })
        status = TextView(this)
        layout.addView(status)
        setContentView(layout)
    }

    override fun onResume() { super.onResume(); handler.post(refresh) }
    override fun onPause() { handler.removeCallbacks(refresh); super.onPause() }

    private fun requestAndStart() {
        val permissions = mutableListOf(Manifest.permission.RECORD_AUDIO)
        if (Build.VERSION.SDK_INT >= 33) permissions.add(Manifest.permission.POST_NOTIFICATIONS)
        val missing = permissions.filter { checkSelfPermission(it) != PackageManager.PERMISSION_GRANTED }
        if (missing.isNotEmpty()) requestPermissions(missing.toTypedArray(), 1) else startTest()
    }

    override fun onRequestPermissionsResult(requestCode: Int, permissions: Array<out String>, grantResults: IntArray) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode == 1 && grantResults.isNotEmpty() && grantResults.all { it == PackageManager.PERMISSION_GRANTED }) {
            startTest()
        } else {
            getSharedPreferences("voice_test", MODE_PRIVATE).edit().putString("log", "Microphone and notification permissions are required for this visible experiment.").apply()
        }
    }

    private fun startTest() {
        try {
            startForegroundService(Intent(this, VoiceTestService::class.java))
        } catch (error: RuntimeException) {
            getSharedPreferences("voice_test", MODE_PRIVATE).edit().putString("log", "Android refused to start the microphone service: ${error.javaClass.simpleName}").apply()
        }
    }
}
