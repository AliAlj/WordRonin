// ListeningModeContainerView.swift
import SwiftUI

struct ListeningModeContainerView: View {
    let onExit: () -> Void
    @State private var hasStarted: Bool = false
    @State private var showHowToPlay: Bool = false

    var body: some View {
        ZStack {
            Image("sliceBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            if hasStarted {
                ListeningModeView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !hasStarted {
                ListeningStartOverlay(
                    onStart: { hasStarted = true },
                    onHowToPlay: { showHowToPlay = true }
                )
                .zIndex(10)
                .accessibilityAddTraits(.isModal)
            }

            if showHowToPlay {
                ListeningHowToPlayOverlay(onClose: { showHowToPlay = false })
                    .zIndex(30)
                    .accessibilityAddTraits(.isModal)
            }
        }
        // Back button pinned top-left, nudged down so it clears the notch
        .overlay(alignment: .topLeading) {
            Button { onExit() } label: {
                Image("backbutton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 110)
            }
            .buttonStyle(.plain)
            .padding(.leading, 2)
            .padding(.top, 74)
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to mode selection")
            .accessibilityAddTraits(.isButton)
        }
        .zIndex(50)
    }
}

#Preview("Listening Mode Container") {
    ListeningModeContainerView(onExit: {})
}
