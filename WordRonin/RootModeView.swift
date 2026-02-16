//RootModeView
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

    private struct Layout {
        static let sliceButtonSize = CGSize(width: 180, height: 360)
        static let listeningButtonSize = CGSize(width: 180, height: 360)

        static let settingsIconSizeCompact: CGFloat = 54
        static let settingsIconSizeRegular: CGFloat = 64
        static let settingsTopPadCompact: CGFloat = 10
        static let settingsTopPadRegular: CGFloat = 18
        static let settingsSidePadCompact: CGFloat = 10
        static let settingsSidePadRegular: CGFloat = 18

        // These are normalized points inside the ORIGINAL image (0...1).
        // Tweak these two numbers once until the buttons sit perfectly on your doors.
        static let leftDoorAnchor  = CGPoint(x: 0.262, y: 0.48)
        static let rightDoorAnchor = CGPoint(x: 0.738, y: 0.48)

        // Small pixel nudges after mapping (optional)
        static let leftDoorNudge  = CGSize(width: 0, height: 0)
        static let rightDoorNudge = CGSize(width: 0, height: 0)
    }

    var body: some View {
        GeometryReader { geo in
            let screenSize = geo.size
            let base = min(screenSize.width, screenSize.height)
            let isCompact = base < 700

            let topPad = geo.safeAreaInsets.top + (isCompact ? Layout.settingsTopPadCompact : Layout.settingsTopPadRegular)
            let trailingPad = geo.safeAreaInsets.trailing + (isCompact ? Layout.settingsSidePadCompact : Layout.settingsSidePadRegular)

            let bgImageSize = UIImage(named: "gameBackground")?.size ?? CGSize(width: 1, height: 1)
            let bgRect = aspectFillRect(imageSize: bgImageSize, in: screenSize)

            // Convert normalized points (0...1) into actual on-screen positions based on the bgRect
            let leftPos = point(in: bgRect, normalized: Layout.leftDoorAnchor, nudge: Layout.leftDoorNudge)
            let rightPos = point(in: bgRect, normalized: Layout.rightDoorAnchor, nudge: Layout.rightDoorNudge)

            ZStack(alignment: .topTrailing) {
                Color.black
                        .ignoresSafeArea()

                    Image("gameBackground")
                        .resizable()
                        .clipped()
                        .ignoresSafeArea()
                        .accessibilityHidden(true)
                
                Text("Select a mode")
                    .font(.largeTitle)
                    .foregroundColor(.clear)
                    .accessibilityLabel("Select a mode")
                    .accessibilityAddTraits(.isHeader)
                    .padding(.top, 1)

                Button { onOpenSettings() } label: {
                    Image("Settings Gear")
                        .resizable()
                        .scaledToFit()
                        .frame(
                            width: isCompact ? Layout.settingsIconSizeCompact : Layout.settingsIconSizeRegular,
                            height: isCompact ? Layout.settingsIconSizeCompact : Layout.settingsIconSizeRegular
                        )
                        .padding(isCompact ? 8 : 10)
                        .background(Color.black.opacity(0.25))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .buttonStyle(.plain)
                .padding(.top, topPad)
                .padding(.trailing, trailingPad)
                .zIndex(10)
                .accessibilityElement()
                .accessibilityLabel("Settings")
                .accessibilityHint("Opens sound and music settings")
                .accessibilityAddTraits(.isButton)

                // Door-anchored buttons (NOT an HStack)
                ModeIconButton(
                    imageName: "slicemodebutton",
                    size: Layout.sliceButtonSize,
                    axLabel: "Slice mode",
                    axHint: "Starts the slicing word game"
                ) { onSelect(.slice) }
                .position(leftPos)

                ModeIconButton(
                    imageName: "listenmodebutton",
                    size: Layout.listeningButtonSize,
                    axLabel: "Listening mode",
                    axHint: "Starts the listening word game"
                ) { onSelect(.listening) }
                .position(rightPos)
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

    private func aspectFillRect(imageSize: CGSize, in container: CGSize) -> CGRect {
        let iw = max(1, imageSize.width)
        let ih = max(1, imageSize.height)
        let cw = max(1, container.width)
        let ch = max(1, container.height)

        let scale = max(cw / iw, ch / ih)   // aspectFill
        let w = iw * scale
        let h = ih * scale

        let x = (cw - w) * 0.5
        let y = (ch - h) * 0.5

        return CGRect(x: x, y: y, width: w, height: h)
    }

    private func point(in rect: CGRect, normalized: CGPoint, nudge: CGSize) -> CGPoint {
        CGPoint(
            x: rect.minX + normalized.x * rect.width + nudge.width,
            y: rect.minY + normalized.y * rect.height + nudge.height
        )
    }
}

private struct ModeIconButton: View {
    let imageName: String
    let size: CGSize
    let axLabel: String
    let axHint: String
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: size.width, height: size.height)
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
