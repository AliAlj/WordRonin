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
            let w = geo.size.width
            let h = geo.size.height

            let base = min(w, h)

            let isCompact = base < 700

            let buttonWidth = clamp(base * 0.3, min: 240, max: 380)
            let buttonSpacing = w * 0.3

            let topPad = geo.safeAreaInsets.top + (isCompact ? 10 : 18)
            let trailingPad = geo.safeAreaInsets.trailing + (isCompact ? 10 : 18)

            ZStack(alignment: .topTrailing) {

                Image("gameBackground")
                    .resizable()
                    .scaledToFill()
                    .ignoresSafeArea()

                Button {
                    onOpenSettings()
                } label: {
                    Image("Settings Gear")
                        .resizable()
                        .scaledToFit()
                        .frame(width: isCompact ? 54 : 64, height: isCompact ? 54 : 64)
                        .padding(isCompact ? 8 : 10)
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, topPad)
                .padding(.trailing, trailingPad)
                .zIndex(10)
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens sound and music settings")
                .accessibilityAddTraits(.isButton)

                VStack {
                    Spacer()

                    HStack(spacing: buttonSpacing) {

                        ModeIconButton(
                            imageName: "slicemodebutton",
                            width: buttonWidth,
                            axLabel: "Slice mode",
                            axHint: "Starts the slicing word game"
                        ) {
                            onSelect(.slice)
                        }

                        ModeIconButton(
                            imageName: "listenmodebutton",
                            width: buttonWidth,
                            axLabel: "Listening mode",
                            axHint: "Starts the listening word game"
                        ) {
                            onSelect(.listening)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, clamp(w * 0.06, min: 18, max: 80))
                    .offset(y: -h * 0.04)

                    Spacer()
                }
            }
        }
        .onAppear {
            if musicEnabled {
                AudioManager.shared.playMusic(fileName: "menusong.caf", volume: 0.7)
            } else {
                AudioManager.shared.stopMusic()
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

    private func clamp(_ value: CGFloat, min: CGFloat, max: CGFloat) -> CGFloat {
        Swift.max(min, Swift.min(max, value))
    }
}

private struct ModeIconButton: View {
    let imageName: String
    let width: CGFloat
    let axLabel: String
    let axHint: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: width)
                .padding(18)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(axLabel)
        .accessibilityHint(axHint)
        .accessibilityAddTraits(.isButton)
    }
}

#Preview("Root Mode – Landscape", traits: .landscapeLeft) {
    RootModeView()
}
