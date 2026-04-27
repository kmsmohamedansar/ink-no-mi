import SwiftUI

struct FlowDeskAppearanceSettingsView: View {
    @Environment(PurchaseManager.self) private var purchaseManager
    @EnvironmentObject private var appearanceManager: AppearanceManager
    @State private var pendingTheme: VisualTheme = AppAppearanceSettings.default.visualTheme

    private var featureGate: FeatureGate {
        FeatureGate(purchaseManager: purchaseManager)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                themeSection
                accentSection
                fontSection
                canvasSection
                interfaceSection
                motionSection
                resetSection
            }
            .padding(16)
        }
        .frame(minWidth: 560, minHeight: 620)
        .onAppear {
            pendingTheme = appearanceManager.settings.visualTheme
        }
    }

    private var themeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Theme").font(.headline)
            Picker("Appearance", selection: $appearanceManager.settings.appearanceMode) {
                ForEach(AppearanceMode.allCases) { mode in
                    Text(mode.rawValue.capitalized).tag(mode)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Appearance mode")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                ForEach(VisualTheme.allCases) { theme in
                    Button {
                        if theme.isProTheme, !featureGate.requirePro(.appearanceCustomization, source: "appearance_theme_\(theme.rawValue)") {
                            return
                        }
                        pendingTheme = theme
                    } label: {
                        ThemeCard(theme: theme, selected: pendingTheme == theme, isLocked: theme.isProTheme && !purchaseManager.isProUser)
                    }
                    .accessibilityLabel("Theme \(theme.displayName)")
                }
            }
            HStack {
                Text("Selected: \(pendingTheme.displayName)")
                    .font(.caption)
                    .foregroundStyle(.primary.opacity(0.85))
                Spacer()
                Button("Apply preset") {
                    if pendingTheme.isProTheme, !featureGate.requirePro(.appearanceCustomization, source: "appearance_apply_preset") {
                        return
                    }
                    appearanceManager.settings.visualTheme = pendingTheme
                }
                .buttonStyle(FlowDeskHomeCardButtonStyle())
                .frame(minHeight: 40)
                .accessibilityLabel("Apply selected theme preset")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(.white)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    Capsule(style: .continuous)
                        .fill(DS.Color.accent)
                )
            }
        }
    }

    private var accentSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Accent color").font(.headline)
            HStack(spacing: 10) {
                ForEach(AccentPalette.allCases) { palette in
                    let token = AccentTokens.palette(palette)
                    Button {
                        appearanceManager.settings.accentPalette = palette
                    } label: {
                        Circle()
                            .fill(LinearGradient(colors: [token.gradientStart, token.gradientEnd], startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 24, height: 24)
                            .overlay(
                                Circle().stroke(appearanceManager.settings.accentPalette == palette ? Color.primary : .clear, lineWidth: 2)
                            )
                    }
                    .frame(width: 40, height: 40)
                    .accessibilityLabel("Accent color \(palette.rawValue)")
                }
            }
            Toggle("Use accent for selection emphasis", isOn: $appearanceManager.settings.useAccentInCanvasSelection)
                .accessibilityLabel("Use accent for selection emphasis")
                .toggleStyle(.switch)
                .animation(FlowDeskMotion.standardEaseOut, value: appearanceManager.settings.useAccentInCanvasSelection)
        }
    }

    private var fontSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Font").font(.headline)
            Picker("Font style", selection: $appearanceManager.settings.fontStyle) {
                ForEach(AppFontStyle.allCases) { style in
                    Text(style.rawValue.capitalized).tag(style)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Font style")
        }
    }

    private var canvasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Canvas").font(.headline)
            Picker("Background", selection: $appearanceManager.settings.canvasBackgroundStyle) {
                ForEach(CanvasBackgroundStyle.allCases) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .accessibilityLabel("Canvas background style")
            Picker("Grid style", selection: $appearanceManager.settings.canvasGridStyle) {
                ForEach(CanvasGridStyle.allCases) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .accessibilityLabel("Canvas grid style")
            Toggle("Texture", isOn: $appearanceManager.settings.canvasTextureEnabled)
                .accessibilityLabel("Canvas texture")
                .toggleStyle(.switch)
                .animation(FlowDeskMotion.standardEaseOut, value: appearanceManager.settings.canvasTextureEnabled)
            Toggle("Color glow", isOn: $appearanceManager.settings.canvasColorGlowEnabled)
                .accessibilityLabel("Canvas color glow")
                .toggleStyle(.switch)
                .animation(FlowDeskMotion.standardEaseOut, value: appearanceManager.settings.canvasColorGlowEnabled)
        }
    }

    private var interfaceSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Interface").font(.headline)
            Picker("Density", selection: $appearanceManager.settings.interfaceDensity) {
                ForEach(InterfaceDensity.allCases) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Interface density")
            Picker("Corner style", selection: $appearanceManager.settings.cornerStyle) {
                ForEach(CornerStyle.allCases) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Corner style")
        }
    }

    private var motionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Motion").font(.headline)
            Picker("Motion level", selection: $appearanceManager.settings.motionLevel) {
                ForEach(MotionLevel.allCases) { value in
                    Text(value.rawValue.capitalized).tag(value)
                }
            }
            .pickerStyle(.segmented)
            .accessibilityLabel("Motion level")
        }
    }

    private var resetSection: some View {
        HStack {
            Button("Reset to defaults", role: .destructive) {
                appearanceManager.resetToDefaults()
            }
            .frame(minHeight: 40)
            .accessibilityLabel("Reset appearance to defaults")
            Spacer()
        }
    }

}

private struct ThemeCard: View {
    let theme: VisualTheme
    let selected: Bool
    let isLocked: Bool

    var body: some View {
        let definition = DynamicTheme.definition(for: theme)
        VStack(alignment: .leading, spacing: 8) {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(LinearGradient(colors: strip, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(height: 56)
                .overlay {
                    HStack(spacing: 8) {
                        RoundedRectangle(cornerRadius: 4, style: .continuous)
                            .fill(definition.panelBackground)
                            .frame(width: 18)
                            .overlay(alignment: .trailing) {
                                Rectangle().fill(definition.border.opacity(0.8)).frame(width: 1)
                            }
                        VStack(spacing: 5) {
                            RoundedRectangle(cornerRadius: 4, style: .continuous)
                                .fill(definition.cardBackground)
                                .frame(height: 16)
                            Rectangle()
                                .fill(definition.gridColor.opacity(0.35))
                                .frame(height: 1)
                            Rectangle()
                                .fill(definition.gridColor.opacity(0.35))
                                .frame(height: 1)
                            HStack {
                                Spacer()
                                Circle().fill(definition.accent).frame(width: 9, height: 9)
                            }
                        }
                    }
                    .padding(8)
                }
            Text(theme.displayName)
                .font(.subheadline.weight(.medium))
        }
        .padding(10)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(Color.primary.opacity(0.04)))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(selected ? Color.primary.opacity(0.32) : Color.primary.opacity(0.08), lineWidth: selected ? 1.6 : 1)
        )
        .overlay(alignment: .topTrailing) {
            if selected {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(Color.primary.opacity(0.78))
                    .padding(6)
            } else if isLocked {
                Text("PRO")
                    .font(.caption2.weight(.bold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Capsule(style: .continuous).fill(Color.accentColor.opacity(0.16)))
                    .foregroundStyle(Color.primary.opacity(0.78))
                    .padding(6)
            }
        }
        .buttonStyle(.plain)
    }

    private var strip: [Color] {
        let definition = DynamicTheme.definition(for: theme)
        return [definition.panelBackground, definition.canvasBackground]
    }
}
