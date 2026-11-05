import AppKit
import Common
import SwiftUI

@MainActor
final class StatusBarManager {
    static let shared = StatusBarManager()

    private var panel: CenteredBarPanel?
    private var hostingView: NSHostingView<CenteredWorkspaceBar>?
    private var screenObserver: Any?

    private init() {
        screenObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didChangeScreenParametersNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.updateCenteredBar(viewModel: .shared) }
        }
    }

    func toggleCenteredBar(viewModel: TrayMenuModel) {
        if viewModel.experimentalUISettings.centeredBarEnabled {
            setupCenteredBar(viewModel: viewModel)
        } else {
            removeCenteredBar()
        }
    }

    func setupCenteredBar(viewModel: TrayMenuModel) {
        guard viewModel.experimentalUISettings.centeredBarEnabled else {
            removeCenteredBar()
            return
        }

        let screen = targetScreen()
        let height = screen.map(menuBarHeight(for:)) ?? 28
        let content = CenteredWorkspaceBar(viewModel: viewModel, barHeight: height)
        if hostingView == nil {
            hostingView = NSHostingView(rootView: content)
        } else {
            hostingView?.rootView = content
        }

        if panel == nil {
            let newPanel = CenteredBarPanel(
                contentRect: .zero,
                styleMask: [.borderless, .nonactivatingPanel],
                backing: .buffered,
                defer: false
            )
            newPanel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
            newPanel.isOpaque = false
            newPanel.backgroundColor = .clear
            newPanel.hasShadow = false
            newPanel.ignoresMouseEvents = false
            newPanel.isFloatingPanel = true
            newPanel.hidesOnDeactivate = false
            newPanel.becomesKeyOnlyIfNeeded = true
            newPanel.isReleasedWhenClosed = false
            newPanel.isMovable = false
            newPanel.isMovableByWindowBackground = false
            panel = newPanel
        }

        guard let panel, let hostingView else { return }
        panel.contentView = hostingView
        updateFrameAndPosition()
        panel.orderFrontRegardless()
    }

    func updateCenteredBar(viewModel: TrayMenuModel) {
        guard viewModel.experimentalUISettings.centeredBarEnabled else { return }
        guard panel != nil else {
            setupCenteredBar(viewModel: viewModel)
            return
        }
        let height = targetScreen().map(menuBarHeight(for:)) ?? 28
        hostingView?.rootView = CenteredWorkspaceBar(viewModel: viewModel, barHeight: height)
        updateFrameAndPosition()
    }

    func removeCenteredBar() {
        panel?.orderOut(nil)
        panel?.close()
        panel = nil
        hostingView = nil
    }

    func cleanup() {
        if let screenObserver {
            NotificationCenter.default.removeObserver(screenObserver)
            self.screenObserver = nil
        }
        removeCenteredBar()
    }

    private func updateFrameAndPosition() {
        guard let panel, let hostingView, let screen = targetScreen() else { return }
        let barHeight = menuBarHeight(for: screen)
        let fittingSize = hostingView.fittingSize
        let width = min(max(fittingSize.width, 1), screen.frame.width)
        let height = min(max(barHeight, 22), 40)
        let x = screen.frame.midX - width / 2
        let y = screen.visibleFrame.maxY
        panel.setFrame(NSRect(x: x, y: y, width: width, height: height), display: true)
    }

    private func targetScreen() -> NSScreen? {
        let screenIndex = globalFocus.workspace.workspaceMonitorInfo.monitorAppKitNsScreenScreensId - 1
        return NSScreen.screens.indices.contains(screenIndex) ? NSScreen.screens[screenIndex] : NSScreen.main
    }

    private func menuBarHeight(for screen: NSScreen) -> CGFloat {
        let height = screen.frame.maxY - screen.visibleFrame.maxY
        return height > 0 ? height : 28
    }
}
