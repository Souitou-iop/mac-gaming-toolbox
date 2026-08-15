import AppKit
import SwiftUI
#if SWIFT_PACKAGE
import MacGameToolboxCore
#endif

public struct SidebarLayoutView: View {
    @EnvironmentObject private var model: AppModel
    @State private var selectedNavIndex: Int = 0

    enum NavItem: Int, CaseIterable, Identifiable {
        case overview = 0
        case metalHUD = 1
        case gameBoost = 2
        case storage = 3
        case system = 4

        var id: Int { rawValue }

        var titleZh: String {
            switch self {
            case .overview: return "概览与状态"
            case .metalHUD: return "Metal HUD 调优"
            case .gameBoost: return "游戏加速与启动"
            case .storage: return "存储与磁盘"
            case .system: return "系统与设置"
            }
        }

        var titleEn: String {
            switch self {
            case .overview: return "Overview"
            case .metalHUD: return "Metal HUD Tuner"
            case .gameBoost: return "Game Boost"
            case .storage: return "Storage & Disks"
            case .system: return "System & Tools"
            }
        }

        var iconName: String {
            switch self {
            case .overview: return "square.grid.2x2.fill"
            case .metalHUD: return "gauge.with.dots.needle.67percent"
            case .gameBoost: return "bolt.fill"
            case .storage: return "externaldrive.fill"
            case .system: return "gearshape.2.fill"
            }
        }

        var accentColor: Color {
            switch self {
            case .overview: return GamingTheme.neonEmerald
            case .metalHUD: return GamingTheme.neonEmerald
            case .gameBoost: return GamingTheme.cyberCyan
            case .storage: return GamingTheme.cyberCyan
            case .system: return GamingTheme.electricViolet
            }
        }
    }

    public init() {}

    public var body: some View {
        HStack(spacing: 0) {
            // Left Sidebar
            sidebarView
                .frame(width: 220)
                .background(
                    VisualEffectBlur(material: .sidebar, blendingMode: .behindWindow)
                        .overlay(Color.black.opacity(0.2))
                )
                .overlay(
                    Rectangle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 0.5),
                    alignment: .trailing
                )

            // Right Main Content Panel
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    contentView
                        .transition(.opacity.combined(with: .scale(scale: 0.99)))
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .animation(.easeInOut(duration: 0.22), value: selectedNavIndex)
        }
    }

    // MARK: - Sidebar View

    private var sidebarView: some View {
        VStack(alignment: .leading, spacing: 8) {
            // App Branding Title in Sidebar
            HStack(spacing: 10) {
                Image(systemName: "gamecontroller.fill")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundStyle(GamingTheme.gradientCyanEmerald)
                VStack(alignment: .leading, spacing: 1) {
                    Text(tr("Mac游戏工具箱", "Mac Gaming"))
                        .font(.system(size: 14, weight: .bold))
                    Text("Toolbox v3.0")
                        .font(.system(size: 10, design: .monospaced))
                        .foregroundStyle(.secondary)
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 20)
            .padding(.bottom, 12)

            Divider().opacity(0.3).padding(.horizontal, 14)

            // Navigation Items
            VStack(spacing: 4) {
                ForEach(NavItem.allCases) { item in
                    sidebarItemRow(item)
                }
            }
            .padding(.horizontal, 10)

            Spacer()

            // Bottom Status Pill
            bottomStatusSummary
                .padding(12)
        }
    }

    private func sidebarItemRow(_ item: NavItem) -> some View {
        let isSelected = selectedNavIndex == item.rawValue
        return Button {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedNavIndex = item.rawValue
            }
        } label: {
            HStack(spacing: 12) {
                Image(systemName: item.iconName)
                    .font(.system(size: 15, weight: isSelected ? .bold : .medium))
                    .foregroundStyle(isSelected ? item.accentColor : .secondary)
                    .frame(width: 22)

                Text(tr(item.titleZh, item.titleEn))
                    .font(.system(size: 13, weight: isSelected ? .semibold : .regular))
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Spacer()

                if item == .metalHUD && model.metalHUDEnabled {
                    Circle()
                        .fill(GamingTheme.neonEmerald)
                        .frame(width: 6, height: 6)
                } else if item == .system && model.configuration.hostnameBackup != nil {
                    Circle()
                        .fill(GamingTheme.electricViolet)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 9)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(isSelected ? item.accentColor.opacity(0.15) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(isSelected ? item.accentColor.opacity(0.3) : Color.clear, lineWidth: 0.5)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }

    private var bottomStatusSummary: some View {
        HStack(spacing: 8) {
            LiveStatusBadge(model.metalHUDEnabled ? .active : .standby, title: model.metalHUDEnabled ? "HUD Active" : "Toolbox Ready")
            Spacer()
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Content View Switcher

    @ViewBuilder
    private var contentView: some View {
        switch selectedNavIndex {
        case 0:
            OverviewSectionView { targetIndex in
                withAnimation { selectedNavIndex = targetIndex }
            }
        case 1:
            MetalHUDSectionView()
        case 2:
            GameBoostSectionView()
        case 3:
            StorageSectionView()
        case 4:
            SystemSectionView()
        default:
            OverviewSectionView()
        }
    }
}

// MARK: - Native Visual Effect Blur Helper

public struct VisualEffectBlur: NSViewRepresentable {
    var material: NSVisualEffectView.Material = .hudWindow
    var blendingMode: NSVisualEffectView.BlendingMode = .withinWindow
    var state: NSVisualEffectView.State = .active

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let view = NSVisualEffectView()
        view.material = material
        view.blendingMode = blendingMode
        view.state = state
        return view
    }

    public func updateNSView(_ nsView: NSVisualEffectView, context: Context) {
        nsView.material = material
        nsView.blendingMode = blendingMode
        nsView.state = state
    }
}
