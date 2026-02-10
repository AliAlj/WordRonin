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
                    Image("fullBamboo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 240, height: 90)

                    Text("Back")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .offset(y: -2)
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
