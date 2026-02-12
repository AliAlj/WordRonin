//
//  GameScene.swift
//  slicenspell
//
//  Created by Jad Aoun on 2/11/26.
//


import AVFoundation
import SpriteKit
import SwiftUI
import UIKit

final class GameScene: SKScene {

    // MARK: - State Properties
    // NOTE: 'internal' access (no keyword) is required for extensions in other files to see these.
    var score = 0 {
        didSet { gameScore.text = "Score: \(score)" }
    }
    
    var timeRemaining: Int = 0
    var roundActive: Bool = false
    var gameEnded = false
    var gameStarted = false
    var isClockTicking = false
    var safeInsets: UIEdgeInsets = .zero
    
    // Settings State
    var isSoundEnabled: Bool = true
    var isMusicEnabled: Bool = true
    
    // MARK: - Game Data
    var baseLetters: [Character] = []
    var selectedIndices: [Int] = []
    var possibleWords: Set<String> = []
    var foundWords: Set<String> = []
    
    // MARK: - Nodes & UI References
    var letterNodes: [SKSpriteNode] = []
    var activeSliceBG: SKShapeNode!
    var activeSliceFG: SKShapeNode!
    var activeSlicePoints = [CGPoint]()
    
    var gameScore: SKLabelNode!
    var timerLabel: SKLabelNode?
    var currentWordLabel: SKLabelNode?
    
    var inGameBackButton: SKNode?
    var startMenuButtonsContainer: SKNode?
    
    var scoreHud: SKNode?
    var timerHud: SKNode?
    
    // MARK: - Overlays
    var gameOverOverlay: SKNode?
    var startOverlay: SKNode?
    var tutorialOverlay: SKNode?
    var settingsOverlay: SKNode?
    
    // MARK: - System
    var roundTimer: Timer?
    let backgroundNodeName = "scene_background"
    
    // MARK: - Lifecycle
    override func didMove(to view: SKView) {
        if #available(iOS 11.0, *) {
            safeInsets = view.safeAreaInsets
        } else {
            safeInsets = .zero
        }

        ensureBackground(named: GameConfig.Assets.menuBackground)

        physicsWorld.gravity = CGVector(dx: 0, dy: 0)
        physicsWorld.speed = 0.85
        backgroundColor = .clear

        createScoreHUD()
        createSlices()
        createCurrentWordLabel()
        createTimerHUD()

        gameStarted = false
        roundActive = false
        gameEnded = false
        timeRemaining = 0
        updateTimerLabel()
        currentWordLabel?.text = ""

        hideInGameBackButton()
        showStartOverlay()

        AudioManager.shared.stopMusic()
        stopClockTick()
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        resizeBackground()

        // Re-layout active overlays if screen size changes
        if startOverlay != nil {
            startOverlay?.removeFromParent()
            startOverlay = nil
            showStartOverlay()
        }
        if tutorialOverlay != nil {
            tutorialOverlay?.removeFromParent()
            tutorialOverlay = nil
            showTutorialOverlay()
        }
        if gameOverOverlay != nil {
            gameOverOverlay?.removeFromParent()
            gameOverOverlay = nil
            showGameOverOverlay()
        }
        if settingsOverlay != nil {
            settingsOverlay?.removeFromParent()
            settingsOverlay = nil
            showSettingsOverlay()
        }

        positionHUD()
        positionTopLabels()

        if gameStarted && !gameEnded {
            showInGameBackButton()
        }
    }
    
    override func update(_ currentTime: TimeInterval) { }
}

#Preview("GameScene – iPad Landscape", traits: .landscapeLeft) {
    SpriteView(scene: {
        let scene = GameScene(size: CGSize(width: 1024, height: 768))
        scene.scaleMode = .aspectFill
        return scene
    }())
    .ignoresSafeArea()
}
