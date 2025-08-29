package com.example.home_widgets

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.os.Bundle
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import es.antonborri.home_widget.HomeWidgetPlugin

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

        val rv = RemoteViews(ctx.packageName, R.layout.my_home_widget).apply {
            // header
            setTextViewText(R.id.company, prefs.getString("company_name", "Sadaqa Welfare Fund"))
            setTextViewText(R.id.updated, "Updated: ${g("last_updated")}")

            // times
            setTextViewText(R.id.fajr, g("fajr"))
            setTextViewText(R.id.dhuhr, g("dhuhr"))
            setTextViewText(R.id.asr, g("asr"))
            setTextViewText(R.id.maghrib, g("maghrib"))
            setTextViewText(R.id.isha, g("isha"))

            // extras
            setTextViewText(R.id.hijri, g("hijri_date"))
            setTextViewText(R.id.sunrise, "Sunrise: ${g("sunrise")}")
            setTextViewText(R.id.hijri_month, " ${g("hijri_month")}")
            setViewVisibility(R.id.hijri, if (style.showExtras) View.VISIBLE else View.GONE)
            setViewVisibility(R.id.sunrise, if (style.showExtras) View.VISIBLE else View.GONE)

            // apply adaptive sizes/padding/background
            setTextViewTextSize(R.id.company, TypedValue.COMPLEX_UNIT_SP, style.titleSp)
            setTextViewTextSize(R.id.updated, TypedValue.COMPLEX_UNIT_SP, style.metaSp)

            setTextViewTextSize(R.id.fajr,    TypedValue.COMPLEX_UNIT_SP, style.timeSp)
            setTextViewTextSize(R.id.dhuhr,   TypedValue.COMPLEX_UNIT_SP, style.timeSp)
            setTextViewTextSize(R.id.asr,     TypedValue.COMPLEX_UNIT_SP, style.timeSp)
            setTextViewTextSize(R.id.maghrib, TypedValue.COMPLEX_UNIT_SP, style.timeSp)
            setTextViewTextSize(R.id.isha,    TypedValue.COMPLEX_UNIT_SP, style.timeSp)
            setTextViewTextSize(R.id.hijri,   TypedValue.COMPLEX_UNIT_SP, style.metaSp)
            setTextViewTextSize(R.id.hijri_month,   TypedValue.COMPLEX_UNIT_SP, style.metaSp)
            setTextViewTextSize(R.id.sunrise, TypedValue.COMPLEX_UNIT_SP, style.metaSp)

            setViewPadding(
                R.id.root,
                style.hPad.dpToPx(ctx), style.vPad.dpToPx(ctx),
                style.hPad.dpToPx(ctx), style.vPad.dpToPx(ctx)
            )

            // if you create alternate backgrounds, you can switch them here:
            // setInt(R.id.root, "setBackgroundResource", style.bgRes)
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
