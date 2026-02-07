//GameViewController
import UIKit
import SpriteKit
final class GameViewController: UIViewController {
    private var scene: GameScene?
    override func viewDidLoad() {
        super.viewDidLoad()
        guard let skView = view as? SKView else { return }
        skView.backgroundColor = .clear
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let skView = view as? SKView else { return }
        if scene == nil {
            let s = GameScene(size: skView.bounds.size)
            s.scaleMode = .resizeFill
            skView.presentScene(s)
            scene = s
        } else {
            scene?.size = skView.bounds.size
        }
    }
    override var shouldAutorotate: Bool { true }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone {
            return .allButUpsideDown
        } else {
            return .all
        }
    }
    override var prefersStatusBarHidden: Bool { true }
}
