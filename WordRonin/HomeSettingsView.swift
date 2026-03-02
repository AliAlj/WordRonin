// HomeSettingsView.swift
// NOTE: Settings are now handled by SettingsModalOverlay inside RootModeView.
// This file is kept in case you need a standalone settings page elsewhere.
import SwiftUI

struct HomeSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettingsKeys.soundEnabled) private var soundEnabled: Bool = true
    @AppStorage(AppSettingsKeys.musicEnabled) private var musicEnabled: Bool = true

    var body: some View {
        ZStack {
            Color(red: 0.95, green: 0.88, blue: 0.65)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Image("Settings Header")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 220)
                    .padding(.top, 40)

                VStack(spacing: 28) {
                    settingsRow(iconAsset: "Sound Setting", label: "Sound", isOn: $soundEnabled)
                    settingsRow(iconAsset: "Music Setting", label: "Music", isOn: $musicEnabled)
                }
                .padding(.horizontal, 32)
                .padding(.vertical, 28)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 0.55, green: 0.42, blue: 0.22).opacity(0.55))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        )
                )
                .padding(.horizontal, 24)

                Spacer()
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

    @ViewBuilder
    private func settingsRow(iconAsset: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 18) {
            Image(iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
                .accessibilityHidden(true)
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .scaleEffect(1.15)
                .accessibilityLabel(label)
        }
    }
}

#Preview {
    HomeSettingsView()
}
