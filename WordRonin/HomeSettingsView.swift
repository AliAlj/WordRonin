// HomeSettingsView.swift
import SwiftUI

struct HomeSettingsView: View {
    @AppStorage(AppSettingsKeys.soundEnabled) private var soundEnabled: Bool = true
    @AppStorage(AppSettingsKeys.musicEnabled) private var musicEnabled: Bool = true

    var body: some View {
        ZStack {
            Image("settingspage")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()
                .frame(maxWidth: 400)

            VStack(spacing: 26) {
                VStack(spacing: 32) {
                    settingsRow(
                        iconAsset: "Sound Setting",
                        label: "Sound effects",
                        isOn: $soundEnabled
                    )

                    settingsRow(
                        iconAsset: "Music Setting",
                        label: "Music",
                        isOn: $musicEnabled
                    )
                }
                .padding(22)
                .frame(maxWidth: 400, maxHeight: 400)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color.black.opacity(0.40))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.18), lineWidth: 2)
                        )
                )
                Spacer()
            }
            .padding(.top, 180)
            .padding(.horizontal, 24)
        }
        .onAppear { syncMenuMusic() }
        .onChange(of: musicEnabled) { _, _ in syncMenuMusic() }
    }

    @ViewBuilder
    private func settingsRow(iconAsset: String, label: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 18) {
            Image(iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .shadow(radius: 4)
                .accessibilityHidden(true)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .scaleEffect(1.25)
                .accessibilityLabel(label)
                .accessibilityHint("Double tap to turn \(label.lowercased()) on or off")
        }
        .padding(.horizontal, 10)
        .accessibilityElement(children: .combine)
    }

    private func syncMenuMusic() {
        if musicEnabled {
            AudioManager.shared.playMusic(fileName: "menusong.caf", volume: 0.7)
        } else {
            AudioManager.shared.stopMusic()
        }
    }
}

#Preview("Root Mode – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
