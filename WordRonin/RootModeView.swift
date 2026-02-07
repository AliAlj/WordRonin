//RootModeView
import SwiftUI
struct RootModeView: View {
    @State private var selectedMode: AppMode? = nil
    var body: some View {
        Group {
            if let mode = selectedMode {
                switch mode {
                case .slice:
                    SliceModeContainerView(onExit: {
                        selectedMode = nil
                    })
                case .listening:
                    ListeningModeContainerView(onExit: {
                        selectedMode = nil
                    })
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
        ZStack {
            Color.black.opacity(0.95).ignoresSafeArea()
            VStack(spacing: 18) {
                Text("WordRonin")
                    .font(.system(size: 40, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                Text("Choose a mode")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.85))
                VStack(spacing: 12) {
                    Button {
                        onSelect(.slice)
                    } label: {
                        Text("Slice Mode")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(maxWidth: 320)
                            .frame(height: 52)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.white)
                    .foregroundStyle(.black)
                    Button {
                        onSelect(.listening)
                    } label: {
                        Text("Listening Mode")
                            .font(.system(size: 20, weight: .bold, design: .rounded))
                            .frame(maxWidth: 320)
                            .frame(height: 52)
                    }
                    .buttonStyle(.bordered)
                    .tint(.white)
                    .foregroundStyle(.white)
                }
                .padding(.top, 10)
                Text("Listening Mode reads scrambled letters out loud for accessibility.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.75))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 8)
            }
            .padding(.horizontal, 24)
        }
    }
}
