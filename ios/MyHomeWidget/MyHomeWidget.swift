import WidgetKit
import SwiftUI

extension Color {
    init(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        Scanner(string: hexSanitized).scanHexInt64(&rgb)

        let r = Double((rgb >> 16) & 0xFF) / 255.0
        let g = Double((rgb >> 8) & 0xFF) / 255.0
        let b = Double(rgb & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
private let APP_GROUP_ID = "group.homeTestScreenApp"
private let API_URL = URL(string: "https://apis.sadaqawelfarefund.ngo/api/get_prayer_times_for_today")!

struct PrayerTimesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { .placeholder }

      func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
          await fetchFromAPI() ?? loadFromShared() ?? .placeholder
      }

      func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
          // Try API, fall back to shared
          let entry = await fetchFromAPI() ?? loadFromShared() ?? .placeholder
          let next = entry.nextRefreshDate() ?? Calendar.current.date(byAdding: .minute, value: 60, to: Date())!
          return Timeline(entries: [entry], policy: .after(next))
      }

      // MARK: - Data sources

      private func fetchFromAPI() async -> SimpleEntry? {
          do {
              let (data, _) = try await URLSession.shared.data(from: API_URL)
              // Adjust decoding to your real JSON shape
              if let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                  func s(_ k: String, _ def: String = "—") -> String { (json[k] as? String) ?? def }
                  let entry = SimpleEntry(
                      date: Date(),
                      fajr: s("fajr"),
                      dhuhr: s("dhuhr"),
                      asr: s("asr"),
                      maghrib: s("maghrib"),
                      isha: s("isha"),
                      sunrise: s("sunrise"),
                      hijriDate: s("hijri_date"),
                      companyName: s("company_name", "Sadaqa Welfare Fund"),
                      lastUpdated: ISO8601DateFormatter().string(from: Date())
                  )
                  // Optional: persist for snapshot/offline
                  saveToShared(entry)
                  return entry
              }
          } catch {
              // Silent fallback
          }
          return nil
      }

      private func loadFromShared() -> SimpleEntry? {
          guard let ud = UserDefaults(suiteName: APP_GROUP_ID) else { return nil }
          func val(_ key: String, _ def: String = "—") -> String { ud.string(forKey: key) ?? def }
          return SimpleEntry(
              date: Date(),
              fajr: val("fajr"),
              dhuhr: val("dhuhr"),
              asr: val("asr"),
              maghrib: val("maghrib"),
              isha: val("isha"),
              sunrise: val("sunrise"),
              hijriDate: val("hijri_date"),
              companyName: val("company_name", "Sadaqa Welfare Fund"),
              lastUpdated: val("last_updated", "Never")
          )
      }

      private func saveToShared(_ e: SimpleEntry) {
          guard let ud = UserDefaults(suiteName: APP_GROUP_ID) else { return }
          ud.set(e.fajr, forKey: "fajr")
          ud.set(e.dhuhr, forKey: "dhuhr")
          ud.set(e.asr, forKey: "asr")
          ud.set(e.maghrib, forKey: "maghrib")
          ud.set(e.isha, forKey: "isha")
          ud.set(e.sunrise, forKey: "sunrise")
          ud.set(e.hijriDate, forKey: "hijri_date")
          ud.set(e.companyName, forKey: "company_name")
          ud.set(e.lastUpdated, forKey: "last_updated")
      }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let fajr: String
    let dhuhr: String
    let asr: String
    let maghrib: String
    let isha: String
    let sunrise: String
    let hijriDate: String
    let companyName: String
    let lastUpdated: String
    // Pick the next time the UI will need to change (e.g., next prayer time)
    func nextRefreshDate() -> Date? {
        let times = [fajr, sunrise, dhuhr, asr, maghrib, isha]
        let now = Date()
        let tz = TimeZone.current
        let cal = Calendar.current

        // Accept times like "05:12" and build a Date for today/tomorrow
        func dateFor(timeStr: String) -> Date? {
            let comps = timeStr.split(separator: ":")
            guard comps.count >= 2,
                  let h = Int(comps[0]), let m = Int(comps[1]) else { return nil }
            var dc = cal.dateComponents(in: tz, from: now)
            dc.hour = h; dc.minute = m; dc.second = 0
            // if already passed today, move to tomorrow
            var d = cal.date(from: DateComponents(year: dc.year, month: dc.month, day: dc.day, hour: h, minute: m, second: 0))
            if let dUnwrapped = d, dUnwrapped <= now {
                d = cal.date(byAdding: .day, value: 1, to: dUnwrapped)
            }
            return d
        }

        // Find the soonest upcoming time and refresh shortly after it
        let upcoming = times.compactMap(dateFor(timeStr:)).sorted().first
        return upcoming.map { cal.date(byAdding: .minute, value: 2, to: $0) ?? $0 }
    }

    static let placeholder = SimpleEntry(
        date: Date(),
        fajr: "07:00",
        dhuhr: "12:53",
        asr: "15:34",
        maghrib: "18:08",
        isha: "19:42",
        sunrise: "07:37",
        hijriDate: "19 Sha’bān 1446",
        companyName: "Sadaqa Welfare Fund",
        lastUpdated: "Never"
    )
}


