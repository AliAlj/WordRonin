// ListeningModeContainerView.swift
import SwiftUI

struct ListeningModeContainerView: View {
    let onExit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {

            ListeningModeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .zIndex(0)

            Button {
                onExit()
            } label: {
                ZStack {
                    Image("fullbamboo")
                        .resizable()
                        .scaledToFit()
                        .scaleEffect(1.5)
                        .frame(width: 250, height: 180)
                    Text("Back")
                        .font(.system(size: 26, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .offset(y: -2)
                }
            }
            .buttonStyle(.plain)
            .offset(x: 20, y: -40)
            .zIndex(10)
        }
    }
}

#Preview("Listening Mode Container") {
    ListeningModeContainerView(onExit: {})
}
