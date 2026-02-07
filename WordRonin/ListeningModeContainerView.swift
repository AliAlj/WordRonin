// ListeningModeContainerView.swift
import SwiftUI

struct ListeningModeContainerView: View {
    let onExit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {

            // Make sure the content owns the whole screen and receives touches normally.
            ListeningModeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.clear)
                .zIndex(0)

            // Back button only, small hit area, doesn’t block the rest of the screen.
            Button {
                onExit()
            } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.10))
                    .foregroundStyle(.black)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .buttonStyle(.plain)
            .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .padding(.leading, 16)
            .padding(.top, 14)
            .zIndex(10)
        }
        // Important: ensures the ZStack itself isn't creating a giant tappable layer.
        .allowsHitTesting(true)
    }
}
