// RootModeView
import SwiftUI

struct RootModeView: View {
    @State private var selectedMode: AppMode? = nil

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
                ModeSelectView(onSelect: { mode in
                    selectedMode = mode
                })
            }
        }
    }
}

private struct ModeSelectView: View {
    let onSelect: (AppMode) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                Image("sliceBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                ModeIconButton(
                    imageName: "katana",
                    title: "SLICE MODE",
                    imageSize: CGSize(width: 180, height: 180),
                    onTap: { onSelect(.slice) }
                )
                .position(
                    x: geo.size.width * 0.24,
                    y: geo.size.height * 0.5
                )

                ModeIconButton(
                    imageName: "ninja",
                    title: "LISTEN MODE",
                    imageSize: CGSize(width: 180, height: 180),
                    onTap: { onSelect(.listening) }
                )
                .position(
                    x: geo.size.width * 0.76,
                    y: geo.size.height * 0.5
                )
            }
        }
    }
}

private struct ModeIconButton: View {
    let imageName: String
    let title: String
    let imageSize: CGSize
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(spacing: 10) {
                Image(imageName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: imageSize.width, height: imageSize.height)
                    .shadow(radius: 8)

                Text(title)
                    .font(.system(size: 34, weight: .heavy, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(radius: 6)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 14)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Mode Select") {
    RootModeView()
}
