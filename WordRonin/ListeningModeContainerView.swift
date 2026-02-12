import SwiftUI

struct ListeningModeContainerView: View {
    let onExit: () -> Void

    @State private var hasStarted: Bool = false
    @State private var showHowToPlay: Bool = false

    var body: some View {
        ZStack(alignment: .topLeading) {

            Image("sliceBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            // Main content only after Start is pressed
            if hasStarted {
                ListeningModeView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            // Back button
            Button {
                onExit()
            } label: {
                Image("backbutton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .padding(.top, 20)
            .zIndex(20)

            // Start overlay (like slice mode start popup)
            if !hasStarted {
                ListeningStartOverlay(
                    onStart: { hasStarted = true },
                    onHowToPlay: { showHowToPlay = true }
                )
                .zIndex(10)
            }

            // How to play overlay
            if showHowToPlay {
                ListeningHowToPlayOverlay(
                    onClose: { showHowToPlay = false }
                )
                .zIndex(30)
            }
        }
    }
}

#Preview("Listening Mode Container") {
    ListeningModeContainerView(onExit: {})
}
