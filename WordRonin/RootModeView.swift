// RootModeView.swift
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
                Image("gameBackground")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .ignoresSafeArea()

                ModeIconButton(
                    imageName: "slicemodebutton",
                    onTap: { onSelect(.slice) }
                )
                .position(
                    x: geo.size.width * 0.25,
                    y: geo.size.height * 0.45
                )

                ModeIconButton(
                    imageName: "listenmodebutton",
                    onTap: { onSelect(.listening) }
                )
                .position(
                    x: geo.size.width * 0.76,
                    y: geo.size.height * 0.45
                )
            }
        }
    }
}

private struct ModeIconButton: View {
    let imageName: String
    let onTap: () -> Void

    var body: some View {
        Button {
            onTap()
        } label: {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 220)              // ✅ remove fixed height to avoid “bar”
                .shadow(radius: 6)
                .frame(width: 220, height: 80)  // ✅ keeps a nice tap target
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

#Preview("Mode Select", traits: .landscapeLeft) {
    RootModeView()
}
