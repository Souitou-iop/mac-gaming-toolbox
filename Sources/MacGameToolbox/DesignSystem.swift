import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

// MARK: - Gaming Theme & Color Tokens

public enum GamingTheme {
    // Primary Background Gradients
    public static let bgDeepDark = Color(red: 0.043, green: 0.051, blue: 0.075)     // #0B0D13
    public static let bgSurfaceDark = Color(red: 0.075, green: 0.086, blue: 0.133)   // #131622
    public static let bgCardGlass = Color(red: 0.11, green: 0.125, blue: 0.18, opacity: 0.55)
    public static let bgCardHover = Color(red: 0.14, green: 0.16, blue: 0.23, opacity: 0.7)

    // Vibrant Gaming Accents
    public static let neonEmerald = Color(red: 0.0, green: 0.95, blue: 0.6)        // #00F298
    public static let cyberCyan = Color(red: 0.0, green: 0.79, blue: 1.0)          // #00C9FF
    public static let electricViolet = Color(red: 0.56, green: 0.18, blue: 0.95)   // #8E2DE2
    public static let deepViolet = Color(red: 0.44, green: 0.0, blue: 1.0)         // #7000FF
    public static let amberWarning = Color(red: 1.0, green: 0.67, blue: 0.0)       // #FFAA00
    public static let coralRed = Color(red: 1.0, green: 0.28, blue: 0.34)          // #FF4757

    // Gradient Presets
    public static let gradientCyanEmerald = LinearGradient(
        colors: [cyberCyan, neonEmerald],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let gradientVioletCyan = LinearGradient(
        colors: [deepViolet, cyberCyan],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let gradientVioletPink = LinearGradient(
        colors: [deepViolet, Color(red: 0.95, green: 0.2, blue: 0.6)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let cardBorderGradient = LinearGradient(
        colors: [
            Color.white.opacity(0.18),
            Color.white.opacity(0.04),
            Color.white.opacity(0.08)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    public static let activeCardBorderGradient = LinearGradient(
        colors: [
            cyberCyan.opacity(0.6),
            neonEmerald.opacity(0.3),
            Color.white.opacity(0.06)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
}

// MARK: - Live Status Glow Badge

public struct LiveStatusBadge: View {
    public enum StatusType {
        case active
        case standby
        case warning
        case idle
        case custom(Color, String)

        var color: Color {
            switch self {
            case .active: return GamingTheme.neonEmerald
            case .standby: return GamingTheme.cyberCyan
            case .warning: return GamingTheme.amberWarning
            case .idle: return Color.gray.opacity(0.6)
            case .custom(let c, _): return c
            }
        }

        var defaultTitle: String {
            switch self {
            case .active: return tr("运行中", "Active")
            case .standby: return tr("待命", "Ready")
            case .warning: return tr("注意", "Warning")
            case .idle: return tr("未启用", "Inactive")
            case .custom(_, let t): return t
            }
        }
    }

    let status: StatusType
    let customText: String?
    @State private var isPulsing = false

    public init(_ status: StatusType, title: String? = nil) {
        self.status = status
        self.customText = title
    }

    public var body: some View {
        HStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(status.color.opacity(0.35))
                    .frame(width: 10, height: 10)
                    .scaleEffect(isPulsing ? 1.5 : 1.0)
                    .opacity(isPulsing ? 0 : 0.8)
                Circle()
                    .fill(status.color)
                    .frame(width: 6, height: 6)
            }
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }

            Text(customText ?? status.defaultTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(status.color)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(status.color.opacity(0.12), in: Capsule())
        .overlay(
            Capsule()
                .strokeBorder(status.color.opacity(0.25), lineWidth: 0.5)
        )
    }
}

// MARK: - Gaming Glass Card Container

public struct GamingGlassCard<Content: View>: View {
    let isActive: Bool
    let cornerRadius: CGFloat
    let padding: CGFloat
    @ViewBuilder let content: Content
    @State private var isHovered = false

    public init(
        isActive: Bool = false,
        cornerRadius: CGFloat = 16,
        padding: CGFloat = 18,
        @ViewBuilder content: () -> Content
    ) {
        self.isActive = isActive
        self.cornerRadius = cornerRadius
        self.padding = padding
        self.content = content()
    }

    public var body: some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(isHovered ? GamingTheme.bgCardHover : GamingTheme.bgCardGlass)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .strokeBorder(
                        isActive ? GamingTheme.activeCardBorderGradient : GamingTheme.cardBorderGradient,
                        lineWidth: isActive ? 1.0 : 0.6
                    )
            )
            .shadow(
                color: isActive ? GamingTheme.cyberCyan.opacity(0.15) : Color.black.opacity(isHovered ? 0.3 : 0.15),
                radius: isHovered ? 12 : 6,
                x: 0,
                y: isHovered ? 6 : 3
            )
            .onHover { isHovered = $0 }
            .animation(.easeOut(duration: 0.2), value: isHovered)
            .animation(.easeOut(duration: 0.25), value: isActive)
    }
}

// MARK: - Metric Stat Card

public struct MetricStatCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String?
    let accentColor: Color

    public init(
        icon: String,
        title: String,
        value: String,
        subtitle: String? = nil,
        accentColor: Color = GamingTheme.cyberCyan
    ) {
        self.icon = icon
        self.title = title
        self.value = value
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(accentColor.opacity(0.14))
                    .frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(accentColor)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .monospacedDigit()
                if let sub = subtitle {
                    Text(sub)
                        .font(.system(size: 10))
                        .foregroundStyle(.tertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(GamingTheme.bgCardGlass)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.white.opacity(0.08), lineWidth: 0.5)
        )
    }
}

// MARK: - Section Header

public struct GamingSectionHeader: View {
    let icon: String
    let title: String
    let subtitle: String?
    let accentColor: Color

    public init(
        icon: String,
        title: String,
        subtitle: String? = nil,
        accentColor: Color = GamingTheme.neonEmerald
    ) {
        self.icon = icon
        self.title = title
        self.subtitle = subtitle
        self.accentColor = accentColor
    }

    public var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(accentColor)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.title3.bold())
                if let sub = subtitle {
                    Text(sub)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
        }
        .padding(.bottom, 6)
    }
}