struct MyHomeWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack{
                
                Image("sadaqa_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 30, height: 30)
                // Title
                Text(entry.companyName)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(.primary)
                    .lineLimit(2)
            }
            // Top row
            HStack {
                Label(entry.sunrise, systemImage: "sunrise")
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)

                Spacer(minLength: 6)

                Text(entry.hijriDate)
                    .font(.caption2)
                    .foregroundStyle(.primary.opacity(0.9))
                    .lineLimit(1)
            }

            // Debug/meta
            Text("Updated: \(entry.lastUpdated)")
                .font(.caption2)
                .foregroundStyle(.primary.opacity(0.7))
                .lineLimit(1)

                    Divider().opacity(0.35)
            TimesPlate{
                HStack(spacing: 8) {
                    PrayerTimeView(name: "Fajr",    time: entry.fajr,    color: .primary)
                    PrayerTimeView(name: "Dhuhr",   time: entry.dhuhr,   color: .primary)
                    PrayerTimeView(name: "Asr",     time: entry.asr,     color: .primary)
                    PrayerTimeView(name: "Maghrib", time: entry.maghrib, color: .primary)
                    PrayerTimeView(name: "Isha",    time: entry.isha,    color: .primary)
            
            }
            }
       
            
        }
        .padding(10)                 // spacing inside the widget
        .foregroundStyle(.primary)   // dynamic legibility
    }
}
struct MyHomeWidget: Widget {
    let kind: String = "MyHomeWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: ConfigurationAppIntent.self,
            provider: PrayerTimesProvider()
        ) { entry in
            MyHomeWidgetEntryView(entry: entry)
                .containerBackground(for: .widget) {
                    // Frosted glass base
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)            // try .thinMaterial / .regularMaterial
                        // Tint the glass with your gradient, lightly
                        .overlay(
                            LinearGradient(
                                colors: [
                                    Color(hex: "#C8E6C9"),
                                    Color(hex: "#4CAF50")
                                ],
                                startPoint: .top, endPoint: .bottom
                            )
                            .opacity(0.35)                   // strength of the tint
                        )
                        // Optional “glass edge” and soft shadow for depth
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .stroke(.white.opacity(0.5), lineWidth: 1)
                        )
                        .shadow(color: .black.opacity(0.08), radius: 10, x: 0, y: 2)
                }
        }
        .supportedFamilies([.systemMedium])
        .contentMarginsDisabled()
    }
}
#Preview(as: .systemMedium) {
    MyHomeWidget()
} timeline: {
    SimpleEntry.placeholder
}
