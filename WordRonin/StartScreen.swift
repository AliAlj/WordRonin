import SwiftUI

struct StartScreen: View {
    let onPickSlice: () -> Void
    let onPickListening: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            Spacer()

            Text("WordRonin")
                .font(.system(size: 42, weight: .bold, design: .rounded))

            Text("Pick a mode")
                .font(.system(size: 18, weight: .semibold))
                .opacity(0.8)

            VStack(spacing: 12) {
                Button(action: onPickSlice) {
                    Text("Slice Mode")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)

                Button(action: onPickListening) {
                    Text("Listening Mode")
                        .font(.system(size: 20, weight: .bold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 22)

            Spacer()
        }
    }
}
