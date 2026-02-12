import SwiftUI

struct ListeningModeContainerView: View {
    let onExit: () -> Void

    var body: some View {
        ZStack(alignment: .topLeading) {

            // Same background as Slice Mode
            Image("sliceBackground")
                .resizable()
                .scaledToFill()
                .ignoresSafeArea()

            ListeningModeView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Back button using asset
            Button {
                onExit()
            } label: {
                Image("backbutton")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160)   // adjust if needed
            }
            .buttonStyle(.plain)
            .padding(.leading, 20)
            .padding(.top, 20)
        }
    }
}

#Preview("Listening Mode Container") {
    ListeningModeContainerView(onExit: {})
}
