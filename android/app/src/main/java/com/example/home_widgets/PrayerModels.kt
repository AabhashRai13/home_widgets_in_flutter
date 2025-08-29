package com.example.home_widgets

import okhttp3.HttpUrl.Companion.toHttpUrl
import okhttp3.OkHttpClient
import okhttp3.Request
import org.json.JSONObject

data class PrayerDay(
    val date: String,
    val fajr: String,
    val dhuhr: String,
    val asr: String,
    val maghrib: String,
    val isha: String,
    val sunrise: String,
    val hijriDate: String,
    val hijriMonth: String,
)

object PrayerApi {
    private const val BASE_URL =
        "https://apis.sadaqawelfarefund.ngo/api/get_prayer_times_for_today"
    private val client = OkHttpClient()

    @Throws(Exception::class)
    fun fetchToday(address: String = "Sydney NSW, Australia"): PrayerDay {
        val url = BASE_URL.toHttpUrl().newBuilder()
            .addQueryParameter("address", address)
            .build()
            .toString()

        val req = Request.Builder()
            .url(url)
            .addHeader("Accept", "application/json")
            .build()

        client.newCall(req).execute().use { resp ->
            if (!resp.isSuccessful) {
                throw IllegalStateException("HTTP ${resp.code}: ${resp.body?.string()}")
            }
            val body = resp.body?.string().orEmpty()
            val j = JSONObject(body)
            fun s(k: String, def: String = "—") = j.optString(k, def)

            return PrayerDay(
                date = s("date", s("gregorian_date", "—")),
                fajr = s("fajr"),
                dhuhr = s("dhuhr", s("zuhr")),
                asr = s("asr"),
                maghrib = s("maghrib"),
                isha = s("isha"),
                sunrise = s("sunrise"),
                hijriDate = s("hijri_date"),
                hijriMonth = s("hijri_month"),
            )
        }
    }
}
