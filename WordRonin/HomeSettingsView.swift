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

           // Color.black.opacity(0.55).ignoresSafeArea()

            VStack(spacing: 26) {
                VStack(spacing: 32) {
                    settingsRow(
                        iconAsset: "Sound Setting",
                        isOn: $soundEnabled
                    )

                    settingsRow(
                        iconAsset: "Music Setting",
                        isOn: $musicEnabled
                    )
                }
                .padding(22)
                .frame(maxWidth: 400)
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
        .onAppear {
            syncMenuMusic()
        }
        .onChange(of: musicEnabled) { _, _ in
            syncMenuMusic()
        }
    }

    @ViewBuilder
    private func settingsRow(iconAsset: String, isOn: Binding<Bool>) -> some View {
        HStack(spacing: 18) {
            Image(iconAsset)
                .resizable()
                .scaledToFit()
                .frame(width: 140)
                .shadow(radius: 4)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
                .toggleStyle(SwitchToggleStyle(tint: .green))
                .scaleEffect(1.25)
        }
        .padding(.horizontal, 10)
    }

    private func syncMenuMusic() {
        if musicEnabled {
            AudioManager.shared.playMusic(fileName: "menusong.caf", volume: 0.7)
        } else {
            AudioManager.shared.stopMusic()
        }
    }
}

#Preview {
    HomeSettingsView()
}
