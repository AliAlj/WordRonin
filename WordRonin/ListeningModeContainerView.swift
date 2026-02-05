import SwiftUI
struct ListeningModeContainerView: View {
    let onExit: () -> Void
    var body: some View {
        ZStack(alignment: .topLeading) {
            ListeningModeView()
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
            .padding(.leading, 16)
            .padding(.top, 14)
        }
    }
}
