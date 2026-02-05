import SwiftUI
import SpriteKit
struct SliceModeContainerView: View {
    let onExit: () -> Void
    var body: some View {
        ZStack(alignment: .topLeading) {
            SpriteView(scene: {
                let scene = GameScene(size: CGSize(width: 1024, height: 768))
                scene.scaleMode = .resizeFill
                return scene
            }())
            .ignoresSafeArea()
            Button {
                onExit()
            } label: {
                Text("Back")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.35))
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .padding(.leading, 16)
            .padding(.top, 14)
        }
    }
}
#Preview("Slice Mode") {
    SliceModeContainerView(onExit: {})
}

