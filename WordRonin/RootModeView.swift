// RootModeView.swift
import SwiftUI
import UIKit

struct RootModeView: View {
    @State private var selectedMode: AppMode? = nil
    @State private var showSettings: Bool = false

    var body: some View {
        Group {
            if let mode = selectedMode {
                switch mode {
                case .slice:
                    SliceModeContainerView(onExit: { selectedMode = nil })
                case .listening:
                    ListeningModeContainerView(onExit: { selectedMode = nil })
                }
            } else {
                ModeSelectView(
                    onSelect: { mode in
                        AudioManager.shared.stopMusic()
                        selectedMode = mode
                    },
                    onOpenSettings: {
                        showSettings = true
                    }
                )
                .overlay {
                    if showSettings {
                        SettingsModalOverlay(isPresented: $showSettings)
                            .transition(.opacity.combined(with: .scale(scale: 0.95)))
                            .zIndex(100)
                    }
                }
                .animation(.easeInOut(duration: 0.18), value: showSettings)
            }
        }
    }
}

// MARK: - Settings Modal Overlay (compact, centered, not full screen)

private struct SettingsModalOverlay: View {
    @Binding var isPresented: Bool
    @AppStorage(AppSettingsKeys.soundEnabled) private var soundEnabled: Bool = true
    @AppStorage(AppSettingsKeys.musicEnabled) private var musicEnabled: Bool = true

    var body: some View {
        ZStack {
            // Dim background — tapping outside dismisses
            Color.black.opacity(0.55)
                .ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 0) {
                // Header image
                Image("Settings Header")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 200)
                    .padding(.top, -20)
                    .zIndex(1)

                // Panel
                VStack(spacing: 24) {
                    settingsRow(iconAsset: "Sound Setting", label: "Sound", isOn: $soundEnabled)
                    settingsRow(iconAsset: "Music Setting", label: "Music", isOn: $musicEnabled)
                }
                .padding(.horizontal, 28)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.95, green: 0.92, blue: 0.78))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color(red: 0.55, green: 0.38, blue: 0.18), lineWidth: 3)
                        )
                )
                .frame(width: 300)
            }
            .overlay(alignment: .topTrailing) {
                // Close (X) button — top right corner of panel
                Button { isPresented = false } label: {
                    Image("Exit Button")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 42)
                }
                .buttonStyle(.plain)
                .offset(x: 16, y: -16)
                .accessibilityLabel("Close settings")
            }
        }
    }

    @ViewBuilder
    private func settingsRow(iconAsset: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 16) {
            Image(iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 80)
                .accessibilityHidden(true)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .scaleEffect(1.1)
                .accessibilityLabel(label)
                .accessibilityHint("Double tap to toggle \(label.lowercased())")
        }
        .onChange(of: musicEnabled) { _, newValue in
            if newValue {
                AudioManager.shared.playMusic(fileName: AppSettingsStore.musicEnabled ? "menusong.caf" : "", volume: 0.7)
            } else {
                AudioManager.shared.stopMusic()
            }
        }
    }
}

// MARK: - Mode Select View

private struct ModeSelectView: View {
    let onSelect: (AppMode) -> Void
    let onOpenSettings: () -> Void

    @AppStorage(AppSettingsKeys.musicEnabled) private var musicEnabled: Bool = true
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        GeometryReader { geo in
            let screenW = geo.size.width
            let screenH = geo.size.height

            ZStack(alignment: .topTrailing) {
                // Background
                Color.black.ignoresSafeArea()
                Image("gameBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: screenW, height: screenH)
                    .clipped()
                    .ignoresSafeArea()
                    .accessibilityHidden(true)

                // ── Door buttons ──────────────────────────────────────────────
                // Looking at the background image:
                //   Left door center  ≈ 26% from left, 46% from top
                //   Right door center ≈ 74% from left, 46% from top
                // These are tuned for the dojo background image aspect ratio.
                
                let btnW: CGFloat = min(screenW * 0.28, 160)
                let btnH: CGFloat = btnW * 2.0   // tall vertical buttons

                // LEFT door — Slice Mode
                Button { onSelect(.slice) } label: {
                    Image("slicemodebutton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: btnW, height: btnH)
                        .contentShape(Rectangle())
                }
                .buttonStyle(DoorButtonStyle())
                .position(
                    x: screenW * 0.265,
                    y: screenH * 0.455
                )
                .accessibilityLabel("Slice mode")
                .accessibilityHint("Starts the slicing word game")

                // RIGHT door — Listen Mode
                Button { onSelect(.listening) } label: {
                    Image("listenmodebutton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: btnW, height: btnH)
                        .contentShape(Rectangle())
                }
                .buttonStyle(DoorButtonStyle())
                .position(
                    x: screenW * 0.735,
                    y: screenH * 0.455
                )
                .accessibilityLabel("Listening mode")
                .accessibilityHint("Starts the listening word game")

                // ── Settings gear — top right ─────────────────────────────────
                Button { onOpenSettings() } label: {
                    Image("Settings Gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 36, height: 36)
                        .padding()
                        .background(Color.black.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 100))
                }
                .buttonStyle(.plain)
                .padding(.top, geo.safeAreaInsets.top + 30)
                .padding(.trailing, geo.safeAreaInsets.trailing + 20)
                .zIndex(10)
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens sound and music settings")
            }
        }
        .ignoresSafeArea()
        .onAppear {
            if musicEnabled {
                AudioManager.shared.playMusic(fileName: "menusong.caf", volume: 0.7)
            }
        }
        .onChange(of: musicEnabled) { _, newValue in
            if newValue {
                AudioManager.shared.playMusic(fileName: "menusong.caf", volume: 0.7)
            } else {
                AudioManager.shared.stopMusic()
            }
        }
    }
}

// MARK: - Door Button Style (subtle press scale)

private struct DoorButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.94 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

#Preview("Root Mode – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
