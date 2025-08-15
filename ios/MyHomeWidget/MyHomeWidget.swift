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

struct PrayerTimesProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry { .placeholder }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> SimpleEntry {
        loadFromShared() ?? .placeholder
    }

    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<SimpleEntry> {
        let entry = loadFromShared() ?? .placeholder
        // Ask WidgetKit to wake us around the next needed UI change
        let next = entry.nextRefreshDate() ?? Calendar.current.date(byAdding: .minute, value: 60, to: Date())!
        return Timeline(entries: [entry], policy: .after(next))
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

// Next refresh = next prayer today; else just after midnight
private extension SimpleEntry {
    func nextRefreshDate() -> Date? {
        let cal = Calendar.current
        let now = Date()

        func parseTimeToday(_ s: String) -> Date? {
            let fmts = ["HH:mm","H:mm","hh:mm a","h:mm a"]
            for df in fmts {
                let f = DateFormatter(); f.locale = .current; f.dateFormat = df
                if let t = f.date(from: s) {
                    var comps = cal.dateComponents([.year,.month,.day], from: now)
                    let hm = cal.dateComponents([.hour,.minute], from: t)
                    comps.hour = hm.hour; comps.minute = hm.minute
                    if let dt = cal.date(from: comps) { return dt }
                }
            }
            return nil
        }

        let candidates = [fajr, sunrise, dhuhr, asr, maghrib, isha]
            .compactMap(parseTimeToday)
            .filter { $0 > now }

        if let soonest = candidates.min() { return soonest }
        let startOfTomorrow = cal.date(byAdding: .day, value: 1, to: cal.startOfDay(for: now))!
        return cal.date(byAdding: .minute, value: 1, to: startOfTomorrow)!
    }
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
