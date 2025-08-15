import 'dart:convert';

class PrayerDay {
  final String date; // e.g. 2025-08-12
  final String fajr;
  final String dhuhr;
  final String asr;
  final String maghrib;
  final String isha;
  final String sunrise;
  final String hijriDate;
  final String hijriMonth;

  const PrayerDay({
    required this.date,
    required this.fajr,
    required this.dhuhr,
    required this.asr,
    required this.maghrib,
    required this.isha,
    required this.sunrise,
    required this.hijriDate,
    required this.hijriMonth,
  });

  factory PrayerDay.fromJson(Map<String, dynamic> j) {
    String pick(dynamic v) => (v ?? '').toString();
    return PrayerDay(
      date: pick(j['date'] ?? j['gregorian_date'] ?? j['day'] ?? ''),
      fajr: pick(j['fajr'] ?? j['Fajr']),
      dhuhr: pick(j['dhuhr'] ?? j['Dhuhr'] ?? j['zuhr']),
      asr: pick(j['asr'] ?? j['Asr']),
      maghrib: pick(j['maghrib'] ?? j['Maghrib']),
      isha: pick(j['isha'] ?? j['Isha']),
      sunrise: pick(j['sunrise'] ?? j['Sunrise']),
      hijriDate: pick(j['hijri_date'] ?? j['hijriDate'] ?? j['hijri_date']),
      hijriMonth: pick(j['hijri_month'] ?? j['hijriMonth'] ?? j['hijri_month']),
    );
  }

  Map<String, String> asStrings() => {
        'date': date,
        'fajr': fajr,
        'dhuhr': dhuhr,
        'asr': asr,
        'maghrib': maghrib,
        'isha': isha,
        'sunrise': sunrise,
        'hijri_date': '$hijriDate $hijriMonth',
      };

  @override
  String toString() => jsonEncode(asStrings());
}
