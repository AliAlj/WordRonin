// GameViewController.swift
import UIKit
import SpriteKit

final class GameViewController: UIViewController {
    private var scene: GameScene?
    private var axTimer: Timer?

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: false)

        guard let skView = view as? SKView else { return }
        skView.backgroundColor = .clear
        skView.ignoresSiblingOrder = true
        skView.showsFPS = true
        skView.showsNodeCount = true

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(voiceOverStatusChanged),
            name: UIAccessibility.voiceOverStatusDidChangeNotification,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationItem.hidesBackButton = true
        navigationController?.setNavigationBarHidden(true, animated: false)
        startAccessibilityRefreshLoop()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopAccessibilityRefreshLoop()
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

        refreshAccessibilityOnce()
    }

    override var shouldAutorotate: Bool { true }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        if UIDevice.current.userInterfaceIdiom == .phone { return .allButUpsideDown }
        return .all
    }

    override var prefersStatusBarHidden: Bool { true }

    @objc private func voiceOverStatusChanged() {
        if UIAccessibility.isVoiceOverRunning {
            startAccessibilityRefreshLoop()
        } else {
            stopAccessibilityRefreshLoop()
            if let skView = view as? SKView {
                skView.accessibilityElements = nil
            }
        }
    }

    private func startAccessibilityRefreshLoop() {
        stopAccessibilityRefreshLoop()
        guard UIAccessibility.isVoiceOverRunning else { return }

        axTimer = Timer.scheduledTimer(withTimeInterval: 0.30, repeats: true) { [weak self] _ in
            self?.refreshAccessibilityOnce()
        }
        if let axTimer {
            RunLoop.main.add(axTimer, forMode: .common)
        }
    }

    private func stopAccessibilityRefreshLoop() {
        axTimer?.invalidate()
        axTimer = nil
    }

    private func refreshAccessibilityOnce() {
        guard UIAccessibility.isVoiceOverRunning else { return }
        guard let skView = view as? SKView else { return }
        scene?.refreshAccessibility(in: skView)
    }
}
