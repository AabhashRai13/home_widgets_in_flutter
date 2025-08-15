import SwiftUI
import WidgetKit

struct PrayerTimeView: View {
    @Environment(\.widgetFamily) private var family
    
    let name: String
    let time: String
    let color: Color  // pass .primary for best legibility
    
    // Fonts per family (unchanged)
    private var nameFont: Font {
        switch family {
        case .systemSmall:          return .caption2.weight(.bold)
        case .systemMedium:         return .caption.weight(.bold)
        case .systemLarge:          return .footnote.weight(.bold)
        case .systemExtraLarge:     return .footnote.weight(.bold)
        case .accessoryCircular:    return .caption2.weight(.bold)
        case .accessoryRectangular: return .caption2.weight(.bold)
        case .accessoryInline:      return .caption2
        @unknown default:           return .caption.weight(.bold)
        }
    }
    
    private var timeFont: Font {
        switch family {
        case .systemSmall:          return .system(size: 12, weight: .bold)
        case .systemMedium:         return .system(size: 16, weight: .bold)
        case .systemLarge:          return .system(size: 18, weight: .bold)
        case .systemExtraLarge:     return .system(size: 20, weight: .bold)
        case .accessoryCircular:    return .system(size: 12, weight: .bold)
        case .accessoryRectangular: return .system(size: 12, weight: .bold)
        case .accessoryInline:      return .caption2
        @unknown default:           return .system(size: 16, weight: .bold)
        }
    }
    
    var body: some View {
        VStack(spacing: 2) {
            Text(name)
                .font(nameFont)
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .allowsTightening(true)
            
            Text(time)
                .font(timeFont)
                .monospacedDigit()
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .allowsTightening(true)
        }
        // keep equal spacing across the row
        .frame(maxWidth: .infinity)
    }
}
