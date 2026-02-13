// ListeningModeContainerView.swift
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

            if hasStarted {
                ListeningModeView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

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
            .accessibilityLabel("Back")
            .accessibilityHint("Returns to mode selection")
            .accessibilityAddTraits(.isButton)

            if !hasStarted {
                ListeningStartOverlay(
                    onStart: { hasStarted = true },
                    onHowToPlay: { showHowToPlay = true }
                )
                .zIndex(10)
                .accessibilityAddTraits(.isModal)
            }

            if showHowToPlay {
                ListeningHowToPlayOverlay(
                    onClose: { showHowToPlay = false }
                )
                .zIndex(30)
                .accessibilityAddTraits(.isModal)
            }
        }
    }
}

#Preview("Listening Mode Container") {
    ListeningModeContainerView(onExit: {})
}
