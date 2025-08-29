package com.example.home_widgets

import android.app.Application

class PrayerApp : Application() {
    override fun onCreate() {
        super.onCreate()
        PrayerTimesWorker.ensurePeriodic(this)
    }
}