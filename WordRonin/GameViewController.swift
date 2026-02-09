// GameViewController.swift
import UIKit
import SpriteKit

final class GameViewController: UIViewController {

    private var scene: GameScene?

    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: false)

        guard let skView = view as? SKView else { return }
        skView.backgroundColor = .clear
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Also hide here (in case something re-shows it when pushing/popping)
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        // Optional: if you want other screens to have the nav bar again, re-enable it here.
        // If you never use the nav bar anywhere, you can delete this entire method.
        navigationController?.setNavigationBarHidden(false, animated: false)
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
