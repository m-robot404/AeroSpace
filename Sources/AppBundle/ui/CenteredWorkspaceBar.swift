import AppKit
import Common
import SwiftUI

@MainActor
struct CenteredWorkspaceBar: View {
    @ObservedObject var viewModel: TrayMenuModel
    let barHeight: CGFloat

    private var itemHeight: CGFloat { max(18, barHeight - 4) }
    private var iconSize: CGFloat { max(12, itemHeight - 7) }

    var body: some View {
        HStack(spacing: 7) {
            ForEach(viewModel.centeredBarWorkspaces, id: \.workspace.name) { item in
                WorkspaceBarItem(
                    item: item,
                    showName: viewModel.experimentalUISettings.centeredBarShowNumbers,
                    itemHeight: itemHeight,
                    iconSize: iconSize
                )
            }
        }
        .padding(.horizontal, 7)
        .frame(height: itemHeight + 4)
        .fixedSize()
    }
}

@MainActor
private struct WorkspaceBarItem: View {
    let item: CenteredBarWorkspaceItem
    let showName: Bool
    let itemHeight: CGFloat
    let iconSize: CGFloat

    @State private var isHovered = false

    private var accent: Color { Color.accentColor }

    var body: some View {
        HStack(spacing: 4) {
            if showName {
                Text(item.workspace.name)
                    .font(.system(size: 11, weight: .semibold, design: .monospaced))
                    .foregroundStyle(item.isFocused ? accent : .secondary)
                    .lineLimit(1)
            }
            ForEach(item.windows, id: \.windowId) { window in
                WindowBarIcon(
                    window: window,
                    workspace: item.workspace,
                    iconSize: iconSize,
                    isFocused: window.isFocused,
                    isInFocusedWorkspace: item.isFocused
                )
            }
        }
        .padding(.horizontal, 7)
        .frame(height: itemHeight)
        .background {
            RoundedRectangle(cornerRadius: 6)
                .fill(item.isFocused ? Color.accentColor.opacity(0.16) : (isHovered ? Color.primary.opacity(0.07) : .clear))
        }
        .overlay {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(item.isFocused ? accent.opacity(0.9) : .clear, lineWidth: 1)
        }
        .contentShape(RoundedRectangle(cornerRadius: 6))
        .onHover { isHovered = $0 }
        .onTapGesture { focusWorkspace(item.workspace) }
        .help("Workspace \(item.workspace.name)")
    }

    private func focusWorkspace(_ workspace: Workspace) {
        guard let token: RunSessionGuard = .isServerEnabled else { return }
        Task.startUnstructured {
            try await runLightSession(.menuBarButton, token) {
                _ = workspace.focusWorkspace()
            }
        }
    }
}

@MainActor
private struct WindowBarIcon: View {
    let window: CenteredBarWindowItem
    let workspace: Workspace
    let iconSize: CGFloat
    let isFocused: Bool
    let isInFocusedWorkspace: Bool

    var body: some View {
        Group {
            if let icon = window.icon {
                Image(nsImage: icon).resizable().aspectRatio(contentMode: .fit)
            } else {
                Image(systemName: "app.dashed").resizable().aspectRatio(contentMode: .fit)
            }
        }
        .frame(width: iconSize, height: iconSize)
        .opacity(isFocused ? 1 : (isInFocusedWorkspace ? 0.62 : 0.82))
        .contentShape(Rectangle())
        .onTapGesture { focusWindow() }
        .help(window.appName ?? "Unknown application")
    }

    private func focusWindow() {
        guard let token: RunSessionGuard = .isServerEnabled else { return }
        Task.startUnstructured {
            try await runLightSession(.menuBarButton, token) {
                _ = workspace.focusWorkspace()
                if let macWindow = workspace.allLeafWindowsRecursive.first(where: { $0.windowId == window.windowId }) {
                    macWindow.nativeFocus()
                }
            }
        }
    }
}

struct CenteredBarWorkspaceItem {
    let workspace: Workspace
    let isFocused: Bool
    let windows: [CenteredBarWindowItem]
}

struct CenteredBarWindowItem {
    let windowId: OpaqueWindowId
    let appName: String?
    let icon: NSImage?
    let isFocused: Bool
}

@MainActor
extension TrayMenuModel {
    var centeredBarWorkspaces: [CenteredBarWorkspaceItem] {
        let currentFocus = globalFocus
        return Workspace.all.sorted().map { workspace in
            let windows = workspace.allLeafWindowsRecursive.map { window in
                let icon = (window as? MacWindow)?.macApp.nsApp.icon
                return CenteredBarWindowItem(
                    windowId: window.windowId,
                    appName: window.app.name,
                    icon: icon,
                    isFocused: window == currentFocus.windowOrNil
                )
            }
            return CenteredBarWorkspaceItem(
                workspace: workspace,
                isFocused: workspace == currentFocus.workspace,
                windows: windows
            )
        }
    }
}
