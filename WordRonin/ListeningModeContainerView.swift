//ListeningModeContainerView
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
                    Image("backbutton")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 200, height: 70)
                }
            }
            .buttonStyle(.plain)
            .padding(.leading, 16)
            .padding(.top, 14)
            .zIndex(10)
        }
    }
}

#Preview("Listening Mode Container") {
    ListeningModeContainerView(onExit: {})
}
