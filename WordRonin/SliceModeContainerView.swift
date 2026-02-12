//SliceModeContainerView
import SwiftUI
import SpriteKit

struct SliceModeContainerView: View {
    let onExit: () -> Void

    var body: some View {
        SpriteView(scene: {
            let scene = GameScene(size: CGSize(width: 1024, height: 768))
            scene.scaleMode = .resizeFill
            return scene
        }())
        .ignoresSafeArea()
        .onReceive(NotificationCenter.default.publisher(for: .exitSliceMode)) { _ in
            onExit()
        }
    }
}

#Preview("Slice Mode") {
    SliceModeContainerView(onExit: {})
}
