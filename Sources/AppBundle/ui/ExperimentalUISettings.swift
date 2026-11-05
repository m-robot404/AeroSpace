import SwiftUI

struct ExperimentalUISettings {
    var centeredBarEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: ExperimentalUISettingsItems.centeredBarEnabled.rawValue) }
        set { UserDefaults.standard.set(newValue, forKey: ExperimentalUISettingsItems.centeredBarEnabled.rawValue) }
    }

    var centeredBarShowNumbers: Bool {
        get {
            UserDefaults.standard.object(forKey: ExperimentalUISettingsItems.centeredBarShowNumbers.rawValue) as? Bool ?? true
        }
        set { UserDefaults.standard.set(newValue, forKey: ExperimentalUISettingsItems.centeredBarShowNumbers.rawValue) }
    }
    var displayStyle: MenuBarStyle {
        get {
            switch UserDefaults.standard.string(forKey: ExperimentalUISettingsItems.displayStyle.rawValue) {
                case let value?: MenuBarStyle(rawValue: value) ?? .monospacedText
                case nil: .monospacedText
            }
        }
        set {
            UserDefaults.standard.setValue(newValue.rawValue, forKey: ExperimentalUISettingsItems.displayStyle.rawValue)
            UserDefaults.standard.synchronize()
        }
    }
}

enum MenuBarStyle: String, CaseIterable, Identifiable, Equatable, Hashable {
    case monospacedText
    case systemText
    case squares
    case i3
    case i3Ordered
    var id: String { rawValue }
    var title: String {
        switch self {
            case .monospacedText: "Monospaced font"
            case .systemText: "System font"
            case .squares: "Square images"
            case .i3: "i3 style grouped"
            case .i3Ordered: "i3 style ordered"
        }
    }
}

enum ExperimentalUISettingsItems: String {
    case displayStyle
    case centeredBarEnabled
    case centeredBarShowNumbers
}

@MainActor
func getExperimentalUISettingsMenu(viewModel: TrayMenuModel) -> some View {
    let color = AppearanceTheme.current == .dark ? Color.white : Color.black
    return Menu {
        Text("Centered Workspace Bar:")
        Button {
            viewModel.experimentalUISettings.centeredBarEnabled.toggle()
            StatusBarManager.shared.toggleCenteredBar(viewModel: viewModel)
        } label: {
            Toggle(isOn: .constant(viewModel.experimentalUISettings.centeredBarEnabled)) {
                Text("Enable centered workspace bar")
            }
        }
        Button {
            viewModel.experimentalUISettings.centeredBarShowNumbers.toggle()
            if viewModel.experimentalUISettings.centeredBarEnabled {
                StatusBarManager.shared.updateCenteredBar(viewModel: viewModel)
            }
        } label: {
            Toggle(isOn: .constant(viewModel.experimentalUISettings.centeredBarShowNumbers)) {
                Text("Show workspace names")
            }
        }
        .disabled(!viewModel.experimentalUISettings.centeredBarEnabled)
        Divider()
        Text("Menu bar style (macOS 14 or later):")
        ForEach(MenuBarStyle.allCases, id: \.id) { style in
            MenuBarStyleButton(style: style, color: color).environmentObject(viewModel)
        }
    } label: {
        Text("Experimental UI Settings (No stability guarantees)")
    }
}

@MainActor
struct MenuBarStyleButton: View {
    @EnvironmentObject var viewModel: TrayMenuModel
    let style: MenuBarStyle
    let color: Color

    var body: some View {
        Button {
            viewModel.experimentalUISettings.displayStyle = style
        } label: {
            Toggle(isOn: .constant(viewModel.experimentalUISettings.displayStyle == style)) {
                MenuBarLabel(style: style, color: color)
                    .environmentObject(viewModel)
                Text(" -  " + style.title)
            }
        }
    }
}
