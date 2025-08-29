package com.example.home_widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin
import android.app.PendingIntent
import android.content.Intent

class MyHomeWidget : AppWidgetProvider() {

    override fun onUpdate(ctx: Context, mgr: AppWidgetManager, ids: IntArray) {
        ids.forEach { render(ctx, mgr, it) }
    }

    override fun onAppWidgetOptionsChanged(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int,
        newOptions: Bundle
    ) {
        render(context, appWidgetManager, appWidgetId)
    }

    override fun onEnabled(context: Context) {
        PrayerTimesWorker.ensurePeriodic(context)
        // PrayerTimesWorker.runOnceNow(context) // <— keep while testing if you want
    }

    private fun render(ctx: Context, mgr: AppWidgetManager, id: Int) {
        val opts = mgr.getAppWidgetOptions(id)
        val minW = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH)   // dp
        val minH = opts.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_HEIGHT)  // dp

        val style = styleFor(minW, minH)

        val prefs = HomeWidgetPlugin.getData(ctx)
        fun g(k: String) = prefs.getString(k, "—")

        val (fajrTime, fajrAmPm)         = splitTimeAndAmPm(g("fajr"))
        val (dhuhrTime, dhuhrAmPm)       = splitTimeAndAmPm(g("dhuhr"))
        val (asrTime, asrAmPm)           = splitTimeAndAmPm(g("asr"))
        val (maghribTime, maghribAmPm)   = splitTimeAndAmPm(g("maghrib"))
        val (ishaTime, ishaAmPm)         = splitTimeAndAmPm(g("isha"))

        val rv = RemoteViews(ctx.packageName, R.layout.my_home_widget).apply {
            // header
            setTextViewText(R.id.company, prefs.getString("company_name", "Sadaqa Welfare Fund"))
            setTextViewText(R.id.updated, "Updated: ${g("last_updated")}")

            // times
            setTextViewText(R.id.fajr, fajrTime)
            setTextViewText(R.id.fajr_ampm, fajrAmPm)

            setTextViewText(R.id.dhuhr, dhuhrTime)
            setTextViewText(R.id.dhuhr_ampm, dhuhrAmPm)

            setTextViewText(R.id.asr, asrTime)
            setTextViewText(R.id.asr_ampm, asrAmPm)

            setTextViewText(R.id.maghrib, maghribTime)
            setTextViewText(R.id.maghrib_ampm, maghribAmPm)

            setTextViewText(R.id.isha, ishaTime)
            setTextViewText(R.id.isha_ampm, ishaAmPm)

            // extras
            setTextViewText(R.id.hijri, g("hijri_date"))
            setTextViewText(R.id.sunrise, "Sunrise: ${g("sunrise")}")
            setTextViewText(R.id.hijri_month, " ${g("hijri_month")}")
            setViewVisibility(R.id.hijri, if (style.showExtras) View.VISIBLE else View.GONE)
            setViewVisibility(R.id.sunrise, if (style.showExtras) View.VISIBLE else View.GONE)

            // apply adaptive sizes/padding/background
            setTextViewTextSize(R.id.company, TypedValue.COMPLEX_UNIT_DIP, style.titleSp)
            setTextViewTextSize(R.id.updated, TypedValue.COMPLEX_UNIT_DIP, style.metaSp)

            setTextViewTextSize(R.id.fajr,    TypedValue.COMPLEX_UNIT_DIP, style.timeSp)
            setTextViewTextSize(R.id.dhuhr,   TypedValue.COMPLEX_UNIT_DIP, style.timeSp)
            setTextViewTextSize(R.id.asr,     TypedValue.COMPLEX_UNIT_DIP, style.timeSp)
            setTextViewTextSize(R.id.maghrib, TypedValue.COMPLEX_UNIT_DIP, style.timeSp)
            setTextViewTextSize(R.id.isha,    TypedValue.COMPLEX_UNIT_DIP, style.timeSp)
            setTextViewTextSize(R.id.hijri,   TypedValue.COMPLEX_UNIT_DIP, style.metaSp)
            setTextViewTextSize(R.id.hijri_month,   TypedValue.COMPLEX_UNIT_DIP, style.metaSp)
            setTextViewTextSize(R.id.sunrise, TypedValue.COMPLEX_UNIT_DIP, style.metaSp)

            setViewPadding(
                R.id.root,
                style.hPad.dpToPx(ctx), style.vPad.dpToPx(ctx),
                style.hPad.dpToPx(ctx), style.vPad.dpToPx(ctx)
            )

            // if you create alternate backgrounds, you can switch them here:
            // setInt(R.id.root, "setBackgroundResource", style.bgRes)
        }
// Make whole widget open the app when tapped
        val launchIntent = ctx.packageManager.getLaunchIntentForPackage(ctx.packageName)
            ?.apply {
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }

        if (launchIntent != null) {
            val pi = PendingIntent.getActivity(
                ctx,
                0,
                launchIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            rv.setOnClickPendingIntent(R.id.root, pi)        // tap anywhere
            // (optional) rv.setOnClickPendingIntent(R.id.times_plate, pi)
        }
        mgr.updateAppWidget(id, rv)
    }

    private fun styleFor(widthDp: Int, heightDp: Int): AdaptiveStyle {
        // crude but effective buckets; tweak numbers to taste
        return when {
            heightDp <= 110 -> AdaptiveStyle(
                titleSp = 16f, timeSp = 13f, metaSp = 11f,
                hPad = 10, vPad = 8, showExtras = false
            )
            heightDp <= 140 -> AdaptiveStyle(
                titleSp = 18f, timeSp = 14f, metaSp = 12f,
                hPad = 12, vPad = 10, showExtras = true
            )
            else -> AdaptiveStyle(
                titleSp = 20f, timeSp = 16f, metaSp = 13f,
                hPad = 14, vPad = 12, showExtras = true
            )
        }
    }
}

private data class AdaptiveStyle(
    val titleSp: Float,
    val timeSp: Float,
    val metaSp: Float,
    val hPad: Int,   // dp
    val vPad: Int,   // dp
    val showExtras: Boolean
    // val bgRes: Int = R.drawable.widget_bg_green // if you want per-size bg
)

private fun Int.dpToPx(ctx: Context): Int =
    TypedValue.applyDimension(
        TypedValue.COMPLEX_UNIT_DIP,
        this.toFloat(),
        ctx.resources.displayMetrics
    ).toInt()

private fun splitTimeAndAmPm(raw: String?): Pair<String, String> {
    if (raw.isNullOrBlank()) return "—" to ""
    val m = Regex("""^\s*([0-9]{1,2}:[0-9]{2})\s*([AP]M)?\s*$""").find(raw)
    val time = m?.groupValues?.getOrNull(1) ?: raw.trim()
    val ampm = m?.groupValues?.getOrNull(2) ?: ""
    return time to ampm
}
