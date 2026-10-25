package dev.cadence.app

import android.content.Intent
import android.os.Bundle
import android.widget.Button
import dev.hotwire.navigation.activities.HotwireActivity
import dev.hotwire.navigation.navigator.NavigatorConfiguration

class MainActivity : HotwireActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_main)
        findViewById<Button>(R.id.voice_test).setOnClickListener {
            startActivity(Intent(this, VoiceTestActivity::class.java))
        }
    }

    override fun navigatorConfigurations() = listOf(
        NavigatorConfiguration(name = "main", startLocation = BuildConfig.BASE_URL, navigatorHostId = R.id.main_nav_host)
    )
}
