package com.example.home_widgets

import android.appwidget.AppWidgetManager
import android.content.ComponentName
import android.content.Context
import android.content.Intent
import androidx.work.*
import es.antonborri.home_widget.HomeWidgetPlugin
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.util.Calendar
import java.util.concurrent.TimeUnit

class PrayerTimesWorker(
    appContext: Context,
    params: WorkerParameters
) : CoroutineWorker(appContext, params) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        try {
            val day = PrayerApi.fetchToday()

            // 1) save values into the same prefs Flutter uses
            val prefs = HomeWidgetPlugin.getData(applicationContext)
            prefs.edit().apply {
                putString("date", day.date)
                putString("fajr", day.fajr)
                putString("dhuhr", day.dhuhr)
                putString("asr", day.asr)
                putString("maghrib", day.maghrib)
                putString("isha", day.isha)
                putString("sunrise", day.sunrise)
                putString("hijri_date", day.hijriDate)
                putString("hijri_month", day.hijriMonth)   // 👈 ADD THIS
                val now = Calendar.getInstance()
                val hh = now.get(Calendar.HOUR_OF_DAY).toString().padStart(2, '0')
                val mm = now.get(Calendar.MINUTE).toString().padStart(2, '0')
                putString("last_updated", "$hh:$mm")
                putString("company_name", "Sadaqa Welfare Fund")
            }.apply()

            // 2) nudge the widget to redraw
            pokeWidget()

            // 3) schedule a simple one-shot later (we'll tune later)
            scheduleOneShotNearFuture()

            Result.success()
        } catch (_: Throwable) {
            Result.retry()
        }
    }

    private fun pokeWidget() {
        val mgr = AppWidgetManager.getInstance(applicationContext)
        val cn = ComponentName(applicationContext, MyHomeWidget::class.java)
        val ids = mgr.getAppWidgetIds(cn)
        val intent = Intent(applicationContext, MyHomeWidget::class.java).apply {
            action = AppWidgetManager.ACTION_APPWIDGET_UPDATE
            putExtra(AppWidgetManager.EXTRA_APPWIDGET_IDS, ids)
        }
        applicationContext.sendBroadcast(intent)
    }

    private fun scheduleOneShotNearFuture() {
        // simple: run again in ~2 hours
        val req = OneTimeWorkRequestBuilder<PrayerTimesWorker>()
            .setInitialDelay(2, TimeUnit.HOURS)
            .setConstraints(Constraints(requiredNetworkType = NetworkType.CONNECTED))
            .build()

        WorkManager.getInstance(applicationContext).enqueueUniqueWork(
            "prayer_times_next",
            ExistingWorkPolicy.REPLACE,
            req
        )
    }

    companion object {
        fun ensurePeriodic(context: Context) {
            val req = PeriodicWorkRequestBuilder<PrayerTimesWorker>(6, TimeUnit.HOURS)
                .setConstraints(Constraints(requiredNetworkType = NetworkType.CONNECTED))
                .build()

            WorkManager.getInstance(context).enqueueUniquePeriodicWork(
                "prayer_times_periodic",
                ExistingPeriodicWorkPolicy.UPDATE,
                req
            )
        }

        // helper so you can trigger immediately while testing
        fun runOnceNow(context: Context) {
            val req = OneTimeWorkRequestBuilder<PrayerTimesWorker>()
                .setConstraints(Constraints(requiredNetworkType = NetworkType.CONNECTED))
                .build()
            WorkManager.getInstance(context).enqueue(req)
        }
    }
}
