//RootModeView
import SwiftUI

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
                .sheet(isPresented: $showSettings) {
                    HomeSettingsView()
                }
            }
        }
    }
}

private struct ModeSelectView: View {
    let onSelect: (AppMode) -> Void
    let onOpenSettings: () -> Void

    @AppStorage(AppSettingsKeys.musicEnabled) private var musicEnabled: Bool = true

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("gameBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                // Home Settings gear (top-right)
                Button {
                    onOpenSettings()
                } label: {
                    Image("Settings Gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 64, height: 64)
                        .padding(10)
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .position(x: geo.size.width - 70, y: 70)
                .zIndex(10)

                // Mode buttons
                ModeIconButton(imageName: "slicemodebutton", width: 320) {
                    onSelect(.slice)
                }
                .position(x: geo.size.width * 0.28, y: geo.size.height * 0.50)

                ModeIconButton(imageName: "listenmodebutton", width: 320) {
                    onSelect(.listening)
                }
                .position(x: geo.size.width * 0.78, y: geo.size.height * 0.50)
            }
        }
        .onAppear {
            if musicEnabled {
                AudioManager.shared.playMusic(fileName: "menusong.caf", volume: 0.7)
            } else {
                AudioManager.shared.stopMusic()
            }
        }
    }
}

private struct ModeIconButton: View {
    let imageName: String
    let width: CGFloat
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .padding(18)                 // bigger hit area
                .contentShape(Rectangle())   // hit area matches visible space
        }
        .buttonStyle(.plain)
    }
}

#Preview("Root Mode – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
