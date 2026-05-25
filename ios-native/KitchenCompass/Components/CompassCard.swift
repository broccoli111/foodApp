import SwiftUI

struct CompassCard<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            content
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
        .shadow(color: Color.black.opacity(0.05), radius: 12, x: 0, y: 6)
    }
}

struct CompassBadge: View {
    let text: String
    var tone: Color = .sage
    var foreground: Color = .basil

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(foreground)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(tone.opacity(0.18))
            .clipShape(Capsule())
    }
}

struct MetricCard: View {
    let value: String
    let label: String
    var helper: String?

    var body: some View {
        CompassCard {
            Text(value)
                .font(.title2.weight(.bold))
                .foregroundStyle(Color.ink)
            Text(label)
                .font(.caption)
                .foregroundStyle(Color.muted)
            if let helper {
                Text(helper)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(Color.basil)
            }
        }
    }
}

struct SectionTitle: View {
    let title: String
    var subtitle: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.title3.weight(.bold))
                .foregroundStyle(Color.ink)
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(Color.muted)
            }
        }
        .padding(.top, 12)
    }
}
